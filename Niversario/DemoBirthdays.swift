import BirthdayKit
import Foundation

enum DemoBirthdays {
    static func make(today: Date, calendar: Calendar) -> [Birthday] {
        [
            birthday("Léa", inDays: 0, year: 1996, color: .rose, emoji: "🌸", today: today, calendar: calendar),
            birthday("Hugo", inDays: 4, year: nil, color: .sky, emoji: nil, today: today, calendar: calendar),
            birthday("Inès", inDays: 23, year: 2000, color: .lavender, emoji: "🦋", today: today, calendar: calendar),
            birthday("Noah", inDays: 61, year: 1988, color: .mint, emoji: "🎸", today: today, calendar: calendar),
        ]
        .compactMap { $0 }
    }

    private static func birthday(
        _ firstName: String,
        inDays days: Int,
        year: Int?,
        color: PastelColor,
        emoji: String?,
        today: Date,
        calendar: Calendar
    ) -> Birthday? {
        guard let date = calendar.date(byAdding: .day, value: days, to: today) else { return nil }
        let birthDate = BirthDate(
            day: calendar.component(.day, from: date),
            month: calendar.component(.month, from: date),
            year: year
        )
        return birthDate.map { Birthday(firstName: firstName, birthDate: $0, color: color, emoji: emoji) }
    }
}
