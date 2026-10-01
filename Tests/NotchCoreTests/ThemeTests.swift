import Testing
@testable import NotchCore

struct ThemeTests {
    @Test func darkIsDefault() {
        #expect(AppTheme.default == .dark)
        #expect(AppTheme(rawValue: "light") == .light)
        #expect(AppTheme(rawValue: "sepia") == nil)
        #expect(AppTheme.allCases.map(\.title) == ["Тёмная тема", "Светлая тема"])
    }

    /// Значения из `docs/DESIGN.md`, «Цвета».
    @Test func palettesMatchDesign() {
        let dark = AppTheme.dark.palette
        #expect(dark.bg == DesignColor(hex: 0x0B0B0D))
        #expect(dark.surface == DesignColor(hex: 0x1C1C1E))
        #expect(dark.raised == DesignColor(hex: 0x2C2C2E))
        #expect(dark.label == DesignColor(hex: 0xF5F5F7))
        #expect(dark.fill == DesignColor(red: 118 / 255, green: 118 / 255, blue: 128 / 255, alpha: 0.24))
        #expect(dark.accent == DesignColor(hex: 0x0A84FF))

        let light = AppTheme.light.palette
        #expect(light.bg == DesignColor(hex: 0xE8E8ED))
        #expect(light.surface == DesignColor(hex: 0xFFFFFF))
        #expect(light.label == DesignColor(hex: 0x1D1D1F))
        #expect(light.accent == DesignColor(hex: 0x007AFF))
        #expect(light.coverMix < dark.coverMix)
    }

    /// Вырез и «уши» от темы не зависят, а фон тёмной темы почти сливается с вырезом.
    @Test func darkBackgroundBlendsWithNotch() {
        let bg = AppTheme.dark.palette.bg
        #expect(DesignPalette.notch == DesignColor(hex: 0x000000))
        #expect(max(bg.red, bg.green, bg.blue) < 0.06)
    }
}
