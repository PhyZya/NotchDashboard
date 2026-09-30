import AppKit
import NotchCore

enum ScreenLocator {
    /// Экран с вырезом — встроенный дисплей MacBook. Если его нет (крышка
    /// закрыта, Mac без выреза), то с `simulate` вырез рисуется заглушкой
    /// на основном экране, иначе приложению показываться негде.
    @MainActor
    static func notchGeometry(simulate: Bool) -> ScreenGeometry? {
        for screen in NSScreen.screens {
            guard
                let left = screen.auxiliaryTopLeftArea,
                let right = screen.auxiliaryTopRightArea,
                let geometry = ScreenGeometry(
                    screenFrame: screen.frame,
                    leftAreaWidth: left.width,
                    rightAreaWidth: right.width,
                    topInset: screen.safeAreaInsets.top
                )
            else { continue }
            return geometry
        }
        guard simulate, let screen = NSScreen.screens.first else { return nil }
        return .simulated(on: screen.frame)
    }
}
