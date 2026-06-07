import AppKit
import ApplicationServices

/// Beobachtet den Finder ueber die Accessibility-API und platziert jedes neu
/// geoeffnete Fenster gemaess den Einstellungen. Reagiert auf Finder-Neustarts.
final class FinderWatcher {
    private var observer: AXObserver?
    private var finderApp: AXUIElement?
    private var finderPID: pid_t = 0
    private(set) var isRunning = false

    private static let finderBundleID = "com.apple.finder"

    func start() {
        guard !isRunning else { return }
        isRunning = true
        attach()
        // Finder kann neu starten (z. B. nach „relaunch") - dann neu anhaengen.
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(appLaunched(_:)),
                       name: NSWorkspace.didLaunchApplicationNotification, object: nil)
    }

    func stop() {
        detach()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        isRunning = false
    }

    @objc private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == Self.finderBundleID else { return }
        // kurz warten, bis der Finder seine UI bereit hat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in self?.attach() }
    }

    // MARK: - Observer anhaengen

    private func attach() {
        guard let finder = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == Self.finderBundleID }) else { return }
        let pid = finder.processIdentifier
        if pid == finderPID, observer != nil { return }   // bereits aktuell

        detach()
        finderPID = pid
        let appEl = AXUIElementCreateApplication(pid)
        finderApp = appEl

        let callback: AXObserverCallback = { _, element, _, refcon in
            guard let refcon else { return }
            let watcher = Unmanaged<FinderWatcher>.fromOpaque(refcon).takeUnretainedValue()
            watcher.windowCreated(element)
        }

        var obs: AXObserver?
        guard AXObserverCreate(pid, callback, &obs) == .success, let obs else { return }
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        AXObserverAddNotification(obs, appEl, kAXWindowCreatedNotification as CFString, refcon)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(obs), .defaultMode)
        observer = obs
    }

    private func detach() {
        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(),
                                  AXObserverGetRunLoopSource(observer), .defaultMode)
        }
        observer = nil
        finderApp = nil
        finderPID = 0
    }

    // MARK: - Platzieren

    private func windowCreated(_ window: AXUIElement) {
        guard Settings.enabled else { return }
        // Dem Finder einen Moment geben, das Fenster fertig aufzubauen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            WindowPlacer.place(window)
        }
    }

    /// Manuell ausloesbar: platziert das vorderste Finder-Fenster sofort.
    func placeFrontmost() {
        attach()   // sicherstellen, dass wir am aktuellen Finder haengen
        guard let app = finderApp else { return }
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success,
           let value {
            // swiftlint:disable:next force_cast
            WindowPlacer.place(value as! AXUIElement)
        }
    }
}
