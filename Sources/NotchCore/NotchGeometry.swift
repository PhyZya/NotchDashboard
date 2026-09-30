import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Размеры состояний выреза в pt. Источник — таблица «Состояния выреза»
/// в `docs/SPEC.md` и CSS `design/v2/index.html`.
public enum NotchMetrics {
    /// Ширина одного «уха» по бокам от выреза.
    public static let earWidth: CGFloat = 44
    /// Отступ содержимого «уха» от внешнего края формы.
    public static let earPadding: CGFloat = 12
    public static let earsCornerRadius: CGFloat = 13

    /// Запас вокруг формы под тень раскрытой панели.
    public static let shadowMargin: CGFloat = 56

    /// Вырез на главной (`.notch` в макете): 190 × 32, нижние углы 14.
    public static let simulatedNotchSize = CGSize(width: 190, height: 32)
    public static let notchCornerRadius: CGFloat = 14

    public static func earsSize(notch: CGSize) -> CGSize {
        CGSize(width: notch.width + 2 * earWidth, height: notch.height)
    }

    /// Размер чёрной формы у выреза. При наведении — панель `HoverLayout`,
    /// высота по содержимому. Пока открыт дашборд, форма у выреза в покое:
    /// её закрывает форма дашборда, которая из неё выросла.
    public static func shapeSize(for phase: NotchPhase, notch: CGSize, hover: HoverContent = HoverContent()) -> CGSize {
        let ears = earsSize(notch: notch)
        switch phase {
        case .idle, .dashboard:
            return ears
        case .hover:
            return fitting(HoverLayout.size(for: hover, notchHeight: notch.height), ears: ears)
        }
    }

    public static func cornerRadius(for phase: NotchPhase) -> CGFloat {
        phase == .hover ? HoverLayout.cornerRadius : earsCornerRadius
    }

    /// Окно у выреза: самое большое состояние плюс место под тень.
    public static func panelSize(notch: CGSize) -> CGSize {
        let largest = fitting(HoverLayout.largestSize(notchHeight: notch.height), ears: earsSize(notch: notch))
        return CGSize(width: largest.width + 2 * shadowMargin, height: largest.height + shadowMargin)
    }

    /// Панель не уже «ушей»: на широком вырезе она растёт вместе с ним.
    private static func fitting(_ size: CGSize, ears: CGSize) -> CGSize {
        CGSize(width: max(size.width, ears.width), height: max(size.height, ears.height))
    }
}

/// Где на экране вырез. Координаты AppKit: начало внизу слева, y растёт вверх.
/// `Equatable`, а не `Hashable`: в CoreGraphics у `CGRect` нет `Hashable`.
public struct ScreenGeometry: Equatable, Sendable {
    /// Весь экран с вырезом.
    public var screenFrame: CGRect
    public var notchFrame: CGRect
    /// Выреза нет, вместо него нарисована заглушка — только для отладки.
    public var isSimulated: Bool

    public init(screenFrame: CGRect, notchFrame: CGRect, isSimulated: Bool = false) {
        self.screenFrame = screenFrame
        self.notchFrame = notchFrame
        self.isSimulated = isSimulated
    }

    /// Вырез по ширине свободных областей слева и справа от него
    /// (`NSScreen.auxiliaryTopLeftArea`, `auxiliaryTopRightArea`)
    /// и высоте безопасной зоны сверху (`NSScreen.safeAreaInsets.top`).
    public init?(screenFrame: CGRect, leftAreaWidth: CGFloat, rightAreaWidth: CGFloat, topInset: CGFloat) {
        let width = screenFrame.width - leftAreaWidth - rightAreaWidth
        guard topInset > 0, width > 0 else { return nil }
        self.init(
            screenFrame: screenFrame,
            notchFrame: CGRect(
                x: screenFrame.minX + leftAreaWidth,
                y: screenFrame.maxY - topInset,
                width: width,
                height: topInset
            )
        )
    }

    /// Заглушка выреза по центру верхнего края экрана без выреза.
    public static func simulated(on screenFrame: CGRect, notchSize: CGSize = NotchMetrics.simulatedNotchSize) -> ScreenGeometry {
        ScreenGeometry(
            screenFrame: screenFrame,
            notchFrame: CGRect(
                x: screenFrame.midX - notchSize.width / 2,
                y: screenFrame.maxY - notchSize.height,
                width: notchSize.width,
                height: notchSize.height
            ),
            isSimulated: true
        )
    }

    public var notchSize: CGSize { notchFrame.size }

    /// Прямоугольник размера `size`, который висит от верхнего края экрана
    /// по центру выреза. Координаты AppKit.
    public func hangingFrame(size: CGSize) -> CGRect {
        CGRect(
            x: notchFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    /// То же, но в координатах экрана с началом вверху слева — как в SwiftUI
    /// внутри окна на весь экран.
    public func localHangingRect(size: CGSize) -> CGRect {
        CGRect(
            x: notchFrame.midX - screenFrame.minX - size.width / 2,
            y: 0,
            width: size.width,
            height: size.height
        )
    }

    public var localNotchRect: CGRect { localHangingRect(size: notchSize) }

    /// Где курсор считается «на вырезе»: форма в текущем состоянии. Сверху
    /// запас в 2 pt: курсор упирается в край экрана и может оказаться ровно на нём.
    public func hotZone(for phase: NotchPhase, hover: HoverContent = HoverContent()) -> CGRect {
        let frame = hangingFrame(size: NotchMetrics.shapeSize(for: phase, notch: notchSize, hover: hover))
        return CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height + 2)
    }
}

/// Форма, которая вырастает из выреза в дашборд на весь экран и сжимается обратно.
public enum DashboardMorph {
    /// Самое большое скругление по пути: на раскадровке раскрытия
    /// (`design/v1/Состояния и движение.png`) нижние углы растущей формы
    /// заметно круглее, чем у выреза, а на весь экран углов нет.
    public static let peakCornerRadius: CGFloat = 56

    /// `progress` 0 — форма совпадает с `origin`, 1 — с `target`.
    /// Пружина может чуть перелететь за 1, это не страшно: форма выйдет за край экрана.
    public static func frame(progress: Double, from origin: CGRect, to target: CGRect) -> CGRect {
        let t = CGFloat(progress)
        return CGRect(
            x: lerp(origin.minX, target.minX, t),
            y: lerp(origin.minY, target.minY, t),
            width: lerp(origin.width, target.width, t),
            height: lerp(origin.height, target.height, t)
        )
    }

    /// Скругление нижних углов: от `originRadius` к нулю с «горбом» посередине,
    /// но не больше половины меньшей стороны формы.
    public static func cornerRadius(progress: Double, originRadius: CGFloat, size: CGSize) -> CGFloat {
        let p = min(max(progress, 0), 1)
        let radius = originRadius * CGFloat(1 - p) + peakCornerRadius * CGFloat(sin(Double.pi * p))
        return max(0, min(radius, size.width / 2, size.height / 2))
    }

    private static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}
