import Foundation

extension BirthDate {
    public func nextOccurrence(from today: Date, in calendar: Calendar) -> Date? {
        let year = nextOccurrenceYear(from: today, in: calendar)
        let celebrated = celebratedMonthAndDay(in: year)
        return calendar.date(from: DateComponents(year: year, month: celebrated.month, day: celebrated.day))
    }

    public func daysUntilNextOccurrence(from today: Date, in calendar: Calendar) -> Int? {
        guard let occurrence = nextOccurrence(from: today, in: calendar) else { return nil }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: today), to: occurrence).day
    }

    public func ageAtNextOccurrence(from today: Date, in calendar: Calendar) -> Int? {
        guard let year else { return nil }
        let age = nextOccurrenceYear(from: today, in: calendar) - year
        return age >= 0 ? age : nil
    }

    public func age(on today: Date, in calendar: Calendar) -> Int? {
        guard let year else { return nil }
        let currentYear = calendar.component(.year, from: today)
        let todayMonthAndDay = (calendar.component(.month, from: today), calendar.component(.day, from: today))
        let celebrated = celebratedMonthAndDay(in: currentYear)
        let hasCelebratedThisYear = (celebrated.month, celebrated.day) <= todayMonthAndDay
        let age = currentYear - year - (hasCelebratedThisYear ? 0 : 1)
        return age >= 0 ? age : nil
    }

    public var dayTitle: String {
        CalendarMonth.dayTitle(day: day, month: month)
    }

    private func nextOccurrenceYear(from today: Date, in calendar: Calendar) -> Int {
        let currentYear = calendar.component(.year, from: today)
        let todayMonthAndDay = (calendar.component(.month, from: today), calendar.component(.day, from: today))
        let celebrated = celebratedMonthAndDay(in: currentYear)
        let isStillAhead = (celebrated.month, celebrated.day) >= todayMonthAndDay
        return isStillAhead ? currentYear : currentYear + 1
    }
}
