import Foundation

/// Zentrale Sammlung aller benutzersichtbaren Texte (Deutsch, Schweizer Orthografie: ss statt ß).
/// Bewusst an einem Ort, damit weitere Sprachen spaeter leicht ergaenzt werden koennen.
enum Strings {
    static let appName = "Finestra"
    static let tagline = "Finder-Fenster automatisch platzieren"
    static let statusTooltip = "Finestra - Finder-Fenster platzieren"

    // Menü
    static let menuSettings = "Einstellungen …"
    static let menuPlaceNow = "Vorderstes Finder-Fenster jetzt platzieren"
    static let menuLog = "Protokoll anzeigen …"
    static let menuCheckUpdate = "Nach Updates suchen …"
    static let menuQuit = "Finestra beenden"

    // Protokoll
    static let logTitle = "Finestra-Protokoll"
    static let logRefresh = "Aktualisieren"
    static let logClear = "Leeren"
    static let logReveal = "Im Finder zeigen"
    static let logHint = "Zeigt für jedes neue Finder-Fenster, welchen Monitor und welche Grösse Finestra wählt. Öffne ein Finder-Fenster und schau hier."
    static let logEmpty = "(noch keine Einträge - öffne ein Finder-Fenster)"
    static let logButton = "Protokoll anzeigen …"

    // Einstellungen - Abschnitte
    static let sectionMonitors = "Monitore"
    static let sectionTarget = "Zielmonitor"
    static let sectionSize = "Fenstergrösse"
    static let sectionPosition = "Position"
    static let sectionGeneral = "Allgemein"

    static let enabledLabel = "Automatisch platzieren"
    static let enabledHint = "Neue Finder-Fenster werden beim Öffnen platziert."

    // Zielmonitor
    static let targetFollow = "Wo das Fenster aufgeht (Folge-Modus)"
    static let targetFollowHint = "Das Fenster bleibt auf dem Monitor, auf dem es geöffnet wurde - nur Grösse und Position werden gesetzt."
    static let targetFixedHint = "Neue Fenster werden immer auf den gewählten Monitor verschoben."
    static let targetMapHint = "Tipp: In der Karte oben direkt auf einen Monitor klicken, um ihn als Ziel zu wählen."
    static let targetMain = "Hauptmonitor"

    static let mapHintFixed = "Klick auf einen Monitor in der Karte wählt den Zielmonitor."
    static let mapHintFollow = "Klick wählt den Monitor, dessen Werte Du unten einstellst - im Folge-Modus hat jeder Monitor eigene Grösse und Position."
    static let editMonitor = "Monitor"

    // Grösse
    static let sizeFixed = "Feste Grösse"
    static let sizePercent = "Anteil am Bildschirm"
    static let sizeWidth = "Breite"
    static let sizeHeight = "Höhe"
    static let sizePresets = "Vorlagen"

    // Position / Versatz
    static let offsetLabel = "Versatz"
    static let offsetHint = "Verschiebt das Fenster zusätzlich (+ = nach rechts bzw. unten)."
    static let offsetReset = "Zurücksetzen"

    // Allgemein
    static let launchAtLogin = "Beim Anmelden starten"
    static let version = "Version"
    static let checkUpdate = "Nach Updates suchen"

    // Positions-Namen (Reihenfolge wie WindowPosition)
    static let positionNames: [String] = [
        "Oben links", "Oben mittig", "Oben rechts",
        "Links", "Mittig", "Rechts",
        "Unten links", "Unten mittig", "Unten rechts",
    ]

    static let ok = "OK"

    // Bedienungshilfen
    static let axNeededTitle = "Bedienungshilfen-Freigabe nötig"
    static let axNeededBody = "Finestra braucht die Freigabe unter Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen, um Finder-Fenster zu bewegen. Nach dem Erteilen startet sich Finestra selbst neu."
    static let openAXSettings = "Bedienungshilfen öffnen"

    // Verschieben nach /Applications
    static let moveTitle = "Finestra in den Programme-Ordner verschieben?"
    static func moveBody(_ folder: String) -> String {
        "Finestra läuft gerade aus dem Ordner \(folder). Empfohlen wird der Programme-Ordner, damit Updates und Rechte zuverlässig bleiben."
    }
    static let moveNow = "Verschieben"
    static let moveLater = "Nicht jetzt"
    static let moveFailed = "Verschieben fehlgeschlagen."

    // Updates
    static func updateTitle(_ v: String) -> String { "Neue Version \(v) verfügbar" }
    static let updateInstall = "Jetzt aktualisieren"
    static let updatePage = "Release-Seite"
    static let updateLater = "Später"
    static let updateNoneTitle = "Finestra ist aktuell"
    static func updateNoneBody(_ v: String) -> String { "Installiert ist Version \(v)." }
    static let updateFailTitle = "Update-Prüfung fehlgeschlagen"
    static let updateFailBody = "Die neueste Version konnte nicht ermittelt werden. Bitte später erneut versuchen."
    static let updateInstalling = "Aktualisierung läuft …"
}
