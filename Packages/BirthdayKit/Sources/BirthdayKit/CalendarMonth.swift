import Foundation

public struct CalendarMonth: Sendable, Hashable, Comparable {
    public static let weekdayInitials = ["L", "M", "M", "J", "V", "S", "D"]

    static let names = [
        "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
        "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
    ]

    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        let (quotient, remainder) = (month - 1).quotientAndRemainder(dividingBy: 12)
        let borrow = remainder < 0 ? 1 : 0
        self.year = year + quotient - borrow
        self.month = remainder + 12 * borrow + 1
    }

    public static func containing(_ date: Date, in calendar: Calendar) -> CalendarMonth {
        CalendarMonth(year: calendar.component(.year, from: date), month: calendar.component(.month, from: date))
    }

    public static func < (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    public var name: String {
        Self.names[month - 1]
    }

    public var title: String {
        "\(name) \(year)"
    }

    public var color: PastelColor {
        PastelColor.allCases[month - 1]
    }

    public var numberOfDays: Int {
        BirthDate.numberOfDays(inMonth: month, year: year)
    }

    public var weeks: [[Int?]] {
        let leadingBlanks: [Int?] = Array(repeating: nil, count: mondayBasedWeekdayOfFirstDay)
        let days: [Int?] = (1...numberOfDays).map { $0 }
        let cells = leadingBlanks + days
        let trailingBlanks: [Int?] = Array(repeating: nil, count: (7 - cells.count % 7) % 7)
        let paddedCells = cells + trailingBlanks
        return stride(from: 0, to: paddedCells.count, by: 7).map { Array(paddedCells[$0..<$0 + 7]) }
    }

    public func adding(months: Int) -> CalendarMonth {
        CalendarMonth(year: year, month: month + months)
    }

    public func surrounding(monthsBefore: Int = 12, monthsAfter: Int = 12) -> [CalendarMonth] {
        (-max(monthsBefore, 0)...max(monthsAfter, 0)).map(adding(months:))
    }

    public func birthdaysByDay(_ birthdays: [Birthday]) -> [Int: [Birthday]] {
        let celebratedThisMonth = birthdays.filter { $0.birthDate.celebratedMonthAndDay(in: year).month == month }
        return Dictionary(grouping: celebratedThisMonth) { $0.birthDate.celebratedMonthAndDay(in: year).day }
            .mapValues { $0.sorted(by: Birthday.isOrderedByFirstName) }
    }

    public func dayTitle(_ day: Int) -> String {
        "\(day == 1 ? "1er" : String(day)) \(name.lowercased())"
    }

    public func birthdayAccessibilityLabel(day: Int, firstNames: [String]) -> String {
        let names = Self.frenchList(firstNames)
        let preposition = names.first.map(Self.startsWithVowel) == true ? "d'" : "de "
        return "\(dayTitle(day)), anniversaire \(preposition)\(names)"
    }

    private var mondayBasedWeekdayOfFirstDay: Int {
        let monthOffsets = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
        let adjustedYear = month < 3 ? year - 1 : year
        let leapDays = adjustedYear / 4 - adjustedYear / 100 + adjustedYear / 400
        let sundayBased = (adjustedYear + leapDays + monthOffsets[month - 1] + 1) % 7
        return (sundayBased + 13) % 7
    }

    private static func frenchList(_ items: [String]) -> String {
        guard let last = items.last else { return "" }
        let others = items.dropLast()
        return others.isEmpty ? last : "\(others.joined(separator: ", ")) et \(last)"
    }

    private static func startsWithVowel(_ character: Character) -> Bool {
        let base = String(character).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        return ["a", "e", "i", "o", "u", "y"].contains(base)
    }
}
