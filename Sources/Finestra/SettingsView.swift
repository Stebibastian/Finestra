import SwiftUI
import AppKit

/// Auswahl im Zielmonitor-Picker: aktiver Monitor (Maus) oder ein fester Monitor.
enum TargetChoice: Hashable {
    case mouse
    case display(UInt32)
}

/// Das Einstellungsfenster. Reihenfolge: Zielmonitor → Grösse → Monitor-Ansicht → Position.
struct SettingsView: View {
    let onToggleLogin: (Bool) -> Void
    let onCheckUpdate: () -> Void
    let onShowLog: () -> Void
    let onLanguageChange: (String) -> Void
    let loginEnabled: () -> Bool

    @State private var enabled = Settings.enabled
    @State private var targetMode = Settings.targetMode
    @State private var targetID = Settings.targetDisplayID
    @State private var focusedID: UInt32 = 0
    @State private var cfg = Settings.defaultConfig
    @State private var login = false
    @State private var screens: [ScreenInfo] = ScreenInfo.all()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            box(Strings.sectionTarget) { targetControls }
            box(boxTitle(Strings.sectionSize)) { SizeEditor(cfg: $cfg) }
            box(Strings.sectionMonitors) { mapControls }
            box(boxTitle(Strings.sectionPosition)) { PositionEditor(cfg: $cfg) }
            box(Strings.sectionGeneral) { generalControls }
        }
        .padding(20)
        .frame(width: 540)
        .onAppear {
            screens = ScreenInfo.all()
            login = loginEnabled()
            focusedID = initialFocus()
            cfg = Settings.config(forKey: focusedKey)
        }
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refreshScreens()
        }
        .onChange(of: focusedID) { _ in cfg = Settings.config(forKey: focusedKey) }
        .onChange(of: cfg) { c in Settings.setConfig(c, forKey: focusedKey) }
        .onChange(of: enabled) { v in Settings.enabled = v }
        .onChange(of: targetMode) { v in Settings.targetMode = v }
        .onChange(of: targetID) { v in Settings.targetDisplayID = v }
    }

    // MARK: - Kopf

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.appName).font(.title2.bold())
                Text(Strings.tagline).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(Strings.enabledLabel, isOn: $enabled).toggleStyle(.switch)
        }
    }

    // MARK: - Zielmonitor

    private var targetControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("", selection: Binding<TargetChoice>(
                get: { targetMode == 1 ? .display(targetID) : .mouse },
                set: { choice in
                    switch choice {
                    case .mouse: targetMode = 2
                    case .display(let id): targetMode = 1; targetID = id; focusedID = id
                    }
                })) {
                Text(Strings.targetMouse).tag(TargetChoice.mouse)
                ForEach(screens) { s in
                    Text(hintedName(for: s)).tag(TargetChoice.display(s.id))
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Text(targetMode == 1 ? Strings.targetFixedHint : Strings.targetMouseHint)
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Monitor-Ansicht (Vorschau + Auswahl des zu bearbeitenden Monitors)

    private var mapControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            MonitorMap(screens: screens,
                       highlightID: focusedID,
                       previewRect: previewRect,
                       hint: { positionHint(for: $0) },
                       onSelect: { setFocus($0) })
                .frame(height: 170)
                .frame(maxWidth: .infinity)
            if !mapCaption.isEmpty {
                Text(mapCaption)
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Allgemein

    private var generalControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(Strings.launchAtLogin, isOn: Binding(
                get: { login },
                set: { v in login = v; onToggleLogin(v) }))
                .toggleStyle(.switch)
            HStack {
                Text(Strings.language)
                Spacer()
                Picker("", selection: Binding<String>(
                    get: { Settings.appLanguage },
                    set: { onLanguageChange($0) })) {
                    Text(Strings.languageSystem).tag("system")
                    Text("Deutsch").tag("de")
                    Text("English").tag("en")
                    Text("Français").tag("fr")
                    Text("Español").tag("es")
                    Text("Italiano").tag("it")
                }
                .labelsHidden()
                .frame(width: 170)
            }
            Divider()
            HStack {
                Button(Strings.logButton) { onShowLog() }.controlSize(.small)
                Spacer()
            }
            HStack {
                Text("\(Strings.version) \(UpdateChecker.currentVersion)")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(Strings.checkUpdate) { onCheckUpdate() }.controlSize(.small)
            }
        }
    }

    // MARK: - Hilfen

    private func box<Content: View>(_ title: String,
                                    @ViewBuilder _ content: () -> Content) -> some View {
        GroupBox(label: Text(title).font(.subheadline).bold()) {
            VStack(alignment: .leading, spacing: 10) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
    }

    /// Monitorname samt Lage-Hinweis (links/rechts/…) und „Haupt".
    private func hintedName(for s: ScreenInfo) -> String {
        var parts: [String] = []
        let hint = positionHint(for: s)
        if !hint.isEmpty { parts.append(hint) }
        if s.isMain { parts.append(Strings.hintMain) }
        return parts.isEmpty ? s.name : "\(s.name) - \(parts.joined(separator: ", "))"
    }

    /// Lage eines Monitors relativ zu den anderen: links/rechts bzw. oben/unten.
    private func positionHint(for s: ScreenInfo) -> String {
        guard screens.count > 1 else { return "" }
        let xs = Set(screens.map { Int($0.frameQuartz.minX.rounded()) })
        if xs.count == screens.count {
            let sorted = screens.sorted { $0.frameQuartz.minX < $1.frameQuartz.minX }
            if s.id == sorted.first?.id { return Strings.hintLeft }
            if s.id == sorted.last?.id { return Strings.hintRight }
            return Strings.hintCenter
        }
        let sorted = screens.sorted { $0.frameQuartz.minY < $1.frameQuartz.minY }
        if s.id == sorted.first?.id { return Strings.hintTop }
        if s.id == sorted.last?.id { return Strings.hintBottom }
        return ""
    }

    private func boxTitle(_ base: String) -> String {
        guard screens.count > 1, !focusedLabel.isEmpty else { return base }
        return "\(base) · \(focusedLabel)"
    }

    private var focusedLabel: String {
        guard let s = ScreenInfo.byID(focusedID, in: screens) else { return "" }
        let h = positionHint(for: s)
        return h.isEmpty ? s.name : h.capitalized
    }

    private var focusedKey: String {
        ScreenInfo.byID(focusedID, in: screens)?.stableKey ?? ""
    }

    private var mapCaption: String {
        guard screens.count > 1 else { return "" }
        return targetMode == 1 ? Strings.mapHintFixed : Strings.mapHintEdit
    }

    private func initialFocus() -> UInt32 {
        if targetMode == 1, ScreenInfo.byID(targetID, in: screens) != nil { return targetID }
        if let m = ScreenInfo.main(in: screens) { return m.id }
        return screens.first?.id ?? 0
    }

    private func setFocus(_ id: UInt32) {
        focusedID = id
        if targetMode == 1 { targetID = id }
    }

    private func refreshScreens() {
        screens = ScreenInfo.all()
        if ScreenInfo.byID(focusedID, in: screens) == nil {
            focusedID = ScreenInfo.main(in: screens)?.id ?? screens.first?.id ?? 0
        }
    }

    private var previewScreen: ScreenInfo? {
        ScreenInfo.byID(focusedID, in: screens) ?? ScreenInfo.main(in: screens) ?? screens.first
    }

    private var previewRect: CGRect? {
        guard let s = previewScreen else { return nil }
        return cfg.rect(in: s.visibleQuartz)
    }
}

/// Zeichnet die angeschlossenen Monitore massstabsgetreu samt Vorschau-Fenster.
/// Ein Klick auf einen Monitor wählt ihn (Zielmonitor bzw. zu bearbeitenden Monitor).
struct MonitorMap: View {
    let screens: [ScreenInfo]
    let highlightID: UInt32?
    let previewRect: CGRect?
    let hint: (ScreenInfo) -> String
    let onSelect: (UInt32) -> Void

    var body: some View {
        GeometryReader { geo in
            let layout = MapLayout(screens: screens, area: geo.size)
            ZStack(alignment: .topLeading) {
                ForEach(screens) { screen in
                    cell(for: screen, layout: layout)
                }
                if let pr = previewRect {
                    let r = layout.transform(pr)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.accentColor.opacity(0.9))
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(.white.opacity(0.75), lineWidth: 1))
                        .frame(width: max(r.width, 6), height: max(r.height, 6))
                        .position(x: r.midX, y: r.midY)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func cell(for screen: ScreenInfo, layout: MapLayout) -> some View {
        let r = layout.transform(screen.frameQuartz)
        let isFocused = screen.id == highlightID
        let lage = hint(screen)
        return RoundedRectangle(cornerRadius: 6)
            .fill(isFocused ? Color.accentColor.opacity(0.14) : Color.gray.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isFocused ? Color.accentColor : Color.gray.opacity(0.45),
                                  lineWidth: isFocused ? 2 : 1.2))
            .overlay(
                VStack(spacing: 1) {
                    Text(lage.isEmpty ? screen.name : lage.capitalized)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                    Text("\(Int(screen.frameQuartz.width)) × \(Int(screen.frameQuartz.height))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    if screen.isMain {
                        Text(Strings.hintMain).font(.system(size: 8)).foregroundStyle(.secondary)
                    }
                }
                .padding(2)
            )
            .frame(width: r.width, height: r.height)
            .contentShape(Rectangle())
            .onTapGesture { onSelect(screen.id) }
            .position(x: r.midX, y: r.midY)
    }
}

/// Rechnet globale Quartz-Koordinaten in die Zeichenfläche um (massstabsgetreu, zentriert).
struct MapLayout {
    let scale: CGFloat
    let bbox: CGRect
    let offset: CGSize

    init(screens: [ScreenInfo], area: CGSize) {
        let union = screens.map(\.frameQuartz).reduce(CGRect.null) { $0.union($1) }
        let pad: CGFloat = 14
        if union.isNull || union.width <= 0 || union.height <= 0 {
            scale = 1; bbox = .zero; offset = .zero; return
        }
        let availW = max(area.width - pad * 2, 1)
        let availH = max(area.height - pad * 2, 1)
        let scl = min(availW / union.width, availH / union.height)
        scale = scl
        bbox = union
        offset = CGSize(width: (area.width - union.width * scl) / 2,
                        height: (area.height - union.height * scl) / 2)
    }

    func transform(_ r: CGRect) -> CGRect {
        CGRect(x: (r.minX - bbox.minX) * scale + offset.width,
               y: (r.minY - bbox.minY) * scale + offset.height,
               width: r.width * scale, height: r.height * scale)
    }
}
