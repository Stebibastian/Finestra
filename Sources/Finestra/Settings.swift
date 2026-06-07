import Foundation

/// Dauerhaft gespeicherte Einstellungen (UserDefaults).
enum Settings {
    private static let d = UserDefaults.standard

    private static let enabledKey = "enabled"
    /// Master-Schalter: werden neue Finder-Fenster automatisch platziert?
    static var enabled: Bool {
        get { d.object(forKey: enabledKey) as? Bool ?? true }
        set { d.set(newValue, forKey: enabledKey) }
    }

    private static let targetModeKey = "targetMode"
    /// 0 = auf dem Monitor lassen, auf dem es aufgeht; 1 = fester Zielmonitor.
    static var targetMode: Int {
        get { d.object(forKey: targetModeKey) as? Int ?? 0 }
        set { d.set(newValue, forKey: targetModeKey) }
    }

    private static let targetDisplayKey = "targetDisplayID"
    /// CGDirectDisplayID des gewaehlten Zielmonitors (nur bei targetMode == 1).
    static var targetDisplayID: UInt32 {
        get { UInt32(d.object(forKey: targetDisplayKey) as? Int ?? 0) }
        set { d.set(Int(newValue), forKey: targetDisplayKey) }
    }

    private static let sizeModeKey = "sizeMode"
    /// 0 = feste Pixelgroesse; 1 = Anteil am Bildschirm (Prozent).
    static var sizeMode: Int {
        get { d.object(forKey: sizeModeKey) as? Int ?? 0 }
        set { d.set(newValue, forKey: sizeModeKey) }
    }

    private static let widthKey = "width"
    /// Feste Breite in Punkten (640-6000).
    static var width: Double {
        get { let v = d.object(forKey: widthKey) as? Double ?? 1440; return min(6000, max(400, v)) }
        set { d.set(min(6000, max(400, newValue)), forKey: widthKey) }
    }

    private static let heightKey = "height"
    /// Feste Hoehe in Punkten (400-4000).
    static var height: Double {
        get { let v = d.object(forKey: heightKey) as? Double ?? 900; return min(4000, max(300, v)) }
        set { d.set(min(4000, max(300, newValue)), forKey: heightKey) }
    }

    private static let percentWKey = "percentW"
    /// Breiten-Anteil am sichtbaren Bildschirm (0.2-1.0).
    static var percentW: Double {
        get { let v = d.object(forKey: percentWKey) as? Double ?? 0.66; return min(1.0, max(0.2, v)) }
        set { d.set(min(1.0, max(0.2, newValue)), forKey: percentWKey) }
    }

    private static let percentHKey = "percentH"
    /// Hoehen-Anteil am sichtbaren Bildschirm (0.2-1.0).
    static var percentH: Double {
        get { let v = d.object(forKey: percentHKey) as? Double ?? 0.85; return min(1.0, max(0.2, v)) }
        set { d.set(min(1.0, max(0.2, newValue)), forKey: percentHKey) }
    }

    private static let positionKey = "position"
    /// Index in WindowPosition.allCases (Standard: 4 = mittig).
    static var position: Int {
        get { let v = d.object(forKey: positionKey) as? Int ?? 4; return min(8, max(0, v)) }
        set { d.set(min(8, max(0, newValue)), forKey: positionKey) }
    }

    private static let offsetXKey = "offsetX"
    /// Zusätzlicher horizontaler Versatz in Punkten (+ = nach rechts), -3000…3000.
    static var offsetX: Double {
        get { let v = d.object(forKey: offsetXKey) as? Double ?? 0; return min(3000, max(-3000, v)) }
        set { d.set(min(3000, max(-3000, newValue)), forKey: offsetXKey) }
    }

    private static let offsetYKey = "offsetY"
    /// Zusätzlicher vertikaler Versatz in Punkten (+ = nach unten), -3000…3000.
    static var offsetY: Double {
        get { let v = d.object(forKey: offsetYKey) as? Double ?? 0; return min(3000, max(-3000, v)) }
        set { d.set(min(3000, max(-3000, newValue)), forKey: offsetYKey) }
    }

    private static let moveDeclinedKey = "moveDeclined"
    /// Hat der Nutzer das Verschieben nach /Applications einmal abgelehnt?
    static var moveDeclined: Bool {
        get { d.bool(forKey: moveDeclinedKey) }
        set { d.set(newValue, forKey: moveDeclinedKey) }
    }

    /// Standard-/Rückfall-Konfiguration (aus den Einzelwerten oben). Dient als Vorlage
    /// für Monitore, die noch keine eigene Konfiguration haben.
    static var defaultConfig: Placement {
        get {
            Placement(sizeMode: sizeMode,
                      width: width, height: height,
                      percentW: percentW, percentH: percentH,
                      position: WindowPosition(rawValue: position) ?? .center,
                      offsetX: offsetX, offsetY: offsetY)
        }
        set {
            sizeMode = newValue.sizeMode
            width = newValue.width
            height = newValue.height
            percentW = newValue.percentW
            percentH = newValue.percentH
            position = newValue.position.rawValue
            offsetX = newValue.offsetX
            offsetY = newValue.offsetY
        }
    }

    private static let perMonitorKey = "perMonitorConfigs"
    /// Pro Monitor (Schlüssel = CGDirectDisplayID als String) eine eigene Konfiguration.
    static var perMonitorConfigs: [String: Placement] {
        get {
            guard let data = d.data(forKey: perMonitorKey),
                  let dict = try? JSONDecoder().decode([String: Placement].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                d.set(data, forKey: perMonitorKey)
            }
        }
    }

    /// Konfiguration für einen bestimmten Monitor - eigene, sonst der Standard.
    static func config(forDisplay id: UInt32) -> Placement {
        perMonitorConfigs[String(id)] ?? defaultConfig
    }

    /// Speichert die Konfiguration für einen bestimmten Monitor.
    static func setConfig(_ c: Placement, forDisplay id: UInt32) {
        var dict = perMonitorConfigs
        dict[String(id)] = c
        perMonitorConfigs = dict
    }
}

/// Gaengige Pixel-Vorlagen fuer die feste Groesse.
enum SizePreset {
    static let all: [(label: String, w: Double, h: Double)] = [
        ("2560 × 1440", 2560, 1440),
        ("1920 × 1080", 1920, 1080),
        ("1680 × 1050", 1680, 1050),
        ("1440 × 900",  1440, 900),
        ("1280 × 800",  1280, 800),
    ]
}
