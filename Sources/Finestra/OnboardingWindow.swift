import AppKit
import SwiftUI

/// Geführter Einrichtungs-Assistent beim ersten Start.
final class OnboardingWindow {
    static let shared = OnboardingWindow()
    private var window: NSWindow?

    var isOpen: Bool { window != nil }

    func present() {
        if window == nil {
            let controller = NSHostingController(rootView: OnboardingView(onFinish: { [weak self] in
                self?.close()
            }))
            let win = NSWindow(contentViewController: controller)
            win.title = Strings.appName
            win.styleMask = [.titled]            // kein Schliessen-Knopf → Skip/Fertig nutzen
            win.isReleasedWhenClosed = false
            win.level = .floating
            window = win
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func close() {
        window?.orderOut(nil)
        window = nil
    }
}

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step = 0
    @State private var targetMode = Settings.targetMode
    @State private var targetID = Settings.targetDisplayID
    @State private var cfg = Settings.defaultConfig
    @State private var screens = ScreenInfo.all()

    /// Welche Monitore im Assistenten konfiguriert werden: bei Maus alle, bei festem Ziel nur dieser.
    private var monitorsToConfigure: [ScreenInfo] {
        if targetMode == 1, let t = ScreenInfo.byID(targetID, in: screens) { return [t] }
        return screens
    }
    private var monitorCount: Int { monitorsToConfigure.count }
    private var totalSteps: Int { 2 + monitorCount + 1 }   // Willkommen, Ziel, je Monitor, Fertig
    private var isLast: Bool { step >= totalSteps - 1 }

    private var currentMonitor: ScreenInfo? {
        let i = step - 2
        guard i >= 0, i < monitorsToConfigure.count else { return nil }
        return monitorsToConfigure[i]
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                content.padding(28)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footer.padding(16)
        }
        .frame(width: 580, height: 600)
        .onChange(of: step) { _ in
            if let m = currentMonitor { cfg = Settings.config(forKey: m.stableKey) }
        }
        .onChange(of: cfg) { c in
            if let m = currentMonitor { Settings.setConfig(c, forKey: m.stableKey) }
        }
    }

    @ViewBuilder private var content: some View {
        if step == 0 {
            welcomePage
        } else if step == 1 {
            targetPage
        } else if step >= 2 && step < 2 + monitorCount {
            monitorPage
        } else {
            donePage
        }
    }

    // MARK: - Seiten

    private var welcomePage: some View {
        VStack(alignment: .center, spacing: 18) {
            Spacer(minLength: 20)
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon).resizable().frame(width: 96, height: 96)
            }
            Text(Strings.obWelcomeTitle).font(.title.bold())
            Text(Strings.obWelcomeBody)
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 420)
            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity)
    }

    private var targetPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Strings.obTargetTitle).font(.title2.bold())
            Text(Strings.obTargetBody).font(.callout).foregroundStyle(.secondary)
            VStack(spacing: 8) {
                targetRow(title: Strings.targetMouse, selected: targetMode != 1) {
                    targetMode = 2; Settings.targetMode = 2
                }
                ForEach(screens) { s in
                    targetRow(title: ScreenInfo.displayName(s, in: screens),
                              selected: targetMode == 1 && targetID == s.id) {
                        targetMode = 1; targetID = s.id
                        Settings.targetMode = 1; Settings.targetDisplayID = s.id
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func targetRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                Text(title).foregroundStyle(.primary)
                Spacer()
            }
            .padding(.vertical, 10).padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(selected ? Color.accentColor.opacity(0.12) : Color.gray.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(selected ? Color.accentColor : Color.gray.opacity(0.3),
                              lineWidth: selected ? 1.5 : 1))
        }
        .buttonStyle(.plain)
    }

    private var monitorPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Strings.obConfigTitle).font(.title2.bold())
            if let m = currentMonitor {
                Text(Strings.obConfigFor(ScreenInfo.displayName(m, in: screens)))
                    .font(.callout.weight(.medium))
            }
            Text(Strings.obConfigBody).font(.caption).foregroundStyle(.secondary)

            MonitorMap(screens: screens,
                       highlightID: currentMonitor?.id,
                       previewRect: previewRect,
                       hint: { ScreenInfo.lageHint($0, in: screens) },
                       onSelect: { _ in },
                       dimOthers: true)
                .frame(height: 130)
                .frame(maxWidth: .infinity)

            GroupBox(label: Text(Strings.sectionSize).font(.subheadline).bold()) {
                SizeEditor(cfg: $cfg).padding(.top, 4)
            }
            GroupBox(label: Text(Strings.sectionPosition).font(.subheadline).bold()) {
                PositionEditor(cfg: $cfg).padding(.top, 4)
            }
        }
    }

    private var donePage: some View {
        VStack(alignment: .center, spacing: 18) {
            Spacer(minLength: 20)
            Image(systemName: "checkmark.circle.fill")
                .resizable().frame(width: 72, height: 72)
                .foregroundStyle(Color.accentColor)
            Text(Strings.obDoneTitle).font(.title.bold())
            Text(Strings.obDoneBody)
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 440)
            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity)
    }

    private var previewRect: CGRect? {
        guard let m = currentMonitor else { return nil }
        return cfg.rect(in: m.visibleQuartz)
    }

    // MARK: - Fusszeile

    private var footer: some View {
        HStack {
            if step == 0 {
                Button(Strings.obSkip) { finish() }.buttonStyle(.plain).foregroundStyle(.secondary)
            } else if !isLast {
                Button(Strings.obBack) { step -= 1 }
            }
            Spacer()
            Text(Strings.obStepOf(step + 1, totalSteps))
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            if isLast {
                Button(Strings.obFinish) { finish() }.keyboardShortcut(.defaultAction)
            } else {
                Button(step == 0 ? Strings.obStart : Strings.obNext) { step += 1 }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func finish() {
        Settings.onboardingDone = true
        onFinish()
    }
}
