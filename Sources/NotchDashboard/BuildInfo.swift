import Foundation

/// Из какой ветки и коммита собрано приложение: `scripts/build-app.sh` пишет
/// это в Info.plist. При `swift run` и в Xcode сведений нет.
enum BuildInfo {
    static let current = Bundle.main.object(forInfoDictionaryKey: "NotchDashboardBuild") as? String

    /// Строка для меню: «Сборка claude/… · 1a2b3c4 · 01.10 14:32».
    static var menuTitle: String? {
        current.map { "Сборка \($0)" }
    }
}
