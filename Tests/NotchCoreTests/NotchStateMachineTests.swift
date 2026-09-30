import Testing
@testable import NotchCore

struct NotchStateMachineTests {
    @Test func hoverOpensAfterDelayAndClosesWhenPointerLeaves() {
        var machine = NotchStateMachine()
        #expect(machine.send(.pointerEntered) == [.startHoverTimer])
        #expect(machine.phase == .idle)

        #expect(machine.send(.hoverDelayElapsed) == [.expandHover])
        #expect(machine.phase == .hover)

        #expect(machine.send(.pointerExited) == [.cancelHoverTimer, .collapseHover])
        #expect(machine.phase == .idle)
    }

    @Test func leavingBeforeDelayCancelsHover() {
        var machine = NotchStateMachine()
        machine.send(.pointerEntered)
        #expect(machine.send(.pointerExited) == [.cancelHoverTimer])
        #expect(machine.send(.hoverDelayElapsed).isEmpty)
        #expect(machine.phase == .idle)
    }

    @Test func repeatedPointerEventsAreIgnored() {
        var machine = NotchStateMachine()
        machine.send(.pointerEntered)
        #expect(machine.send(.pointerEntered).isEmpty)
        machine.send(.pointerExited)
        #expect(machine.send(.pointerExited).isEmpty)
    }

    @Test func clickOnEarsExpandsHoverWithoutDelay() {
        var machine = NotchStateMachine()
        machine.send(.pointerEntered)
        #expect(machine.send(.notchClicked) == [.cancelHoverTimer, .expandHover])
        #expect(machine.phase == .hover)
        // Таймер наведения, который успел сработать, ничего не меняет.
        #expect(machine.send(.hoverDelayElapsed).isEmpty)
    }

    @Test func clickOnHoverPanelDoesNotOpenDashboard() {
        var machine = NotchStateMachine()
        machine.send(.pointerEntered)
        machine.send(.hoverDelayElapsed)
        #expect(machine.send(.notchClicked).isEmpty)
        #expect(machine.phase == .hover)
    }

    @Test func dashboardButtonOpensDashboardFromHover() {
        var machine = NotchStateMachine()
        machine.send(.pointerEntered)
        machine.send(.hoverDelayElapsed)
        #expect(machine.send(.dashboardButtonTapped) == [.cancelHoverTimer, .openDashboard(from: .hover)])
        #expect(machine.phase == .dashboard)
        #expect(machine.send(.dashboardButtonTapped).isEmpty)
    }

    @Test func dashboardButtonDoesNothingOutsideHover() {
        var machine = NotchStateMachine()
        #expect(machine.send(.dashboardButtonTapped).isEmpty)
        #expect(machine.phase == .idle)
    }

    @Test func toggleOpensDashboardFromIdleAndHover() {
        var idle = NotchStateMachine()
        #expect(idle.send(.toggleDashboard) == [.cancelHoverTimer, .openDashboard(from: .idle)])
        #expect(idle.phase == .dashboard)

        var hover = NotchStateMachine()
        hover.send(.pointerEntered)
        hover.send(.hoverDelayElapsed)
        #expect(hover.send(.toggleDashboard) == [.cancelHoverTimer, .openDashboard(from: .hover)])
        #expect(hover.phase == .dashboard)
    }

    @Test func dashboardClosesByToggleClickEscapeButtonAndFocusLoss() {
        let closers: [NotchStateMachine.Event] = [.toggleDashboard, .notchClicked, .escape, .closeDashboard, .lostFocus]
        for event in closers {
            var machine = NotchStateMachine()
            machine.send(.toggleDashboard)
            #expect(machine.send(event) == [.closeDashboard], "\(event)")
            #expect(machine.phase == .idle)
        }
    }

    @Test func closingEventsDoNothingOutsideDashboard() {
        var machine = NotchStateMachine()
        #expect(machine.send(.escape).isEmpty)
        #expect(machine.send(.lostFocus).isEmpty)
        #expect(machine.send(.closeDashboard).isEmpty)
        #expect(machine.send(.openSection(.tasks)).isEmpty)
        #expect(machine.phase == .idle)
    }

    @Test func escapeReturnsFromSectionToHomeThenCloses() {
        var machine = NotchStateMachine()
        machine.send(.toggleDashboard)
        #expect(machine.send(.openSection(.work)) == [.showRoute(.section(.work))])
        #expect(machine.route == .section(.work))
        #expect(machine.send(.openSection(.work)).isEmpty)

        #expect(machine.send(.escape) == [.showRoute(.home)])
        #expect(machine.route == .home)
        #expect(machine.phase == .dashboard)

        #expect(machine.send(.escape) == [.closeDashboard])
        #expect(machine.phase == .idle)
    }

    @Test func reopeningStartsAtHome() {
        var machine = NotchStateMachine()
        machine.send(.toggleDashboard)
        machine.send(.openSection(.notes))
        machine.send(.lostFocus)
        machine.send(.toggleDashboard)
        #expect(machine.route == .home)
    }

    @Test func noHoverRightAfterClosingByClickUntilPointerLeaves() {
        var machine = NotchStateMachine()
        machine.send(.pointerEntered)
        machine.send(.hoverDelayElapsed)
        machine.send(.dashboardButtonTapped)
        machine.send(.notchClicked)
        #expect(machine.phase == .idle)
        #expect(!machine.isHoverArmed)
        #expect(machine.send(.hoverDelayElapsed).isEmpty)

        machine.send(.pointerExited)
        #expect(machine.isHoverArmed)
        #expect(machine.send(.pointerEntered) == [.startHoverTimer])
    }

    /// Сам по себе курсор после закрытия панель не раскроет, а клик — раскроет.
    @Test func clickExpandsHoverEvenRightAfterClosing() {
        var machine = NotchStateMachine()
        machine.send(.pointerEntered)
        machine.send(.toggleDashboard)
        machine.send(.notchClicked)
        #expect(!machine.isHoverArmed)
        #expect(machine.send(.notchClicked) == [.cancelHoverTimer, .expandHover])
        #expect(machine.send(.pointerExited) == [.cancelHoverTimer, .collapseHover])
        #expect(machine.phase == .idle)
    }

    @Test func hoverStaysArmedWhenClosedAwayFromNotch() {
        var machine = NotchStateMachine()
        machine.send(.toggleDashboard)
        machine.send(.escape)
        #expect(machine.isHoverArmed)
        #expect(machine.send(.pointerEntered) == [.startHoverTimer])
    }

    @Test func pointerInsideDashboardDoesNotStartHover() {
        var machine = NotchStateMachine()
        machine.send(.toggleDashboard)
        #expect(machine.send(.pointerEntered).isEmpty)
        #expect(machine.send(.hoverDelayElapsed).isEmpty)
        #expect(machine.phase == .dashboard)
    }
}
