import Foundation

/// Цвет в sRGB, компоненты 0…1.
public struct DesignColor: Hashable, Sendable {
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

    /// `DesignColor(hex: 0x1C1C1E)` — как в CSS макета.
    public init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    public func opacity(_ alpha: Double) -> DesignColor {
        DesignColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

/// Тема оформления (`docs/DESIGN.md`, «Тема»). Тёмная — основная,
/// светлая — второй вариант в настройках.
public enum AppTheme: String, CaseIterable, Hashable, Sendable {
    case dark
    case light

    public static let `default` = AppTheme.dark

    /// Пункт в меню настроек.
    public var title: String {
        switch self {
        case .dark: "Тёмная тема"
        case .light: "Светлая тема"
        }
    }

    public var palette: ThemePalette {
        switch self {
        case .dark: .dark
        case .light: .light
        }
    }
}

/// Токены одной темы из `docs/DESIGN.md`, «Цвета». Точные значения —
/// в CSS `design/v3/index.html` (`:root` и `:root[data-theme="light"]`).
public struct ThemePalette: Hashable, Sendable {
    /// Фон дашборда; в тёмной теме сливается с вырезом.
    public var bg: DesignColor
    /// Блоки.
    public var surface: DesignColor
    /// Строки, карточки и чипы внутри блоков.
    public var raised: DesignColor
    /// Выделенная строка: задача в фокусе, подсказка.
    public var raised2: DesignColor
    /// Кнопки, плитки иконок.
    public var fill: DesignColor
    /// Тихие кнопки (↗, ■), дорожки, пилюли.
    public var fill2: DesignColor
    /// Основной текст и контрастная кнопка.
    public var label: DesignColor
    public var label2: DesignColor
    /// Подписи, метки, плейсхолдеры.
    public var label3: DesignColor
    /// Обводки и разделители.
    public var sep: DesignColor
    /// Обводка по краю блока.
    public var edge: DesignColor
    /// Текст на контрастной кнопке.
    public var onLabel: DesignColor
    /// Полупрозрачные наложения: дорожки, сегменты, сделанная задача.
    public var overlay1: DesignColor
    public var overlay2: DesignColor
    public var overlay3: DesignColor
    public var overlay4: DesignColor
    /// Кружок чекбокса.
    public var hair: DesignColor
    /// Свет из выреза под шапкой, чтобы стеклу было что преломлять.
    public var notchGlow: DesignColor
    /// Фон блока музыки под подсветкой обложкой.
    public var musicBackground: DesignColor
    /// Сколько цвета обложки в подсветке музыки.
    public var coverMix: Double
    /// Системный акцент при «Мультицвете»: так он нарисован в макетах.
    public var accent: DesignColor
    public var orange: DesignColor
    public var green: DesignColor
    public var red: DesignColor
    public var yellow: DesignColor

    public static let dark = ThemePalette(
        bg: DesignColor(hex: 0x0B0B0D),
        surface: DesignColor(hex: 0x1C1C1E),
        raised: DesignColor(hex: 0x2C2C2E),
        raised2: DesignColor(hex: 0x3A3A3C),
        fill: DesignColor(hex: 0x767680, alpha: 0.24),
        fill2: DesignColor(hex: 0x767680, alpha: 0.16),
        label: DesignColor(hex: 0xF5F5F7),
        label2: DesignColor(hex: 0xEBEBF5, alpha: 0.62),
        label3: DesignColor(hex: 0xEBEBF5, alpha: 0.38),
        sep: DesignColor(hex: 0xFFFFFF, alpha: 0.08),
        edge: DesignColor(hex: 0xFFFFFF, alpha: 0.05),
        onLabel: DesignColor(hex: 0x111111),
        overlay1: DesignColor(hex: 0xFFFFFF, alpha: 0.04),
        overlay2: DesignColor(hex: 0xFFFFFF, alpha: 0.1),
        overlay3: DesignColor(hex: 0xFFFFFF, alpha: 0.16),
        overlay4: DesignColor(hex: 0xFFFFFF, alpha: 0.24),
        hair: DesignColor(hex: 0xEBEBF5, alpha: 0.34),
        notchGlow: DesignColor(hex: 0x78788C, alpha: 0.16),
        musicBackground: DesignColor(hex: 0x161618),
        coverMix: 0.62,
        accent: DesignColor(hex: 0x0A84FF),
        orange: DesignColor(hex: 0xFF9F0A),
        green: DesignColor(hex: 0x30D158),
        red: DesignColor(hex: 0xFF453A),
        yellow: DesignColor(hex: 0xFFD60A)
    )

    public static let light = ThemePalette(
        bg: DesignColor(hex: 0xE8E8ED),
        surface: DesignColor(hex: 0xFFFFFF),
        raised: DesignColor(hex: 0xF2F2F7),
        raised2: DesignColor(hex: 0xE5E5EA),
        fill: DesignColor(hex: 0x787880, alpha: 0.16),
        fill2: DesignColor(hex: 0x787880, alpha: 0.1),
        label: DesignColor(hex: 0x1D1D1F),
        label2: DesignColor(hex: 0x3C3C43, alpha: 0.72),
        label3: DesignColor(hex: 0x3C3C43, alpha: 0.46),
        sep: DesignColor(hex: 0x000000, alpha: 0.08),
        edge: DesignColor(hex: 0x000000, alpha: 0.04),
        onLabel: DesignColor(hex: 0xFFFFFF),
        overlay1: DesignColor(hex: 0x000000, alpha: 0.03),
        overlay2: DesignColor(hex: 0x000000, alpha: 0.07),
        overlay3: DesignColor(hex: 0x000000, alpha: 0.1),
        overlay4: DesignColor(hex: 0x000000, alpha: 0.18),
        hair: DesignColor(hex: 0x3C3C43, alpha: 0.3),
        notchGlow: DesignColor(hex: 0xFFFFFF, alpha: 0.7),
        musicBackground: DesignColor(hex: 0xFFFFFF),
        coverMix: 0.34,
        accent: DesignColor(hex: 0x007AFF),
        orange: DesignColor(hex: 0xFF9500),
        green: DesignColor(hex: 0x28CD41),
        red: DesignColor(hex: 0xFF3B30),
        yellow: DesignColor(hex: 0xFFCC00)
    )
}

/// Цвета, которые не зависят от темы.
public enum DesignPalette {
    /// Вырез, «уши» и панель наведения — всегда чёрные, как сам вырез.
    public static let notch = DesignColor(hex: 0x000000)
    /// Рабочий стол на листах спецификации — фон для `--backdrop`.
    public static let desk = DesignColor(hex: 0x1F2B33)
    /// Обложка трека в образце `--sample` (`--cover` в макете).
    public static let sampleCover = DesignColor(hex: 0xFF453A)
}
