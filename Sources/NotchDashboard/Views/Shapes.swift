import NotchCore
import SwiftUI

/// Чёрная форма у выреза: висит от верхнего края по центру, скруглены
/// только нижние углы. Размер и скругление анимируются.
struct NotchShape: Shape {
    var size: CGSize
    var cornerRadius: CGFloat

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { AnimatablePair(AnimatablePair(size.width, size.height), cornerRadius) }
        set {
            size = CGSize(width: newValue.first.first, height: newValue.first.second)
            cornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let frame = CGRect(x: rect.midX - size.width / 2, y: rect.minY, width: size.width, height: size.height)
        return bottomRounded(frame, radius: cornerRadius)
    }
}

/// Форма дашборда: вырастает из формы у выреза (`origin`) на весь `rect`.
struct DashboardMorphShape: Shape {
    var progress: Double
    var origin: CGRect
    var originRadius: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let frame = DashboardMorph.frame(progress: progress, from: origin, to: rect)
        let radius = DashboardMorph.cornerRadius(progress: progress, originRadius: originRadius, size: frame.size)
        return bottomRounded(frame, radius: radius)
    }
}

private func bottomRounded(_ frame: CGRect, radius: CGFloat) -> Path {
    let radius = max(0, min(radius, frame.width / 2, frame.height / 2))
    return UnevenRoundedRectangle(
        bottomLeadingRadius: radius,
        bottomTrailingRadius: radius,
        style: .continuous
    )
    .path(in: frame)
}
