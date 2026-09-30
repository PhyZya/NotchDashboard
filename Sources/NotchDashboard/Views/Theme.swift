import NotchCore
import SwiftUI

extension Color {
    init(_ color: DesignColor) {
        self.init(.sRGB, red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
    }
}

/// Цвета `docs/DESIGN.md` для SwiftUI.
enum Theme {
    static var bg: Color { Color(DesignPalette.bg) }
    static var surface: Color { Color(DesignPalette.surface) }
    static var ink: Color { Color(DesignPalette.ink) }
    static var ink2: Color { Color(DesignPalette.ink2) }
    static var ink3: Color { Color(DesignPalette.ink3) }
    static var purple: Color { Color(DesignPalette.purple) }
    static var yellow: Color { Color(DesignPalette.yellow) }
    static var dark: Color { Color(DesignPalette.dark) }
    static var dark2: Color { Color(DesignPalette.dark2) }
    static var dark3: Color { Color(DesignPalette.dark3) }
    static var darkText2: Color { Color(DesignPalette.darkText2) }
    static var redOnDark: Color { Color(DesignPalette.redOnDark) }
    static var ok: Color { Color(DesignPalette.ok) }
    static var notch: Color { Color(DesignPalette.notch) }
    static var clock: Color { Color(DesignPalette.clock) }
    static var assistantPlaceholder: Color { Color(DesignPalette.assistantPlaceholder) }
    static var assistantShortcut: Color { Color(DesignPalette.assistantShortcut) }
}
