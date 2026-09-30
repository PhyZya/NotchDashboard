import NotchCore
import SwiftUI

extension Color {
    init(_ color: RGBColor) {
        self.init(.sRGB, red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
    }
}

/// Цвета `docs/DESIGN.md` для SwiftUI.
enum Theme {
    static var bg: Color { Color(Palette.bg) }
    static var surface: Color { Color(Palette.surface) }
    static var ink: Color { Color(Palette.ink) }
    static var ink2: Color { Color(Palette.ink2) }
    static var ink3: Color { Color(Palette.ink3) }
    static var purple: Color { Color(Palette.purple) }
    static var yellow: Color { Color(Palette.yellow) }
    static var dark: Color { Color(Palette.dark) }
    static var dark2: Color { Color(Palette.dark2) }
    static var darkText2: Color { Color(Palette.darkText2) }
    static var ok: Color { Color(Palette.ok) }
    static var notch: Color { Color(Palette.notch) }
    static var clock: Color { Color(Palette.clock) }
    static var assistantPlaceholder: Color { Color(Palette.assistantPlaceholder) }
    static var assistantShortcut: Color { Color(Palette.assistantShortcut) }
}
