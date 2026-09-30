import NotchCore
import SwiftUI

/// Верхняя строка у выреза: логотип слева, дата и время справа.
struct TopBar: View {
    let layout: DashboardLayout

    var body: some View {
        TimelineView(.everyMinute) { context in
            HStack(spacing: 0) {
                HStack(spacing: 9) {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 2,
                        bottomLeadingRadius: 5,
                        bottomTrailingRadius: 5,
                        topTrailingRadius: 2,
                        style: .continuous
                    )
                    .fill(Theme.ink)
                    .frame(width: 15, height: 10)
                    Text("NotchDashboard")
                        .font(.system(size: 15, weight: .bold))
                        .tracking(-0.15)
                }
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    Text(RussianText.shortDate(context.date))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.clock)
                    Text(RussianText.time(context.date))
                        .font(.system(size: 15, weight: .bold))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, DashboardLayout.margin)
            .frame(width: layout.canvasSize.width, height: layout.topInset)
        }
    }
}

/// Главная v2: приветствие, кнопки шапки и блоки по сетке. Блоки пока пустые —
/// содержимое появляется по шагам плана в `docs/SPEC.md`.
struct DashboardHome: View {
    let layout: DashboardLayout
    let controller: NotchController

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(alignment: .top, spacing: 0) {
                Greeting()
                Spacer(minLength: 24)
                HeaderActions(controller: controller)
                    .padding(.top, layout.actionsTop - layout.heroTop)
            }
            .padding(.horizontal, DashboardLayout.margin)
            .frame(width: layout.canvasSize.width, alignment: .topLeading)
            .offset(y: layout.heroTop)

            ForEach(layout.items) { item in
                block(item.block)
                    .frame(width: item.frame.width, height: item.frame.height)
                    .offset(x: item.frame.minX, y: item.frame.minY)
            }
        }
        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height, alignment: .topLeading)
    }

    @ViewBuilder
    private func block(_ block: DashboardBlock) -> some View {
        switch block {
        case .assistant:
            AssistantBar()
        default:
            BlockCard(block: block) { controller.openSection(block) }
        }
    }
}

/// «Добрый день» и дата под ним.
struct Greeting: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(alignment: .leading, spacing: 4) {
                Text(RussianText.greeting(hour: Calendar.current.component(.hour, from: context.date)))
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.7)
                    .foregroundStyle(Theme.ink)
                Text(RussianText.longDate(context.date))
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink2)
            }
        }
    }
}

/// Поиск `⌘F`, «+ Запись `⌘K`», настройки и «закрыть».
/// Поиск и запись заработают вместе со своими шагами плана, пока это вид из макета.
struct HeaderActions: View {
    let controller: NotchController

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                Text("Искать по всему дашборду")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("⌘F")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink3)
            }
            .font(.system(size: 14))
            .foregroundStyle(Theme.ink2)
            .padding(.horizontal, 18)
            .frame(width: 338, height: 44)
            .background(Capsule().fill(Theme.surface))

            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                Text("Запись")
                Text("⌘K")
                    .fontWeight(.semibold)
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 20)
            .frame(height: 44)
            .background(Capsule().fill(Theme.yellow))

            CircleButton(systemImage: "slider.horizontal.3", help: "Настройки") {
                controller.showSettingsMenu()
            }
            CircleButton(systemImage: "xmark", help: "Свернуть в вырез · Esc") {
                controller.closeButtonTapped()
            }
        }
    }
}

struct CircleButton: View {
    let systemImage: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.surface))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

/// Полоса ассистента внизу по центру: `⌘J`. Сам чат — шаг 5 плана.
struct AssistantBar: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bubble.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.purple))
            HStack(spacing: 10) {
                Text("Спросить ассистента — о чём угодно или о ваших записях")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("⌘J")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.assistantShortcut)
            }
            .font(.system(size: 14.5))
            .foregroundStyle(Theme.assistantPlaceholder)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Capsule().fill(Theme.dark2))
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Capsule().fill(Theme.dark))
        .shadow(color: Theme.ink.opacity(0.18), radius: 15, y: 12)
    }
}
