import Foundation
import Testing
@testable import NotchCore

struct NotchGeometryTests {
    /// Экран 1512 × 982 с вырезом 200 × 38 по центру.
    let geometry = ScreenGeometry(
        screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        leftAreaWidth: 656,
        rightAreaWidth: 656,
        topInset: 38
    )!

    @Test func notchIsBetweenAuxiliaryAreas() {
        #expect(geometry.notchFrame == CGRect(x: 656, y: 944, width: 200, height: 38))
        #expect(geometry.localNotchRect == CGRect(x: 656, y: 0, width: 200, height: 38))
        #expect(!geometry.isSimulated)
    }

    @Test func screenWithoutNotchHasNoGeometry() {
        let frame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        #expect(ScreenGeometry(screenFrame: frame, leftAreaWidth: 960, rightAreaWidth: 960, topInset: 0) == nil)
        #expect(ScreenGeometry(screenFrame: frame, leftAreaWidth: 960, rightAreaWidth: 960, topInset: 24) == nil)
    }

    @Test func secondaryScreenOffsetsAreRespected() {
        let frame = CGRect(x: -1512, y: 200, width: 1512, height: 982)
        let notched = ScreenGeometry(screenFrame: frame, leftAreaWidth: 656, rightAreaWidth: 656, topInset: 38)!
        #expect(notched.notchFrame == CGRect(x: -856, y: 1144, width: 200, height: 38))
        #expect(notched.localNotchRect.minX == 656)
        #expect(notched.hangingFrame(size: CGSize(width: 520, height: 168)).maxY == frame.maxY)
    }

    @Test func simulatedNotchUsesDesignSize() {
        let simulated = ScreenGeometry.simulated(on: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        #expect(simulated.isSimulated)
        #expect(simulated.notchFrame == CGRect(x: 865, y: 1048, width: 190, height: 32))
    }

    @Test func statesHangFromTopEdgeCenteredOnNotch() {
        let ears = NotchMetrics.shapeSize(for: .idle, notch: geometry.notchSize)
        #expect(ears == CGSize(width: 288, height: 38))
        #expect(geometry.hangingFrame(size: ears) == CGRect(x: 612, y: 944, width: 288, height: 38))

        let hover = NotchMetrics.shapeSize(for: .hover, notch: geometry.notchSize)
        #expect(hover == CGSize(width: 520, height: 168))
        #expect(geometry.hangingFrame(size: hover) == CGRect(x: 496, y: 814, width: 520, height: 168))
        #expect(geometry.localHangingRect(size: hover) == CGRect(x: 496, y: 0, width: 520, height: 168))

        #expect(NotchMetrics.shapeSize(for: .dashboard, notch: geometry.notchSize) == ears)
    }

    @Test func hotZoneCoversShapeAndTopEdge() {
        let zone = geometry.hotZone(for: .idle)
        #expect(zone.contains(CGPoint(x: 612, y: 944)))
        #expect(zone.contains(CGPoint(x: 899, y: 982)))
        #expect(!zone.contains(CGPoint(x: 611, y: 960)))
        #expect(!zone.contains(CGPoint(x: 700, y: 943)))
        #expect(geometry.hotZone(for: .hover).contains(CGPoint(x: 500, y: 820)))
    }

    @Test func panelFitsLargestStateWithShadow() {
        let panel = NotchMetrics.panelSize(notch: geometry.notchSize)
        #expect(panel.width >= 520 + 2 * NotchMetrics.shadowMargin)
        #expect(panel.height >= 168 + NotchMetrics.shadowMargin)
    }

    @Test func morphGoesFromOriginToTarget() {
        let origin = CGRect(x: 612, y: 0, width: 288, height: 38)
        let target = CGRect(x: 0, y: 0, width: 1512, height: 982)
        #expect(DashboardMorph.frame(progress: 0, from: origin, to: target) == origin)
        #expect(DashboardMorph.frame(progress: 1, from: origin, to: target) == target)
        let half = DashboardMorph.frame(progress: 0.5, from: origin, to: target)
        #expect(half == CGRect(x: 306, y: 0, width: 900, height: 510))
    }

    @Test func morphRadiusStartsAtOriginPeaksAndEndsSquare() {
        let big = CGSize(width: 1000, height: 1000)
        #expect(DashboardMorph.cornerRadius(progress: 0, originRadius: 13, size: big) == 13)
        #expect(abs(DashboardMorph.cornerRadius(progress: 0.5, originRadius: 13, size: big) - (6.5 + 56)) < 0.001)
        #expect(DashboardMorph.cornerRadius(progress: 1, originRadius: 13, size: big) < 0.001)
        #expect(DashboardMorph.cornerRadius(progress: 1.01, originRadius: 13, size: big) >= 0)
        #expect(DashboardMorph.cornerRadius(progress: 0.5, originRadius: 13, size: CGSize(width: 300, height: 40)) == 20)
    }
}
