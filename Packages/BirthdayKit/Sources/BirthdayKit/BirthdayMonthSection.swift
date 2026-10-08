import Foundation

public struct BirthdayMonthSection: Identifiable, Sendable, Hashable {
    public let month: CalendarMonth
    public let entries: [UpcomingBirthday]

    public var id: CalendarMonth { month }
}

extension [Birthday] {
    public func matching(_ query: String) -> [Birthday] {
        guard let trimmedQuery = Birthday.normalizedText(query) else { return self }
        return filter { birthday in
            [birthday.firstName, birthday.nickname]
                .compactMap { $0 }
                .contains {
                    $0.range(
                        of: trimmedQuery,
                        options: [.caseInsensitive, .diacriticInsensitive],
                        locale: Locale(identifier: "fr_FR")
                    ) != nil
                }
        }
    }

    public func monthSections(from today: Date, in calendar: Calendar) -> [BirthdayMonthSection] {
        let upcomingByID = Dictionary(
            upcoming(limit: count, from: today, in: calendar).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let currentMonth = CalendarMonth.containing(today, in: calendar)
        return (0..<12).compactMap { offset in
            let month = currentMonth.adding(months: offset)
            let birthdaysByDay = month.birthdaysByDay(self)
            let entries = birthdaysByDay.keys.sorted()
                .flatMap { birthdaysByDay[$0] ?? [] }
                .compactMap { upcomingByID[$0.id] }
            return entries.isEmpty ? nil : BirthdayMonthSection(month: month, entries: entries)
        }
    }
}
