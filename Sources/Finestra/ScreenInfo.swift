import AppKit

/// Ein angeschlossener Monitor, samt Rahmen in Quartz-/Accessibility-Koordinaten
/// (Ursprung oben-links des Hauptmonitors, y waechst nach unten).
struct ScreenInfo: Identifiable {
    let id: UInt32              // CGDirectDisplayID
    let name: String
    let isMain: Bool
    let frameQuartz: CGRect     // gesamter Rahmen, oben-links
    let visibleQuartz: CGRect   // ohne Menueleiste/Dock, oben-links

    /// Liest alle aktuell angeschlossenen Monitore aus.
    static func all() -> [ScreenInfo] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return [] }
        // Der Monitor mit Ursprung (0,0) ist der Hauptmonitor; seine Hoehe ist die
        // Bezugsgroesse, um zwischen AppKit (unten-links) und Quartz (oben-links)
        // umzurechnen.
        let zero = screens.first(where: { $0.frame.origin == .zero }) ?? screens[0]
        let flipBase = zero.frame.maxY

        func toQuartz(_ r: NSRect) -> CGRect {
            CGRect(x: r.minX, y: flipBase - r.maxY, width: r.width, height: r.height)
        }

        return screens.map { s in
            let num = (s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            return ScreenInfo(id: num,
                              name: s.localizedName,
                              isMain: s.frame.origin == .zero,
                              frameQuartz: toQuartz(s.frame),
                              visibleQuartz: toQuartz(s.visibleFrame))
        }
    }

    /// Der Monitor, der einen Quartz-Punkt enthaelt (z. B. die obere linke Ecke eines Fensters).
    static func containing(point: CGPoint, in list: [ScreenInfo]) -> ScreenInfo? {
        list.first { $0.frameQuartz.contains(point) }
    }

    static func main(in list: [ScreenInfo]) -> ScreenInfo? {
        list.first { $0.isMain } ?? list.first
    }

    static func byID(_ id: UInt32, in list: [ScreenInfo]) -> ScreenInfo? {
        list.first { $0.id == id }
    }
}
