import Testing
@testable import NotchCore

struct HoverPanelTests {
    @Test func toggleTaskUpdatesRowAndCounter() {
        var content = HoverContent.sample
        #expect(content.tasksLeft == 5)

        content.toggleTask(id: "report")
        #expect(content.hotTasks[1].isDone)
        #expect(content.tasksDone == 4)
        #expect(content.tasksLeft == 4)
        // Строка остаётся на месте, пока панель открыта.
        #expect(content.visibleTasks.map(\.id) == ["internet", "report", "workout"])

        content.toggleTask(id: "report")
        #expect(!content.hotTasks[1].isDone)
        #expect(content.tasksDone == 3)

        content.toggleTask(id: "missing")
        #expect(content == .sample)
    }

    @Test func counterStaysWithinBounds() {
        var content = HoverContent(hotTasks: [HotTask(id: "a", title: "А", meta: "")], tasksDone: 0, tasksTotal: 0)
        content.toggleTask(id: "a")
        #expect(content.tasksDone == 0)
        #expect(content.tasksLeft == 0)
    }

    @Test func sampleFollowsHotTaskOrder() {
        let tasks = HoverContent.sample.hotTasks
        #expect(tasks.first?.isOverdue == true)
        #expect(tasks.first?.priority == .high)
        #expect(TaskPriority.high.mark == "!!")
        #expect(TaskPriority.normal.mark == "!")
    }
}
