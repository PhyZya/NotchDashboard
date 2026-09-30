import Foundation

/// Тексты интерфейса, которые зависят от числа, времени и даты. Интерфейс только на русском.
public enum RussianText {
    /// Форма слова после числа: 1 задача, 2 задачи, 5 задач, 11 задач, 21 задача.
    public static func plural(_ count: Int, _ one: String, _ few: String, _ many: String) -> String {
        let n = abs(count) % 100
        if (11...14).contains(n) { return many }
        switch n % 10 {
        case 1: return one
        case 2...4: return few
        default: return many
        }
    }

    /// «Доброе утро» с 5 до 12, «Добрый день» до 17, «Добрый вечер» до 23, дальше «Доброй ночи».
    public static func greeting(hour: Int) -> String {
        switch hour {
        case 5..<12: "Доброе утро"
        case 12..<17: "Добрый день"
        case 17..<23: "Добрый вечер"
        default: "Доброй ночи"
        }
    }

    /// Подпись под приветствием: «Среда, 30 сентября».
    public static func longDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        capitalized(format(date, "EEEE, d MMMM", timeZone))
    }

    /// Дата в строке с часами: «Ср, 30 сентября».
    public static func shortDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        capitalized(format(date, "EEE, d MMMM", timeZone))
    }

    /// «14:32».
    public static func time(_ date: Date, timeZone: TimeZone = .current) -> String {
        format(date, "HH:mm", timeZone)
    }

    /// Шапка панели наведения: «3 из 8 сделано».
    public static func tasksDone(_ done: Int, of total: Int) -> String {
        "\(done) из \(total) сделано"
    }

    /// Подпись под «На сегодня всё горящее сделано» при наведении.
    public static func tasksLeft(_ count: Int) -> String {
        guard count > 0 else { return "Задач на сегодня больше нет" }
        return "Ещё \(count) \(plural(count, "задача", "задачи", "задач")) на сегодня"
    }

    private static func format(_ date: Date, _ pattern: String, _ timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    private static func capitalized(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }
}
