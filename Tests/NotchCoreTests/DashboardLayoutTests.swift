import Foundation
import Testing
@testable import NotchCore

struct DashboardLayoutTests {
    /// Таблица «Сетка главной v2» из `docs/DESIGN.md`.
    @Test func matchesDesignOnDesignCanvas() {
        let layout = DashboardLayout(screenSize: CGSize(width: 1440, height: 900), topInset: 32)
        #expect(layout.scale == 1)
        #expect(layout.canvasSize == CGSize(width: 1440, height: 900))
        #expect(layout.heroTop == 44)
        #expect(layout.actionsTop == 46)
        #expect(layout.gridFrame == CGRect(x: 24, y: 112, width: 1392, height: 764))

        #expect(layout.frame(of: .tasks) == CGRect(x: 24, y: 112, width: 348, height: 536))
        #expect(layout.frame(of: .miniApps) == CGRect(x: 24, y: 664, width: 348, height: 212))
        #expect(layout.frame(of: .music) == CGRect(x: 388, y: 112, width: 664, height: 120))
        #expect(layout.frame(of: .work) == CGRect(x: 388, y: 248, width: 664, height: 548))
        #expect(layout.frame(of: .assistant) == CGRect(x: 434, y: 816, width: 572, height: 60))
        #expect(layout.frame(of: .focus) == CGRect(x: 1068, y: 112, width: 348, height: 290))
        #expect(layout.frame(of: .notes) == CGRect(x: 1068, y: 418, width: 348, height: 222))
        #expect(layout.frame(of: .clipboard) == CGRect(x: 1068, y: 656, width: 348, height: 220))
    }

    @Test func everyBlockIsPlacedOnce() {
        let layout = DashboardLayout(screenSize: CGSize(width: 1512, height: 982), topInset: 38)
        #expect(layout.items.map(\.block) == DashboardBlock.allCases)
    }

    /// 14" MacBook Pro: экран шире и выше холста — растут средняя колонка
    /// и блоки задач, работы и буфера обмена.
    @Test func largerScreenStretchesFlexibleBlocks() {
        let layout = DashboardLayout(screenSize: CGSize(width: 1512, height: 982), topInset: 38)
        #expect(layout.scale == 1)
        #expect(layout.gridFrame == CGRect(x: 24, y: 118, width: 1464, height: 840))

        #expect(layout.frame(of: .music).width == 736)
        #expect(layout.frame(of: .work).width == 736)
        #expect(layout.frame(of: .tasks).width == 348)
        #expect(layout.frame(of: .focus).minX == 1140)

        #expect(layout.frame(of: .music).height == 120)
        #expect(layout.frame(of: .miniApps).height == 212)
        #expect(layout.frame(of: .focus).height == 290)
        #expect(layout.frame(of: .notes).height == 222)
        #expect(layout.frame(of: .assistant).size == CGSize(width: 572, height: 60))

        // Сетка выше макетной на 76: 840 против 764.
        #expect(layout.frame(of: .tasks).height == 612)
        #expect(layout.frame(of: .work).height == 624)
        #expect(layout.frame(of: .clipboard).height == 296)
    }

    @Test(arguments: [
        CGSize(width: 1440, height: 900),
        CGSize(width: 1470, height: 956),
        CGSize(width: 1512, height: 982),
        CGSize(width: 1728, height: 1117),
        CGSize(width: 1024, height: 665),
        CGSize(width: 1920, height: 1080),
    ])
    func blocksFitTheGridWithoutOverlaps(screen: CGSize) {
        let layout = DashboardLayout(screenSize: screen, topInset: 32)
        let grid = layout.gridFrame
        for item in layout.items {
            #expect(grid.contains(item.frame), "\(item.block) выходит за сетку")
        }
        for (index, item) in layout.items.enumerated() {
            for other in layout.items[(index + 1)...] {
                #expect(!item.frame.intersects(other.frame), "\(item.block) и \(other.block) пересекаются")
            }
        }
        #expect(abs(layout.frame(of: .tasks).maxY + 16 - layout.frame(of: .miniApps).minY) < 0.001)
        #expect(abs(layout.frame(of: .miniApps).maxY - grid.maxY) < 0.001)
        #expect(abs(layout.frame(of: .clipboard).maxY - grid.maxY) < 0.001)
        #expect(abs(layout.frame(of: .assistant).maxY - grid.maxY) < 0.001)
        #expect(abs(layout.canvasSize.width * layout.scale - screen.width) < 0.001)
        #expect(abs(layout.canvasSize.height * layout.scale - screen.height) < 0.001)
    }

    /// «Крупный текст» на 13" MacBook Air: холст уменьшается целиком,
    /// а верхняя строка на экране остаётся высотой с вырез.
    @Test func smallerScreenScalesCanvasDown() {
        let layout = DashboardLayout(screenSize: CGSize(width: 1024, height: 665), topInset: 32)
        #expect(layout.scale < 1)
        #expect(layout.canvasSize.width >= 1440 - 0.001)
        #expect(layout.gridFrame.height >= DashboardLayout.minGridHeight - 0.001)
        #expect(layout.frame(of: .music).width >= DashboardLayout.minCenterColumnWidth - 0.001)
        #expect(abs(layout.topInset * layout.scale - 32) < 0.001)
    }
}
