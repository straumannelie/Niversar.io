import Foundation

public struct Birthday: Identifiable, Sendable, Hashable {
    public let id: UUID
    public private(set) var firstName: String
    public var birthDate: BirthDate
    public var color: PastelColor
    public private(set) var emoji: String?
    public private(set) var nickname: String?
    public private(set) var note: String?
    public var instagram: InstagramHandle?
    public private(set) var photoFileName: String?

    public init?(
        id: UUID = UUID(),
        firstName: String,
        birthDate: BirthDate,
        color: PastelColor,
        emoji: String? = nil,
        nickname: String? = nil,
        note: String? = nil,
        instagram: InstagramHandle? = nil,
        photoFileName: String? = nil
    ) {
        guard let normalizedFirstName = Self.normalizedFirstName(firstName) else { return nil }
        let normalizedEmoji = emoji.flatMap(Self.normalizedText)
        if let normalizedEmoji, Self.singleEmoji(normalizedEmoji) == nil {
            return nil
        }
        let normalizedPhotoFileName = photoFileName.flatMap(Self.normalizedText)
        if let normalizedPhotoFileName, !PhotoFileName.isValid(normalizedPhotoFileName) {
            return nil
        }
        self.id = id
        self.firstName = normalizedFirstName
        self.birthDate = birthDate
        self.color = color
        self.emoji = normalizedEmoji
        self.nickname = nickname.flatMap(Self.normalizedText)
        self.note = note.flatMap(Self.normalizedText)
        self.instagram = instagram
        self.photoFileName = normalizedPhotoFileName
    }

    public static func normalizedFirstName(_ firstName: String) -> String? {
        normalizedText(firstName)
    }

    public static func normalizedText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public static func singleEmoji(_ text: String) -> String? {
        guard let trimmed = normalizedText(text), trimmed.count == 1,
            let character = trimmed.first, isEmoji(character)
        else { return nil }
        return trimmed
    }

    private static func isEmoji(_ character: Character) -> Bool {
        let scalars = character.unicodeScalars
        guard let first = scalars.first, first.properties.isEmoji else { return false }
        let variationSelector16: Unicode.Scalar = "\u{FE0F}"
        return first.properties.isEmojiPresentation || scalars.contains(variationSelector16)
    }
}

extension Birthday: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case birthDate
        case color
        case emoji
        case nickname
        case note
        case instagram
        case photoFileName
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let birthday = Birthday(
            id: try container.decode(UUID.self, forKey: .id),
            firstName: try container.decode(String.self, forKey: .firstName),
            birthDate: try container.decode(BirthDate.self, forKey: .birthDate),
            color: try container.decode(PastelColor.self, forKey: .color),
            emoji: try container.decodeIfPresent(String.self, forKey: .emoji),
            nickname: try container.decodeIfPresent(String.self, forKey: .nickname),
            note: try container.decodeIfPresent(String.self, forKey: .note),
            instagram: try container.decodeIfPresent(InstagramHandle.self, forKey: .instagram),
            photoFileName: try container.decodeIfPresent(String.self, forKey: .photoFileName)
        )
        guard let birthday else {
            throw DecodingError.dataCorruptedError(
                forKey: .firstName,
                in: container,
                debugDescription: "Prénom vide, emoji ou nom de photo invalide"
            )
        }
        self = birthday
    }
}
