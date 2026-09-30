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
public struct LaunchOptions: Hashable, Sendable {
    public enum State: String, Hashable, Sendable {
        case idle
        case hover
        case dashboard
    }

    public var simulateNotch = false
    public var state: State = .idle
    public var section: DashboardBlock?

    public init(arguments: [String], environment: [String: String] = [:]) {
        simulateNotch = arguments.contains("--simulate-notch")
            || environment["NOTCHDASHBOARD_SIMULATE_NOTCH"] == "1"
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
