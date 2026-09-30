import NotchCore
import SwiftUI

/// Окно у выреза: чёрная форма, в покое — «уши», при наведении — панель 520 × 168.
struct NotchPanelView: View {
    let model: NotchModel
    let controller: NotchController

    var body: some View {
        if let geometry = model.geometry {
            content(notch: geometry.notchSize)
        }
    }

    private func content(notch: CGSize) -> some View {
        let phase = model.phase
        let isHover = phase == .hover
        let shape = NotchShape(
            size: NotchMetrics.shapeSize(for: phase, notch: notch),
            cornerRadius: NotchMetrics.cornerRadius(for: phase)
        )
        let panel = NotchMetrics.panelSize(notch: notch)

        return ZStack(alignment: .top) {
            shape
                .fill(Theme.notch)
                .shadow(color: .black.opacity(isHover ? 0.35 : 0), radius: 24, y: 10)

            ZStack(alignment: .top) {
                EarsView(tasksToday: model.tasksToday)
                    .frame(width: NotchMetrics.earsSize(notch: notch).width, height: notch.height)
                    .opacity(isHover ? 0 : 1)
                    .animation(.easeOut(duration: 0.12), value: isHover)

                HoverView(notchHeight: notch.height, tasksToday: model.tasksToday)
                    .frame(width: NotchMetrics.hoverSize.width, height: NotchMetrics.hoverSize.height)
                    .opacity(isHover ? 1 : 0)
                    .animation(.easeOut(duration: 0.2).delay(isHover ? 0.12 : 0), value: isHover)
            }
            .frame(width: panel.width, height: panel.height, alignment: .top)
            .clipShape(shape)
        }
        .frame(width: panel.width, height: panel.height, alignment: .top)
        .contentShape(shape)
        .onTapGesture { controller.notchClicked() }
        .contextMenu {
            Button("Открыть дашборд  ⌥D") { controller.notchClicked() }
            Divider()
            Button("Выйти из NotchDashboard") { NSApplication.shared.terminate(nil) }
        }
        .ignoresSafeArea()
    }
}

/// «Уши» в покое, когда музыка не играет: слева счётчик задач на сегодня,
/// правое «ухо» ждёт отметки о сохранении записи.
struct EarsView: View {
    let tasksToday: Int

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.square")
                    .font(.system(size: 12, weight: .semibold))
                Text("\(tasksToday)")
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, NotchMetrics.earPadding)
        .foregroundStyle(.white)
    }
}

/// Наведение без музыки: горящие задачи. Пока задач нет, это состояние
/// «горящих нет» (`docs/SPEC.md`, «Состояния выреза»); макета для него пока нет.
struct HoverView: View {
    let notchHeight: CGFloat
    let tasksToday: Int

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Theme.ok)
            Text("На сегодня всё горящее сделано")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            Text(RussianText.tasksLeft(tasksToday))
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.darkText2)
        }
        .padding(.top, notchHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
