import BirthdayKit
import Foundation
import Testing

struct BirthdayFieldsTests {
    static let photoFileName = "8B9C0C4E-6F4B-4C8E-9C3A-2D1E5F6A7B8C.jpg"

    @Test("Texte vide ou fait d'espaces : nil", arguments: ["", " ", "\n\t "])
    func blankTextBecomesNil(text: String) throws {
        let birthday = try #require(
            Birthday(
                firstName: "Zoé",
                birthDate: try birthDate(3, 5),
                color: .rose,
                emoji: text,
                nickname: text,
                note: text,
                photoFileName: text
            )
        )

        #expect(birthday.emoji == nil)
        #expect(birthday.nickname == nil)
        #expect(birthday.note == nil)
        #expect(birthday.photoFileName == nil)
    }

    @Test("Surnom et note nettoyés en début et fin, retours à la ligne internes gardés")
    func textIsTrimmed() throws {
        let birthday = try #require(
            Birthday(
                firstName: "Zoé",
                birthDate: try birthDate(3, 5),
                color: .rose,
                nickname: "  Zozo ",
                note: "\n Aime le chocolat.\nDéteste les surprises. \n"
            )
        )

        #expect(birthday.nickname == "Zozo")
        #expect(birthday.note == "Aime le chocolat.\nDéteste les surprises.")
    }

    @Test(
        "Un seul emoji accepté",
        arguments: [
            "🎂", "⭐️", "👨‍👩‍👧", "🇵🇹", "👍🏽", " 🎂 ", "🎁", "🌸", "🔥", "💜", "🐶", "🌍", "🎸", "⚽️", "☕️", "🍕", "❤️",
        ]
    )
    func singleEmojiIsAccepted(text: String) throws {
        #expect(Birthday.singleEmoji(text) == text.trimmingCharacters(in: .whitespaces))
        let birthday = try #require(
            Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .rose, emoji: text))
        #expect(birthday.emoji == text.trimmingCharacters(in: .whitespaces))
    }

    @Test("Emoji refusé", arguments: ["1", "7", "#", "a", "Z", "é", "🎂🎂", "🎂a", "ab", "©"])
    func invalidEmojiIsRejected(text: String) throws {
        #expect(Birthday.singleEmoji(text) == nil)
        #expect(Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .rose, emoji: text) == nil)
    }

    @Test("Texte vide : pas un emoji", arguments: ["", " "])
    func emptyTextIsNotAnEmoji(text: String) {
        #expect(Birthday.singleEmoji(text) == nil)
    }

    @Test("Champ de saisie : vide, valide ou invalide")
    func fieldInput() {
        #expect(FieldInput("  ", parse: Birthday.singleEmoji) == .empty)
        #expect(FieldInput(" 🎂 ", parse: Birthday.singleEmoji).value == "🎂")
        #expect(FieldInput("🎂", parse: Birthday.singleEmoji) == .valid("🎂"))
        #expect(FieldInput("ab", parse: Birthday.singleEmoji) == .invalid)
        #expect(!FieldInput("", parse: Birthday.singleEmoji).isInvalid)
    }

    @Test(
        "Nom de fichier photo : un UUID suivi de .jpg uniquement",
        arguments: [
            (photoFileName, true),
            ("8b9c0c4e-6f4b-4c8e-9c3a-2d1e5f6a7b8c.jpg", true),
            ("photo.jpg", false),
            ("../8B9C0C4E-6F4B-4C8E-9C3A-2D1E5F6A7B8C.jpg", false),
            ("Photos/8B9C0C4E-6F4B-4C8E-9C3A-2D1E5F6A7B8C.jpg", false),
            ("8B9C0C4E-6F4B-4C8E-9C3A-2D1E5F6A7B8C.png", false),
        ]
    )
    func photoFileNameValidation(fileName: String, isValid: Bool) throws {
        #expect(PhotoFileName.isValid(fileName) == isValid)
        let birthday = Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .rose, photoFileName: fileName)
        #expect((birthday != nil) == isValid)
    }

    @Test("Aller-retour JSON avec tous les champs")
    func codableRoundTripWithAllFields() throws {
        let original = try #require(
            Birthday(
                firstName: "Zoé",
                birthDate: try birthDate(29, 2, 1996),
                color: .lavender,
                emoji: "👍🏽",
                nickname: "Zozo",
                note: "Aime le chocolat.",
                photoFileName: Self.photoFileName
            )
        )

        let decoded = try JSONDecoder().decode(Birthday.self, from: JSONEncoder().encode(original))

        #expect(decoded == original)
    }

    @Test("Un fichier v1 écrit avant les nouveaux champs se lit et reste en version 1")
    func readsVersionOneFileWithoutNewFields() throws {
        let json = """
            {"version":1,"birthdays":[{"id":"8B9C0C4E-6F4B-4C8E-9C3A-2D1E5F6A7B8C","firstName":"Zoé",\
            "birthDate":{"day":3,"month":5,"year":1990},"color":"sky","emoji":"🌸"}]}
            """
        let directory = FileManager.default.temporaryDirectory.appending(path: "BirthdayKitTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appending(path: "birthdays.json")
        try Data(json.utf8).write(to: fileURL)
        let repository = BirthdayFileRepository(fileURL: fileURL)

        let birthdays = try repository.load()
        try repository.save(birthdays)

        let zoe = try #require(birthdays.first)
        #expect(birthdays.count == 1)
        #expect(zoe.firstName == "Zoé")
        #expect(zoe.emoji == "🌸")
        #expect(zoe.nickname == nil)
        #expect(zoe.note == nil)
        #expect(zoe.photoFileName == nil)
        #expect(try BirthdayArchive(data: Data(contentsOf: fileURL)).version == 1)
        #expect(try repository.load() == birthdays)
    }

    @Test(
        "Fichier avec un champ invalide : erreur explicite",
        arguments: [#""emoji":"ab""#, #""photoFileName":"../x.jpg""#]
    )
    func invalidFieldInFile(field: String) {
        let json = """
            {"version":1,"birthdays":[{"id":"8B9C0C4E-6F4B-4C8E-9C3A-2D1E5F6A7B8C","firstName":"Zoé",\
            "birthDate":{"day":3,"month":5},"color":"sky",\(field)}]}
            """

        #expect(throws: BirthdayArchiveError.invalidContent) {
            try BirthdayArchive(data: Data(json.utf8))
        }
    }

    @Test(
        "Un fichier v1 avec un ancien champ instagram se lit, le champ disparaît à la prochaine écriture",
        arguments: ["zoe.test", "pseudo invalide !"]
    )
    func ignoresLegacyInstagramField(instagram: String) throws {
        let json = """
            {"version":1,"birthdays":[{"id":"8B9C0C4E-6F4B-4C8E-9C3A-2D1E5F6A7B8C","firstName":"Zoé",\
            "birthDate":{"day":3,"month":5,"year":1990},"color":"sky","instagram":"\(instagram)"}]}
            """
        let directory = FileManager.default.temporaryDirectory.appending(path: "BirthdayKitTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appending(path: "birthdays.json")
        try Data(json.utf8).write(to: fileURL)
        let repository = BirthdayFileRepository(fileURL: fileURL)

        let birthdays = try repository.load()
        try repository.save(birthdays)

        let rewritten = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(birthdays.map(\.firstName) == ["Zoé"])
        #expect(!rewritten.contains("instagram"))
        #expect(try BirthdayArchive(data: Data(contentsOf: fileURL)).version == 1)
        #expect(try repository.load() == birthdays)
    }
}
