import Testing
@testable import NotchCore

struct HotkeysTests {
    /// `docs/SPEC.md`, «Горячие клавиши».
    @Test func globalDefaultsMatchSpec() {
        let expected: [GlobalHotkey: String] = [
            .quickInput: "⌥K",
            .dashboard: "⌥D",
            .assistant: "⌥J",
            .clipboardHistory: "⌥V",
            .screenshot: "⌥S",
            .focusTimer: "⌥F",
        ]
        for hotkey in GlobalHotkey.allCases {
            #expect(hotkey.defaultCombo.displayString == expected[hotkey])
        }
        #expect(Set(GlobalHotkey.allCases.map(\.defaultCombo)).count == GlobalHotkey.allCases.count)
    }

    /// Коды — физические клавиши американской раскладки (`kVK_ANSI_*`).
    @Test func physicalKeyCodes() {
        #expect(KeyCode.k.rawValue == 40)
        #expect(KeyCode.d.rawValue == 2)
        #expect(KeyCode.j.rawValue == 38)
        #expect(KeyCode.v.rawValue == 9)
        #expect(KeyCode.s.rawValue == 1)
        #expect(KeyCode.f.rawValue == 3)
        #expect(KeyCode.space.rawValue == 49)
        #expect(KeyCode.escape.rawValue == 53)
    }

    @Test func carbonIDsRoundTrip() {
        for hotkey in GlobalHotkey.allCases {
            #expect(hotkey.carbonID > 0)
            #expect(GlobalHotkey(carbonID: hotkey.carbonID) == hotkey)
        }
        #expect(GlobalHotkey(carbonID: 0) == nil)
    }

    @Test func modifierFlags() {
        #expect(KeyModifiers.option.carbonFlags == 0x0800)
        #expect(KeyModifiers([.command, .shift]).carbonFlags == 0x0300)
        #expect(KeyModifiers([.control, .option, .shift, .command]).symbols == "⌃⌥⇧⌘")

        // NSEvent.ModifierFlags: ⇧ 1<<17, ⌃ 1<<18, ⌥ 1<<19, ⌘ 1<<20, Caps Lock 1<<16.
        #expect(KeyModifiers(eventFlags: 1 << 20) == .command)
        #expect(KeyModifiers(eventFlags: (1 << 19) | (1 << 16)) == .option)
        #expect(KeyModifiers(eventFlags: 0) == [])
    }

    @Test func dashboardShortcuts() {
        #expect(DashboardShortcut(key: .k, modifiers: .command) == .record)
        #expect(DashboardShortcut(key: .f, modifiers: .command) == .search)
        #expect(DashboardShortcut(key: .j, modifiers: .command) == .assistant)
        #expect(DashboardShortcut(key: .space, modifiers: []) == .timer)
        #expect(DashboardShortcut(key: .escape, modifiers: []) == .back)
        #expect(DashboardShortcut(key: .k, modifiers: .option) == nil)
        #expect(DashboardShortcut.back.combo.displayString == "Esc")
    }
}
