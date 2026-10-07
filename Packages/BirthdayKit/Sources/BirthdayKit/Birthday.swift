import Foundation

public struct Birthday: Identifiable, Sendable, Hashable {
    public let id: UUID
    public private(set) var firstName: String
    public var birthDate: BirthDate
    public var color: PastelColor
    public var emoji: String?

    public init?(
        id: UUID = UUID(),
        firstName: String,
        birthDate: BirthDate,
        color: PastelColor,
        emoji: String? = nil
    ) {
        guard let normalizedFirstName = Self.normalizedFirstName(firstName) else { return nil }
        self.id = id
        self.firstName = normalizedFirstName
        self.birthDate = birthDate
        self.color = color
        self.emoji = emoji
    }

    public static func normalizedFirstName(_ firstName: String) -> String? {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension Birthday: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case birthDate
        case color
        case emoji
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let birthday = Birthday(
            id: try container.decode(UUID.self, forKey: .id),
            firstName: try container.decode(String.self, forKey: .firstName),
            birthDate: try container.decode(BirthDate.self, forKey: .birthDate),
            color: try container.decode(PastelColor.self, forKey: .color),
            emoji: try container.decodeIfPresent(String.self, forKey: .emoji)
        )
        guard let birthday else {
            throw DecodingError.dataCorruptedError(forKey: .firstName, in: container, debugDescription: "Prénom vide")
        }
        self = birthday
    }
}
