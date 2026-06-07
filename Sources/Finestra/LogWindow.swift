import AppKit
import SwiftUI

/// Fenster mit dem Finestra-Protokoll (live aktualisiert).
final class LogWindow {
    static let shared = LogWindow()
    private var window: NSWindow?

    func present() {
        if window == nil {
            let controller = NSHostingController(rootView: LogView())
            let win = NSWindow(contentViewController: controller)
            win.title = Strings.logTitle
            win.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            win.setContentSize(NSSize(width: 660, height: 460))
            win.isReleasedWhenClosed = false
            window = win
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}

struct LogView: View {
    @State private var text = Log.readTail()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Strings.logTitle).font(.headline)
                Spacer()
                Button(Strings.logRefresh) { text = Log.readTail() }
                Button(Strings.logClear) { Log.clear(); text = "" }
                Button(Strings.logReveal) {
                    NSWorkspace.shared.activateFileViewerSelecting([Log.fileURL])
                }
            }
            Text(Strings.logHint)
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    Text(text.isEmpty ? Strings.logEmpty : text)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("logbottom")
                }
                .onChange(of: text) { _ in
                    proxy.scrollTo("logbottom", anchor: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
        .frame(minWidth: 520, minHeight: 360)
        .onReceive(Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()) { _ in
            text = Log.readTail()
        }
    }
}
