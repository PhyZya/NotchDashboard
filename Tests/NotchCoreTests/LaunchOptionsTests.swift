import Testing
@testable import NotchCore

struct LaunchOptionsTests {
    @Test func defaults() {
        let options = LaunchOptions(arguments: ["NotchDashboard"])
        #expect(!options.simulateNotch)
        #expect(options.state == .idle)
        #expect(options.section == nil)
    }

    @Test func flagsAndEnvironment() {
        let options = LaunchOptions(arguments: ["NotchDashboard", "--simulate-notch", "--state", "hover"])
        #expect(options.simulateNotch)
        #expect(options.state == .hover)

        let fromEnvironment = LaunchOptions(arguments: [], environment: ["NOTCHDASHBOARD_SIMULATE_NOTCH": "1"])
        #expect(fromEnvironment.simulateNotch)
    }

    @Test func sectionOpensDashboard() {
        let options = LaunchOptions(arguments: ["NotchDashboard", "--section", "work"])
        #expect(options.state == .dashboard)
        #expect(options.section == .work)
    }

    @Test func debugFlagsAndPointerTracking() {
        let plain = LaunchOptions(arguments: [])
        #expect(!plain.showsBackdrop && !plain.runsDemo)
        #expect(plain.tracksPointer)

        let demo = LaunchOptions(arguments: ["--demo", "--backdrop", "--sample"])
        #expect(demo.runsDemo && demo.showsBackdrop && demo.showsSample)
        #expect(!demo.tracksPointer)
        #expect(!plain.showsSample)

        #expect(!LaunchOptions(arguments: ["--state", "hover"]).tracksPointer)
    }

    @Test func themeFlag() {
        #expect(LaunchOptions(arguments: []).theme == nil)
        #expect(LaunchOptions(arguments: ["--theme", "light"]).theme == .light)
        #expect(LaunchOptions(arguments: ["--theme", "dark"]).theme == .dark)
        #expect(LaunchOptions(arguments: ["--theme", "sepia"]).theme == nil)
    }

    /// Сценарий проходит все состояния каркаса и возвращается в покой.
    @Test func demoScriptVisitsEveryState() {
        let times = DemoStep.script.map(\.at)
        #expect(times == times.sorted())

        var machine = NotchStateMachine()
        var effects: [NotchStateMachine.Effect] = []
        for step in DemoStep.script {
            effects += machine.send(step.event)
            if step.event == .pointerEntered {
                // В приложении это делает таймер наведения.
                effects += machine.send(.hoverDelayElapsed)
            }
        }
        #expect(effects.contains(.expandHover))
        // Дашборд открывает кнопка ↗ в панели наведения, а не клик по вырезу.
        #expect(DemoStep.script.contains { $0.event == .dashboardButtonTapped })
        #expect(!DemoStep.script.contains { $0.event == .notchClicked })
        #expect(effects.contains(.openDashboard(from: .hover)))
        #expect(effects.contains(.showRoute(.section(.tasks))))
        #expect(effects.contains(.showRoute(.home)))
        #expect(effects.last == .cancelHoverTimer)
        #expect(effects.contains(.closeDashboard))
        #expect(machine.phase == .idle)
        #expect(machine.isHoverArmed)
    }

    /// Xcode добавляет свои аргументы, например `-NSDocumentRevisionsDebugMode YES`.
    @Test func unknownValuesAreIgnored() {
        let options = LaunchOptions(arguments: ["-NSDocumentRevisionsDebugMode", "YES", "--state", "fullscreen", "--section"])
        #expect(options.state == .idle)
        #expect(options.section == nil)
    }
}
