import NotchCore
import SwiftUI

/// Полный раздел блока. Открывается стрелкой ↗, `Esc` возвращает на главную.
/// Содержимое разделов появится вместе с блоками.
struct SectionPage: View {
    let block: DashboardBlock
    let layout: DashboardLayout
    let controller: NotchController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                CircleButton(systemImage: "chevron.left", help: "На главную · Esc") {
                    controller.backToHome()
                }
                Text(block.sectionTitle)
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.7)
                    .foregroundStyle(Theme.label)
                Spacer(minLength: 0)
                Text("Esc — на главную")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.label3)
            }
            .frame(height: 44)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Theme.edge, lineWidth: 1)
                }
                .overlay {
                    Text("Раздел пока пустой")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.label3)
                }
                .padding(.top, layout.gridFrame.minY - layout.heroTop - 44)
        }
        .padding(.horizontal, DashboardLayout.margin)
        .padding(.top, layout.heroTop)
        .padding(.bottom, DashboardLayout.margin)
        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height, alignment: .topLeading)
    }
}
