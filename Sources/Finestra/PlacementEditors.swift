import SwiftUI

private let intFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .none
    f.maximumFractionDigits = 0
    f.minimum = 300
    f.maximum = 6000
    return f
}()

private let signedFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .none
    f.maximumFractionDigits = 0
    f.minimum = -3000
    f.maximum = 3000
    return f
}()

/// Bearbeitet die Grösse einer Platzierung (feste px oder Prozent). Wiederverwendbar.
struct SizeEditor: View {
    @Binding var cfg: Placement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $cfg.sizeMode) {
                Text(Strings.sizeFixed).tag(0)
                Text(Strings.sizePercent).tag(1)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if cfg.sizeMode == 0 {
                HStack(spacing: 6) {
                    ForEach(SizePreset.all, id: \.label) { preset in
                        Button(preset.label) {
                            cfg.width = preset.w
                            cfg.height = preset.h
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(cfg.width == preset.w && cfg.height == preset.h ? .accentColor : nil)
                    }
                }
                HStack(spacing: 16) {
                    pixelField(Strings.sizeWidth, $cfg.width)
                    pixelField(Strings.sizeHeight, $cfg.height)
                }
            } else {
                percentRow(Strings.sizeWidth, $cfg.percentW)
                percentRow(Strings.sizeHeight, $cfg.percentH)
            }
        }
    }

    private func pixelField(_ label: String, _ value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Text(label).frame(width: 64, alignment: .leading)
            TextField("", value: value, formatter: intFormatter)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
            Stepper("", value: value, in: 300...6000, step: 20).labelsHidden()
            Text("px").foregroundStyle(.secondary)
        }
    }

    private func percentRow(_ label: String, _ value: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(label).frame(width: 64, alignment: .leading)
            Slider(value: value, in: 0.2...1.0)
            Text("\(Int((value.wrappedValue * 100).rounded())) %")
                .frame(width: 46, alignment: .trailing)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

/// Bearbeitet Position (3×3-Raster) und Versatz einer Platzierung. Wiederverwendbar.
struct PositionEditor: View {
    @Binding var cfg: Placement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { col in
                                cell(index: row * 3 + col)
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.positionNames[cfg.position.rawValue])
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
                Text(Strings.offsetLabel).frame(width: 64, alignment: .leading)
                offsetField("X", $cfg.offsetX)
                offsetField("Y", $cfg.offsetY)
                Button(Strings.offsetReset) { cfg.offsetX = 0; cfg.offsetY = 0 }
                    .controlSize(.small)
                    .disabled(cfg.offsetX == 0 && cfg.offsetY == 0)
            }
            Text(Strings.offsetHint).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func offsetField(_ label: String, _ value: Binding<Double>) -> some View {
        HStack(spacing: 5) {
            Text(label).foregroundStyle(.secondary)
            TextField("", value: value, formatter: signedFormatter)
                .textFieldStyle(.roundedBorder)
                .frame(width: 62)
            Stepper("", value: value, in: -3000...3000, step: 10).labelsHidden()
        }
    }

    private func cell(index: Int) -> some View {
        let selected = cfg.position.rawValue == index
        let col = index % 3
        let row = index / 3
        let align = Alignment(
            horizontal: col == 0 ? .leading : (col == 2 ? .trailing : .center),
            vertical: row == 0 ? .top : (row == 2 ? .bottom : .center))
        return Button {
            cfg.position = WindowPosition(rawValue: index) ?? .center
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

    private var sizeSummary: String {
        if cfg.sizeMode == 0 {
            return "\(Int(cfg.width)) × \(Int(cfg.height)) px"
        } else {
            return "\(Int((cfg.percentW * 100).rounded())) % × \(Int((cfg.percentH * 100).rounded())) %"
        }
    }
}
