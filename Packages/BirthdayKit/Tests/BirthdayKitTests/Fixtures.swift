import BirthdayKit
import Foundation
import Testing

struct Day: Sendable, Equatable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(_ year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    var description: String { "\(day)/\(month)/\(year)" }
}

struct Lisbon {
    let calendar: Calendar

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Lisbon"))
        self.calendar = calendar
    }

    func date(_ day: Day, hour: Int = 12, minute: Int = 0) throws -> Date {
        let components = DateComponents(year: day.year, month: day.month, day: day.day, hour: hour, minute: minute)
        return try #require(calendar.date(from: components))
    }

    func day(of date: Date) -> Day {
        Day(
            calendar.component(.year, from: date),
            calendar.component(.month, from: date),
            calendar.component(.day, from: date)
        )
    }
}

func birthDate(_ day: Int, _ month: Int, _ year: Int? = nil) throws -> BirthDate {
    try #require(BirthDate(day: day, month: month, year: year))
}

func birthday(_ firstName: String, _ birthDate: BirthDate, id: UUID = UUID()) throws -> Birthday {
    try #require(Birthday(id: id, firstName: firstName, birthDate: birthDate, color: .rose))
}
