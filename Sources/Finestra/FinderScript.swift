import Foundation

/// Steuert den Finder über `osascript`-SUBPROZESSE (nicht in-process!).
/// Wichtig: ein In-Process-Apple-Event (NSAppleScript) wird vom Finder ~0.3 s später
/// auf die gemerkte Position zurückgeschoben; ein osascript-Subprozess dagegen bleibt
/// stabil - genau wie das alte SwiftBar-Skript. Braucht die Automation-Berechtigung.
/// Alle Aufrufe blockieren (waitUntilExit) → IMMER vom Hintergrund-Thread rufen.
enum FinderScript {
    static let notAuthorized = -1743

    private static func runOsa(_ lines: [String]) -> (out: String, err: String, status: Int32) {
        var args: [String] = []
        for l in lines { args.append("-e"); args.append(l) }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = args
        let outPipe = Pipe(), errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        do { try p.run() } catch { return ("", "spawn-failed", -1) }
        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        p.waitUntilExit()
        return (out.trimmingCharacters(in: .whitespacesAndNewlines), err, p.terminationStatus)
    }

    /// Führt einen Finder-Befehl aus. nil = Erfolg, sonst Fehlercode.
    @discardableResult
    static func run(_ body: String) -> Int? {
        let r = runOsa(["tell application \"Finder\"", body, "end tell"])
        if r.status == 0 { return nil }
        if r.err.contains("-1743") { return notAuthorized }
        if let range = r.err.range(of: "-?\\d+(?=\\)\\s*$)", options: .regularExpression) {
            return Int(r.err[range]) ?? -1
        }
        return -1
    }

    /// IDs aller offenen Finder-Fenster (Finders eigene window id).
    static func windowIDs() -> [Int] {
        let r = runOsa([
            "set text item delimiters to \",\"",
            "tell application \"Finder\" to set theIDs to id of every window",
            "return theIDs as string",
        ])
        guard r.status == 0 else { return [] }
        return r.out.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    /// Setzt die Bounds (Quartz, oben-links global) eines Fensters per id.
    @discardableResult
    static func setBounds(_ rect: CGRect, id: Int) -> Int? {
        run("set bounds of window id \(id) to {\(Int(rect.minX)), \(Int(rect.minY)), \(Int(rect.maxX)), \(Int(rect.maxY))}")
    }

    /// Setzt die Bounds des vordersten Finder-Fensters (window 1).
    @discardableResult
    static func setFrontBounds(_ rect: CGRect) -> Int? {
        run("set bounds of window 1 to {\(Int(rect.minX)), \(Int(rect.minY)), \(Int(rect.maxX)), \(Int(rect.maxY))}")
    }

    /// Echte Bounds (Quartz, oben-links) eines Fensters per id.
    static func bounds(id: Int) -> CGRect? {
        let r = runOsa([
            "set text item delimiters to \",\"",
            "tell application \"Finder\" to set b to bounds of window id \(id)",
            "return b as string",
        ])
        guard r.status == 0 else { return nil }
        let p = r.out.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard p.count == 4 else { return nil }
        return CGRect(x: p[0], y: p[1], width: p[2] - p[0], height: p[3] - p[1])
    }

    /// Stösst den Automation-Berechtigungsdialog an und meldet, ob erlaubt.
    @discardableResult
    static func requestPermission() -> Bool {
        run("count windows") != notAuthorized
    }
}
