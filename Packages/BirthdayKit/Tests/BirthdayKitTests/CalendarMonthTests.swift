import BirthdayKit
import Foundation
import Testing

struct CalendarMonthTests {
    @Test("Mois commençant un lundi : aucune case vide au début")
    func monthStartingOnMonday() {
        let weeks = CalendarMonth(year: 2026, month: 6).weeks

        #expect(weeks.count == 5)
        #expect(weeks.first == [1, 2, 3, 4, 5, 6, 7])
        #expect(weeks.last == [29, 30, nil, nil, nil, nil, nil])
    }

    @Test("Mois commençant un dimanche, sur 6 semaines")
    func monthStartingOnSundayOverSixWeeks() {
        let weeks = CalendarMonth(year: 2026, month: 3).weeks

        #expect(weeks.count == 6)
        #expect(weeks.first == [nil, nil, nil, nil, nil, nil, 1])
        #expect(weeks.last == [30, 31, nil, nil, nil, nil, nil])
    }

    @Test("Mois commençant un samedi, sur 6 semaines")
    func monthStartingOnSaturdayOverSixWeeks() {
        let weeks = CalendarMonth(year: 2026, month: 8).weeks

        #expect(weeks.count == 6)
        #expect(weeks.first == [nil, nil, nil, nil, nil, 1, 2])
        #expect(weeks.last == [31, nil, nil, nil, nil, nil, nil])
    }

    @Test(
        "Février bissextile et non bissextile",
        arguments: [(2027, 28, 4), (2028, 29, 5), (2100, 28, 4), (2000, 29, 5)]
    )
    func february(year: Int, expectedDays: Int, expectedWeeks: Int) {
        let month = CalendarMonth(year: year, month: 2)

        #expect(month.numberOfDays == expectedDays)
        #expect(month.weeks.count == expectedWeeks)
        #expect(month.weeks.flatMap { $0 }.compactMap { $0 } == Array(1...expectedDays))
    }

    @Test("Chaque semaine a 7 cases et les jours sont dans l'ordre, sans trou")
    func gridShape() {
        for month in CalendarMonth(year: 2026, month: 6).surrounding() {
            let weeks = month.weeks
            #expect(weeks.allSatisfy { $0.count == 7 })
            #expect(weeks.flatMap { $0 }.compactMap { $0 } == Array(1...month.numberOfDays))
        }
    }

    @Test("Le premier jour tombe le même jour de la semaine qu'avec Calendar, de 1900 à 2100")
    func firstWeekdayMatchesFoundationCalendar() throws {
        let lisbon = try Lisbon()
        for year in 1900...2100 {
            for monthNumber in 1...12 {
                let month = CalendarMonth(year: year, month: monthNumber)
                let firstDay = try lisbon.date(Day(year, monthNumber, 1))
                let mondayBased = (lisbon.calendar.component(.weekday, from: firstDay) + 5) % 7
                #expect(month.weeks.first?.firstIndex(of: 1) == mondayBased, "\(month.title)")
            }
        }
    }

    @Test("Personne née un 29 février : le 28 en février 2027, le 29 en février 2028")
    func bornOnFebruary29() throws {
        let zoe = try birthday("Zoé", birthDate(29, 2, 1996))

        let in2027 = CalendarMonth(year: 2027, month: 2).birthdaysByDay([zoe])
        let in2028 = CalendarMonth(year: 2028, month: 2).birthdaysByDay([zoe])

        #expect(in2027 == [28: [zoe]])
        #expect(in2028 == [29: [zoe]])
    }

    @Test("Plusieurs personnes le même jour, triées par prénom ; les autres mois exclus")
    func severalPeopleOnTheSameDay() throws {
        let zoe = try birthday("Zoé", birthDate(12, 10))
        let emile = try birthday("émile", birthDate(12, 10))
        let adam = try birthday("Adam", birthDate(12, 10))
        let lina = try birthday("Lina", birthDate(3, 10, 1990))
        let noe = try birthday("Noé", birthDate(12, 11))

        let byDay = CalendarMonth(year: 2026, month: 10).birthdaysByDay([zoe, emile, adam, lina, noe])

        #expect(byDay == [12: [adam, emile, zoe], 3: [lina]])
    }

    @Test(
        "Plage de 25 mois de part et d'autre d'un changement d'année",
        arguments: [
            (
                CalendarMonth(year: 2027, month: 1), CalendarMonth(year: 2026, month: 1),
                CalendarMonth(year: 2028, month: 1)
            ),
            (
                CalendarMonth(year: 2026, month: 12), CalendarMonth(year: 2025, month: 12),
                CalendarMonth(year: 2027, month: 12)
            ),
            (
                CalendarMonth(year: 2026, month: 10), CalendarMonth(year: 2025, month: 10),
                CalendarMonth(year: 2027, month: 10)
            ),
        ]
    )
    func twentyFiveMonthRange(center: CalendarMonth, expectedFirst: CalendarMonth, expectedLast: CalendarMonth) {
        let months = center.surrounding()

        #expect(months.count == 25)
        #expect(months.first == expectedFirst)
        #expect(months.last == expectedLast)
        #expect(months[12] == center)
        #expect(zip(months, months.dropFirst()).allSatisfy { $0.adding(months: 1) == $1 && $0 < $1 })
    }

    @Test(
        "Mois hors limites normalisés",
        arguments: [
            (2026, 13, 2027, 1), (2026, 0, 2025, 12), (2026, -12, 2024, 12), (2026, 25, 2028, 1), (2026, 10, 2026, 10),
        ]
    )
    func monthNormalization(year: Int, month: Int, expectedYear: Int, expectedMonth: Int) {
        let calendarMonth = CalendarMonth(year: year, month: month)

        #expect(calendarMonth.year == expectedYear)
        #expect(calendarMonth.month == expectedMonth)
    }

    @Test("Mois contenant un instant, dans le fuseau du calendrier")
    func monthContainingDate() throws {
        let lisbon = try Lisbon()
        let lastEveningOfOctober = try lisbon.date(Day(2026, 10, 31), hour: 23, minute: 30)

        #expect(
            CalendarMonth.containing(lastEveningOfOctober, in: lisbon.calendar) == CalendarMonth(year: 2026, month: 10))
    }

    @Test(
        "Nom du mois en français et couleur pastel",
        arguments: zip(
            1...12,
            [
                "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
                "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
            ]
        )
    )
    func nameAndColor(month: Int, expectedName: String) {
        let calendarMonth = CalendarMonth(year: 2026, month: month)

        #expect(calendarMonth.name == expectedName)
        #expect(calendarMonth.title == "\(expectedName) 2026")
        #expect(calendarMonth.color == PastelColor(month: month))
    }

    @Test("Initiales des jours, du lundi au dimanche")
    func weekdayInitials() {
        #expect(CalendarMonth.weekdayInitials == ["L", "M", "M", "J", "V", "S", "D"])
    }

    @Test(
        "Libellé VoiceOver d'un jour d'anniversaire",
        arguments: [
            (12, ["Léa"], "12 octobre, anniversaire de Léa"),
            (1, ["Léa"], "1er octobre, anniversaire de Léa"),
            (12, ["Inès"], "12 octobre, anniversaire d'Inès"),
            (12, ["Émile", "Léa"], "12 octobre, anniversaire d'Émile et Léa"),
            (12, ["Adam", "Léa", "Zoé"], "12 octobre, anniversaire d'Adam, Léa et Zoé"),
            (12, ["Hugo"], "12 octobre, anniversaire de Hugo"),
        ]
    )
    func accessibilityLabel(day: Int, firstNames: [String], expected: String) {
        let october = CalendarMonth(year: 2026, month: 10)

        #expect(october.birthdayAccessibilityLabel(day: day, firstNames: firstNames) == expected)
    }

    @Test("Titre d'un jour", arguments: [(1, 1, "1er janvier"), (12, 10, "12 octobre"), (31, 8, "31 août")])
    func dayTitle(day: Int, month: Int, expected: String) {
        #expect(CalendarMonth(year: 2026, month: month).dayTitle(day) == expected)
    }
}
