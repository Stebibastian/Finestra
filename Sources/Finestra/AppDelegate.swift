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
        Strings.lang = Settings.resolvedLanguage   // Sprache VOR dem ersten Text-/Menüaufbau setzen
        NSApp.setActivationPolicy(.accessory)
        setupMainMenu()
        setupStatusItem()
        configureSettingsWindow()

        if offerMoveToApplications() { return }   // verschiebt + startet neu → Rest ueberspringen
        autoCheckForUpdates()

        promptAccessibility()
        trustedAtLaunch = AXIsProcessTrusted()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let modeLabel = Settings.targetMode == 1 ? "Fester Monitor" : "Maus"
        Log.log("Finestra \(version) gestartet | Bedienungshilfen: \(trustedAtLaunch ? "erteilt" : "NICHT erteilt") | aktiv: \(Settings.enabled) | Modus: \(modeLabel)")
        if trustedAtLaunch {
            watcher.start()
            maybeShowOnboarding()
        } else {
            Log.log("Watcher startet nicht - warte auf Bedienungshilfen-Freigabe")
            startTrustBackupPolling()
        }

        // Auf Aenderung der Bedienungshilfen-Freigabe lauschen und dann neu starten -
        // ein frischer Prozess erhaelt den Accessibility-Zugriff zuverlaessig.
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(accessibilityChanged),
            name: NSNotification.Name("com.apple.accessibility.api"), object: nil)
    }

    // MARK: - Hauptmenü (damit Cmd-C/V/X/A/Z in Textfeldern funktionieren)

    /// Eine Menüleisten-App ohne Hauptmenü bekommt kein „Bearbeiten"-Menü - dann
    /// greifen die Standard-Tastenkürzel in Textfeldern nicht. Wir setzen daher ein
    /// minimales Hauptmenü (App + Bearbeiten); es erscheint nur, wenn ein Finestra-
    /// Fenster aktiv ist, und macht Kopieren/Einsetzen/Alles-auswählen verfügbar.
    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        let settingsItem = appMenu.addItem(withTitle: Strings.menuSettings,
                                           action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: Strings.menuQuit,
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Bearbeiten")
        editMenu.addItem(withTitle: "Widerrufen", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Wiederholen", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Ausschneiden", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Kopieren", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Einsetzen", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Alles auswählen", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
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
        menu.addItem(NSMenuItem(title: Strings.menuLog,
                                action: #selector(openLog), keyEquivalent: ""))
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
        SettingsWindow.shared.onShowLog = { [weak self] in self?.openLog() }
        SettingsWindow.shared.onLanguageChange = { [weak self] lang in
            Settings.appLanguage = lang
            self?.relaunchSelf()   // Neustart, damit Menü und alle Texte in der neuen Sprache neu aufgebaut werden
        }
        SettingsWindow.shared.loginEnabled = { SMAppService.mainApp.status == .enabled }
    }

    @objc private func openSettings() { SettingsWindow.shared.present() }

    @objc private func placeNow() {
        guard AXIsProcessTrusted() else { promptAccessibility(); return }
        watcher.placeFrontmost()
    }

    @objc private func openLog() { LogWindow.shared.present() }

    /// Beim ersten Start (noch nicht abgeschlossen) den Einrichtungs-Assistenten zeigen.
    private func maybeShowOnboarding() {
        guard !Settings.onboardingDone else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            OnboardingWindow.shared.present()
        }
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
            if Settings.autoUpdate {
                self?.runUpdate()              // still im Hintergrund installieren
            } else {
                self?.showUpdateAlert(info)
            }
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
        let host = NSHostingView(rootView: UpdateView(notes: info.notes))
        host.frame.size = host.fittingSize
        alert.accessoryView = host
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

    /// Kleines Fenster mit laufendem Balken, sichtbar bis das Skript die App neu startet.
    private var updateProgressWindow: NSWindow?
    private func showUpdateProgress() {
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 130),
                           styleMask: [.titled], backing: .buffered, defer: false)
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.level = .floating
        win.isReleasedWhenClosed = false
        win.contentView = NSHostingView(rootView: UpdateProgressView())
        win.center()
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        updateProgressWindow = win
    }

    /// Laedt + installiert die neueste notarisierte Version (web-install.sh) und startet neu.
    /// Losgeloest gestartet (nohup + &), damit es den pkill der App ueberlebt.
    private func runUpdate() {
        showUpdateProgress()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c",
            "nohup /bin/bash -c '\(UpdateChecker.installCommand)' >/tmp/finestra-update.log 2>&1 &"]
        do {
            try task.run()
        } catch {
            updateProgressWindow?.orderOut(nil)
            infoAlert(Strings.appName, Strings.updateFailBody)
        }
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
