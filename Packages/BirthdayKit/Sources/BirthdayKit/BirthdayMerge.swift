import Foundation

public struct BirthdayMerge: Sendable, Equatable {
    public let birthdays: [Birthday]
    public let addedCount: Int
    public let updatedCount: Int

    public var summary: String {
        Self.summary(addedCount: addedCount, updatedCount: updatedCount)
    }

    public static func summary(addedCount: Int, updatedCount: Int) -> String {
        "\(addedCount) \(addedCount < 2 ? "ajouté" : "ajoutés"), \(updatedCount) mis à jour"
    }

    public static func confirmationQuestion(importedCount: Int) -> String {
        "Importer \(importedCount) \(importedCount < 2 ? "anniversaire" : "anniversaires") ?"
    }
}

extension [Birthday] {
    public func merging(_ imported: [Birthday], availablePhotoFileNames: Set<String>) -> BirthdayMerge {
        var merged = self
        var addedCount = 0
        var updatedCount = 0
        for importedBirthday in imported {
            let existing = merged.first { $0.id == importedBirthday.id }
            let photoFileName = [importedBirthday.photoFileName, existing?.photoFileName]
                .compactMap { $0 }
                .first { availablePhotoFileNames.contains($0) }
            let candidate = importedBirthday.withPhotoFileName(photoFileName)
            if let existing {
                updatedCount += existing == candidate ? 0 : 1
            } else {
                addedCount += 1
            }
            merged = merged.addingOrReplacing(candidate)
        }
        return BirthdayMerge(birthdays: merged, addedCount: addedCount, updatedCount: updatedCount)
    }
}

extension BirthdayArchive {
    public static func backupFileName(on date: Date, in calendar: Calendar) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return String(format: "niversario-%04d-%02d-%02d.json", year, month, day)
    }
}
