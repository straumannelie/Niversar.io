public struct BirthDate: Sendable, Hashable {
    public let day: Int
    public let month: Int
    public let year: Int?

    public init?(day: Int, month: Int, year: Int? = nil) {
        guard Self.isValid(day: day, month: month, year: year) else { return nil }
        self.day = day
        self.month = month
        self.year = year
    }

    func celebratedMonthAndDay(in year: Int) -> (month: Int, day: Int) {
        if month == 2 && day == 29 && !Self.isLeapYear(year) {
            return (month: 2, day: 28)
        }
        return (month: month, day: day)
    }

    public static func maximumDay(inMonth month: Int) -> Int {
        numberOfDays(inMonth: month, year: nil)
    }

    static func isLeapYear(_ year: Int) -> Bool {
        year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
    }

    private static func isValid(day: Int, month: Int, year: Int?) -> Bool {
        if let year, year < 1 {
            return false
        }
        guard (1...12).contains(month) else { return false }
        return (1...numberOfDays(inMonth: month, year: year)).contains(day)
    }

    private static func numberOfDays(inMonth month: Int, year: Int?) -> Int {
        switch month {
        case 2:
            guard let year else { return 29 }
            return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }
}

extension BirthDate: Codable {
    private enum CodingKeys: String, CodingKey {
        case day
        case month
        case year
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let day = try container.decode(Int.self, forKey: .day)
        let month = try container.decode(Int.self, forKey: .month)
        let year = try container.decodeIfPresent(Int.self, forKey: .year)
        guard let birthDate = BirthDate(day: day, month: month, year: year) else {
            throw DecodingError.dataCorruptedError(
                forKey: .day,
                in: container,
                debugDescription: "Date de naissance invalide : \(day)/\(month)/\(year.map(String.init) ?? "?")"
            )
        }
        self = birthDate
    }
}
