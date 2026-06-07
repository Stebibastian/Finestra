import AppKit
import SwiftUI
import ApplicationServices
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let watcher = FinderWatcher()
    private var trustTimer: Timer?
    private var didForceRelaunch = false
    private var trustedAtLaunch = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        configureSettingsWindow()

        if offerMoveToApplications() { return }   // verschiebt + startet neu → Rest ueberspringen
        autoCheckForUpdates()

        promptAccessibility()
        trustedAtLaunch = AXIsProcessTrusted()
        if trustedAtLaunch {
            watcher.start()
        } else {
            startTrustBackupPolling()
        }

        // Auf Aenderung der Bedienungshilfen-Freigabe lauschen und dann neu starten -
        // ein frischer Prozess erhaelt den Accessibility-Zugriff zuverlaessig.
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(accessibilityChanged),
            name: NSNotification.Name("com.apple.accessibility.api"), object: nil)
    }

    // MARK: - Statusleiste

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            button.image = NSImage(systemSymbolName: "macwindow.on.rectangle",
                                   accessibilityDescription: Strings.statusTooltip)?
                .withSymbolConfiguration(config)
            button.image?.isTemplate = true
            button.toolTip = Strings.statusTooltip
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: Strings.menuSettings,
                                action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: Strings.menuPlaceNow,
                                action: #selector(placeNow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: Strings.menuCheckUpdate,
                                action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: Strings.menuQuit,
                                action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items where item.action != nil { item.target = self }
        statusItem.menu = menu
    }

    // MARK: - Einstellungen

    private func configureSettingsWindow() {
        SettingsWindow.shared.onToggleLogin = { [weak self] on in self?.setLogin(on) }
        SettingsWindow.shared.onCheckUpdate = { [weak self] in self?.checkForUpdates() }
        SettingsWindow.shared.loginEnabled = { SMAppService.mainApp.status == .enabled }
    }

    @objc private func openSettings() { SettingsWindow.shared.present() }

    @objc private func placeNow() {
        guard AXIsProcessTrusted() else { promptAccessibility(); return }
        watcher.placeFrontmost()
    }

    private func setLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            infoAlert(Strings.appName, error.localizedDescription)
        }
    }

    // MARK: - Bedienungshilfen

    private func promptAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    @objc private func accessibilityChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, !self.didForceRelaunch else { return }
            if AXIsProcessTrusted() != self.trustedAtLaunch {
                self.didForceRelaunch = true
                self.relaunchSelf()
            }
        }
    }

    private func startTrustBackupPolling() {
        trustTimer?.invalidate()
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if self.didForceRelaunch { timer.invalidate(); return }
            if !self.trustedAtLaunch && AXIsProcessTrusted() {
                self.didForceRelaunch = true
                timer.invalidate()
                self.trustTimer = nil
                self.relaunchSelf()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        trustTimer = timer
    }

    private func relaunchSelf() {
        let path = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c",
            "while /bin/kill -0 \(pid) 2>/dev/null; do sleep 0.2; done; /usr/bin/open \"\(path)\""]
        try? process.run()
        NSApp.terminate(nil)
    }

    // MARK: - Verschieben nach /Applications

    @discardableResult
    private func offerMoveToApplications() -> Bool {
        let path = Bundle.main.bundlePath
        guard !path.hasPrefix("/Applications/"), !Settings.moveDeclined else { return false }
        if path.contains("/.build/") || path.contains("/DerivedData/") { return false }

        let folder = (path as NSString).deletingLastPathComponent
        let alert = NSAlert()
        alert.messageText = Strings.moveTitle
        alert.informativeText = Strings.moveBody((folder as NSString).lastPathComponent)
        alert.addButton(withTitle: Strings.moveNow)
        alert.addButton(withTitle: Strings.moveLater)
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            moveToApplications()
            return true
        }
        Settings.moveDeclined = true
        return false
    }

    private func moveToApplications() {
        let src = Bundle.main.bundlePath
        let dest = "/Applications/" + (src as NSString).lastPathComponent
        let inner = "sleep 1; rm -rf '\(dest)'; mv '\(src)' '\(dest)' && open '\(dest)'"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", "nohup bash -c \"\(inner)\" >/tmp/finestra-move.log 2>&1 &"]
        do {
            try task.run()
            NSApp.terminate(nil)
        } catch {
            infoAlert(Strings.appName, Strings.moveFailed)
        }
    }

    // MARK: - Updates

    private func autoCheckForUpdates() {
        let last = UserDefaults.standard.double(forKey: "lastUpdateCheck")
        let now = Date().timeIntervalSince1970
        guard now - last > 86_400 else { return }
        UserDefaults.standard.set(now, forKey: "lastUpdateCheck")
        UpdateChecker.check { [weak self] result in
            guard case .success(let info?) = result else { return }
            self?.showUpdateAlert(info)
        }
    }

    @objc private func checkForUpdates() {
        UpdateChecker.check { [weak self] result in
            switch result {
            case .success(let info?):
                self?.showUpdateAlert(info)
            case .success(nil):
                self?.infoAlert(Strings.updateNoneTitle,
                                Strings.updateNoneBody(UpdateChecker.currentVersion))
            case .failure:
                self?.infoAlert(Strings.updateFailTitle, Strings.updateFailBody)
            }
        }
    }

    private func showUpdateAlert(_ info: UpdateInfo) {
        let alert = NSAlert()
        alert.messageText = Strings.updateTitle(info.version)
        let notes = info.notes.count > 600 ? String(info.notes.prefix(600)) + " …" : info.notes
        alert.informativeText = notes.isEmpty ? " " : notes
        alert.addButton(withTitle: Strings.updateInstall)
        alert.addButton(withTitle: Strings.updatePage)
        alert.addButton(withTitle: Strings.updateLater)
        NSApp.activate(ignoringOtherApps: true)
        switch alert.runModal() {
        case .alertFirstButtonReturn: runUpdate()
        case .alertSecondButtonReturn:
            if let url = URL(string: info.pageURL) { NSWorkspace.shared.open(url) }
        default: break
        }
    }

    /// Laedt + installiert die neueste notarisierte Version (web-install.sh) und startet neu.
    /// Losgeloest gestartet (nohup + &), damit es den pkill der App ueberlebt.
    private func runUpdate() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c",
            "nohup /bin/bash -c '\(UpdateChecker.installCommand)' >/tmp/finestra-update.log 2>&1 &"]
        try? task.run()
    }

    private func infoAlert(_ title: String, _ body: String) {
        let a = NSAlert()
        a.messageText = title
        a.informativeText = body
        a.addButton(withTitle: Strings.ok)
        NSApp.activate(ignoringOtherApps: true)
        a.runModal()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
