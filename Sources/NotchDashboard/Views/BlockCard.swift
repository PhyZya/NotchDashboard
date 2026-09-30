import NotchCore
import SwiftUI

/// Блок главной: цветная карточка, заголовок и стрелка ↗ в полный раздел.
struct BlockCard: View {
    let block: DashboardBlock
    let open: () -> Void

    var body: some View {
        let style = block.style
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(block.title)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.15)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button(action: open) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(style.goBackground)))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Открыть раздел")
            }
            .frame(height: 32)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color(style.foreground))
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(style.background)))
    }
}
