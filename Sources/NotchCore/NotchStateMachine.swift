import Foundation

/// Состояние выреза. Таблица состояний — `docs/SPEC.md`, «Состояния выреза».
/// Быстрый ввод добавится вместе с распознаванием записей (шаг 2 плана).
public enum NotchPhase: Hashable, Sendable {
    /// Покой: форма сливается с вырезом, видны «уши».
    case idle
    /// Наведение: из выреза вытекла панель с музыкой и горящими задачами.
    case hover
    /// Дашборд на весь экран.
    case dashboard
}

/// Что открыто в дашборде: главная или полный раздел блока (стрелка ↗).
public enum DashboardRoute: Hashable, Sendable {
    case home
    case section(DashboardBlock)
}

/// Переходы между состояниями выреза без таймеров и окон: контроллер
/// приложения отправляет события и выполняет возвращённые эффекты.
public struct NotchStateMachine: Sendable {
    public enum Event: Hashable, Sendable {
        case pointerEntered
        case pointerExited
        /// Курсор пробыл на вырезе `Motion.hoverDelay`.
        case hoverDelayElapsed
        /// Клик по «ушам» раскрывает панель наведения сразу, клик по вырезу
        /// в дашборде сворачивает его. Дашборд из выреза кликом не открывается.
        case notchClicked
        /// Кнопка ↗ в панели наведения — единственный клик, который открывает дашборд.
        case dashboardButtonTapped
        /// `⌥D` или жест вниз по вырезу.
        case toggleDashboard
        /// Кнопка «закрыть» в шапке дашборда.
        case closeDashboard
        case escape
        /// Фокус ушёл: `⌘Tab`, другое приложение, другой рабочий стол.
        case lostFocus
        case openSection(DashboardBlock)
    }

    public enum Effect: Hashable, Sendable {
        case startHoverTimer
        case cancelHoverTimer
        case expandHover
        case collapseHover
        /// Форма растёт из того, что было видно в состоянии `from`.
        case openDashboard(from: NotchPhase)
        case closeDashboard
        case showRoute(DashboardRoute)
    }

    public private(set) var phase: NotchPhase = .idle
    public private(set) var route: DashboardRoute = .home
    public private(set) var isPointerInside = false
    /// Выключается, когда дашборд закрыли кликом по вырезу: иначе вырез
    /// тут же раскрылся бы под курсором. Включается, когда курсор уйдёт.
    public private(set) var isHoverArmed = true

    public init() {}

    @discardableResult
    public mutating func send(_ event: Event) -> [Effect] {
        switch event {
        case .pointerEntered:
            guard !isPointerInside else { return [] }
            isPointerInside = true
            return phase == .idle && isHoverArmed ? [.startHoverTimer] : []

        case .pointerExited:
            guard isPointerInside else { return [] }
            isPointerInside = false
            isHoverArmed = true
            guard phase == .hover else { return [.cancelHoverTimer] }
            phase = .idle
            return [.cancelHoverTimer, .collapseHover]

        case .hoverDelayElapsed:
            guard phase == .idle, isPointerInside, isHoverArmed else { return [] }
            phase = .hover
            return [.expandHover]

        case .notchClicked:
            switch phase {
            case .idle:
                phase = .hover
                return [.cancelHoverTimer, .expandHover]
            case .hover:
                return []
            case .dashboard:
                return close()
            }

        case .dashboardButtonTapped:
            return phase == .hover ? open() : []

        case .toggleDashboard:
            return phase == .dashboard ? close() : open()

        case .closeDashboard, .lostFocus:
            return phase == .dashboard ? close() : []

        case .escape:
            guard phase == .dashboard else { return [] }
            guard route == .home else {
                route = .home
                return [.showRoute(.home)]
            }
            return close()

        case .openSection(let block):
            guard phase == .dashboard, route != .section(block) else { return [] }
            route = .section(block)
            return [.showRoute(route)]
        }
    }

    private mutating func open() -> [Effect] {
        let from = phase
        phase = .dashboard
        route = .home
        return [.cancelHoverTimer, .openDashboard(from: from)]
    }

    private mutating func close() -> [Effect] {
        phase = .idle
        route = .home
        isHoverArmed = !isPointerInside
        return [.closeDashboard]
    }
}
