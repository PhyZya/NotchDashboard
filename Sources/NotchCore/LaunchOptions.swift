import Foundation

/// Параметры запуска для разработки и снимков экрана в CI:
///
///     NotchDashboard --simulate-notch --state dashboard --section tasks
///
/// - `--simulate-notch` или `NOTCHDASHBOARD_SIMULATE_NOTCH=1` — заглушка
///   выреза на экране без выреза (внешний монитор, виртуальная машина).
///   Если настоящий вырез есть, используется он.
/// - `--state idle|hover|dashboard` — в каком состоянии открыться.
///   `hover` закрепляется и не сворачивается, когда курсор уходит.
/// - `--section <блок>` — сразу открыть раздел, например `tasks`.
/// - `--backdrop` — под окнами фон цвета «стола» с листов дизайна: на
///   чёрных обоях виртуальной машины иначе не видно краёв и тени.
/// - `--demo` — проиграть `DemoStep.script`, чтобы снять анимации на видео.
///   Курсор при этом не отслеживается.
/// - `--sample` — панель наведения с музыкой и задачами из макета
///   (`HoverContent.sample`), пока нет настоящих задач и Spotify.
/// - `--theme dark|light` — тема на этот запуск, выбор в настройках не меняется.
public struct LaunchOptions: Hashable, Sendable {
    public enum State: String, Hashable, Sendable {
        case idle
        case hover
        case dashboard
    }

    public var simulateNotch = false
    public var state: State = .idle
    public var section: DashboardBlock?
    public var showsBackdrop = false
    public var runsDemo = false
    public var showsSample = false
    public var theme: AppTheme?

    /// Курсор мешает закреплённому наведению и сценарию.
    public var tracksPointer: Bool {
        state != .hover && !runsDemo
    }

    public init(arguments: [String], environment: [String: String] = [:]) {
        simulateNotch = arguments.contains("--simulate-notch")
            || environment["NOTCHDASHBOARD_SIMULATE_NOTCH"] == "1"
        showsBackdrop = arguments.contains("--backdrop")
        runsDemo = arguments.contains("--demo")
        showsSample = arguments.contains("--sample")
        if let value = Self.value(after: "--theme", in: arguments) {
            theme = AppTheme(rawValue: value)
        }
        if let value = Self.value(after: "--state", in: arguments), let state = State(rawValue: value) {
            self.state = state
        }
        if let value = Self.value(after: "--section", in: arguments), let block = DashboardBlock(rawValue: value) {
            section = block
            state = .dashboard
        }
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}

/// Шаг сценария `--demo`: событие через `at` секунд после запуска.
public struct DemoStep: Hashable, Sendable {
    public var at: Double
    public var event: NotchStateMachine.Event

    /// Наведение → кнопка ↗ → дашборд из панели → раздел → главная → вырез.
    public static let script: [DemoStep] = [
        DemoStep(at: 1.0, event: .pointerEntered),
        DemoStep(at: 2.6, event: .dashboardButtonTapped),
        DemoStep(at: 4.0, event: .openSection(.tasks)),
        DemoStep(at: 5.0, event: .escape),
        DemoStep(at: 6.0, event: .escape),
        DemoStep(at: 7.0, event: .pointerExited),
    ]
}
