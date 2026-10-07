import BirthdayKit
import Foundation
import Testing

struct OccurrenceCase: Sendable, CustomTestStringConvertible {
    let testDescription: String
    let today: Day
    let birthDay: Int
    let birthMonth: Int
    let expectedOccurrence: Day
    let expectedDaysRemaining: Int
}

struct NextOccurrenceTests {
    static let cases: [OccurrenceCase] = [
        OccurrenceCase(
            testDescription: "Jour J",
            today: Day(2026, 6, 15), birthDay: 15, birthMonth: 6,
            expectedOccurrence: Day(2026, 6, 15), expectedDaysRemaining: 0
        ),
        OccurrenceCase(
            testDescription: "Lendemain",
            today: Day(2026, 6, 15), birthDay: 16, birthMonth: 6,
            expectedOccurrence: Day(2026, 6, 16), expectedDaysRemaining: 1
        ),
        OccurrenceCase(
            testDescription: "Veille, année suivante sans 29 février",
            today: Day(2026, 6, 15), birthDay: 14, birthMonth: 6,
            expectedOccurrence: Day(2027, 6, 14), expectedDaysRemaining: 364
        ),
        OccurrenceCase(
            testDescription: "Veille, année suivante avec 29 février",
            today: Day(2027, 6, 15), birthDay: 14, birthMonth: 6,
            expectedOccurrence: Day(2028, 6, 14), expectedDaysRemaining: 365
        ),
        OccurrenceCase(
            testDescription: "31 décembre, anniversaire le 1er janvier",
            today: Day(2026, 12, 31), birthDay: 1, birthMonth: 1,
            expectedOccurrence: Day(2027, 1, 1), expectedDaysRemaining: 1
        ),
        OccurrenceCase(
            testDescription: "1er janvier, anniversaire le 31 décembre",
            today: Day(2027, 1, 1), birthDay: 31, birthMonth: 12,
            expectedOccurrence: Day(2027, 12, 31), expectedDaysRemaining: 364
        ),
        OccurrenceCase(
            testDescription: "29 février en année bissextile",
            today: Day(2028, 2, 1), birthDay: 29, birthMonth: 2,
            expectedOccurrence: Day(2028, 2, 29), expectedDaysRemaining: 28
        ),
        OccurrenceCase(
            testDescription: "29 février en année non bissextile",
            today: Day(2027, 2, 1), birthDay: 29, birthMonth: 2,
            expectedOccurrence: Day(2027, 2, 28), expectedDaysRemaining: 27
        ),
        OccurrenceCase(
            testDescription: "Né un 29 février, vu le 28 février d'une année non bissextile",
            today: Day(2027, 2, 28), birthDay: 29, birthMonth: 2,
            expectedOccurrence: Day(2027, 2, 28), expectedDaysRemaining: 0
        ),
        OccurrenceCase(
            testDescription: "Né un 29 février, vu le 28 février d'une année bissextile",
            today: Day(2028, 2, 28), birthDay: 29, birthMonth: 2,
            expectedOccurrence: Day(2028, 2, 29), expectedDaysRemaining: 1
        ),
        OccurrenceCase(
            testDescription: "Né un 29 février, vu le 1er mars d'une année non bissextile",
            today: Day(2027, 3, 1), birthDay: 29, birthMonth: 2,
            expectedOccurrence: Day(2028, 2, 29), expectedDaysRemaining: 365
        ),
        OccurrenceCase(
            testDescription: "Passage à l'heure d'été",
            today: Day(2026, 3, 28), birthDay: 30, birthMonth: 3,
            expectedOccurrence: Day(2026, 3, 30), expectedDaysRemaining: 2
        ),
        OccurrenceCase(
            testDescription: "Passage à l'heure d'hiver",
            today: Day(2026, 10, 24), birthDay: 26, birthMonth: 10,
            expectedOccurrence: Day(2026, 10, 26), expectedDaysRemaining: 2
        ),
    ]

    @Test("Prochaine occurrence et jours restants", arguments: cases)
    func nextOccurrenceAndDaysRemaining(_ occurrenceCase: OccurrenceCase) throws {
        let lisbon = try Lisbon()
        let today = try lisbon.date(occurrenceCase.today)
        let birthDate = try birthDate(occurrenceCase.birthDay, occurrenceCase.birthMonth)

        let occurrence = try #require(birthDate.nextOccurrence(from: today, in: lisbon.calendar))

        #expect(lisbon.day(of: occurrence) == occurrenceCase.expectedOccurrence)
        #expect(occurrence == lisbon.calendar.startOfDay(for: occurrence))
        #expect(
            birthDate.daysUntilNextOccurrence(from: today, in: lisbon.calendar) == occurrenceCase.expectedDaysRemaining)
    }

    @Test(
        "Jours restants indépendants de l'heure, les jours de changement d'heure",
        arguments: [Day(2026, 3, 29), Day(2026, 10, 25)],
        [(0, 0), (23, 59)]
    )
    func daysRemainingIgnoreTimeOfDay(on day: Day, at time: (hour: Int, minute: Int)) throws {
        let lisbon = try Lisbon()
        let today = try lisbon.date(day, hour: time.hour, minute: time.minute)
        let sameDay = try birthDate(day.day, day.month)
        let nextDay = try birthDate(day.day + 1, day.month)

        #expect(sameDay.daysUntilNextOccurrence(from: today, in: lisbon.calendar) == 0)
        #expect(nextDay.daysUntilNextOccurrence(from: today, in: lisbon.calendar) == 1)
    }

    @Test(
        "Âge atteint à la prochaine occurrence",
        arguments: [
            (Day(2026, 6, 10), 15, 6, 1990, 36),
            (Day(2026, 6, 15), 15, 6, 1990, 36),
            (Day(2026, 6, 20), 15, 6, 1990, 37),
            (Day(2026, 12, 31), 1, 1, 2000, 27),
            (Day(2027, 2, 28), 29, 2, 2000, 27),
            (Day(2026, 6, 15), 15, 6, 2026, 0),
        ]
    )
    func ageAtNextOccurrence(today: Day, birthDay: Int, birthMonth: Int, birthYear: Int, expectedAge: Int) throws {
        let lisbon = try Lisbon()
        let birthDate = try birthDate(birthDay, birthMonth, birthYear)

        let age = birthDate.ageAtNextOccurrence(from: try lisbon.date(today), in: lisbon.calendar)

        #expect(age == expectedAge)
    }

    @Test("Pas d'âge si l'année est inconnue")
    func noAgeWithoutYear() throws {
        let lisbon = try Lisbon()
        let birthDate = try birthDate(15, 6)

        #expect(birthDate.ageAtNextOccurrence(from: try lisbon.date(Day(2026, 6, 15)), in: lisbon.calendar) == nil)
    }

    @Test("Pas d'âge si l'année de naissance est dans le futur")
    func noAgeForFutureYear() throws {
        let lisbon = try Lisbon()
        let birthDate = try birthDate(15, 6, 2030)

        #expect(birthDate.ageAtNextOccurrence(from: try lisbon.date(Day(2026, 6, 15)), in: lisbon.calendar) == nil)
    }
}
