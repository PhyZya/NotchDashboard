import AppKit

/// Следит за курсором во всей системе. Разрешений не требует: глобальный
/// монитор получает события мыши других приложений, локальный — своих окон.
@MainActor
final class PointerMonitor {
    var onMove: (() -> Void)?
    private var monitors: [Any] = []

    func start() {
        guard monitors.isEmpty else { return }
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]
        let global = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.onMove?() }
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            if let self {
                MainActor.assumeIsolated { self.onMove?() }
            }
            return event
        }
        monitors = [global, local].compactMap { $0 }
    }
}
