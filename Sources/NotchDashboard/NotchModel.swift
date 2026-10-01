import Foundation
import NotchCore
import Observation

/// Всё, что рисуют окна у выреза и дашборда. Меняет только `NotchController`,
/// обычно внутри `withAnimation`.
@MainActor
@Observable
final class NotchModel {
    var geometry: ScreenGeometry?

    /// Что видно у выреза. Пока открыт дашборд — `.dashboard`: форма у выреза
    /// в покое, поверх неё лежит форма дашборда.
    var phase: NotchPhase = .idle
    var route: DashboardRoute = .home

    /// Окно дашборда на экране, форма растёт или сжимается.
    var isDashboardPresented = false
    /// 0 — форма дашборда совпадает с формой у выреза, 1 — на весь экран.
    var morphProgress = 0.0
    /// Откуда растёт форма, в координатах экрана с началом вверху слева.
    var morphOrigin = CGRect.zero
    var morphOriginRadius = NotchMetrics.earsCornerRadius
    /// Форма перекрашивается из чёрного выреза в фон дашборда `bg`
    /// (в тёмной теме он почти чёрный, в светлой — светло-серый).
    var hasDashboardBackground = false
    var showsDashboardContent = false

    /// Что показывает панель наведения и счётчик в «ухе». Задачи появятся
    /// на шаге 2 плана, Spotify — на шаге 3; до тех пор пусто или образец `--sample`.
    var hover = HoverContent()
}
