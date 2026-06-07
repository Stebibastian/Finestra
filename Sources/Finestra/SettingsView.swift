import SwiftUI
import AppKit

/// Das Einstellungsfenster: Monitore visuell, Zielmonitor, Groesse und Position
/// einstellbar - mit Live-Vorschau, wo das Fenster landen wird.
struct SettingsView: View {
    let onToggleLogin: (Bool) -> Void
    let onCheckUpdate: () -> Void
    let loginEnabled: () -> Bool

    @State private var enabled = Settings.enabled
    @State private var targetMode = Settings.targetMode
    @State private var targetID = Settings.targetDisplayID
    @State private var sizeMode = Settings.sizeMode
    @State private var width = Settings.width
    @State private var height = Settings.height
    @State private var percentW = Settings.percentW
    @State private var percentH = Settings.percentH
    @State private var position = Settings.position
    @State private var offsetX = Settings.offsetX
    @State private var offsetY = Settings.offsetY
    @State private var login = false
    @State private var screens: [ScreenInfo] = ScreenInfo.all()

    private static let intFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.maximumFractionDigits = 0
        f.minimum = 300
        f.maximum = 6000
        return f
    }()

    private static let signedFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .none
        f.maximumFractionDigits = 0
        f.minimum = -3000
        f.maximum = 3000
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            box(Strings.sectionMonitors) {
                MonitorMap(screens: screens,
                           targetID: targetMode == 1 ? targetID : nil,
                           followMode: targetMode == 0,
                           previewRect: previewRect,
                           hint: { positionHint(for: $0) },
                           onSelect: { id in targetMode = 1; targetID = id })
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
            }
            box(Strings.sectionTarget) { targetControls }
            box(Strings.sectionSize) { sizeControls }
            box(Strings.sectionPosition) { positionControls }
            box(Strings.sectionGeneral) { generalControls }
        }
        .padding(20)
        .frame(width: 540)
        .onAppear {
            refreshScreens()
            login = loginEnabled()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didChangeScreenParametersNotification)) { _ in
            refreshScreens()
        }
        .onChange(of: enabled) { v in Settings.enabled = v }
        .onChange(of: targetMode) { v in Settings.targetMode = v }
        .onChange(of: targetID) { v in Settings.targetDisplayID = v }
        .onChange(of: sizeMode) { v in Settings.sizeMode = v }
        .onChange(of: width) { v in Settings.width = v }
        .onChange(of: height) { v in Settings.height = v }
        .onChange(of: percentW) { v in Settings.percentW = v }
        .onChange(of: percentH) { v in Settings.percentH = v }
        .onChange(of: position) { v in Settings.position = v }
        .onChange(of: offsetX) { v in Settings.offsetX = v }
        .onChange(of: offsetY) { v in Settings.offsetY = v }
    }

    // MARK: - Kopf

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.appName).font(.title2.bold())
                Text(Strings.tagline).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(Strings.enabledLabel, isOn: $enabled)
                .toggleStyle(.switch)
        }
    }

    // MARK: - Zielmonitor

    private var targetControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("", selection: Binding<UInt32>(
                get: { targetMode == 0 ? 0 : targetID },
                set: { v in
                    if v == 0 { targetMode = 0 }
                    else { targetMode = 1; targetID = v }
                })) {
                Text(Strings.targetFollow).tag(UInt32(0))
                ForEach(screens) { s in
                    Text(hintedName(for: s)).tag(s.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Text(targetMode == 0 ? Strings.targetFollowHint : Strings.targetFixedHint)
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(Strings.targetMapHint)
                .font(.caption).foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Monitorname samt Lage-Hinweis (links/rechts/…) und „Haupt", da gleiche Modelle gleich heissen.
    private func hintedName(for s: ScreenInfo) -> String {
        var parts: [String] = []
        let hint = positionHint(for: s)
        if !hint.isEmpty { parts.append(hint) }
        if s.isMain { parts.append("Haupt") }
        return parts.isEmpty ? s.name : "\(s.name) - \(parts.joined(separator: ", "))"
    }

    /// Lage eines Monitors relativ zu den anderen: links/rechts bzw. oben/unten.
    private func positionHint(for s: ScreenInfo) -> String {
        guard screens.count > 1 else { return "" }
        let xs = Set(screens.map { Int($0.frameQuartz.minX.rounded()) })
        if xs.count == screens.count {
            let sorted = screens.sorted { $0.frameQuartz.minX < $1.frameQuartz.minX }
            if s.id == sorted.first?.id { return "links" }
            if s.id == sorted.last?.id { return "rechts" }
            return "Mitte"
        }
        let sorted = screens.sorted { $0.frameQuartz.minY < $1.frameQuartz.minY }
        if s.id == sorted.first?.id { return "oben" }
        if s.id == sorted.last?.id { return "unten" }
        return ""
    }

    // MARK: - Groesse

    private var sizeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $sizeMode) {
                Text(Strings.sizeFixed).tag(0)
                Text(Strings.sizePercent).tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if sizeMode == 0 {
                HStack(spacing: 6) {
                    ForEach(SizePreset.all, id: \.label) { preset in
                        Button(preset.label) {
                            width = preset.w
                            height = preset.h
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(width == preset.w && height == preset.h ? .accentColor : nil)
                    }
                }
                HStack(spacing: 16) {
                    pixelField(Strings.sizeWidth, $width)
                    pixelField(Strings.sizeHeight, $height)
                }
            } else {
                percentRow(Strings.sizeWidth, $percentW)
                percentRow(Strings.sizeHeight, $percentH)
            }
        }
    }

    private func pixelField(_ label: String, _ value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Text(label).frame(width: 54, alignment: .leading)
            TextField("", value: value, formatter: Self.intFormatter)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
            Stepper("", value: value, in: 300...6000, step: 20)
                .labelsHidden()
            Text("px").foregroundStyle(.secondary)
        }
    }

    private func percentRow(_ label: String, _ value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(label).frame(width: 54, alignment: .leading)
            Slider(value: value, in: 0.2...1.0)
            Text("\(Int((value.wrappedValue * 100).rounded())) %")
                .frame(width: 46, alignment: .trailing)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Position

    private var positionControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { col in
                                positionCell(index: row * 3 + col)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.positionNames[position])
                        .font(.callout.weight(.medium))
                    Text(sizeSummary)
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            Divider()
            offsetControls
        }
    }

    private var offsetControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 14) {
                Text(Strings.offsetLabel).frame(width: 54, alignment: .leading)
                offsetField("X", $offsetX)
                offsetField("Y", $offsetY)
                Button(Strings.offsetReset) { offsetX = 0; offsetY = 0 }
                    .controlSize(.small)
                    .disabled(offsetX == 0 && offsetY == 0)
            }
            Text(Strings.offsetHint).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func offsetField(_ label: String, _ value: Binding<Double>) -> some View {
        HStack(spacing: 5) {
            Text(label).foregroundStyle(.secondary)
            TextField("", value: value, formatter: Self.signedFormatter)
                .textFieldStyle(.roundedBorder)
                .frame(width: 62)
            Stepper("", value: value, in: -3000...3000, step: 10)
                .labelsHidden()
        }
    }

    private func positionCell(index: Int) -> some View {
        let selected = position == index
        let col = index % 3
        let row = index / 3
        let align = Alignment(
            horizontal: col == 0 ? .leading : (col == 2 ? .trailing : .center),
            vertical: row == 0 ? .top : (row == 2 ? .bottom : .center))
        return Button {
            position = index
        } label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(selected ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(selected ? Color.accentColor : Color.gray.opacity(0.4),
                                      lineWidth: selected ? 1.5 : 1))
                .overlay(alignment: align) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(selected ? Color.accentColor : Color.gray.opacity(0.55))
                        .frame(width: 18, height: 12)
                        .padding(4)
                }
                .frame(width: 46, height: 32)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Allgemein

    private var generalControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(Strings.launchAtLogin, isOn: Binding(
                get: { login },
                set: { v in login = v; onToggleLogin(v) }))
                .toggleStyle(.switch)
            Divider()
            HStack {
                Text("\(Strings.version) \(UpdateChecker.currentVersion)")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(Strings.checkUpdate) { onCheckUpdate() }
                    .controlSize(.small)
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

    private func refreshScreens() {
        screens = ScreenInfo.all()
    }

    /// Der Monitor, fuer den die Vorschau gezeichnet wird.
    private var previewScreen: ScreenInfo? {
        if targetMode == 1, let s = ScreenInfo.byID(targetID, in: screens) { return s }
        return ScreenInfo.main(in: screens) ?? screens.first
    }

    private var previewPlacement: Placement {
        Placement(sizeMode: sizeMode, width: width, height: height,
                  percentW: percentW, percentH: percentH,
                  position: WindowPosition(rawValue: position) ?? .center,
                  offsetX: offsetX, offsetY: offsetY)
    }

    private var previewRect: CGRect? {
        guard let s = previewScreen else { return nil }
        return previewPlacement.rect(in: s.visibleQuartz)
    }

    private var sizeSummary: String {
        if sizeMode == 0 {
            return "\(Int(width)) × \(Int(height)) px"
        } else {
            return "\(Int((percentW * 100).rounded())) % × \(Int((percentH * 100).rounded())) %"
        }
    }
}

/// Zeichnet die angeschlossenen Monitore massstabsgetreu samt Vorschau-Fenster.
/// Ein Klick auf einen Monitor waehlt ihn als festen Zielmonitor.
struct MonitorMap: View {
    let screens: [ScreenInfo]
    let targetID: UInt32?     // nil = Folge-Modus (kein fester Zielmonitor)
    let followMode: Bool
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
                        .allowsHitTesting(false)   // Klicks gehen an den Monitor darunter
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func cell(for screen: ScreenInfo, layout: MapLayout) -> some View {
        let r = layout.transform(screen.frameQuartz)
        let isTarget = !followMode && screen.id == targetID
        let lage = hint(screen)
        return RoundedRectangle(cornerRadius: 6)
            .fill(isTarget ? Color.accentColor.opacity(0.14) : Color.gray.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isTarget ? Color.accentColor : Color.gray.opacity(0.45),
                                  lineWidth: isTarget ? 2 : 1.2))
            .overlay(
                VStack(spacing: 1) {
                    Text(lage.isEmpty ? screen.name : lage.capitalized)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                    Text("\(Int(screen.frameQuartz.width)) × \(Int(screen.frameQuartz.height))")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    if screen.isMain {
                        Text("Haupt").font(.system(size: 8)).foregroundStyle(.secondary)
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

/// Rechnet globale Quartz-Koordinaten in die Zeichenflaeche um (massstabsgetreu, zentriert).
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
        let s = min(availW / union.width, availH / union.height)
        scale = s
        bbox = union
        offset = CGSize(width: (area.width - union.width * s) / 2,
                        height: (area.height - union.height * s) / 2)
    }

    func transform(_ r: CGRect) -> CGRect {
        CGRect(x: (r.minX - bbox.minX) * scale + offset.width,
               y: (r.minY - bbox.minY) * scale + offset.height,
               width: r.width * scale, height: r.height * scale)
    }
}
