import Foundation

/// Параметры движения из `docs/DESIGN.md`, раздел «Движение». Время в секундах.
public enum Motion {
    /// Раскрытие: пружина без отскока. В CSS — 520 мс, cubic-bezier(0.32, 0.72, 0, 1).
    public static let springResponse = 0.45
    public static let springDamping = 0.86

    /// Цвет формы: чёрный → `bg` за 300 мс с задержкой 60 мс, при закрытии обратно за 200 мс.
    public static let colorInDuration = 0.30
    public static let colorInDelay = 0.06
    public static let colorOutDuration = 0.20

    /// Блоки проявляются за 280 мс с задержкой 160 мс:
    /// прозрачность 0 → 1, размытие 6 → 0, масштаб 0,985 → 1.
    public static let blocksInDuration = 0.28
    public static let blocksInDelay = 0.16
    public static let blocksBlur = 6.0
    public static let blocksScale = 0.985

    /// Закрытие: блоки гаснут за 100 мс, затем форма сжимается в вырез за 320 мс (ease-in-out).
    public static let blocksOutDuration = 0.10
    public static let shrinkDuration = 0.32

    /// Наведение: вырез раскрывается, если курсор задержался на нём 150 мс.
    public static let hoverDelay = 0.15
}
