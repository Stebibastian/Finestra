import Foundation

/// Beobachtet den Finder per AppleScript-Polling (osascript) auf einem eigenen
/// Hintergrund-Thread und platziert jedes neue Fenster. Kein Accessibility - rein
/// osascript, wie das alte Skript (ruckelfrei). osascript blockiert, darum NICHT
/// auf dem Main-Thread.
final class FinderWatcher {
    private let queue = DispatchQueue(label: "com.realview.finestra.watcher")
    private var seen: Set<Int> = []
    private var running = false

    func start() {
        queue.async { [weak self] in
            guard let self, !self.running else { return }
            self.running = true
            self.seen = Set(FinderScript.windowIDs())   // bestehende merken (nicht verschieben)
            Log.log("Watcher: Start (osascript) | \(self.seen.count) bestehende Fenster gemerkt")
            self.tick()
        }
    }

    func stop() { queue.async { [weak self] in self?.running = false } }

    private func tick() {
        guard running else { return }
        scan()
        queue.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.tick() }
    }

    private func scan() {
        guard Settings.enabled else { return }
        let current = Set(FinderScript.windowIDs())
        for id in current where !seen.contains(id) {
            seen.insert(id)
            Log.log("Neues Fenster \(id) erkannt")
            // Kurz warten, bis der Finder das Fenster fertig hat, dann platzieren (auf dieser bg-Queue).
            queue.asyncAfter(deadline: .now() + 0.3) {
                WindowPlacer.placeWindow(finderID: id)
            }
        }
        seen.formIntersection(current)
    }

    /// Manuell: vorderstes Finder-Fenster platzieren.
    func placeFrontmost() {
        queue.async {
            Log.log("Manuell: platziere vorderstes Fenster")
            WindowPlacer.placeFrontWindow()
        }
    }
}
