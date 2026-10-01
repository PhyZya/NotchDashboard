import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Блоки главной (`design/v3/Дашборд главная v3.png`). Все — `surface`,
/// кроме музыки: её подсвечивает обложка трека.
public enum DashboardBlock: String, CaseIterable, Hashable, Sendable, Identifiable {
    case tasks
    case miniApps
    case music
    case work
    case assistant
    case focus
    case notes
    case clipboard

    public var id: String { rawValue }

    /// Заголовок на главной.
    public var title: String {
        switch self {
        case .tasks: "Задачи на сегодня"
        case .miniApps: "Мини-приложения"
        case .music: "Музыка"
        case .work: "Работа"
        case .assistant: "Ассистент"
        case .focus: "Фокус"
        case .notes: "Заметки и закладки"
        case .clipboard: "Буфер обмена"
        }
    }

    /// Заголовок полного раздела, который открывается по стрелке ↗.
    public var sectionTitle: String {
        switch self {
        case .tasks: "Задачи"
        case .focus: "Фокус-таймер"
        default: title
        }
    }
}

/// Раскладка главной. Холст макета — 1440 × 900 pt; на другом экране
/// правила такие (они же в `docs/DESIGN.md`, «Сетка главной»):
/// - боковые колонки по 348, средняя забирает остаток ширины;
/// - по высоте растут задачи, работа и буфер обмена, остальные блоки
///   фиксированы; ассистент — полоса 572 × 60 по центру средней колонки;
/// - если экран меньше холста, раскладка строится на холсте минимального
///   размера и уменьшается целиком (`scale` < 1).
///
/// Координаты — от верхнего левого угла холста, в pt холста.
public struct DashboardLayout: Equatable, Sendable {
    public static let designSize = CGSize(width: 1440, height: 900)
    public static let margin: CGFloat = 24
    public static let gap: CGFloat = 16
    public static let sideColumnWidth: CGFloat = 348
    public static let minCenterColumnWidth: CGFloat = 664
    /// Верхняя строка в макете: вырез 190 × 32.
    public static let designTopInset: CGFloat = 32
    /// Приветствие, кнопки шапки и сетка — ниже верхней строки на столько.
    public static let heroOffset: CGFloat = 12
    public static let actionsOffset: CGFloat = 14
    public static let gridOffset: CGFloat = 80
    public static let minGridHeight: CGFloat = 764

    public static let musicHeight: CGFloat = 120
    public static let miniAppsHeight: CGFloat = 212
    public static let focusHeight: CGFloat = 290
    public static let notesHeight: CGFloat = 222
    public static let assistantSize = CGSize(width: 572, height: 60)
    /// Над полосой ассистента промежуток 16 + 4.
    public static let assistantGap: CGFloat = 20

    public struct Item: Equatable, Sendable, Identifiable {
        public var block: DashboardBlock
        public var frame: CGRect
        public var id: DashboardBlock { block }
    }

    /// Во сколько раз холст уменьшен, чтобы поместиться на экран. На экранах
    /// не меньше холста — 1.
    public var scale: CGFloat
    /// Холст в pt холста. На экране он занимает `canvasSize × scale`.
    public var canvasSize: CGSize
    /// Высота верхней строки с вырезом.
    public var topInset: CGFloat
    public var heroTop: CGFloat
    public var actionsTop: CGFloat
    public var gridFrame: CGRect
    public var items: [Item]

    /// - Parameters:
    ///   - screenSize: экран целиком, вместе со строкой меню.
    ///   - topInset: высота выреза на этом экране.
    public init(screenSize: CGSize, topInset: CGFloat) {
        let fixedHeight = Self.designSize.height - Self.designTopInset
        let scale = min(
            1,
            screenSize.width / Self.designSize.width,
            (screenSize.height - topInset) / fixedHeight
        )
        let canvas = CGSize(width: screenSize.width / scale, height: screenSize.height / scale)
        let top = topInset / scale

        self.scale = scale
        canvasSize = canvas
        self.topInset = top
        heroTop = top + Self.heroOffset
        actionsTop = top + Self.actionsOffset

        let grid = CGRect(
            x: Self.margin,
            y: top + Self.gridOffset,
            width: canvas.width - 2 * Self.margin,
            height: canvas.height - top - Self.gridOffset - Self.margin
        )
        gridFrame = grid
        items = Self.items(in: grid)
    }

    public func frame(of block: DashboardBlock) -> CGRect {
        items.first { $0.block == block }?.frame ?? .zero
    }

    private static func items(in grid: CGRect) -> [Item] {
        let side = sideColumnWidth
        let center = grid.width - 2 * side - 2 * gap
        let leftX = grid.minX
        let centerX = leftX + side + gap
        let rightX = centerX + center + gap
        let top = grid.minY
        let bottom = grid.maxY

        let appsTop = bottom - miniAppsHeight
        let assistantTop = bottom - assistantSize.height
        let workTop = top + musicHeight + gap
        let notesTop = top + focusHeight + gap
        let clipboardTop = notesTop + notesHeight + gap

        return [
            Item(block: .tasks, frame: CGRect(x: leftX, y: top, width: side, height: appsTop - gap - top)),
            Item(block: .miniApps, frame: CGRect(x: leftX, y: appsTop, width: side, height: miniAppsHeight)),
            Item(block: .music, frame: CGRect(x: centerX, y: top, width: center, height: musicHeight)),
            Item(block: .work, frame: CGRect(x: centerX, y: workTop, width: center, height: assistantTop - assistantGap - workTop)),
            Item(block: .assistant, frame: CGRect(
                x: centerX + (center - assistantSize.width) / 2,
                y: assistantTop,
                width: assistantSize.width,
                height: assistantSize.height
            )),
            Item(block: .focus, frame: CGRect(x: rightX, y: top, width: side, height: focusHeight)),
            Item(block: .notes, frame: CGRect(x: rightX, y: notesTop, width: side, height: notesHeight)),
            Item(block: .clipboard, frame: CGRect(x: rightX, y: clipboardTop, width: side, height: bottom - clipboardTop)),
        ]
    }
}
