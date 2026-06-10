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
    static func place(_ window: AXUIElement, windowID: CGWindowID? = nil,
                      refetch: (() -> AXUIElement?)? = nil) {
        let tag = windowID.map { "#\($0) " } ?? ""
        let screens = ScreenInfo.all()
        guard !screens.isEmpty else { Log.log("\(tag)Platzieren: keine Monitore gefunden"); return }

        let pos = position(of: window)
        let mouse = NSEvent.mouseLocation        // AppKit global, nur zur Diagnose im Log
        let target: ScreenInfo
        let how: String
        if Settings.targetMode == 1,
           let chosen = ScreenInfo.byID(Settings.targetDisplayID, in: screens) {
            target = chosen
            how = "Fix → \(chosen.name)"
        } else if let m = ScreenInfo.screenUnderMouse(in: screens) {
            // Standard: aktiver Monitor (wo der Mauszeiger ist).
            target = m
            how = "Maus → \(m.name)"
        } else {
            target = ScreenInfo.main(in: screens) ?? screens[0]
            how = "Rueckfall Haupt (\(target.name))"
        }

        // Pro Monitor eigene Konfiguration (Fix-Modus: gewaehlter Monitor; sonst Maus). Stabiler Schlüssel.
        let cfg = Settings.config(forKey: target.stableKey)
        let rect = cfg.rect(in: target.visibleQuartz)

        let posText = pos.map { "(\(Int($0.x)),\(Int($0.y)))" } ?? "nicht lesbar"
        let sizeText = cfg.sizeMode == 1
            ? "\(Int(cfg.percentW * 100))%×\(Int(cfg.percentH * 100))%"
            : "\(Int(cfg.width))×\(Int(cfg.height))px"
        Log.log("\(tag)AX-Pos \(posText) | Maus(\(Int(mouse.x)),\(Int(mouse.y))) | \(how) | Konfig \(sizeText) | sichtbar \(rectText(target.visibleQuartz)) | setze \(rectText(rect))")

        // Frisch erstellte Finder-Fenster sind manchmal noch nicht bereit und
        // „verschlucken" die Groessenaenderung. Darum setzen wir mehrfach nach,
        // bis der Rahmen wirklich passt - und holen pro Versuch ein frisches
        // Fenster-Element (das alte kann „stale" sein → fuehrte zu winzigen Fenstern).
        enforce(window, rect, tag: tag, attempt: 0, refetch: refetch)
    }

    private static let retryDelays: [Double] = [0.2, 0.35, 0.5, 0.8]

    private static func enforce(_ window: AXUIElement, _ rect: CGRect, tag: String,
                                attempt: Int, refetch: (() -> AXUIElement?)?) {
        let element = refetch?() ?? window
        setFrame(element, rect)
        let delay = retryDelays[min(attempt, retryDelays.count - 1)]
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let check = refetch?() ?? element
            guard let after = frame(of: check) else {
                Log.log("\(tag)Ergebnis nicht lesbar")
                return
            }
            let ok = abs(after.width - rect.width) < 12 && abs(after.height - rect.height) < 12
            if ok {
                Log.log("\(tag)Ergebnis \(rectText(after)) ✓\(attempt > 0 ? " (Versuch \(attempt + 1))" : "")")
            } else if attempt < retryDelays.count - 1 {
                Log.log("\(tag)Ergebnis \(rectText(after)) ⚠ Versuch \(attempt + 1) zu klein/falsch, wiederhole")
                enforce(check, rect, tag: tag, attempt: attempt + 1, refetch: refetch)
            } else {
                Log.log("\(tag)Ergebnis \(rectText(after)) ✗ nach \(attempt + 1) Versuchen aufgegeben")
            }
        }
    }

    private static func rectText(_ r: CGRect) -> String {
        "[x\(Int(r.minX)) y\(Int(r.minY)) \(Int(r.width))×\(Int(r.height))]"
    }

    /// Aktueller Rahmen (Position + Groesse) eines Fensters in Quartz-Koordinaten.
    static func frame(of window: AXUIElement) -> CGRect? {
        guard let pos = position(of: window) else { return nil }
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let sizeValue else { return nil }
        var size = CGSize.zero
        // swiftlint:disable:next force_cast
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return CGRect(origin: pos, size: size)
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
