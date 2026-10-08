import BirthdayKit
import CoreTransferable
import Foundation
import UniformTypeIdentifiers

nonisolated struct BirthdayBackup: Transferable {
    let birthdays: [Birthday]
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { backup in
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appending(path: backup.fileName)
            try BirthdayArchive(birthdays: backup.birthdays).encoded().write(to: fileURL, options: .atomic)
            return SentTransferredFile(fileURL)
        }
    }
}
