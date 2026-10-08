import BirthdayKit
import Foundation
import Testing

struct BirthdayMergeTests {
    @Test("Fusion dans une liste vide : tout est ajouté")
    func mergeIntoEmptyList() throws {
        let imported = [try birthday("Adam", birthDate(1, 1)), try birthday("Lina", birthDate(20, 6))]

        let merge = [Birthday]().merging(imported, availablePhotoFileNames: [])

        #expect(merge.birthdays == imported)
        #expect(merge.addedCount == 2)
        #expect(merge.updatedCount == 0)
    }

    @Test("Ajouts et remplacements mélangés : remplacement sur place, ajouts à la fin")
    func mixedAdditionsAndReplacements() throws {
        let adam = try birthday("Adam", birthDate(1, 1))
        let lina = try birthday("Lina", birthDate(20, 6))
        let renamedLina = try birthday("Lina Rose", birthDate(21, 6), id: lina.id)
        let noe = try birthday("Noé", birthDate(3, 3))

        let merge = [adam, lina].merging([renamedLina, noe], availablePhotoFileNames: [])

        #expect(merge.birthdays == [adam, renamedLina, noe])
        #expect(merge.addedCount == 1)
        #expect(merge.updatedCount == 1)
    }

    @Test("Réimport identique : 0 ajout, 0 mise à jour, contenu inchangé")
    func identicalReimport() throws {
        let photo = PhotoFileName.make()
        let zoe = try #require(
            Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .sky, photoFileName: photo))
        let current = [try birthday("Adam", birthDate(1, 1)), zoe]
        let exported = try BirthdayArchive(birthdays: current).encoded()

        let merge = current.merging(try BirthdayArchive(data: exported).birthdays, availablePhotoFileNames: [photo])

        #expect(merge.birthdays == current)
        #expect(merge.addedCount == 0)
        #expect(merge.updatedCount == 0)
    }

    @Test("Photo d'une nouvelle personne : gardée si le fichier existe, retirée sinon")
    func photoOfNewPerson() throws {
        let present = PhotoFileName.make()
        let missing = PhotoFileName.make()
        let zoe = try #require(
            Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .sky, photoFileName: present))
        let lina = try #require(
            Birthday(firstName: "Lina", birthDate: try birthDate(4, 5), color: .sky, photoFileName: missing))

        let merge = [Birthday]().merging([zoe, lina], availablePhotoFileNames: [present])

        #expect(merge.birthdays.map(\.photoFileName) == [present, nil])
    }

    @Test(
        "Personne existante : la photo locale est gardée si la photo importée est absente",
        arguments: [true, false]
    )
    func localPhotoIsKept(importedHasPhotoReference: Bool) throws {
        let local = PhotoFileName.make()
        let current = try #require(
            Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .sky, photoFileName: local)
        )
        let imported = try #require(
            Birthday(
                id: current.id,
                firstName: "Zoé",
                birthDate: try birthDate(3, 5),
                color: .sky,
                photoFileName: importedHasPhotoReference ? PhotoFileName.make() : nil
            )
        )

        let merge = [current].merging([imported], availablePhotoFileNames: [local])

        #expect(merge.birthdays == [current])
        #expect(merge.updatedCount == 0)
    }

    @Test("Personne existante : une photo importée présente localement remplace la photo locale")
    func importedPhotoReplacesLocalPhoto() throws {
        let local = PhotoFileName.make()
        let importedPhoto = PhotoFileName.make()
        let current = try #require(
            Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .sky, photoFileName: local)
        )
        let imported = try #require(
            Birthday(
                id: current.id, firstName: "Zoé", birthDate: try birthDate(3, 5), color: .sky,
                photoFileName: importedPhoto)
        )

        let merge = [current].merging([imported], availablePhotoFileNames: [local, importedPhoto])

        #expect(merge.birthdays.map(\.photoFileName) == [importedPhoto])
        #expect(merge.updatedCount == 1)
    }

    @Test(
        "Fichier invalide refusé sans rien modifier",
        arguments: [
            "pas du json", #"{"version":2,"birthdays":[]}"#, #"{"version":1,"birthdays":[{"firstName":"Zoé"}]}"#,
        ]
    )
    func invalidFileIsRejected(contents: String) throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "BirthdayKitTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = BirthdayFileRepository(fileURL: directory.appending(path: "birthdays.json"))
        let current = [try birthday("Adam", birthDate(1, 1))]
        try repository.save(current)

        #expect(throws: BirthdayArchiveError.self) {
            let imported = try BirthdayArchive(data: Data(contents.utf8)).birthdays
            try repository.save(current.merging(imported, availablePhotoFileNames: []).birthdays)
        }
        #expect(try repository.load() == current)
    }

    @Test(
        "Messages d'import",
        arguments: [
            (0, 0, "0 ajouté, 0 mis à jour"), (1, 1, "1 ajouté, 1 mis à jour"), (3, 2, "3 ajoutés, 2 mis à jour"),
        ]
    )
    func summary(addedCount: Int, updatedCount: Int, expected: String) {
        #expect(BirthdayMerge.summary(addedCount: addedCount, updatedCount: updatedCount) == expected)
    }

    @Test(
        "Question de confirmation", arguments: [(1, "Importer 1 anniversaire ?"), (12, "Importer 12 anniversaires ?")])
    func confirmationQuestion(count: Int, expected: String) {
        #expect(BirthdayMerge.confirmationQuestion(importedCount: count) == expected)
    }

    @Test(
        "Nom du fichier de sauvegarde, dans le fuseau du calendrier",
        arguments: [
            (Day(2026, 10, 8), 23, "niversario-2026-10-08.json"), (Day(2027, 1, 5), 0, "niversario-2027-01-05.json"),
        ]
    )
    func backupFileName(day: Day, hour: Int, expected: String) throws {
        let lisbon = try Lisbon()
        #expect(BirthdayArchive.backupFileName(on: try lisbon.date(day, hour: hour), in: lisbon.calendar) == expected)
    }
}
