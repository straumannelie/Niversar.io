import BirthdayKit
import Foundation
import Testing

struct BirthdayFileRepositoryTests {
    static let unreadableContents: [(String, BirthdayArchiveError)] = [
        ("pas du json", .corruptedData),
        ("{}", .corruptedData),
        (#"{"version":2,"birthdays":[]}"#, .unsupportedVersion(2)),
        (#"{"version":1,"birthdays":"rien"}"#, .invalidContent),
        (archiveJSON(firstName: "Zoé", day: 31, month: 4), .invalidContent),
        (archiveJSON(firstName: "   ", day: 1, month: 4), .invalidContent),
    ]

    @Test("Aller-retour écriture puis lecture, dossier créé si besoin")
    func saveThenLoad() throws {
        let directory = try TemporaryDirectory()
        defer { directory.remove() }
        let repository = BirthdayFileRepository(fileURL: directory.url.appending(path: "a/b/birthdays.json"))
        let birthdays = [
            try #require(
                Birthday(firstName: "Zoé", birthDate: try birthDate(29, 2, 1996), color: .lavender, emoji: "🦄")
            ),
            try birthday("Adam", birthDate(31, 12)),
        ]

        try repository.save(birthdays)

        #expect(try repository.load() == birthdays)
    }

    @Test("Le fichier écrit porte le numéro de version 1")
    func savedFileHasVersionOne() throws {
        let directory = try TemporaryDirectory()
        defer { directory.remove() }
        let fileURL = directory.url.appending(path: "birthdays.json")

        try BirthdayFileRepository(fileURL: fileURL).save([])

        let header = try JSONDecoder().decode(VersionHeader.self, from: Data(contentsOf: fileURL))
        #expect(header.version == 1)
    }

    @Test("Fichier absent : liste vide")
    func missingFileLoadsEmptyList() throws {
        let directory = try TemporaryDirectory()
        defer { directory.remove() }
        let repository = BirthdayFileRepository(fileURL: directory.url.appending(path: "absent/birthdays.json"))

        #expect(try repository.load() == [])
    }

    @Test("Fichier illisible : erreur explicite à la lecture", arguments: unreadableContents)
    func unreadableFileThrows(contents: String, expectedError: BirthdayArchiveError) throws {
        let directory = try TemporaryDirectory()
        defer { directory.remove() }
        let fileURL = directory.url.appending(path: "birthdays.json")
        try Data(contents.utf8).write(to: fileURL)

        #expect(throws: expectedError) {
            try BirthdayFileRepository(fileURL: fileURL).load()
        }
    }

    @Test("Fichier illisible : jamais écrasé", arguments: unreadableContents)
    func unreadableFileIsNeverOverwritten(contents: String, expectedError: BirthdayArchiveError) throws {
        let directory = try TemporaryDirectory()
        defer { directory.remove() }
        let fileURL = directory.url.appending(path: "birthdays.json")
        try Data(contents.utf8).write(to: fileURL)
        let repository = BirthdayFileRepository(fileURL: fileURL)

        #expect(throws: BirthdayFileRepositoryError.overwriteRefused) {
            try repository.save([try birthday("Adam", birthDate(25, 6))])
        }
        #expect(try String(contentsOf: fileURL, encoding: .utf8) == contents)
    }

    private static func archiveJSON(firstName: String, day: Int, month: Int) -> String {
        """
        {"version":1,"birthdays":[{"id":"8B9C0C4E-6F4B-4C8E-9C3A-2D1E5F6A7B8C","firstName":"\(firstName)",\
        "birthDate":{"day":\(day),"month":\(month)},"color":"rose"}]}
        """
    }
}

private struct VersionHeader: Decodable {
    let version: Int
}

private struct TemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory.appending(path: "BirthdayKitTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
