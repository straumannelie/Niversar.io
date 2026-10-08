import Foundation

public struct TimeOfDay: Sendable, Hashable {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    public init(minutesSinceMidnight: Int) {
        let minutesInDay = 24 * 60
        let normalized = (minutesSinceMidnight % minutesInDay + minutesInDay) % minutesInDay
        self.init(hour: normalized / 60, minute: normalized % 60)
    }

    public var minutesSinceMidnight: Int {
        hour * 60 + minute
    }
}

public struct Reminder: Identifiable, Sendable, Hashable {
    public let id: String
    public let birthday: Birthday
    public let date: Date
    public let dateComponents: DateComponents
    public let title: String
    public let body: String
}

public struct ReminderPlan: Sendable, Equatable {
    public let reminders: [Reminder]
    public let unschedulable: [Birthday]
}

public enum ReminderPlanner {
    public static let defaultTime = TimeOfDay(hour: 9, minute: 0)
    public static let defaultLimit = 64
    public static let title = "Anniversaire 🎂"

    public static func plan(
        for birthdays: [Birthday],
        now: Date,
        calendar: Calendar,
        time: TimeOfDay = defaultTime,
        limit: Int = defaultLimit
    ) -> ReminderPlan {
        var reminders: [Reminder] = []
        var unschedulable: [Birthday] = []
        for birthday in birthdays {
            if let reminder = nextReminder(for: birthday, now: now, calendar: calendar, time: time) {
                reminders.append(reminder)
            } else {
                unschedulable.append(birthday)
            }
        }
        let sorted = reminders.sorted { ($0.date, $0.id) < ($1.date, $1.id) }
        return ReminderPlan(reminders: Array(sorted.prefix(max(limit, 0))), unschedulable: unschedulable)
    }

    private static func nextReminder(
        for birthday: Birthday,
        now: Date,
        calendar: Calendar,
        time: TimeOfDay
    ) -> Reminder? {
        let currentYear = calendar.component(.year, from: now)
        for year in [currentYear, currentYear + 1] {
            let components = dateComponents(of: birthday.birthDate, in: year, at: time)
            guard let date = calendar.date(from: components) else { return nil }
            if date > now {
                return Reminder(
                    id: "birthday-\(birthday.id.uuidString)-\(year)",
                    birthday: birthday,
                    date: date,
                    dateComponents: components,
                    title: title,
                    body: ReminderMessage.body(for: birthday, year: year)
                )
            }
        }
        return nil
    }

    private static func dateComponents(of birthDate: BirthDate, in year: Int, at time: TimeOfDay) -> DateComponents {
        let celebrated = birthDate.celebratedMonthAndDay(in: year)
        return DateComponents(
            year: year,
            month: celebrated.month,
            day: celebrated.day,
            hour: time.hour,
            minute: time.minute
        )
    }
}
