import Foundation

public struct UpcomingBirthday: Identifiable, Sendable, Hashable {
    public let birthday: Birthday
    public let daysRemaining: Int
    public let age: Int?

    public var id: UUID { birthday.id }

    public var label: String {
        Self.label(daysRemaining: daysRemaining, age: age)
    }

    init?(birthday: Birthday, today: Date, calendar: Calendar) {
        guard let daysRemaining = birthday.birthDate.daysUntilNextOccurrence(from: today, in: calendar) else {
            return nil
        }
        self.birthday = birthday
        self.daysRemaining = daysRemaining
        self.age = birthday.birthDate.ageAtNextOccurrence(from: today, in: calendar)
    }

    public static func label(daysRemaining: Int, age: Int?) -> String {
        let countdown = countdownLabel(daysRemaining: daysRemaining)
        guard let age else { return countdown }
        return "\(countdown) · \(age) \(age < 2 ? "an" : "ans")"
    }

    private static func countdownLabel(daysRemaining: Int) -> String {
        switch daysRemaining {
        case 0:
            "Aujourd'hui"
        case 1:
            "Demain"
        default:
            "Dans \(daysRemaining) jours"
        }
    }
}

extension Collection<Birthday> {
    public func upcoming(limit: Int, from today: Date, in calendar: Calendar) -> [UpcomingBirthday] {
        let sorted = compactMap { UpcomingBirthday(birthday: $0, today: today, calendar: calendar) }
            .sorted(by: isBefore)
        return Array(sorted.prefix(Swift.max(limit, 0)))
    }
}

private func isBefore(_ lhs: UpcomingBirthday, _ rhs: UpcomingBirthday) -> Bool {
    if lhs.daysRemaining != rhs.daysRemaining {
        return lhs.daysRemaining < rhs.daysRemaining
    }
    return Birthday.isOrderedByFirstName(lhs.birthday, rhs.birthday)
}
