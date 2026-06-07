import AppKit
import SwiftUI

/// Traegt das SwiftUI-Einstellungsfenster und reicht Aktionen an den AppDelegate.
final class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    var onToggleLogin: ((Bool) -> Void)?
    var onCheckUpdate: (() -> Void)?
    var onShowLog: (() -> Void)?
    var loginEnabled: (() -> Bool)?

    func present() {
        if window == nil { build() }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func build() {
        let view = SettingsView(
            onToggleLogin: { [weak self] on in self?.onToggleLogin?(on) },
            onCheckUpdate: { [weak self] in self?.onCheckUpdate?() },
            onShowLog: { [weak self] in self?.onShowLog?() },
            loginEnabled: { [weak self] in self?.loginEnabled?() ?? false }
        )
        let controller = NSHostingController(rootView: view)
        controller.sizingOptions = [.preferredContentSize]
        let win = NSWindow(contentViewController: controller)
        win.title = Strings.appName
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.isReleasedWhenClosed = false
        window = win
    }
}
