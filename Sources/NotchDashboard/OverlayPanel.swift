import AppKit
import SwiftUI

/// Панель без рамки поверх строки меню и Dock. Не активирует приложение:
/// то, в чём работает пользователь, остаётся активным.
final class OverlayPanel: NSPanel {
    /// Может ли панель принимать клавиатуру. У выреза — нет, у дашборда — да.
    var acceptsKey = false
    /// Возвращает `true`, если нажатие обработано и дальше не идёт.
    var keyDownHandler: ((UInt16, NSEvent.ModifierFlags) -> Bool)?
    var scrollHandler: ((NSEvent) -> Bool)?
    var resignKeyHandler: (() -> Void)?

    static func make() -> OverlayPanel {
        let panel = OverlayPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.animationBehavior = .none
        return panel
    }

    override var canBecomeKey: Bool { acceptsKey }
    override var canBecomeMain: Bool { false }

    /// Панель висит над строкой меню — не даём AppKit сдвинуть её ниже.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .keyDown where keyDownHandler?(event.keyCode, event.modifierFlags) == true:
            return
        case .scrollWheel where scrollHandler?(event) == true:
            return
        default:
            super.sendEvent(event)
        }
    }

    override func resignKey() {
        super.resignKey()
        resignKeyHandler?()
    }
}

/// Клик по неактивной панели сразу доходит до SwiftUI, без клика «на фокус».
final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}
