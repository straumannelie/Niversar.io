import Foundation

public enum BirthdayFileRepositoryError: Error, Equatable, LocalizedError {
    case readFailed
    case writeFailed
    case overwriteRefused

    public var errorDescription: String? {
        switch self {
        case .readFailed:
            "Le fichier des anniversaires n'a pas pu être lu."
        case .writeFailed:
            "Le fichier des anniversaires n'a pas pu être écrit."
        case .overwriteRefused:
            "Le fichier existant est illisible : il n'a pas été remplacé."
        }
    }
}

public struct BirthdayFileRepository: Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> [Birthday] {
        guard let data = try existingData() else { return [] }
        return try BirthdayArchive(data: data).birthdays
    }

    public func save(_ birthdays: [Birthday]) throws {
        do {
            _ = try load()
        } catch {
            throw BirthdayFileRepositoryError.overwriteRefused
        }
        do {
            let data = try BirthdayArchive(birthdays: birthdays).encoded()
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw BirthdayFileRepositoryError.writeFailed
        }
    }

    private func existingData() throws -> Data? {
        do {
            return try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        } catch {
            throw BirthdayFileRepositoryError.readFailed
        }
    }
}
