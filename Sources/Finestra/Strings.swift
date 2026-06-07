import Foundation

/// Zentrale Sammlung aller benutzersichtbaren Texte (Deutsch).
/// Bewusst an einem Ort, damit weitere Sprachen spaeter leicht ergaenzt werden koennen.
enum Strings {
    static let appName = "Finestra"
    static let tagline = "Finder-Fenster automatisch platzieren"
    static let statusTooltip = "Finestra - Finder-Fenster platzieren"

    // Menue
    static let menuSettings = "Einstellungen …"
    static let menuPlaceNow = "Vorderstes Finder-Fenster jetzt platzieren"
    static let menuCheckUpdate = "Nach Updates suchen …"
    static let menuQuit = "Finestra beenden"

    // Einstellungen - Abschnitte
    static let sectionMonitors = "Monitore"
    static let sectionTarget = "Zielmonitor"
    static let sectionSize = "Fenstergroesse"
    static let sectionPosition = "Position"
    static let sectionGeneral = "Allgemein"

    static let enabledLabel = "Automatisch platzieren"
    static let enabledHint = "Neue Finder-Fenster werden beim Oeffnen platziert."

    // Zielmonitor
    static let targetFollow = "Wo das Fenster aufgeht"
    static let targetFollowHint = "Das Fenster bleibt auf dem Monitor, auf dem es geoeffnet wurde."
    static let targetMain = "Hauptmonitor"

    // Groesse
    static let sizeFixed = "Feste Groesse"
    static let sizePercent = "Anteil am Bildschirm"
    static let sizeWidth = "Breite"
    static let sizeHeight = "Hoehe"
    static let sizePresets = "Vorlagen"

    // Allgemein
    static let launchAtLogin = "Beim Anmelden starten"
    static let version = "Version"
    static let checkUpdate = "Nach Updates suchen"

    // Position-Namen (Reihenfolge wie WindowPosition)
    static let positionNames: [String] = [
        "Oben links", "Oben mittig", "Oben rechts",
        "Links", "Mittig", "Rechts",
        "Unten links", "Unten mittig", "Unten rechts",
    ]

    static let ok = "OK"

    // Bedienungshilfen
    static let axNeededTitle = "Bedienungshilfen-Freigabe noetig"
    static let axNeededBody = "Finestra braucht die Freigabe unter Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen, um Finder-Fenster zu bewegen. Nach dem Erteilen startet sich Finestra selbst neu."
    static let openAXSettings = "Bedienungshilfen oeffnen"

    // Verschieben nach /Applications
    static let moveTitle = "Finestra in den Programme-Ordner verschieben?"
    static func moveBody(_ folder: String) -> String {
        "Finestra laeuft gerade aus dem Ordner \(folder). Empfohlen wird der Programme-Ordner, damit Updates und Rechte zuverlaessig bleiben."
    }
    static let moveNow = "Verschieben"
    static let moveLater = "Nicht jetzt"
    static let moveFailed = "Verschieben fehlgeschlagen."

    // Updates
    static func updateTitle(_ v: String) -> String { "Neue Version \(v) verfuegbar" }
    static let updateInstall = "Jetzt aktualisieren"
    static let updatePage = "Release-Seite"
    static let updateLater = "Spaeter"
    static let updateNoneTitle = "Finestra ist aktuell"
    static func updateNoneBody(_ v: String) -> String { "Installiert ist Version \(v)." }
    static let updateFailTitle = "Update-Pruefung fehlgeschlagen"
    static let updateFailBody = "Die neueste Version konnte nicht ermittelt werden. Bitte spaeter erneut versuchen."
    static let updateInstalling = "Aktualisierung laeuft …"
}
