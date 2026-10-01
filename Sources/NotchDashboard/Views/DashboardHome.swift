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
                    .fill(Theme.label)
                    .frame(width: 15, height: 10)
                    Text("NotchDashboard")
                        .font(.system(size: 15, weight: .bold))
                        .tracking(-0.15)
                }
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    Text(RussianText.shortDate(context.date))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.label2)
                    Text(RussianText.time(context.date))
                        .font(.system(size: 15, weight: .bold))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(Theme.label)
            .padding(.horizontal, DashboardLayout.margin)
            .frame(width: layout.canvasSize.width, height: layout.topInset)
        }
    }
}

/// Главная v3: приветствие, стеклянная шапка и блоки по сетке. Блоки пока
/// пустые — содержимое появляется по шагам плана в `docs/SPEC.md`.
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
        case .music:
            // Подсветка обложкой — пока трек есть только в образце `--sample`.
            BlockCard(block: block, cover: controller.model.hover.nowPlaying?.coverColor) {
                controller.openSection(block)
            }
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
                    .foregroundStyle(Theme.label)
                Text(RussianText.longDate(context.date))
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.label2)
            }
        }
    }
}

/// Поиск `⌘F`, «+ Запись `⌘K`», настройки и «закрыть» — слой управления
/// на стекле (`docs/DESIGN.md`, «Liquid Glass»). Поиск и запись заработают
/// вместе со своими шагами плана, пока это вид из макета.
struct HeaderActions: View {
    let controller: NotchController

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Искать по всему дашборду")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("⌘F")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.label3)
                }
                .font(.system(size: 14))
                .foregroundStyle(Theme.label2)
                .padding(.horizontal, 18)
                .frame(width: 338, height: 44)
                .glassEffect(.regular, in: .capsule)

                // Акцент — системный цвет из настроек macOS, при «Мультицвете» синий.
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                    Text("Запись")
                    Text("⌘K")
                        .fontWeight(.semibold)
                        .opacity(0.8)
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .glassEffect(.regular.tint(.accentColor).interactive(), in: .capsule)

                CircleButton(systemImage: "slider.horizontal.3", help: "Настройки и тема") {
                    controller.showSettingsMenu()
                }
                CircleButton(systemImage: "xmark", help: "Свернуть в вырез · Esc") {
                    controller.closeButtonTapped()
                }
            }
        }
    }
}

/// Стеклянный кружок 44 в шапке и в разделе.
struct CircleButton: View {
    let systemImage: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.label)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .help(help)
    }
}

/// Ассистент — плавающая стеклянная капсула внизу по центру: `⌘J`.
/// Сам чат — шаг 5 плана.
struct AssistantBar: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.label)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.overlay2))
            Text("Спросить ассистента — о чём угодно или о ваших записях")
                .font(.system(size: 14.5))
                .foregroundStyle(Theme.label3)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("⌘J")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.label2)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background(Capsule().fill(Theme.overlay2))
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.regular, in: .capsule)
    }
}
