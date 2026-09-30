// swift-tools-version: 6.2
import PackageDescription

// NotchCore — логика без интерфейса: собирается и тестируется где угодно,
// в том числе в Linux (`swift test`). Приложение с AppKit и SwiftUI
// собирается только на macOS, поэтому добавляется ниже под условием.
let package = Package(
    name: "NotchDashboard",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "NotchCore", targets: ["NotchCore"]),
    ],
    targets: [
        .target(name: "NotchCore"),
        .testTarget(name: "NotchCoreTests", dependencies: ["NotchCore"]),
    ]
)

#if os(macOS)
package.products.append(.executable(name: "NotchDashboard", targets: ["NotchDashboard"]))
package.targets.append(
    .executableTarget(
        name: "NotchDashboard",
        dependencies: ["NotchCore"],
        linkerSettings: [.linkedFramework("Carbon")]
    )
)
#endif
