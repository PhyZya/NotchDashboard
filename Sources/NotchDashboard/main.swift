import AppKit

// Приложение без иконки в Dock: в собранном .app это задаёт LSUIElement,
// а при запуске через `swift run` — политика активации.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
