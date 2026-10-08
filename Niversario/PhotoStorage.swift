import BirthdayKit
import Foundation

nonisolated struct PhotoStorage: Sendable {
    static let live = PhotoStorage(directory: liveDirectory)

    private static var liveDirectory: URL {
        #if DEBUG
            if LaunchOptions.isDemo {
                return URL.temporaryDirectory.appending(path: "NiversarioDemo/Photos", directoryHint: .isDirectory)
            }
        #endif
        return URL.applicationSupportDirectory
            .appending(path: "Niversario", directoryHint: .isDirectory)
            .appending(path: "Photos", directoryHint: .isDirectory)
    }

    let directory: URL

    func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    @concurrent
    func saveResizedPhoto(from data: Data) async throws -> String {
        let jpeg = try PhotoResizer.resizedJPEG(from: data)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = PhotoFileName.make()
        try jpeg.write(to: url(for: fileName), options: .atomic)
        return fileName
    }

    @concurrent
    func loadPhotoData(_ fileName: String) async -> Data? {
        guard PhotoFileName.isValid(fileName) else { return nil }
        return try? Data(contentsOf: url(for: fileName))
    }

    func existingPhotoFileNames() -> Set<String> {
        let fileNames =
            (try? FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))) ?? []
        return Set(fileNames.filter(PhotoFileName.isValid))
    }

    func delete(_ fileName: String) {
        guard PhotoFileName.isValid(fileName) else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    @concurrent
    func deleteOrphans(referencedBy birthdays: [Birthday]) async {
        let fileNames =
            (try? FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))) ?? []
        for fileName in PhotoFileName.orphans(among: fileNames, referencedBy: birthdays) {
            delete(fileName)
        }
    }
}
