import NotchCore
import SwiftUI

/// Блок главной: плотная поверхность `surface` с обводкой по краю,
/// заголовок и тихая кнопка ↗ в полный раздел. Блоки цветом не заливаются,
/// кроме музыки: её подсвечивает обложка трека.
struct BlockCard: View {
    let block: DashboardBlock
    /// Цвет обложки текущего трека — только у блока музыки, пока что-то играет.
    var cover: DesignColor?
    let open: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(block.title)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.15)
                    .foregroundStyle(Theme.label)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button(action: open) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.label2)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.fill2))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Открыть раздел")
            }
            .frame(height: 32)
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            if let cover {
                CoverGlow(cover: Color(cover)).clipShape(shape)
            } else {
                shape.fill(Theme.surface)
            }
        }
        .overlay {
            if cover != nil {
                // Блик по краю, как у стекла.
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.34), location: 0),
                            .init(color: .white.opacity(0.06), location: 0.3),
                            .init(color: .white.opacity(0), location: 0.6),
                            .init(color: .white.opacity(0.14), location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            } else {
                shape.strokeBorder(Theme.edge, lineWidth: 1)
            }
        }
    }
}

/// Подсветка блока музыки размытой обложкой: цвет обложки слева,
/// отсвет снизу и блик справа сверху (`.music .amb` в `design/v3/index.html`).
private struct CoverGlow: View {
    let cover: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let mix = Theme.coverMix(dark: colorScheme == .dark)
        Theme.musicBackground
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    glow(cover.opacity(mix), fadeAt: 0.72, center: CGPoint(x: 70, y: 60), radii: CGSize(width: 240, height: 170))
                    glow(cover.opacity(0.2), fadeAt: 0.7, center: CGPoint(x: 300, y: 150), radii: CGSize(width: 420, height: 160))
                    glow(Theme.overlay2, fadeAt: 0.7, center: CGPoint(x: 640, y: -20), radii: CGSize(width: 260, height: 140))
                }
                .blur(radius: 10)
            }
    }

    /// Эллиптическое пятно как `radial-gradient(rx ry at x y, color, transparent fade)`.
    private func glow(_ color: Color, fadeAt fade: CGFloat, center: CGPoint, radii: CGSize) -> some View {
        Rectangle()
            .fill(EllipticalGradient(
                gradient: Gradient(stops: [.init(color: color, location: 0), .init(color: .clear, location: fade)]),
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            ))
            .frame(width: radii.width * 2, height: radii.height * 2)
            .offset(x: center.x - radii.width, y: center.y - radii.height)
    }
}
