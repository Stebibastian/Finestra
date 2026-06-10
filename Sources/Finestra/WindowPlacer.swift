import AppKit

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

/// Platziert Finder-Fenster über Finders eigenes AppleScript (`set bounds`).
/// Das ist ruckelfrei und stabil - der Finder bewegt sein Fenster selbst und merkt
/// sich die Position, statt es nach einem Setzen über die Bedienungshilfen
/// zurückzuschieben (was Pingpong verursachte).
enum WindowPlacer {
    /// Wird aufgerufen, wenn die Automation-Berechtigung („Finder steuern") fehlt.
    static var onPermissionDenied: (() -> Void)?

    /// Platziert das vorderste Finder-Fenster gemäss den Einstellungen.
    static func placeFrontWindow(windowID: CGWindowID? = nil) {
        let tag = windowID.map { "#\($0) " } ?? ""
        let screens = ScreenInfo.all()
        guard !screens.isEmpty else { Log.log("\(tag)Platzieren: keine Monitore gefunden"); return }

        let mouse = NSEvent.mouseLocation        // AppKit global, zur Diagnose im Log
        let target: ScreenInfo
        let how: String
        if Settings.targetMode == 1,
           let chosen = ScreenInfo.byID(Settings.targetDisplayID, in: screens) {
            target = chosen
            how = "Fix → \(chosen.name)"
        } else if let m = ScreenInfo.screenUnderMouse(in: screens) {
            target = m
            how = "Maus → \(m.name)"
        } else {
            target = ScreenInfo.main(in: screens) ?? screens[0]
            how = "Rueckfall Haupt (\(target.name))"
        }

        let cfg = Settings.config(forKey: target.stableKey)
        let rect = cfg.rect(in: target.visibleQuartz)
        let sizeText = cfg.sizeMode == 1
            ? "\(Int(cfg.percentW * 100))%×\(Int(cfg.percentH * 100))%"
            : "\(Int(cfg.width))×\(Int(cfg.height))px"
        Log.log("\(tag)Maus(\(Int(mouse.x)),\(Int(mouse.y))) | \(how) | Konfig \(sizeText) | setze \(rectText(rect))")

        if let err = FinderScript.setFrontWindowBounds(rect) {
            if err == FinderScript.notAuthorized {
                Log.log("\(tag)✗ keine Finder-Steuerungs-Berechtigung (Automation)")
                DispatchQueue.main.async { onPermissionDenied?() }
            } else {
                Log.log("\(tag)✗ AppleScript-Fehler \(err)")
            }
            return
        }
        // Kurze Bestätigung gegen die echte Position (AppleScript ist stabil; eine Kontrolle reicht).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if let after = FinderScript.frontWindowBounds() {
                let ok = abs(after.minX - rect.minX) < 16 && abs(after.minY - rect.minY) < 16
                Log.log("\(tag)Ergebnis \(rectText(after)) \(ok ? "✓" : "⚠")")
            }
        }
    }

    private static func rectText(_ r: CGRect) -> String {
        "[x\(Int(r.minX)) y\(Int(r.minY)) \(Int(r.width))×\(Int(r.height))]"
    }
}
