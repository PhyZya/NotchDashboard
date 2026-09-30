import AppKit
import NotchCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: NotchController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let process = ProcessInfo.processInfo
        let options = LaunchOptions(arguments: process.arguments, environment: process.environment)
        let controller = NotchController(options: options)
        controller.start()
        self.controller = controller
    }
}
