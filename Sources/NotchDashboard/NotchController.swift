import AppKit
import NotchCore
import SwiftUI

/// Связывает окна, курсор, клавиатуру и `NotchStateMachine`: события идут
/// в машину состояний, её эффекты превращаются в анимации и окна.
@MainActor
final class NotchController {
    let model = NotchModel()

    private let options: LaunchOptions
    private var machine = NotchStateMachine()
    private var notchPanel: OverlayPanel?
    private var dashboardPanel: OverlayPanel?
    private var backdrop: NSWindow?
    private let pointer = PointerMonitor()
    private let hotkeys = HotkeyCenter()
    private var observers: [NSObjectProtocol] = []
    private var hoverTimer: Task<Void, Never>?
    private var closing: Task<Void, Never>?
    private var scrollDistance: CGFloat = 0
    private var scrollFired = false

    init(options: LaunchOptions) {
        self.options = options
    }

    func start() {
        if options.showsSample {
            model.hover = .sample
        }
        updateScreen()
        observeSystem()

        hotkeys.onPress = { [weak self] hotkey in self?.handle(hotkey) }
        // Остальные глобальные сочетания займём вместе с их функциями:
        // пустое сочетание мешало бы набирать символы вроде ⌥K = «˚».
        hotkeys.register(.dashboard)

        if options.tracksPointer {
            pointer.onMove = { [weak self] in self?.refreshPointer() }
            pointer.start()
        }
        applyLaunchState()
        if options.runsDemo {
            runDemo()
        }
    }

    // MARK: - Действия из интерфейса

    /// Клик по «ушам» раскрывает панель наведения, клик по вырезу в дашборде сворачивает его.
    func notchClicked() {
        send(.notchClicked)
    }

    /// Кнопка ↗ в панели наведения.
    func dashboardButtonTapped() {
        send(.dashboardButtonTapped)
    }

    /// Пункт «Открыть дашборд» в меню по правому клику — как `⌥D`.
    func toggleDashboard() {
        send(.toggleDashboard)
    }

    /// Кружок в строке горящей задачи. Пока задачи есть только в образце
    /// `--sample`, отметка живёт до перезапуска; хранилище задач — шаг 2 плана.
    func toggleTask(_ id: HotTask.ID) {
        withAnimation(.easeOut(duration: 0.2)) {
            model.hover.toggleTask(id: id)
        }
    }

    /// Кнопки плеера. Spotify подключим на шаге 3 плана, пока пауза
    /// переключается только в образце `--sample`.
    func music(_ command: MusicCommand) {
        guard var track = model.hover.nowPlaying else { return }
        switch command {
        case .playPause:
            track.isPlaying.toggle()
        case .previous, .next:
            return
        }
        model.hover.nowPlaying = track
    }

    /// Клик по обложке открывает Spotify.
    func openSpotify() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") else { return }
        NSWorkspace.shared.open(url)
    }

    func closeButtonTapped() {
        send(.closeDashboard)
    }

    func openSection(_ block: DashboardBlock) {
        send(.openSection(block))
    }

    func backToHome() {
        guard case .section = machine.route else { return }
        send(.escape)
    }

    /// Форма дашборда появилась на экране в том же виде, что форма у выреза, — можно расти.
    func dashboardDidAppear() {
        guard machine.phase == .dashboard else { return }
        animateOpen()
    }

    func showSettingsMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Настройки появятся позже", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Выйти из NotchDashboard", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        if let build = BuildInfo.menuTitle {
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: build, action: nil, keyEquivalent: ""))
        }
        _ = menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    // MARK: - Машина состояний

    private func send(_ event: NotchStateMachine.Event) {
        // Без экрана с вырезом показывать нечего.
        guard model.geometry != nil else { return }
        for effect in machine.send(event) {
            perform(effect)
        }
        updateMouseTransparency()
    }

    private func perform(_ effect: NotchStateMachine.Effect) {
        switch effect {
        case .startHoverTimer:
            hoverTimer?.cancel()
            hoverTimer = Task { [weak self] in
                try? await Task.sleep(for: .seconds(Motion.hoverDelay))
                guard !Task.isCancelled else { return }
                self?.send(.hoverDelayElapsed)
            }
        case .cancelHoverTimer:
            hoverTimer?.cancel()
            hoverTimer = nil
        case .expandHover:
            withAnimation(.notchSpring) { model.phase = .hover }
        case .collapseHover:
            withAnimation(.notchSpring) { model.phase = .idle }
        case .openDashboard(let from):
            openDashboard(from: from)
        case .closeDashboard:
            closeDashboard()
        case .showRoute(let route):
            withAnimation(.easeOut(duration: Motion.blocksInDuration)) { model.route = route }
        }
    }

    private func handle(_ hotkey: GlobalHotkey) {
        switch hotkey {
        case .dashboard:
            send(.toggleDashboard)
        case .quickInput, .assistant, .clipboardHistory, .screenshot, .focusTimer:
            break
        }
    }

    private func applyLaunchState() {
        switch options.state {
        case .idle:
            break
        case .hover:
            send(.pointerEntered)
            send(.hoverDelayElapsed)
        case .dashboard:
            send(.toggleDashboard)
            if let section = options.section {
                send(.openSection(section))
            }
        }
    }

    private func runDemo() {
        Task { [weak self] in
            var elapsed = 0.0
            for step in DemoStep.script {
                try? await Task.sleep(for: .seconds(step.at - elapsed))
                elapsed = step.at
                self?.send(step.event)
            }
        }
    }

    // MARK: - Дашборд

    private func openDashboard(from phase: NotchPhase) {
        guard let geometry = model.geometry, let panel = dashboardPanel else { return }
        closing?.cancel()
        closing = nil
        model.route = .home

        panel.setFrame(geometry.screenFrame, display: false)
        panel.makeKeyAndOrderFront(nil)

        if model.isDashboardPresented {
            // Открыли снова, пока форма сжималась: растём из текущего положения.
            animateOpen()
        } else {
            let size = NotchMetrics.shapeSize(for: phase, notch: geometry.notchSize, hover: model.hover)
            model.morphOrigin = geometry.localHangingRect(size: size)
            model.morphOriginRadius = NotchMetrics.cornerRadius(for: phase)
            model.morphProgress = 0
            model.isDashboardLight = false
            model.showsDashboardContent = false
            // Дальше — `dashboardDidAppear()`: форма появится там же, где форма у выреза.
            model.isDashboardPresented = true
        }
    }

    private func animateOpen() {
        // Форма у выреза прячется под растущей формой дашборда.
        model.phase = .dashboard
        withAnimation(.notchSpring) {
            model.morphProgress = 1
        }
        withAnimation(.easeInOut(duration: Motion.colorInDuration).delay(Motion.colorInDelay)) {
            model.isDashboardLight = true
        }
        withAnimation(.easeOut(duration: Motion.blocksInDuration).delay(Motion.blocksInDelay)) {
            model.showsDashboardContent = true
        }
    }

    /// Блоки гаснут, затем форма сжимается в вырез и темнеет.
    private func closeDashboard() {
        closing?.cancel()
        if let geometry = model.geometry {
            // Сжимаемся в «уши», даже если открывали из наведения. На весь экран
            // форма от этого не меняется.
            model.morphOrigin = geometry.localHangingRect(size: NotchMetrics.shapeSize(for: .idle, notch: geometry.notchSize))
            model.morphOriginRadius = NotchMetrics.earsCornerRadius
        }
        closing = Task { [weak self] in
            guard let self else { return }
            withAnimation(.easeIn(duration: Motion.blocksOutDuration)) {
                self.model.showsDashboardContent = false
            }
            try? await Task.sleep(for: .seconds(Motion.blocksOutDuration))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: Motion.shrinkDuration)) {
                self.model.morphProgress = 0
            }
            withAnimation(.easeIn(duration: Motion.colorOutDuration)) {
                self.model.isDashboardLight = false
            }
            // Небольшой запас, чтобы анимация точно дошла до конца.
            try? await Task.sleep(for: .seconds(Motion.shrinkDuration + 0.04))
            guard !Task.isCancelled else { return }
            self.finishClosing()
        }
    }

    private func finishClosing() {
        closing = nil
        dashboardPanel?.orderOut(nil)
        model.isDashboardPresented = false
        model.route = .home
        model.phase = machine.phase
        updateMouseTransparency()
    }

    private func handleDashboardKey(_ keyCode: UInt16, _ flags: NSEvent.ModifierFlags) -> Bool {
        let modifiers = KeyModifiers(eventFlags: flags.rawValue)
        guard let shortcut = DashboardShortcut(key: KeyCode(rawValue: keyCode), modifiers: modifiers) else { return false }
        switch shortcut {
        case .back:
            send(.escape)
            return true
        case .record, .search, .assistant, .timer:
            // Запись, поиск, ассистент и таймер — следующие шаги плана.
            return false
        }
    }

    // MARK: - Курсор

    private func refreshPointer() {
        guard let geometry = model.geometry else { return }
        let inside = geometry.hotZone(for: machine.phase, hover: model.hover).contains(NSEvent.mouseLocation)
        send(inside ? .pointerEntered : .pointerExited)
    }

    /// Панель у выреза пропускает клики насквозь везде, кроме своей формы.
    private func updateMouseTransparency() {
        guard let geometry = model.geometry, let panel = notchPanel else { return }
        let inside = geometry.hotZone(for: machine.phase, hover: model.hover).contains(NSEvent.mouseLocation)
        let ignores = machine.phase == .dashboard || !inside
        if panel.ignoresMouseEvents != ignores {
            panel.ignoresMouseEvents = ignores
        }
    }

    /// Жест двумя пальцами вниз по вырезу открывает дашборд. Колесо мыши —
    /// нет: его легко задеть, пока курсор на панели наведения.
    private func handleNotchScroll(_ event: NSEvent) -> Bool {
        guard machine.phase != .dashboard, event.momentumPhase.isEmpty, !event.phase.isEmpty else { return true }
        // Вниз — в сторону пользователя, с учётом «естественной» прокрутки.
        let down = event.isDirectionInvertedFromDevice ? event.scrollingDeltaY : -event.scrollingDeltaY
        if event.phase.contains(.began) {
            scrollDistance = 0
            scrollFired = false
        }
        guard !scrollFired else { return true }
        scrollDistance += down
        if scrollDistance > 24 {
            scrollFired = true
            send(.toggleDashboard)
        }
        return true
    }

    // MARK: - Экран и окна

    private func updateScreen() {
        let geometry = ScreenLocator.notchGeometry(simulate: options.simulateNotch)
        guard geometry != model.geometry else { return }

        guard let geometry else {
            // Экран с вырезом пропал (например, закрыли крышку): закрываемся без анимации.
            if machine.phase == .dashboard {
                send(.lostFocus)
                closing?.cancel()
                finishClosing()
            }
            notchPanel?.orderOut(nil)
            model.geometry = nil
            return
        }
        model.geometry = geometry

        if options.showsBackdrop {
            showBackdrop(on: geometry)
        }
        let panel = notchPanel ?? makeNotchPanel()
        notchPanel = panel
        panel.setFrame(geometry.hangingFrame(size: NotchMetrics.panelSize(notch: geometry.notchSize)), display: true)
        panel.orderFrontRegardless()

        if dashboardPanel == nil {
            dashboardPanel = makeDashboardPanel()
        }
        if model.isDashboardPresented {
            dashboardPanel?.setFrame(geometry.screenFrame, display: true)
        }
        updateMouseTransparency()
    }

    /// Фон цвета «стола» под всеми окнами, как на листах дизайна (`--backdrop`).
    private func showBackdrop(on geometry: ScreenGeometry) {
        let window = backdrop ?? NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        backdrop = window
        let desk = DesignPalette.desk
        window.backgroundColor = NSColor(srgbRed: desk.red, green: desk.green, blue: desk.blue, alpha: desk.alpha)
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.setFrame(geometry.screenFrame, display: true)
        window.orderFrontRegardless()
    }

    private func makeNotchPanel() -> OverlayPanel {
        let panel = OverlayPanel.make()
        panel.acceptsMouseMovedEvents = true
        panel.ignoresMouseEvents = true
        panel.scrollHandler = { [weak self] event in
            self?.handleNotchScroll(event) ?? false
        }
        let host = FirstClickHostingView(rootView: NotchPanelView(model: model, controller: self))
        host.sizingOptions = []
        panel.contentView = host
        return panel
    }

    private func makeDashboardPanel() -> OverlayPanel {
        let panel = OverlayPanel.make()
        panel.acceptsKey = true
        panel.acceptsMouseMovedEvents = true
        panel.keyDownHandler = { [weak self] keyCode, flags in
            self?.handleDashboardKey(keyCode, flags) ?? false
        }
        // ⌘Tab, клик в другое приложение: панель теряет клавиатуру — сворачиваемся.
        panel.resignKeyHandler = { [weak self] in
            self?.send(.lostFocus)
        }
        let host = FirstClickHostingView(rootView: DashboardRootView(model: model, controller: self))
        host.sizingOptions = []
        panel.contentView = host
        return panel
    }

    private func observeSystem() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.updateScreen() }
        })

        // Другой рабочий стол или другое приложение (⌘Tab) — дашборд сворачивается.
        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.send(.lostFocus) }
        })
        observers.append(workspace.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                let frontmost = NSWorkspace.shared.frontmostApplication?.processIdentifier
                guard frontmost != NSRunningApplication.current.processIdentifier else { return }
                self.send(.lostFocus)
            }
        })
    }
}

enum MusicCommand {
    case previous
    case playPause
    case next
}

extension Animation {
    /// Раскрытие из выреза: пружина без отскока (`docs/DESIGN.md`, «Движение»).
    static var notchSpring: Animation {
        .spring(response: Motion.springResponse, dampingFraction: Motion.springDamping)
    }
}
