import Foundation
import Testing

@testable import BirthdayKit

struct ReminderMessageTests {
    static let fixedID = UUID(uuid: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16))

    @Test("Dix phrases")
    func tenTemplates() {
        #expect(ReminderMessage.templates.count == 10)
    }

    @Test("Même id et même année : même phrase")
    func sameIdAndYearGiveSamePhrase() throws {
        let lea = try #require(
            Birthday(id: Self.fixedID, firstName: "Léa", birthDate: try birthDate(3, 5), color: .rose, emoji: "🌸")
        )
        let sameLea = try #require(
            Birthday(id: Self.fixedID, firstName: "Léa", birthDate: try birthDate(3, 5), color: .sky, emoji: "🌸")
        )

        #expect(ReminderMessage.body(for: lea, year: 2027) == ReminderMessage.body(for: lea, year: 2027))
        #expect(ReminderMessage.body(for: lea, year: 2027) == ReminderMessage.body(for: sameLea, year: 2027))
        #expect(ReminderMessage.templateIndex(id: Self.fixedID, year: 2027) == 6)
    }

    @Test("La phrase varie selon l'année")
    func phraseVariesWithYear() {
        let indices = Set((2026...2045).map { ReminderMessage.templateIndex(id: Self.fixedID, year: $0) })
        #expect(indices.count > 1)
    }

    @Test("Les dix phrases sont utilisées")
    func allTemplatesAreUsed() throws {
        let ids = try (0..<200).map { index in
            try #require(UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index)))
        }
        let indices = Set(ids.map { ReminderMessage.templateIndex(id: $0, year: 2027) })
        #expect(indices == Set(0..<10))
    }

    @Test("Avec emoji : prénom et emoji remplacés", arguments: ReminderMessage.templates)
    func renderWithEmoji(template: String) {
        let text = ReminderMessage.render(template, firstName: "Léa", emoji: "🌸")

        #expect(text.contains("Léa 🌸"))
        #expect(!text.contains("["))
        #expect(!text.contains("  "))
    }

    @Test("Sans emoji : ni double espace ni espace avant une virgule ou un point", arguments: ReminderMessage.templates)
    func renderWithoutEmoji(template: String) {
        for emoji in [nil, "", " "] as [String?] {
            let text = ReminderMessage.render(template, firstName: "Léa", emoji: emoji)

            #expect(text.hasPrefix("🎉🥳 "))
            #expect(text.contains("Léa"))
            #expect(!text.contains("["))
            #expect(!text.contains("  "))
            #expect(!text.contains(" ,"))
            #expect(!text.contains(" ."))
        }
    }

    @Test(
        "Exemples complets",
        arguments: [
            (0, "🌸", "🎉🥳 C'est l'anniversaire de Léa 🌸 aujourd'hui !"),
            (0, nil, "🎉🥳 C'est l'anniversaire de Léa aujourd'hui !"),
            (4, nil, "🎉🥳 Happy birthday Léa, don't forget to wish them well !"),
            (
                8, nil,
                "🎉🥳 Mission du jour : souhaiter un joyeux anniversaire à Léa. Ce message s'autodétruira à minuit."
            ),
        ] as [(Int, String?, String)]
    )
    func completeExamples(templateIndex: Int, emoji: String?, expected: String) {
        let template = ReminderMessage.templates[templateIndex]
        #expect(ReminderMessage.render(template, firstName: "Léa", emoji: emoji) == expected)
    }
}
