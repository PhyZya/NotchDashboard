import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Что показывает панель наведения: плеер, пока играет музыка, и горящие задачи.
/// Лист: `design/v3/Наведение.png`. Музыку подключим на шаге 3 плана, задачи —
/// на шаге 2, до тех пор данные есть только в образце `--sample`.
public struct HoverContent: Equatable, Sendable {
    /// Трек Spotify. `nil` — музыка не играет и не стоит на паузе меньше 10 минут.
    public var nowPlaying: NowPlaying?
    /// Горящие задачи по порядку: просроченные, затем `!!`, затем с ближайшим
    /// сроком сегодня. Панель показывает первые `HoverLayout.maxTasks`.
    public var hotTasks: [HotTask]
    /// Сделано и всего задач на сегодня — «3 из 8 сделано» в шапке.
    public var tasksDone: Int
    public var tasksTotal: Int

    public init(nowPlaying: NowPlaying? = nil, hotTasks: [HotTask] = [], tasksDone: Int = 0, tasksTotal: Int = 0) {
        self.nowPlaying = nowPlaying
        self.hotTasks = hotTasks
        self.tasksDone = tasksDone
        self.tasksTotal = tasksTotal
    }

    public var visibleTasks: ArraySlice<HotTask> {
        hotTasks.prefix(HoverLayout.maxTasks)
    }

    /// Счётчик в «ухе»: сколько задач на сегодня ещё не сделано.
    public var tasksLeft: Int {
        max(0, tasksTotal - tasksDone)
    }

    /// Кружок в строке: задача сделана или снова нет. Строка остаётся
    /// зачёркнутой, пока панель открыта.
    public mutating func toggleTask(id: HotTask.ID) {
        guard let index = hotTasks.firstIndex(where: { $0.id == id }) else { return }
        hotTasks[index].isDone.toggle()
        tasksDone = min(max(0, tasksDone + (hotTasks[index].isDone ? 1 : -1)), tasksTotal)
    }
}

public struct NowPlaying: Equatable, Sendable {
    public var title: String
    public var artist: String
    public var isPlaying: Bool
    /// Прогресс трека 0…1.
    public var progress: Double
    /// Основной цвет обложки: эквалайзер и полоска прогресса.
    public var coverColor: DesignColor

    public init(title: String, artist: String, isPlaying: Bool, progress: Double, coverColor: DesignColor) {
        self.title = title
        self.artist = artist
        self.isPlaying = isPlaying
        self.progress = progress
        self.coverColor = coverColor
    }
}

public enum TaskPriority: Hashable, Sendable {
    /// `!` — белый кружок.
    case normal
    /// `!!` — жёлтый кружок.
    case high

    public var mark: String {
        switch self {
        case .normal: "!"
        case .high: "!!"
        }
    }
}

public struct HotTask: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    /// Строка под названием: «Просрочено · вчера, 18:00», «19:30 · ↻ пн, ср, пт».
    public var meta: String
    public var isOverdue: Bool
    public var priority: TaskPriority?
    public var isDone: Bool

    public init(id: String, title: String, meta: String, isOverdue: Bool = false, priority: TaskPriority? = nil, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.meta = meta
        self.isOverdue = isOverdue
        self.priority = priority
        self.isDone = isDone
    }
}

/// Размеры панели наведения в pt: ширина постоянная, высота — по содержимому.
/// Сверху полоса высотой с вырез, под ней шапка с кнопкой ↗, плеер и задачи.
public enum HoverLayout {
    public static let width: CGFloat = 520
    public static let cornerRadius: CGFloat = 26
    public static let sidePadding: CGFloat = 20
    public static let bottomPadding: CGFloat = 16
    /// От выреза до шапки.
    public static let headerGap: CGFloat = 8
    /// Шапка: «Сегодня», сколько сделано и кнопка ↗ (кружок 32).
    public static let headerHeight: CGFloat = 32
    public static let sectionGap: CGFloat = 10
    public static let playerHeight: CGFloat = 64
    public static let taskHeight: CGFloat = 44
    public static let taskGap: CGFloat = 6
    /// Строка «На сегодня всё горящее сделано».
    public static let allDoneHeight: CGFloat = 56
    public static let maxTasks = 3

    public static func height(for content: HoverContent, notchHeight: CGFloat) -> CGFloat {
        var height = notchHeight + headerGap + headerHeight
        if content.nowPlaying != nil {
            height += sectionGap + playerHeight
        }
        let rows = CGFloat(content.visibleTasks.count)
        height += sectionGap + (rows == 0 ? allDoneHeight : rows * taskHeight + (rows - 1) * taskGap)
        return height + bottomPadding
    }

    public static func size(for content: HoverContent, notchHeight: CGFloat) -> CGSize {
        CGSize(width: width, height: height(for: content, notchHeight: notchHeight))
    }

    /// Самая высокая панель — с плеером и тремя задачами. По ней считается окно у выреза.
    public static func largestSize(notchHeight: CGFloat) -> CGSize {
        let tasks = (0..<maxTasks).map { HotTask(id: "\($0)", title: "", meta: "") }
        let music = NowPlaying(title: "", artist: "", isPlaying: true, progress: 0, coverColor: DesignPalette.sampleCover)
        return size(for: HoverContent(nowPlaying: music, hotTasks: tasks), notchHeight: notchHeight)
    }
}

extension HoverContent {
    /// Образец с листов дизайна для `--sample`: снимки, видео и проверка вёрстки,
    /// пока нет настоящих задач и Spotify.
    public static let sample = HoverContent(
        nowPlaying: NowPlaying(title: "Тёплый шум", artist: "Кассета", isPlaying: true, progress: 0.36, coverColor: DesignPalette.sampleCover),
        hotTasks: [
            HotTask(id: "internet", title: "Оплатить интернет", meta: "Просрочено · вчера, 18:00", isOverdue: true, priority: .high),
            HotTask(id: "report", title: "Отправить отчёт за квартал", meta: "18:00 · #работа"),
            HotTask(id: "workout", title: "Тренировка", meta: "19:30 · ↻ пн, ср, пт"),
        ],
        tasksDone: 3,
        tasksTotal: 8
    )
}
