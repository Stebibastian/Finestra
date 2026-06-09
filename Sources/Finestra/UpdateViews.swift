import SwiftUI

/// Zeigt die Release-Notes im „Update verfügbar"-Dialog (als NSAlert-accessoryView).
struct UpdateView: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if lines.isEmpty {
                Text(Strings.updateBody).fixedSize(horizontal: false, vertical: true)
            } else {
                Text(Strings.updateAvailableLabel)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(lines, id: \.self) { line in
                    Text(.init(line)).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .font(.system(size: 13))
        .frame(width: 420)
        .padding(.horizontal, 2)
    }

    /// Release-Notes ohne Installations-/Signatur-Zeilen; „### X"→fett, „- "→„• ".
    private var lines: [String] {
        notes.split(separator: "\n").map(String.init).compactMap { raw in
            let t = raw.trimmingCharacters(in: .whitespaces)
            let l = t.lowercased()
            if t.isEmpty || t == "```" || l.contains("install") || l.contains("curl ")
                || l.contains("notarized") || l.contains("one-liner")
                || l.contains("update via") || l.contains("requires macos") { return nil }
            if t.hasPrefix("### ") { return "**" + t.dropFirst(4) + "**" }
            if t.hasPrefix("## ") { return "**" + t.dropFirst(3) + "**" }
            if t.hasPrefix("# ") { return "**" + t.dropFirst(2) + "**" }
            return t.hasPrefix("- ") ? "• " + t.dropFirst(2) : t
        }
    }
}

/// Kleines Fortschritts-Fenster während des Updates (unbestimmter Balken).
struct UpdateProgressView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text(Strings.updateInstalling).font(.system(size: 13, weight: .medium))
            ProgressView().progressViewStyle(.linear).frame(width: 260)
            Text(Strings.updateRelaunchHint)
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(26)
        .frame(width: 320)
    }
}
