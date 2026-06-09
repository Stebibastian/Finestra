import Foundation

/// Alle benutzersichtbaren Texte, mehrsprachig (DE/EN/FR/ES/IT).
/// Deutsch in Schweizer Orthografie (ss statt ß). `lang` wird beim Start gesetzt.
enum Strings {
    /// Aktuelle Oberflächensprache ("de"/"en"/"fr"/"es"/"it").
    static var lang = "de"

    /// Wählt die Variante zur aktuellen Sprache (EN als Rückfall).
    private static func s(_ de: String, _ en: String,
                         _ fr: String, _ es: String, _ it: String) -> String {
        switch lang {
        case "en": return en
        case "fr": return fr
        case "es": return es
        case "it": return it
        default:   return de
        }
    }

    static let appName = "Finestra"
    static var tagline: String { s(
        "Finder-Fenster automatisch platzieren",
        "Place Finder windows automatically",
        "Placer les fenêtres du Finder automatiquement",
        "Coloca las ventanas del Finder automáticamente",
        "Posiziona automaticamente le finestre del Finder") }
    static var statusTooltip: String { s(
        "Finestra - Finder-Fenster platzieren",
        "Finestra - place Finder windows",
        "Finestra - placer les fenêtres du Finder",
        "Finestra - colocar ventanas del Finder",
        "Finestra - posiziona le finestre del Finder") }

    // MARK: Menü
    static var menuSettings: String { s("Einstellungen …", "Settings …", "Réglages …", "Ajustes …", "Impostazioni …") }
    static var menuPlaceNow: String { s(
        "Vorderstes Finder-Fenster jetzt platzieren",
        "Place frontmost Finder window now",
        "Placer la fenêtre du Finder au premier plan",
        "Colocar la ventana del Finder en primer plano",
        "Posiziona ora la finestra del Finder in primo piano") }
    static var menuOnboarding: String { s(
        "Einführung anzeigen …", "Show setup assistant …", "Afficher l'assistant …",
        "Mostrar el asistente …", "Mostra l'assistente …") }
    static var menuLog: String { s("Protokoll anzeigen …", "Show log …", "Afficher le journal …", "Mostrar registro …", "Mostra registro …") }
    static var menuCheckUpdate: String { s("Nach Updates suchen …", "Check for updates …", "Rechercher des mises à jour …", "Buscar actualizaciones …", "Cerca aggiornamenti …") }
    static var menuQuit: String { s("Finestra beenden", "Quit Finestra", "Quitter Finestra", "Salir de Finestra", "Esci da Finestra") }

    // MARK: Protokoll
    static var logTitle: String { s("Finestra-Protokoll", "Finestra log", "Journal Finestra", "Registro de Finestra", "Registro di Finestra") }
    static var logRefresh: String { s("Aktualisieren", "Refresh", "Actualiser", "Actualizar", "Aggiorna") }
    static var logClear: String { s("Leeren", "Clear", "Effacer", "Vaciar", "Svuota") }
    static var logReveal: String { s("Im Finder zeigen", "Show in Finder", "Afficher dans le Finder", "Mostrar en el Finder", "Mostra nel Finder") }
    static var logHint: String { s(
        "Zeigt für jedes neue Finder-Fenster, welchen Monitor und welche Grösse Finestra wählt.",
        "Shows, for each new Finder window, which monitor and size Finestra picks.",
        "Indique, pour chaque nouvelle fenêtre du Finder, le moniteur et la taille choisis par Finestra.",
        "Muestra, para cada nueva ventana del Finder, qué monitor y tamaño elige Finestra.",
        "Mostra, per ogni nuova finestra del Finder, quale monitor e dimensione sceglie Finestra.") }
    static var logEmpty: String { s(
        "(noch keine Einträge - öffne ein Finder-Fenster)",
        "(no entries yet - open a Finder window)",
        "(aucune entrée - ouvrez une fenêtre du Finder)",
        "(sin entradas - abre una ventana del Finder)",
        "(nessuna voce - apri una finestra del Finder)") }
    static var logButton: String { menuLog }

    // MARK: Abschnitte
    static var sectionMonitors: String { s("Monitore", "Monitors", "Moniteurs", "Monitores", "Monitor") }
    static var sectionTarget: String { s("Zielmonitor", "Target monitor", "Moniteur cible", "Monitor de destino", "Monitor di destinazione") }
    static var sectionSize: String { s("Fenstergrösse", "Window size", "Taille de fenêtre", "Tamaño de ventana", "Dimensione finestra") }
    static var sectionPosition: String { s("Position", "Position", "Position", "Posición", "Posizione") }
    static var sectionGeneral: String { s("Allgemein", "General", "Général", "General", "Generale") }

    static var enabledLabel: String { s("Automatisch platzieren", "Place automatically", "Placer automatiquement", "Colocar automáticamente", "Posiziona automaticamente") }

    // MARK: Zielmonitor
    static var targetMouse: String { s(
        "Aktiver Monitor (wo die Maus ist)",
        "Active monitor (where the mouse is)",
        "Moniteur actif (où est la souris)",
        "Monitor activo (donde está el ratón)",
        "Monitor attivo (dov'è il mouse)") }
    static var targetMouseHint: String { s(
        "Neue Fenster gehen auf dem Monitor auf, auf dem gerade der Mauszeiger ist.",
        "New windows open on the monitor the pointer is currently on.",
        "Les nouvelles fenêtres s'ouvrent sur le moniteur où se trouve le pointeur.",
        "Las nuevas ventanas se abren en el monitor donde está el puntero.",
        "Le nuove finestre si aprono sul monitor dove si trova il puntatore.") }
    static var targetFixedHint: String { s(
        "Neue Fenster werden immer auf den gewählten Monitor verschoben.",
        "New windows always go to the chosen monitor.",
        "Les nouvelles fenêtres vont toujours sur le moniteur choisi.",
        "Las nuevas ventanas van siempre al monitor elegido.",
        "Le nuove finestre vanno sempre sul monitor scelto.") }

    static var mapHintFixed: String { s(
        "Klick auf einen Monitor in der Karte wählt den Zielmonitor.",
        "Click a monitor in the map to choose the target.",
        "Cliquez sur un moniteur dans le plan pour choisir la cible.",
        "Haz clic en un monitor del mapa para elegir el destino.",
        "Fai clic su un monitor nella mappa per scegliere la destinazione.") }
    static var mapHintEdit: String { s(
        "Klick auf einen Monitor wählt, für welchen Du oben Grösse und unten Position einstellst. Jeder Monitor hat eigene Werte.",
        "Click a monitor to choose which one you set size (above) and position (below) for. Each monitor has its own values.",
        "Cliquez sur un moniteur pour choisir celui dont vous réglez la taille (au-dessus) et la position (en dessous). Chaque moniteur a ses propres valeurs.",
        "Haz clic en un monitor para elegir para cuál ajustas el tamaño (arriba) y la posición (abajo). Cada monitor tiene sus propios valores.",
        "Fai clic su un monitor per scegliere quello di cui imposti dimensione (sopra) e posizione (sotto). Ogni monitor ha i propri valori.") }

    // MARK: Grösse
    static var sizeFixed: String { s("Feste Grösse", "Fixed size", "Taille fixe", "Tamaño fijo", "Dimensione fissa") }
    static var sizePercent: String { s("Anteil am Bildschirm", "Share of screen", "Part de l'écran", "Porcentaje de pantalla", "Percentuale dello schermo") }
    static var sizeWidth: String { s("Breite", "Width", "Largeur", "Anchura", "Larghezza") }
    static var sizeHeight: String { s("Höhe", "Height", "Hauteur", "Altura", "Altezza") }

    // MARK: Versatz
    static var offsetLabel: String { s("Versatz", "Offset", "Décalage", "Desplazamiento", "Scostamento") }
    static var offsetHint: String { s(
        "Verschiebt das Fenster zusätzlich (+ = nach rechts bzw. unten).",
        "Nudges the window further (+ = right / down).",
        "Décale la fenêtre (+ = droite / bas).",
        "Desplaza la ventana (+ = derecha / abajo).",
        "Sposta ulteriormente la finestra (+ = destra / giù).") }
    static var offsetReset: String { s("Zurücksetzen", "Reset", "Réinitialiser", "Restablecer", "Reimposta") }

    // MARK: Allgemein
    static var launchAtLogin: String { s("Beim Anmelden starten", "Launch at login", "Lancer à la connexion", "Abrir al iniciar sesión", "Avvia all'accesso") }
    static var version: String { s("Version", "Version", "Version", "Versión", "Versione") }
    static var checkUpdate: String { s("Nach Updates suchen", "Check for updates", "Rechercher des mises à jour", "Buscar actualizaciones", "Cerca aggiornamenti") }
    static var language: String { s("Sprache", "Language", "Langue", "Idioma", "Lingua") }
    static var languageSystem: String { s("System", "System", "Système", "Sistema", "Sistema") }

    // MARK: Positionsnamen (Reihenfolge wie WindowPosition)
    static var positionNames: [String] { [
        s("Oben links", "Top left", "En haut à gauche", "Arriba izquierda", "In alto a sinistra"),
        s("Oben mittig", "Top centre", "En haut au centre", "Arriba centro", "In alto al centro"),
        s("Oben rechts", "Top right", "En haut à droite", "Arriba derecha", "In alto a destra"),
        s("Links", "Left", "Gauche", "Izquierda", "Sinistra"),
        s("Mittig", "Centre", "Centre", "Centro", "Centro"),
        s("Rechts", "Right", "Droite", "Derecha", "Destra"),
        s("Unten links", "Bottom left", "En bas à gauche", "Abajo izquierda", "In basso a sinistra"),
        s("Unten mittig", "Bottom centre", "En bas au centre", "Abajo centro", "In basso al centro"),
        s("Unten rechts", "Bottom right", "En bas à droite", "Abajo derecha", "In basso a destra"),
    ] }

    static var ok: String { "OK" }

    // MARK: Lage-Hinweise (links/rechts/…)
    static var hintLeft: String { s("links", "left", "gauche", "izquierda", "sinistra") }
    static var hintRight: String { s("rechts", "right", "droite", "derecha", "destra") }
    static var hintCenter: String { s("Mitte", "centre", "centre", "centro", "centro") }
    static var hintTop: String { s("oben", "top", "haut", "arriba", "alto") }
    static var hintBottom: String { s("unten", "bottom", "bas", "abajo", "basso") }
    static var hintMain: String { s("Haupt", "Main", "Principal", "Principal", "Principale") }

    // MARK: Verschieben nach /Applications
    static var moveTitle: String { s(
        "Finestra in den Programme-Ordner verschieben?",
        "Move Finestra to the Applications folder?",
        "Déplacer Finestra dans le dossier Applications ?",
        "¿Mover Finestra a la carpeta Aplicaciones?",
        "Spostare Finestra nella cartella Applicazioni?") }
    static func moveBody(_ folder: String) -> String { s(
        "Finestra läuft gerade aus dem Ordner \(folder). Empfohlen wird der Programme-Ordner, damit Updates und Rechte zuverlässig bleiben.",
        "Finestra is running from the \(folder) folder. The Applications folder is recommended so updates and permissions stay reliable.",
        "Finestra s'exécute depuis le dossier \(folder). Le dossier Applications est recommandé pour des mises à jour et autorisations fiables.",
        "Finestra se ejecuta desde la carpeta \(folder). Se recomienda la carpeta Aplicaciones para que las actualizaciones y los permisos sigan siendo fiables.",
        "Finestra è in esecuzione dalla cartella \(folder). Si consiglia la cartella Applicazioni affinché aggiornamenti e autorizzazioni restino affidabili.") }
    static var moveNow: String { s("Verschieben", "Move", "Déplacer", "Mover", "Sposta") }
    static var moveLater: String { s("Nicht jetzt", "Not now", "Pas maintenant", "Ahora no", "Non ora") }
    static var moveFailed: String { s("Verschieben fehlgeschlagen.", "Move failed.", "Échec du déplacement.", "Error al mover.", "Spostamento non riuscito.") }

    // MARK: Updates
    static func updateTitle(_ v: String) -> String { s(
        "Neue Version \(v) verfügbar", "New version \(v) available", "Nouvelle version \(v) disponible",
        "Nueva versión \(v) disponible", "Nuova versione \(v) disponibile") }
    static var updateInstall: String { s("Jetzt aktualisieren", "Update now", "Mettre à jour", "Actualizar ahora", "Aggiorna ora") }
    static var updatePage: String { s("Release-Seite", "Release page", "Page de version", "Página de versión", "Pagina della versione") }
    static var updateLater: String { s("Später", "Later", "Plus tard", "Más tarde", "Più tardi") }
    static var updateNoneTitle: String { s("Finestra ist aktuell", "Finestra is up to date", "Finestra est à jour", "Finestra está actualizado", "Finestra è aggiornato") }
    static func updateNoneBody(_ v: String) -> String { s(
        "Installiert ist Version \(v).", "Version \(v) is installed.", "La version \(v) est installée.",
        "La versión \(v) está instalada.", "È installata la versione \(v).") }
    static var updateFailTitle: String { s("Update-Prüfung fehlgeschlagen", "Update check failed", "Échec de la vérification", "Error al buscar actualizaciones", "Controllo aggiornamenti non riuscito") }
    static var updateFailBody: String { s(
        "Die neueste Version konnte nicht ermittelt werden. Bitte später erneut versuchen.",
        "Couldn't determine the latest version. Please try again later.",
        "Impossible de déterminer la dernière version. Réessayez plus tard.",
        "No se pudo determinar la última versión. Inténtalo de nuevo más tarde.",
        "Impossibile determinare l'ultima versione. Riprova più tardi.") }
    static var updateInstalling: String { s("Aktualisierung läuft …", "Updating …", "Mise à jour …", "Actualizando …", "Aggiornamento …") }
    static var updateRelaunchHint: String { s(
        "Finestra wird heruntergeladen und startet sich neu.",
        "Finestra is downloading and will relaunch.",
        "Finestra se télécharge et redémarre.",
        "Finestra se está descargando y se reiniciará.",
        "Finestra si sta scaricando e si riavvierà.") }
    static var updateAvailableLabel: String { s("Neuerungen:", "What's new:", "Nouveautés :", "Novedades:", "Novità:") }
    static var updateBody: String { s(
        "Eine neue Version ist verfügbar.", "A new version is available.",
        "Une nouvelle version est disponible.", "Hay una nueva versión disponible.",
        "È disponibile una nuova versione.") }
    static var autoUpdate: String { s(
        "Updates automatisch installieren", "Install updates automatically",
        "Installer les mises à jour automatiquement", "Instalar actualizaciones automáticamente",
        "Installa gli aggiornamenti automaticamente") }

    // MARK: Onboarding
    static var obWelcomeTitle: String { s("Willkommen bei Finestra", "Welcome to Finestra", "Bienvenue dans Finestra", "Te damos la bienvenida a Finestra", "Benvenuto in Finestra") }
    static var obWelcomeBody: String { s(
        "Finestra platziert neue Finder-Fenster automatisch. Richten wir das in wenigen Schritten ein.",
        "Finestra places new Finder windows automatically. Let's set it up in a few steps.",
        "Finestra place automatiquement les nouvelles fenêtres du Finder. Configurons cela en quelques étapes.",
        "Finestra coloca automáticamente las nuevas ventanas del Finder. Vamos a configurarlo en unos pasos.",
        "Finestra posiziona automaticamente le nuove finestre del Finder. Configuriamolo in pochi passaggi.") }
    static var obStart: String { s("Los geht's", "Get started", "Commencer", "Empezar", "Iniziamo") }
    static var obBack: String { s("Zurück", "Back", "Retour", "Atrás", "Indietro") }
    static var obNext: String { s("Weiter", "Continue", "Continuer", "Continuar", "Avanti") }
    static var obFinish: String { s("Fertig", "Done", "Terminé", "Listo", "Fine") }
    static var obSkip: String { s("Überspringen", "Skip", "Ignorer", "Omitir", "Salta") }
    static var obTargetTitle: String { s(
        "Wo sollen neue Fenster aufgehen?", "Where should new windows open?",
        "Où les nouvelles fenêtres doivent-elles s'ouvrir ?", "¿Dónde deben abrirse las nuevas ventanas?",
        "Dove devono aprirsi le nuove finestre?") }
    static var obTargetBody: String { s(
        "Wähle, auf welchen Monitor neue Finder-Fenster gehen sollen.",
        "Choose which monitor new Finder windows go to.",
        "Choisissez le moniteur des nouvelles fenêtres du Finder.",
        "Elige a qué monitor van las nuevas ventanas del Finder.",
        "Scegli su quale monitor vanno le nuove finestre del Finder.") }
    static var obConfigTitle: String { s("Grösse & Position", "Size & position", "Taille et position", "Tamaño y posición", "Dimensione e posizione") }
    static func obConfigFor(_ name: String) -> String { s(
        "Für Monitor: \(name)", "For monitor: \(name)", "Pour le moniteur : \(name)",
        "Para el monitor: \(name)", "Per il monitor: \(name)") }
    static var obConfigBody: String { s(
        "So sollen Fenster auf diesem Monitor erscheinen.",
        "How windows should appear on this monitor.",
        "Comment les fenêtres doivent apparaître sur ce moniteur.",
        "Cómo deben aparecer las ventanas en este monitor.",
        "Come devono apparire le finestre su questo monitor.") }
    static var obDoneTitle: String { s("Alles bereit!", "All set!", "Tout est prêt !", "¡Todo listo!", "Tutto pronto!") }
    static var obDoneBody: String { s(
        "Finestra läuft jetzt in der Menüleiste. Öffne ein Finder-Fenster zum Ausprobieren. Du kannst alles jederzeit in den Einstellungen ändern.",
        "Finestra now lives in the menu bar. Open a Finder window to try it. You can change everything anytime in Settings.",
        "Finestra est maintenant dans la barre des menus. Ouvrez une fenêtre du Finder pour l'essayer. Vous pouvez tout modifier dans les réglages.",
        "Finestra ahora está en la barra de menús. Abre una ventana del Finder para probarlo. Puedes cambiar todo cuando quieras en los ajustes.",
        "Finestra ora è nella barra dei menu. Apri una finestra del Finder per provarlo. Puoi cambiare tutto nelle impostazioni.") }
    static func obStepOf(_ a: Int, _ b: Int) -> String { s(
        "Schritt \(a) von \(b)", "Step \(a) of \(b)", "Étape \(a) sur \(b)", "Paso \(a) de \(b)", "Passo \(a) di \(b)") }
    static var obChooseLanguage: String { s("Sprache", "Language", "Langue", "Idioma", "Lingua") }
}
