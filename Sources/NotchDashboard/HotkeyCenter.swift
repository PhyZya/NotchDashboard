import Carbon.HIToolbox
import NotchCore
import os

private let log = Logger(subsystem: "com.phyzya.NotchDashboard", category: "hotkeys")

/// Подпись наших сочетаний в Carbon: 'NDhk'.
private let hotkeySignature: OSType = 0x4E44_686B

/// Глобальные сочетания через Carbon `RegisterEventHotKey`: работают из любого
/// приложения без разрешения «Универсальный доступ» и привязаны к физическим
/// клавишам, поэтому не зависят от раскладки.
@MainActor
final class HotkeyCenter {
    var onPress: ((GlobalHotkey) -> Void)?
    private var handler: EventHandlerRef?
    private var registered: [GlobalHotkey: EventHotKeyRef] = [:]

    func register(_ hotkey: GlobalHotkey, as combo: KeyCombo? = nil) {
        installHandlerIfNeeded()
        unregister(hotkey)
        let combo = combo ?? hotkey.defaultCombo
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(combo.key.rawValue),
            combo.modifiers.carbonFlags,
            EventHotKeyID(signature: hotkeySignature, id: hotkey.carbonID),
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == OSStatus(noErr), let ref else {
            log.error("Не удалось занять \(combo.displayString, privacy: .public) для «\(hotkey.title, privacy: .public)»: \(status)")
            return
        }
        registered[hotkey] = ref
    }

    func unregister(_ hotkey: GlobalHotkey) {
        guard let ref = registered.removeValue(forKey: hotkey) else { return }
        UnregisterEventHotKey(ref)
    }

    fileprivate func handlePress(carbonID: UInt32) {
        guard let hotkey = GlobalHotkey(carbonID: carbonID) else { return }
        onPress?(hotkey)
    }

    private func installHandlerIfNeeded() {
        guard handler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &handler
        )
        if status != OSStatus(noErr) {
            log.error("Не удалось подписаться на горячие клавиши: \(status)")
        }
    }
}

/// Carbon вызывает обработчик в главном потоке, из цикла событий приложения.
private func hotkeyEventHandler(
    _ call: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hotkeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )
    guard status == OSStatus(noErr), hotkeyID.signature == hotkeySignature else {
        return OSStatus(eventNotHandledErr)
    }
    let center = Unmanaged<HotkeyCenter>.fromOpaque(userData).takeUnretainedValue()
    let carbonID = hotkeyID.id
    MainActor.assumeIsolated { center.handlePress(carbonID: carbonID) }
    return OSStatus(noErr)
}
