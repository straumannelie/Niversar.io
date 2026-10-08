import BirthdayKit
import Foundation
import Testing

struct HomeTaglineTests {
    @Test("Liste vide : invitation à ajouter")
    func emptyList() throws {
        let lisbon = try Lisbon()

        let text = HomeTagline.text(for: [], today: try lisbon.date(Day(2026, 6, 15)), calendar: lisbon.calendar)

        #expect(text == "C'est qui la prochaine star du gâteau ? 🎂")
    }

    @Test(
        "Prochain anniversaire",
        arguments: [
            ([15], "🎉 C'est le jour J 🎉"),
            ([16], "🎂 demain"),
            ([18], "🎂 dans 3 jours"),
            ([25, 18, 30], "🎂 dans 3 jours"),
            ([25, 15, 16], "🎉 C'est le jour J 🎉"),
        ]
    )
    func nextBirthday(junesDays: [Int], expected: String) throws {
        let lisbon = try Lisbon()
        let birthdays = try junesDays.map { try birthday("Zoé", birthDate($0, 6)) }

        let text = HomeTagline.text(for: birthdays, today: try lisbon.date(Day(2026, 6, 15)), calendar: lisbon.calendar)

        #expect(text == expected)
    }

    @Test("Anniversaire passé cette année : compté jusqu'à l'année suivante")
    func birthdayAlreadyPassed() throws {
        let lisbon = try Lisbon()
        let zoe = try birthday("Zoé", birthDate(14, 6))

        let text = HomeTagline.text(for: [zoe], today: try lisbon.date(Day(2026, 6, 15)), calendar: lisbon.calendar)

        #expect(text == "🎂 dans 364 jours")
    }
}
