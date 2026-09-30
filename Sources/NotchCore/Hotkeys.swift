import Foundation

/// Физическая клавиша — виртуальный код macOS (`kVK_*` из Carbon).
/// Сочетания привязаны к ним, поэтому работают в любой раскладке.
public struct KeyCode: RawRepresentable, Hashable, Sendable, Codable {
    public var rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public static let a = KeyCode(rawValue: 0x00)
    public static let s = KeyCode(rawValue: 0x01)
    public static let d = KeyCode(rawValue: 0x02)
    public static let f = KeyCode(rawValue: 0x03)
    public static let h = KeyCode(rawValue: 0x04)
    public static let g = KeyCode(rawValue: 0x05)
    public static let z = KeyCode(rawValue: 0x06)
    public static let x = KeyCode(rawValue: 0x07)
    public static let c = KeyCode(rawValue: 0x08)
    public static let v = KeyCode(rawValue: 0x09)
    public static let b = KeyCode(rawValue: 0x0B)
    public static let q = KeyCode(rawValue: 0x0C)
    public static let w = KeyCode(rawValue: 0x0D)
    public static let e = KeyCode(rawValue: 0x0E)
    public static let r = KeyCode(rawValue: 0x0F)
    public static let y = KeyCode(rawValue: 0x10)
    public static let t = KeyCode(rawValue: 0x11)
    public static let o = KeyCode(rawValue: 0x1F)
    public static let u = KeyCode(rawValue: 0x20)
    public static let i = KeyCode(rawValue: 0x22)
    public static let p = KeyCode(rawValue: 0x23)
    public static let l = KeyCode(rawValue: 0x25)
    public static let j = KeyCode(rawValue: 0x26)
    public static let k = KeyCode(rawValue: 0x28)
    public static let n = KeyCode(rawValue: 0x2D)
    public static let m = KeyCode(rawValue: 0x2E)
    public static let returnKey = KeyCode(rawValue: 0x24)
    public static let tab = KeyCode(rawValue: 0x30)
    public static let space = KeyCode(rawValue: 0x31)
    public static let escape = KeyCode(rawValue: 0x35)

    /// Подпись клавиши, как на американской раскладке: так сочетания показаны в макетах.
    public var label: String {
        Self.labels[self] ?? String(format: "0x%02X", rawValue)
    }

    private static let labels: [KeyCode: String] = [
        .a: "A", .b: "B", .c: "C", .d: "D", .e: "E", .f: "F", .g: "G", .h: "H", .i: "I",
        .j: "J", .k: "K", .l: "L", .m: "M", .n: "N", .o: "O", .p: "P", .q: "Q", .r: "R",
        .s: "S", .t: "T", .u: "U", .v: "V", .w: "W", .x: "X", .y: "Y", .z: "Z",
        .returnKey: "↵", .tab: "⇥", .space: "Space", .escape: "Esc",
    ]
}

public struct KeyModifiers: OptionSet, Hashable, Sendable, Codable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let control = KeyModifiers(rawValue: 1 << 0)
    public static let option = KeyModifiers(rawValue: 1 << 1)
    public static let shift = KeyModifiers(rawValue: 1 << 2)
    public static let command = KeyModifiers(rawValue: 1 << 3)

    /// Из `NSEvent.ModifierFlags.rawValue`. Остальные флаги (Caps Lock, Fn) не учитываются.
    public init(eventFlags: UInt) {
        var modifiers: KeyModifiers = []
        if eventFlags & (1 << 18) != 0 { modifiers.insert(.control) }
        if eventFlags & (1 << 19) != 0 { modifiers.insert(.option) }
        if eventFlags & (1 << 17) != 0 { modifiers.insert(.shift) }
        if eventFlags & (1 << 20) != 0 { modifiers.insert(.command) }
        self = modifiers
    }

    /// Флаги для `RegisterEventHotKey`: `controlKey`, `optionKey`, `shiftKey`, `cmdKey`.
    public var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.control) { flags |= 0x1000 }
        if contains(.option) { flags |= 0x0800 }
        if contains(.shift) { flags |= 0x0200 }
        if contains(.command) { flags |= 0x0100 }
        return flags
    }

    /// Символы в порядке меню macOS: ⌃⌥⇧⌘.
    public var symbols: String {
        var result = ""
        if contains(.control) { result += "⌃" }
        if contains(.option) { result += "⌥" }
        if contains(.shift) { result += "⇧" }
        if contains(.command) { result += "⌘" }
        return result
    }
}

public struct KeyCombo: Hashable, Sendable, Codable {
    public var key: KeyCode
    public var modifiers: KeyModifiers

    public init(_ modifiers: KeyModifiers, _ key: KeyCode) {
        self.key = key
        self.modifiers = modifiers
    }

    /// «⌥K», «⌘F», «Esc».
    public var displayString: String {
        modifiers.symbols + key.label
    }
}

/// Сочетания из любого приложения (`docs/SPEC.md`, «Горячие клавиши»).
/// Каждое можно переназначить; здесь — значения по умолчанию.
public enum GlobalHotkey: String, CaseIterable, Hashable, Sendable, Codable {
    case quickInput
    case dashboard
    case assistant
    case clipboardHistory
    case screenshot
    case focusTimer

    public var title: String {
        switch self {
        case .quickInput: "Быстрый ввод"
        case .dashboard: "Дашборд"
        case .assistant: "Ассистент"
        case .clipboardHistory: "История буфера"
        case .screenshot: "Снимок области"
        case .focusTimer: "Фокус-таймер"
        }
    }

    public var defaultCombo: KeyCombo {
        switch self {
        case .quickInput: KeyCombo(.option, .k)
        case .dashboard: KeyCombo(.option, .d)
        case .assistant: KeyCombo(.option, .j)
        case .clipboardHistory: KeyCombo(.option, .v)
        case .screenshot: KeyCombo(.option, .s)
        case .focusTimer: KeyCombo(.option, .f)
        }
    }

    /// Номер для `EventHotKeyID`: по нему Carbon сообщает, какое сочетание нажато.
    public var carbonID: UInt32 {
        UInt32(Self.allCases.firstIndex(of: self)!) + 1
    }

    public init?(carbonID: UInt32) {
        guard let hotkey = Self.allCases.first(where: { $0.carbonID == carbonID }) else { return nil }
        self = hotkey
    }
}

/// Сочетания внутри дашборда.
public enum DashboardShortcut: CaseIterable, Hashable, Sendable {
    case record
    case search
    case assistant
    case timer
    case back

    public var combo: KeyCombo {
        switch self {
        case .record: KeyCombo(.command, .k)
        case .search: KeyCombo(.command, .f)
        case .assistant: KeyCombo(.command, .j)
        case .timer: KeyCombo([], .space)
        case .back: KeyCombo([], .escape)
        }
    }

    public init?(key: KeyCode, modifiers: KeyModifiers) {
        guard let shortcut = Self.allCases.first(where: { $0.combo == KeyCombo(modifiers, key) }) else { return nil }
        self = shortcut
    }
}
