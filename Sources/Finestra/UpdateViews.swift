import SwiftUI

/// Zeigt die Release-Notes im „Update verfügbar"-Dialog (als NSAlert-accessoryView).
/// Markdown wird über AttributedString gerendert (Text(LocalizedStringKey) parst
/// Laufzeit-Strings NICHT) - so erscheinen Fett, Überschriften und Aufzählungen korrekt.
struct UpdateView: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if items.isEmpty {
                Text(Strings.updateBody).fixedSize(horizontal: false, vertical: true)
            } else {
                Text(Strings.updateAvailableLabel)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Text(item).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .font(.system(size: 13))
        .frame(width: 420, alignment: .leading)
        .padding(.horizontal, 2)
    }

    /// Notes ohne Installations-/Signatur-Zeilen; Überschriften fett, „- " als „• ",
    /// inline-Markdown (**fett** usw.) gerendert. Sehr lange Notes werden gekappt,
    /// damit der Dialog nicht riesig wird (Rest auf der Release-Seite).
    private var items: [AttributedString] {
        let all: [AttributedString] = notes.split(separator: "\n").map(String.init).compactMap { raw in
            let t = raw.trimmingCharacters(in: .whitespaces)
            let l = t.lowercased()
            if t.isEmpty || t == "```" || l.contains("install") || l.contains("curl ")
                || l.contains("notarized") || l.contains("one-liner")
                || l.contains("update via") || l.contains("requires macos") { return nil }

            if t.hasPrefix("#") {
                let text = String(t.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces))
                var a = Self.inline(text)
                a.font = .system(size: 13, weight: .semibold)
                return a
            }
            if t.hasPrefix("- ") {
                return AttributedString("•  ") + Self.inline(String(t.dropFirst(2)))
            }
            return Self.inline(t)
        }
        let maxLines = 16
        guard all.count > maxLines else { return all }
        return Array(all.prefix(maxLines)) + [AttributedString("…")]
    }

    /// Parst inline-Markdown (Fett/Kursiv/Code) und behält Leerzeichen.
    private static func inline(_ s: String) -> AttributedString {
        (try? AttributedString(
            markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(s)
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
