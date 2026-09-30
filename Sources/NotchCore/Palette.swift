import Foundation

/// Цвет в sRGB, компоненты 0…1.
public struct RGBColor: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// `RGBColor(hex: 0x7B5CFF)` — как в CSS макета.
    public init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    public func opacity(_ alpha: Double) -> RGBColor {
        RGBColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

/// Цвета из `docs/DESIGN.md`. Точные значения — в CSS `design/v2/index.html`.
public enum Palette {
    public static let bg = RGBColor(hex: 0xE6E6EA)
    public static let surface = RGBColor(hex: 0xF5F5F7)
    public static let white = RGBColor(hex: 0xFFFFFF)
    public static let ink = RGBColor(hex: 0x17171A)
    public static let ink2 = RGBColor(hex: 0x5E5E66)
    public static let ink3 = RGBColor(hex: 0x8E8E96)
    public static let line = RGBColor(hex: 0x17171A, alpha: 0.08)

    public static let purple = RGBColor(hex: 0x7B5CFF)
    public static let purpleButton = RGBColor(hex: 0x9379FF)
    public static let yellow = RGBColor(hex: 0xFFD43B)
    public static let yellowGo = RGBColor(hex: 0xFFE27A)
    public static let red = RGBColor(hex: 0xFF5A4E)
    public static let blue = RGBColor(hex: 0x2F6BFF)
    public static let dark = RGBColor(hex: 0x17171A)
    public static let dark2 = RGBColor(hex: 0x26262B)
    public static let darkText2 = RGBColor(hex: 0xA1A1A8)
    public static let ok = RGBColor(hex: 0x2FBF5B)
    public static let notch = RGBColor(hex: 0x000000)

    /// Дата в строке с часами (`.clock` в макете).
    public static let clock = RGBColor(hex: 0x3D3D42)
    /// Подсказка в поле ассистента и сочетание `⌘J` рядом с ней.
    public static let assistantPlaceholder = RGBColor(hex: 0x8A8A92)
    public static let assistantShortcut = RGBColor(hex: 0xC8C8CE)
}
