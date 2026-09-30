import NotchCore
import SwiftUI

/// Окно дашборда на весь экран. Пока дашборд закрыт, внутри пусто.
struct DashboardRootView: View {
    let model: NotchModel
    let controller: NotchController

    var body: some View {
        ZStack(alignment: .topLeading) {
            if model.isDashboardPresented, let geometry = model.geometry {
                DashboardStage(model: model, controller: controller, geometry: geometry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
    }
}

/// Одна форма растёт из выреза и по пути светлеет до фона дашборда,
/// а блоки проявляются, когда она почти раскрылась.
struct DashboardStage: View {
    let model: NotchModel
    let controller: NotchController
    let geometry: ScreenGeometry

    var body: some View {
        let screen = geometry.screenFrame.size
        let shape = DashboardMorphShape(
            progress: model.morphProgress,
            origin: model.morphOrigin,
            originRadius: model.morphOriginRadius
        )
        let visible = model.showsDashboardContent

        ZStack(alignment: .topLeading) {
            shape.fill(model.isDashboardLight ? Theme.bg : Theme.notch)

            DashboardContent(model: model, controller: controller, geometry: geometry)
                .frame(width: screen.width, height: screen.height, alignment: .topLeading)
                .scaleEffect(visible ? 1 : CGFloat(Motion.blocksScale))
                .blur(radius: visible ? 0 : CGFloat(Motion.blocksBlur))
                .opacity(visible ? 1 : 0)
                .clipShape(shape)
                .allowsHitTesting(visible)
        }
        .frame(width: screen.width, height: screen.height, alignment: .topLeading)
        .onAppear { controller.dashboardDidAppear() }
    }
}

/// Главная или раздел на холсте из `DashboardLayout` и вырез поверх.
struct DashboardContent: View {
    let model: NotchModel
    let controller: NotchController
    let geometry: ScreenGeometry

    var body: some View {
        let layout = DashboardLayout(screenSize: geometry.screenFrame.size, topInset: geometry.notchSize.height)

        ZStack(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                TopBar(layout: layout)

                switch model.route {
                case .home:
                    DashboardHome(layout: layout, controller: controller)
                        .transition(.opacity.combined(with: .scale(scale: CGFloat(Motion.blocksScale))))
                case .section(let block):
                    SectionPage(block: block, layout: layout, controller: controller)
                        .transition(.opacity.combined(with: .scale(scale: CGFloat(Motion.blocksScale))))
                }
            }
            .frame(width: layout.canvasSize.width, height: layout.canvasSize.height, alignment: .topLeading)
            .scaleEffect(layout.scale, anchor: .topLeading)

            // На MacBook здесь сам вырез, на заглушке — чёрная форма из макета.
            // Клик по вырезу сворачивает дашборд.
            NotchCutout(rect: geometry.localNotchRect)
                .onTapGesture { controller.notchClicked() }
        }
    }
}

struct NotchCutout: View {
    let rect: CGRect

    var body: some View {
        UnevenRoundedRectangle(
            bottomLeadingRadius: NotchMetrics.notchCornerRadius,
            bottomTrailingRadius: NotchMetrics.notchCornerRadius,
            style: .continuous
        )
        .fill(Theme.notch)
        .frame(width: rect.width, height: rect.height)
        .contentShape(Rectangle())
        .offset(x: rect.minX, y: rect.minY)
    }
}
