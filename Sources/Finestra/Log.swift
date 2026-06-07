import Foundation

/// Einfaches Datei-Protokoll (plus Lesefunktion für die In-App-Anzeige).
/// Schreibt nach ~/Library/Logs/Finestra.log.
enum Log {
    private static let queue = DispatchQueue(label: "com.realview.finestra.log")

    static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Finestra.log")
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    static func log(_ message: String) {
        let line = "\(timeFormatter.string(from: Date()))  \(message)\n"
        queue.async {
            guard let data = line.data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    defer { try? handle.close() }
                    _ = try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                }
            } else {
                try? data.write(to: fileURL)
            }
        }
    }

    /// Die letzten `n` Zeilen (für die Anzeige).
    static func readTail(_ n: Int = 300) -> String {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return "" }
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.suffix(n).joined(separator: "\n")
    }

    static func clear() {
        queue.async { try? "".write(to: fileURL, atomically: true, encoding: .utf8) }
    }
}
