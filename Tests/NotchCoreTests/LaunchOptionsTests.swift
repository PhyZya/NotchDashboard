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

    /// Xcode добавляет свои аргументы, например `-NSDocumentRevisionsDebugMode YES`.
    @Test func unknownValuesAreIgnored() {
        let options = LaunchOptions(arguments: ["-NSDocumentRevisionsDebugMode", "YES", "--state", "fullscreen", "--section"])
        #expect(options.state == .idle)
        #expect(options.section == nil)
    }
}
