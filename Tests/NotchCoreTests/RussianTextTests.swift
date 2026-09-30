import Foundation
import Testing
@testable import NotchCore

struct RussianTextTests {
    @Test(arguments: [
        (0, "задач"), (1, "задача"), (2, "задачи"), (4, "задачи"), (5, "задач"),
        (11, "задач"), (12, "задач"), (14, "задач"), (21, "задача"), (22, "задачи"),
        (25, "задач"), (101, "задача"), (111, "задач"), (1004, "задачи"),
    ])
    func pluralForms(count: Int, word: String) {
        #expect(RussianText.plural(count, "задача", "задачи", "задач") == word)
    }

    @Test func greetingByHour() {
        #expect(RussianText.greeting(hour: 4) == "Доброй ночи")
        #expect(RussianText.greeting(hour: 5) == "Доброе утро")
        #expect(RussianText.greeting(hour: 11) == "Доброе утро")
        #expect(RussianText.greeting(hour: 12) == "Добрый день")
        #expect(RussianText.greeting(hour: 14) == "Добрый день")
        #expect(RussianText.greeting(hour: 17) == "Добрый вечер")
        #expect(RussianText.greeting(hour: 23) == "Доброй ночи")
    }

    /// Как в шапке макета: среда, 30 сентября 2026, 14:32.
    @Test func datesLikeInDesign() throws {
        let moscow = try #require(TimeZone(identifier: "Europe/Moscow"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = moscow
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 14, minute: 32)))

        #expect(RussianText.longDate(date, timeZone: moscow) == "Среда, 30 сентября")
        #expect(RussianText.shortDate(date, timeZone: moscow) == "Ср, 30 сентября")
        #expect(RussianText.time(date, timeZone: moscow) == "14:32")
    }

    @Test func tasksLeft() {
        #expect(RussianText.tasksLeft(0) == "Задач на сегодня больше нет")
        #expect(RussianText.tasksLeft(1) == "Ещё 1 задача на сегодня")
        #expect(RussianText.tasksLeft(3) == "Ещё 3 задачи на сегодня")
        #expect(RussianText.tasksLeft(5) == "Ещё 5 задач на сегодня")
    }
}
