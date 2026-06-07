import AppKit
import ApplicationServices

/// Position eines Fensters im sichtbaren Bereich eines Monitors (3×3-Raster).
enum WindowPosition: Int, CaseIterable, Codable, Equatable {
    case topLeft, topCenter, topRight
    case centerLeft, center, centerRight
    case bottomLeft, bottomCenter, bottomRight

    var column: Int { rawValue % 3 }   // 0 = links, 1 = mitte, 2 = rechts
    var row: Int { rawValue / 3 }      // 0 = oben, 1 = mitte, 2 = unten
}

/// Beschreibt, wie gross ein Fenster werden und wohin es soll. Pro Monitor speicherbar.
struct Placement: Codable, Equatable {
    var sizeMode: Int            // 0 = feste Groesse, 1 = Prozent
    var width: Double
    var height: Double
    var percentW: Double
    var percentH: Double
    var position: WindowPosition
    var offsetX: Double = 0
    var offsetY: Double = 0

    /// Berechnet den Ziel-Rahmen (Quartz, oben-links) im sichtbaren Bereich `vis`.
    func rect(in vis: CGRect) -> CGRect {
        var w: CGFloat
        var h: CGFloat
        if sizeMode == 1 {
            w = vis.width * CGFloat(percentW)
            h = vis.height * CGFloat(percentH)
        } else {
            w = min(CGFloat(width), vis.width)
            h = min(CGFloat(height), vis.height)
        }
        // Niemals groesser als der sichtbare Bereich.
        w = min(w, vis.width)
        h = min(h, vis.height)

        var x: CGFloat
        switch position.column {
        case 0:  x = vis.minX
        case 2:  x = vis.maxX - w
        default: x = vis.minX + (vis.width - w) / 2
        }
        var y: CGFloat
        switch position.row {
        case 0:  y = vis.minY                        // oben (Quartz: kleinstes y)
        case 2:  y = vis.maxY - h                    // unten
        default: y = vis.minY + (vis.height - h) / 2 // mittig
        }

        // Versatz anwenden, dann ins Sichtbare zurueckholen (Fenster bleibt auf dem Monitor).
        x += CGFloat(offsetX)
        y += CGFloat(offsetY)
        x = min(max(x, vis.minX), vis.maxX - w)
        y = min(max(y, vis.minY), vis.maxY - h)

        return CGRect(x: x.rounded(), y: y.rounded(), width: w.rounded(), height: h.rounded())
    }
}

/// Setzt Position/Groesse echter Fenster ueber die Accessibility-API.
enum WindowPlacer {
    /// Platziert ein Fenster gemaess den aktuellen Einstellungen.
    static func place(_ window: AXUIElement) {
        let screens = ScreenInfo.all()
        guard !screens.isEmpty else { return }

        let target: ScreenInfo
        if Settings.targetMode == 1,
           let chosen = ScreenInfo.byID(Settings.targetDisplayID, in: screens) {
            target = chosen
        } else if Settings.targetMode == 0,
                  let pos = position(of: window),
                  let here = ScreenInfo.containing(point: pos, in: screens) {
            target = here
        } else {
            target = ScreenInfo.main(in: screens) ?? screens[0]
        }

        // Pro Monitor eigene Konfiguration (Folge-Modus: der Monitor, auf dem das
        // Fenster aufgeht; Fix-Modus: der gewaehlte Zielmonitor).
        let rect = Settings.config(forDisplay: target.id).rect(in: target.visibleQuartz)
        setFrame(window, rect)
    }

    /// Setzt Groesse + Position. Position wird zweimal gesetzt, weil manche Fenster
    /// beim ersten Mal noch von ihrer alten Groesse her am Bildschirmrand klemmen.
    static func setFrame(_ window: AXUIElement, _ rect: CGRect) {
        var pos = rect.origin
        var size = rect.size
        if let p = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, p)
        }
        if let s = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, s)
        }
        if let p = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, p)
        }
    }

    /// Aktuelle obere linke Ecke eines Fensters (Quartz), falls lesbar.
    static func position(of window: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &value) == .success,
              let value else { return nil }
        var point = CGPoint.zero
        // swiftlint:disable:next force_cast
        AXValueGetValue(value as! AXValue, .cgPoint, &point)
        return point
    }
}
