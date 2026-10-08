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
            (0, 37, "Aujourd'hui · 37 ans"),
            (1, 1, "Demain · va avoir 1 an"),
            (1, 37, "Demain · va avoir 37 ans"),
            (3, 37, "Dans 3 jours · va avoir 37 ans"),
            (5, 2, "Dans 5 jours · va avoir 2 ans"),
        ] as [(Int, Int?, String)]
    )
    func label(daysRemaining: Int, age: Int?, expected: String) {
        #expect(UpcomingBirthday.label(daysRemaining: daysRemaining, age: age) == expected)
    }

    @Test(
        "Libellé VoiceOver de la carte",
        arguments: [
            (0, 37, "Léa, aujourd'hui, 37 ans"),
            (1, 1, "Léa, demain, va avoir 1 an"),
            (3, 37, "Léa, dans 3 jours, va avoir 37 ans"),
            (3, nil, "Léa, dans 3 jours"),
            (0, nil, "Léa, aujourd'hui"),
        ] as [(Int, Int?, String)]
    )
    func accessibilityLabel(daysRemaining: Int, age: Int?, expected: String) {
        #expect(
            UpcomingBirthday.accessibilityLabel(firstName: "Léa", daysRemaining: daysRemaining, age: age) == expected)
    }
}

struct CountdownTests {
    @Test(
        "Compte à rebours seul",
        arguments: [(0, "Aujourd'hui"), (1, "Demain"), (2, "Dans 2 jours"), (300, "Dans 300 jours")])
    func countdown(daysRemaining: Int, expected: String) throws {
        let lisbon = try Lisbon()
        let today = try lisbon.date(Day(2026, 1, 1))
        let date = try #require(lisbon.calendar.date(byAdding: .day, value: daysRemaining, to: today))
        let day = lisbon.day(of: date)
        let person = try birthday("Zoé", birthDate(day.day, day.month))

        let upcoming = try #require([person].upcoming(limit: 1, from: today, in: lisbon.calendar).first)

        #expect(upcoming.countdown == expected)
    }

    @Test("Âge seul", arguments: [(0, "0 an"), (1, "1 an"), (2, "2 ans"), (36, "36 ans")])
    func ageLabel(age: Int, expected: String) {
        #expect(UpcomingBirthday.ageLabel(age) == expected)
    }
}
