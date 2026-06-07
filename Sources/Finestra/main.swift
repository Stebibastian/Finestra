import AppKit

// Finestra: platziert neue Finder-Fenster automatisch in der eingestellten
// Groesse/Position auf dem gewuenschten Monitor. Laeuft als Menueleisten-App.
let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
