import BirthdayKit
import Foundation
import Testing

struct BirthdayMonthSectionTests {
    @Test("Sections par mois à partir du mois en cours, mois vides omis, personnes triées par jour puis prénom")
    func sectionsStartAtCurrentMonth() throws {
        let lisbon = try Lisbon()
        let pastThisMonth = try birthday("Adam", birthDate(2, 10))
        let laterThisMonth = try birthday("Lina", birthDate(20, 10))
        let sameDayZoe = try birthday("Zoé", birthDate(20, 10))
        let december = try birthday("Noé", birthDate(5, 12))
        let september = try birthday("Inès", birthDate(30, 9))

        let sections = [december, sameDayZoe, september, laterThisMonth, pastThisMonth]
            .monthSections(from: try lisbon.date(Day(2026, 10, 15)), in: lisbon.calendar)

        #expect(
            sections.map(\.month) == [
                CalendarMonth(year: 2026, month: 10), CalendarMonth(year: 2026, month: 12),
                CalendarMonth(year: 2027, month: 9),
            ]
        )
        #expect(sections.map { $0.entries.map(\.birthday.firstName) } == [["Adam", "Lina", "Zoé"], ["Noé"], ["Inès"]])
        #expect(sections.first?.entries.map(\.daysRemaining) == [352, 5, 5])
    }

    @Test("Passage d'année : décembre puis janvier de l'année suivante")
    func yearTransition() throws {
        let lisbon = try Lisbon()
        let people = [try birthday("Adam", birthDate(3, 1)), try birthday("Lina", birthDate(28, 12))]

        let sections = people.monthSections(from: try lisbon.date(Day(2026, 12, 20)), in: lisbon.calendar)

        #expect(sections.map(\.month) == [CalendarMonth(year: 2026, month: 12), CalendarMonth(year: 2027, month: 1)])
        #expect(sections.map(\.month.title) == ["Décembre 2026", "Janvier 2027"])
    }

    @Test(
        "29 février : placé le 28 en année non bissextile, le 29 en année bissextile",
        arguments: [(Day(2026, 11, 15), ["Adam", "Lina", "Zoé"]), (Day(2027, 11, 15), ["Adam", "Lina", "Zoé"])]
    )
    func bornOnFebruary29(today: Day, expectedOrder: [String]) throws {
        let lisbon = try Lisbon()
        let zoe = try birthday("Zoé", birthDate(29, 2, 2000))
        let lina = try birthday("Lina", birthDate(28, 2))
        let adam = try birthday("Adam", birthDate(27, 2))

        let sections = [zoe, lina, adam].monthSections(from: try lisbon.date(today), in: lisbon.calendar)

        let february = try #require(sections.first)
        #expect(february.month == CalendarMonth(year: today.year + 1, month: 2))
        #expect(february.entries.map(\.birthday.firstName) == expectedOrder)
    }

    @Test("29 février en année non bissextile : à égalité avec le 28, départagé par le prénom")
    func februaryTwentyNinthTiesWithTwentyEighth() throws {
        let lisbon = try Lisbon()
        let anna = try birthday("Anna", birthDate(29, 2))
        let lina = try birthday("Lina", birthDate(28, 2))

        let sections = [lina, anna].monthSections(from: try lisbon.date(Day(2026, 11, 15)), in: lisbon.calendar)
        let leapSections = [lina, anna].monthSections(from: try lisbon.date(Day(2027, 11, 15)), in: lisbon.calendar)

        #expect(sections.first?.entries.map(\.birthday.firstName) == ["Anna", "Lina"])
        #expect(leapSections.first?.entries.map(\.birthday.firstName) == ["Lina", "Anna"])
    }

    @Test("Liste vide : aucune section")
    func emptyList() throws {
        let lisbon = try Lisbon()
        #expect([Birthday]().monthSections(from: try lisbon.date(Day(2026, 10, 15)), in: lisbon.calendar).isEmpty)
    }

    @Test(
        "Recherche par prénom et surnom, insensible à la casse et aux accents",
        arguments: [
            ("lea", ["Léa"]),
            ("LÉ", ["Léa"]),
            ("  léa ", ["Léa"]),
            ("zozo", ["Zoé"]),
            ("oa", ["Noah"]),
            ("o", ["Zoé", "Noah"]),
            ("", ["Léa", "Zoé", "Noah"]),
            ("   ", ["Léa", "Zoé", "Noah"]),
            ("xyz", []),
        ]
    )
    func search(query: String, expected: [String]) throws {
        let lea = try birthday("Léa", birthDate(1, 1))
        let zoe = try #require(
            Birthday(firstName: "Zoé", birthDate: try birthDate(2, 2), color: .sky, nickname: "Zozo"))
        let noah = try birthday("Noah", birthDate(3, 3))

        #expect([lea, zoe, noah].matching(query).map(\.firstName) == expected)
    }
}
