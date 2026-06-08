import AppKit
import CoreGraphics

/// Ein angeschlossener Monitor, samt Rahmen in Quartz-/Accessibility-Koordinaten
/// (Ursprung oben-links des Hauptmonitors, y waechst nach unten).
struct ScreenInfo: Identifiable {
    let id: UInt32              // CGDirectDisplayID (für UI/aktuelle Sitzung)
    let name: String
    let isMain: Bool
    let frameQuartz: CGRect     // gesamter Rahmen, oben-links
    let visibleQuartz: CGRect   // ohne Menueleiste/Dock, oben-links
    /// Stabiler Schlüssel (Hersteller-Modell-Seriennummer) zum dauerhaften Speichern
    /// pro Monitor - überlebt Reboots/Neuanschluss, anders als die CGDirectDisplayID.
    let stableKey: String

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

        struct Raw {
            let num: UInt32; let name: String; let isMain: Bool
            let frame: CGRect; let vis: CGRect; let baseKey: String
        }
        let raws: [Raw] = screens.map { s in
            let num = (s.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
            let did = CGDirectDisplayID(num)
            let baseKey = "\(CGDisplayVendorNumber(did))-\(CGDisplayModelNumber(did))-\(CGDisplaySerialNumber(did))"
            return Raw(num: num, name: s.localizedName, isMain: s.frame.origin == .zero,
                       frame: toQuartz(s.frame), vis: toQuartz(s.visibleFrame), baseKey: baseKey)
        }

        // Bei identischen Monitoren (gleicher baseKey) per Lage (x von links) eindeutig machen.
        let counts = Dictionary(grouping: raws, by: \.baseKey).mapValues(\.count)
        var rankByNum: [UInt32: Int] = [:]
        if counts.values.contains(where: { $0 > 1 }) {
            var seen: [String: Int] = [:]
            for r in raws.sorted(by: { $0.frame.minX < $1.frame.minX }) {
                let k = seen[r.baseKey, default: 0]
                rankByNum[r.num] = k
                seen[r.baseKey] = k + 1
            }
        }

        return raws.map { r in
            let key = (counts[r.baseKey] ?? 1) > 1 ? "\(r.baseKey)#\(rankByNum[r.num] ?? 0)" : r.baseKey
            return ScreenInfo(id: r.num, name: r.name, isMain: r.isMain,
                              frameQuartz: r.frame, visibleQuartz: r.vis, stableKey: key)
        }
    }

    /// Der Monitor, der einen Quartz-Punkt enthaelt (z. B. die obere linke Ecke eines Fensters).
    static func containing(point: CGPoint, in list: [ScreenInfo]) -> ScreenInfo? {
        list.first { $0.frameQuartz.contains(point) }
    }

    static func main(in list: [ScreenInfo]) -> ScreenInfo? {
        list.first { $0.isMain } ?? list.first
    }

    /// Der Monitor, auf dem sich gerade der Mauszeiger befindet.
    static func screenUnderMouse(in list: [ScreenInfo]) -> ScreenInfo? {
        guard !list.isEmpty else { return nil }
        let screens = NSScreen.screens
        let zero = screens.first(where: { $0.frame.origin == .zero }) ?? screens.first
        let flipBase = zero?.frame.maxY ?? 0
        let m = NSEvent.mouseLocation                       // AppKit (unten-links)
        let point = CGPoint(x: m.x, y: flipBase - m.y)       // → Quartz (oben-links)
        return containing(point: point, in: list) ?? main(in: list)
    }

    static func byID(_ id: UInt32, in list: [ScreenInfo]) -> ScreenInfo? {
        list.first { $0.id == id }
    }
}
