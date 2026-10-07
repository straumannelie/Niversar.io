import BirthdayKit
import Foundation
import Testing

struct UpcomingBirthdayTests {
    @Test("Les prochains anniversaires sont triés par jours restants et limités")
    func sortedByDaysRemainingAndLimited() throws {
        let lisbon = try Lisbon()
        let birthdays = [
            try birthday("Adam", birthDate(25, 6)),
            try birthday("Zoé", birthDate(15, 6, 1990)),
            try birthday("Noé", birthDate(18, 6)),
            try birthday("Lina", birthDate(1, 1)),
        ]

        let upcoming = birthdays.upcoming(limit: 2, from: try lisbon.date(Day(2026, 6, 15)), in: lisbon.calendar)

        #expect(upcoming.map(\.birthday.firstName) == ["Zoé", "Noé"])
        #expect(upcoming.map(\.daysRemaining) == [0, 3])
        #expect(upcoming.map(\.age) == [36, nil])
        #expect(upcoming.map(\.label) == ["Aujourd'hui · 36 ans", "Dans 3 jours"])
    }

    @Test("À égalité de jours, tri par prénom sans tenir compte de la casse ni des accents")
    func tiesAreSortedByFirstName() throws {
        let lisbon = try Lisbon()
        let sameDay = try birthDate(20, 6)
        let birthdays = try ["Zoé", "émile", "Adam", "Élodie"].map { try birthday($0, sameDay) }

        let upcoming = birthdays.upcoming(limit: 10, from: try lisbon.date(Day(2026, 6, 15)), in: lisbon.calendar)

        #expect(upcoming.map(\.birthday.firstName) == ["Adam", "Élodie", "émile", "Zoé"])
    }

    @Test("Limite supérieure au nombre de personnes, nulle ou négative", arguments: [(10, 2), (0, 0), (-1, 0)])
    func limitIsRespected(limit: Int, expectedCount: Int) throws {
        let lisbon = try Lisbon()
        let birthdays = [try birthday("Adam", birthDate(25, 6)), try birthday("Lina", birthDate(1, 1))]

        let upcoming = birthdays.upcoming(limit: limit, from: try lisbon.date(Day(2026, 6, 15)), in: lisbon.calendar)

        #expect(upcoming.count == expectedCount)
    }

    @Test(
        "Libellé de la carte",
        arguments: [
            (0, nil, "Aujourd'hui"),
            (1, nil, "Demain"),
            (2, nil, "Dans 2 jours"),
            (364, nil, "Dans 364 jours"),
            (0, 0, "Aujourd'hui · 0 an"),
            (1, 1, "Demain · 1 an"),
            (5, 2, "Dans 5 jours · 2 ans"),
            (0, 30, "Aujourd'hui · 30 ans"),
        ] as [(Int, Int?, String)]
    )
    func label(daysRemaining: Int, age: Int?, expected: String) {
        #expect(UpcomingBirthday.label(daysRemaining: daysRemaining, age: age) == expected)
    }
}
