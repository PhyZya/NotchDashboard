import AppKit
import NotchCore
import SwiftUI

/// Окно у выреза: чёрная форма, в покое — «уши», при наведении — панель
/// с музыкой и горящими задачами (`design/v2/Наведение.png`).
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
            size: NotchMetrics.shapeSize(for: phase, notch: notch, hover: model.hover),
            cornerRadius: NotchMetrics.cornerRadius(for: phase)
        )
        let panel = NotchMetrics.panelSize(notch: notch)

        return ZStack(alignment: .top) {
            shape
                .fill(Theme.notch)
                .shadow(color: .black.opacity(isHover ? 0.35 : 0), radius: 24, y: 10)

            ZStack(alignment: .top) {
                EarsView(tasksLeft: model.hover.tasksLeft)
                    .frame(width: NotchMetrics.earsSize(notch: notch).width, height: notch.height)
                    .opacity(isHover ? 0 : 1)
                    .animation(.easeOut(duration: 0.12), value: isHover)

                HoverView(content: model.hover, notchHeight: notch.height, isShown: isHover, controller: controller)
                    .allowsHitTesting(isHover)
            }
            .frame(width: panel.width, height: panel.height, alignment: .top)
            .clipShape(shape)
        }
        .frame(width: panel.width, height: panel.height, alignment: .top)
        .contentShape(shape)
        // Клик по «ушам» раскрывает панель сразу, по самой панели — ничего.
        // Дашборд на весь экран — только кнопкой ↗, `⌥D` или жестом вниз.
        .onTapGesture { controller.notchClicked() }
        .contextMenu {
            Button("Открыть дашборд  ⌥D") { controller.toggleDashboard() }
            Divider()
            Button("Выйти из NotchDashboard") { NSApplication.shared.terminate(nil) }
        }
        .ignoresSafeArea()
    }
}

/// «Уши» в покое, когда музыка не играет: слева счётчик задач на сегодня,
/// правое «ухо» ждёт отметки о сохранении записи.
struct EarsView: View {
    let tasksLeft: Int

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.square")
                    .font(.system(size: 12, weight: .semibold))
                Text("\(tasksLeft)")
                    .font(.system(size: 12, weight: .bold))
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, NotchMetrics.earPadding)
        .foregroundStyle(.white)
    }
}

/// Панель наведения: шапка с кнопкой ↗, плеер, пока играет музыка,
/// и до трёх горящих задач. Размеры — `HoverLayout`, движение — `Motion.hoverRows…`.
struct HoverView: View {
    let content: HoverContent
    let notchHeight: CGFloat
    /// Панель раскрыта: строки вытекают сверху вниз вслед за формой.
    let isShown: Bool
    let controller: NotchController

    var body: some View {
        let tasks = Array(content.visibleTasks)
        let firstTaskRow = content.nowPlaying == nil ? 1 : 2

        VStack(alignment: .leading, spacing: HoverLayout.sectionGap) {
            HoverHeader(content: content) { controller.dashboardButtonTapped() }
                .flowIn(isShown, row: 0)

            if let track = content.nowPlaying {
                PlayerCard(track: track, controller: controller)
                    .flowIn(isShown, row: 1)
            }

            if tasks.isEmpty {
                AllDoneCard(tasksLeft: content.tasksLeft)
                    .flowIn(isShown, row: firstTaskRow)
            } else {
                VStack(spacing: HoverLayout.taskGap) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                        HotTaskRow(task: task) { controller.toggleTask(task.id) }
                            .flowIn(isShown, row: firstTaskRow + index)
                    }
                }
            }
        }
        .padding(.top, notchHeight + HoverLayout.headerGap)
        .padding(.horizontal, HoverLayout.sidePadding)
        .frame(width: HoverLayout.width, alignment: .top)
    }
}

/// «Сегодня · 3 из 8 сделано» и кнопка ↗ — дашборд на весь экран. Кнопка
/// ниже строки меню: промах по пункту меню рядом с вырезом её не заденет.
private struct HoverHeader: View {
    let content: HoverContent
    let openDashboard: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Сегодня")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.15)
                    .foregroundStyle(.white)
                if content.tasksTotal > 0 {
                    Text(RussianText.tasksDone(content.tasksDone, of: content.tasksTotal))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.darkText2)
                        .contentTransition(.numericText())
                }
            }
            Spacer(minLength: 0)
            Button(action: openDashboard) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .buttonStyle(CircleButtonStyle(size: 32, fill: Theme.dark2, foreground: .white, hoverFill: .white, hoverForeground: Theme.ink))
            .help("Открыть дашборд  ⌥D")
            .accessibilityLabel("Открыть дашборд")
        }
        .frame(height: HoverLayout.headerHeight)
    }
}

/// Плеер Spotify: обложка открывает Spotify, кнопки управляют им,
/// полоска внизу — прогресс трека в цвет обложки.
private struct PlayerCard: View {
    let track: NowPlaying
    let controller: NotchController

    var body: some View {
        let accent = Color(track.coverColor)

        HStack(spacing: 12) {
            Button { controller.openSpotify() } label: {
                CoverArt(color: accent)
            }
            .buttonStyle(.plain)
            .help("Открыть Spotify")

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 7) {
                    Text(track.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(.white)
                    if track.isPlaying {
                        Image(systemName: "waveform")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(accent)
                            .symbolEffect(.variableColor.iterative, isActive: true)
                    }
                }
                .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.darkText2)
                    .lineLimit(1)
                ProgressLine(progress: track.progress, color: accent)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Button { controller.music(.previous) } label: {
                    Image(systemName: "backward.end.fill").font(.system(size: 12))
                }
                .buttonStyle(CircleButtonStyle(size: 30, fill: .clear, foreground: .white, hoverFill: Theme.dark3))
                .accessibilityLabel("Назад")

                Button { controller.music(.playPause) } label: {
                    Image(systemName: track.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 14))
                }
                .buttonStyle(CircleButtonStyle(size: 36, fill: .white, foreground: Theme.ink))
                .accessibilityLabel(track.isPlaying ? "Пауза" : "Играть")

                Button { controller.music(.next) } label: {
                    Image(systemName: "forward.end.fill").font(.system(size: 12))
                }
                .buttonStyle(CircleButtonStyle(size: 30, fill: .clear, foreground: .white, hoverFill: Theme.dark3))
                .accessibilityLabel("Вперёд")
            }
        }
        .padding(10)
        .frame(height: HoverLayout.playerHeight)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.dark2))
    }
}

/// Заглушка обложки как в макете, пока нет настоящей из Spotify.
private struct CoverArt: View {
    let color: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            Theme.dark
            Capsule()
                .fill(Theme.bg)
                .frame(width: 13, height: 3)
                .offset(x: 7, y: 8)
            Circle()
                .fill(color)
                .frame(width: 34, height: 34)
                .offset(x: 18, y: 18)
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ProgressLine: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.dark3)
                Capsule()
                    .fill(color)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 3)
    }
}

/// Горящая задача: кружок отмечает сделанной, строка остаётся зачёркнутой,
/// пока панель открыта. Клик по строке ничего не раскрывает.
private struct HotTaskRow: View {
    let task: HotTask
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                CheckCircle(isDone: task.isDone)
            }
            .buttonStyle(.plain)
            .help(task.isDone ? "Вернуть задачу" : "Отметить сделанной")

            VStack(alignment: .leading, spacing: 0) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .strikethrough(task.isDone)
                Text(task.meta)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(task.isOverdue ? Theme.redOnDark : Theme.darkText2)
            }
            .lineLimit(1)
            .opacity(task.isDone ? 0.6 : 1)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let priority = task.priority {
                PriorityBadge(priority: priority)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: HoverLayout.taskHeight)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.dark2))
    }
}

private struct CheckCircle: View {
    let isDone: Bool

    var body: some View {
        ZStack {
            if isDone {
                Circle().fill(.white)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Theme.ink)
            } else {
                Circle().strokeBorder(.white.opacity(0.85), lineWidth: 2)
            }
        }
        .frame(width: 20, height: 20)
        .contentShape(Circle())
    }
}

/// `!!` — жёлтый кружок, `!` — белый, как в блоке задач на главной.
private struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.mark)
            .font(.system(size: 11.5, weight: .heavy))
            .tracking(-0.5)
            .foregroundStyle(Theme.ink)
            .frame(width: 22, height: 22)
            .background(Circle().fill(priority == .high ? Theme.yellow : .white))
    }
}

/// Горящих задач нет (`docs/SPEC.md`, «Состояния выреза»).
private struct AllDoneCard: View {
    let tasksLeft: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white, Theme.ok)
            VStack(alignment: .leading, spacing: 0) {
                Text("На сегодня всё горящее сделано")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(RussianText.tasksLeft(tasksLeft))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.darkText2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: HoverLayout.allDoneHeight)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.dark2))
    }
}

/// Круглая кнопка панели: под курсором может светлеть, при нажатии чуть сжимается.
struct CircleButtonStyle: ButtonStyle {
    var size: CGFloat
    var fill: Color
    var foreground: Color
    var hoverFill: Color?
    var hoverForeground: Color?

    func makeBody(configuration: Configuration) -> some View {
        CircleButton(configuration: configuration, style: self)
    }
}

private struct CircleButton: View {
    let configuration: ButtonStyleConfiguration
    let style: CircleButtonStyle
    @State private var isHovered = false

    var body: some View {
        let lit = isHovered && style.hoverFill != nil
        configuration.label
            .foregroundStyle(lit ? style.hoverForeground ?? style.foreground : style.foreground)
            .frame(width: style.size, height: style.size)
            .background(Circle().fill(lit ? style.hoverFill ?? style.fill : style.fill))
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: lit)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

extension View {
    /// Строка панели наведения вытекает вслед за формой: сверху вниз
    /// с шагом `Motion.hoverRowsStagger`, а гаснет сразу и вся вместе.
    func flowIn(_ isShown: Bool, row: Int) -> some View {
        modifier(FlowIn(isShown: isShown, row: row))
    }
}

private struct FlowIn: ViewModifier {
    let isShown: Bool
    let row: Int

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .blur(radius: isShown ? 0 : CGFloat(Motion.blocksBlur))
            .offset(y: isShown ? 0 : -CGFloat(Motion.hoverRowsOffset))
            .animation(animation, value: isShown)
    }

    private var animation: Animation {
        guard isShown else { return .easeIn(duration: Motion.hoverRowsOutDuration) }
        return .easeOut(duration: Motion.hoverRowsDuration)
            .delay(Motion.hoverRowsDelay + Double(row) * Motion.hoverRowsStagger)
    }
}
