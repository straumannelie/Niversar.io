import Foundation

public enum BirthdayArchiveError: Error, Equatable, LocalizedError {
    case corruptedData
    case unsupportedVersion(Int)
    case invalidContent

    public var errorDescription: String? {
        switch self {
        case .corruptedData:
            "Le fichier des anniversaires est illisible."
        case .unsupportedVersion(let version):
            "Le fichier des anniversaires est au format \(version), inconnu de cette version de l'app."
        case .invalidContent:
            "Le fichier des anniversaires contient une date ou un prénom invalide."
        }
    }
}

public struct BirthdayArchive: Sendable, Equatable {
    public static let currentVersion = 1

    public let version: Int
    public let birthdays: [Birthday]

    public init(birthdays: [Birthday]) {
        self.version = Self.currentVersion
        self.birthdays = birthdays
    }

    public init(data: Data) throws(BirthdayArchiveError) {
        let decoder = JSONDecoder()
        let header: VersionHeader
        do {
            header = try decoder.decode(VersionHeader.self, from: data)
        } catch {
            throw .corruptedData
        }
        guard header.version == Self.currentVersion else {
            throw .unsupportedVersion(header.version)
        }
        do {
            let payload = try decoder.decode(Payload.self, from: data)
            self.version = payload.version
            self.birthdays = payload.birthdays
        } catch {
            throw .invalidContent
        }
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(Payload(version: version, birthdays: birthdays))
    }
}

private struct VersionHeader: Decodable {
    let version: Int
}

private struct Payload: Codable {
    let version: Int
    let birthdays: [Birthday]
}
