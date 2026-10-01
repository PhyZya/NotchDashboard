import AppKit
import NotchCore
import SwiftUI

extension Color {
    init(_ color: DesignColor) {
        self.init(.sRGB, red: color.red, green: color.green, blue: color.blue, opacity: color.alpha)
    }
}

extension NSColor {
    convenience init(_ color: DesignColor) {
        self.init(srgbRed: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }
}

extension NSAppearance {
    /// Оформление окна для темы приложения: системное стекло и меню
    /// подстраиваются под него сами.
    static func forTheme(_ theme: AppTheme) -> NSAppearance? {
        NSAppearance(named: theme == .dark ? .darkAqua : .aqua)
    }

    var isDark: Bool {
        bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

/// Цвета `docs/DESIGN.md` для SwiftUI. Каждый токен сам выбирает значение
/// тёмной или светлой темы по оформлению окна: тему переключает
/// `NotchController.apply(theme:)`, а панель у выреза всегда тёмная.
enum Theme {
    static let bg = token(\.bg)
    static let surface = token(\.surface)
    static let raised = token(\.raised)
    static let raised2 = token(\.raised2)
    static let fill = token(\.fill)
    static let fill2 = token(\.fill2)
    static let label = token(\.label)
    static let label2 = token(\.label2)
    static let label3 = token(\.label3)
    static let sep = token(\.sep)
    static let edge = token(\.edge)
    static let onLabel = token(\.onLabel)
    static let overlay1 = token(\.overlay1)
    static let overlay2 = token(\.overlay2)
    static let overlay3 = token(\.overlay3)
    static let overlay4 = token(\.overlay4)
    static let hair = token(\.hair)
    static let notchGlow = token(\.notchGlow)
    static let musicBackground = token(\.musicBackground)
    static let orange = token(\.orange)
    static let green = token(\.green)
    static let red = token(\.red)
    static let yellow = token(\.yellow)

    static let notch = Color(DesignPalette.notch)

    /// Сколько цвета обложки в подсветке музыки — в тёмной теме больше.
    static func coverMix(dark: Bool) -> Double {
        (dark ? ThemePalette.dark : ThemePalette.light).coverMix
    }

    private static func token(_ key: KeyPath<ThemePalette, DesignColor>) -> Color {
        let dark = ThemePalette.dark[keyPath: key]
        let light = ThemePalette.light[keyPath: key]
        return Color(nsColor: NSColor(name: nil) { appearance in
            NSColor(appearance.isDark ? dark : light)
        })
    }
}
