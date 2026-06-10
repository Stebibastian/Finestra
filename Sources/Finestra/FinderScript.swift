import Foundation

/// Führt Finder-Befehle über AppleScript aus. Finder bewegt sein eigenes Fenster
/// damit ruckelfrei und merkt sich die Position - anders als beim Setzen über die
/// Bedienungshilfen, das den Finder zum Zurückschieben provoziert (Pingpong).
/// Braucht die Automation-Berechtigung „Finder steuern".
enum FinderScript {
    /// AppleScript-Fehlercode für „nicht berechtigt" (Automation-Recht fehlt).
    static let notAuthorized = -1743

    /// Führt ein Skript im `tell application "Finder"`-Block aus.
    /// Gibt nil bei Erfolg zurück, sonst den Fehlercode.
    @discardableResult
    static func run(_ body: String) -> Int? {
        let source = "tell application \"Finder\"\n\(body)\nend tell"
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            let code = (error["NSAppleScriptErrorNumber"] as? Int) ?? -1
            return code
        }
        return nil
    }

    /// Setzt die Bounds (Quartz, oben-links global) des vordersten Finder-Fensters.
    @discardableResult
    static func setFrontWindowBounds(_ rect: CGRect) -> Int? {
        run("set bounds of window 1 to {\(Int(rect.minX)), \(Int(rect.minY)), \(Int(rect.maxX)), \(Int(rect.maxY))}")
    }

    /// Echte Bounds (Quartz, oben-links) des vordersten Finder-Fensters, falls lesbar.
    static func frontWindowBounds() -> CGRect? {
        let source = """
        set AppleScript's text item delimiters to ","
        tell application "Finder" to set b to bounds of window 1
        return b as string
        """
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        guard error == nil, let s = result?.stringValue else { return nil }
        let parts = s.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 4 else { return nil }
        return CGRect(x: parts[0], y: parts[1], width: parts[2] - parts[0], height: parts[3] - parts[1])
    }

    /// Stösst den Automation-Berechtigungsdialog an und meldet, ob erlaubt.
    @discardableResult
    static func requestPermission() -> Bool {
        run("count windows") != notAuthorized
    }
}
