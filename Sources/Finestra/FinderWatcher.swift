import AppKit
import ApplicationServices

// Private, aber stabile API (auch von Fenstermanagern genutzt): liefert die
// CGWindowID eines AX-Fensters - damit verfolgen wir Fenster eindeutig und
// platzieren jedes nur EINMAL (sonst koennte man Fenster nicht mehr von Hand groesser ziehen).
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement,
                                   _ identifier: UnsafeMutablePointer<CGWindowID>) -> AXError

/// Beobachtet den Finder und platziert jedes neu geoeffnete Fenster gemaess den
/// Einstellungen. Nutzt eine AX-Benachrichtigung (sofort) UND ein Polling als
/// Backup, falls die Benachrichtigung mal ausbleibt.
final class FinderWatcher {
    private var observer: AXObserver?
    private var finderApp: AXUIElement?
    private var finderPID: pid_t = 0
    private var seen: Set<CGWindowID> = []
    private var pollTimer: Timer?
    private(set) var isRunning = false

    private static let finderBundleID = "com.apple.finder"

    func start() {
        guard !isRunning else { return }
        isRunning = true
        Log.log("Watcher: Start")
        attach(seedExisting: true)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(appLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in self?.scan() }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    func stop() {
        pollTimer?.invalidate(); pollTimer = nil
        detach()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        isRunning = false
    }

    @objc private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier == Self.finderBundleID else { return }
        Log.log("Watcher: Finder neu gestartet")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.attach(seedExisting: true)
        }
    }

    // MARK: - Anhängen

    private func attach(seedExisting: Bool) {
        guard let finder = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == Self.finderBundleID }) else {
            Log.log("Watcher: Finder laeuft nicht"); return
        }
        let pid = finder.processIdentifier
        if pid != finderPID {
            detach()
            finderPID = pid
            seen.removeAll()
            let appEl = AXUIElementCreateApplication(pid)
            finderApp = appEl

            let callback: AXObserverCallback = { _, _, _, refcon in
                guard let refcon else { return }
                let watcher = Unmanaged<FinderWatcher>.fromOpaque(refcon).takeUnretainedValue()
                DispatchQueue.main.async { watcher.scan() }
            }
            var obs: AXObserver?
            if AXObserverCreate(pid, callback, &obs) == .success, let obs {
                let refcon = Unmanaged.passUnretained(self).toOpaque()
                AXObserverAddNotification(obs, appEl, kAXWindowCreatedNotification as CFString, refcon)
                CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(obs), .defaultMode)
                observer = obs
                Log.log("Watcher: an Finder angehaengt (pid \(pid))")
            } else {
                Log.log("Watcher: AXObserverCreate fehlgeschlagen - Polling uebernimmt")
            }
        }
        if seedExisting {
            seen = currentWindowIDs()
            Log.log("Watcher: \(seen.count) bestehende Fenster gemerkt (werden nicht verschoben)")
        }
    }

    private func detach() {
        if let observer {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(),
                                  AXObserverGetRunLoopSource(observer), .defaultMode)
        }
        observer = nil; finderApp = nil; finderPID = 0
    }

    // MARK: - Fenster lesen

    private func windows() -> [AXUIElement] {
        guard let app = finderApp else { return [] }
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success
        else { return [] }
        return value as? [AXUIElement] ?? []
    }

    private func windowID(_ element: AXUIElement) -> CGWindowID? {
        var id: CGWindowID = 0
        return _AXUIElementGetWindow(element, &id) == .success && id != 0 ? id : nil
    }

    private func currentWindowIDs() -> Set<CGWindowID> {
        Set(windows().compactMap { windowID($0) })
    }

    private func isStandardWindow(_ element: AXUIElement) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &value) == .success,
              let subrole = value as? String else { return true }   // unbekannt → wie normal behandeln
        return subrole == (kAXStandardWindowSubrole as String)
    }

    // MARK: - Scan + Platzieren

    /// Sucht neue Finder-Fenster und platziert sie genau einmal.
    private func scan() {
        // Finder neu gestartet? Dann neu anhaengen und diesen Durchlauf auslassen.
        if let finder = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == Self.finderBundleID }),
           finder.processIdentifier != finderPID {
            attach(seedExisting: true)
            return
        }
        guard Settings.enabled else { return }

        let wins = windows()
        var present: Set<CGWindowID> = []
        for window in wins {
            guard let id = windowID(window) else { continue }
            present.insert(id)
            if seen.contains(id) { continue }
            seen.insert(id)
            guard isStandardWindow(window) else {
                Log.log("Neues Fenster \(id): kein Standardfenster → uebersprungen")
                continue
            }
            Log.log("Neues Fenster \(id) erkannt")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                WindowPlacer.place(window, windowID: id)
            }
        }
        // Geschlossene Fenster vergessen.
        seen.formIntersection(present)
    }

    /// Manuell: vorderstes Finder-Fenster platzieren.
    func placeFrontmost() {
        guard let app = finderApp else { Log.log("Manuell: kein Finder"); return }
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success,
           let value {
            // swiftlint:disable:next force_cast
            let window = value as! AXUIElement
            Log.log("Manuell: platziere vorderstes Fenster")
            WindowPlacer.place(window, windowID: windowID(window))
        } else {
            Log.log("Manuell: kein vorderstes Fenster gefunden")
        }
    }
}
