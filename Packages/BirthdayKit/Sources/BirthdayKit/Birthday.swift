import Foundation

public struct Birthday: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var firstName: String
    public var birthDate: BirthDate
    public var color: PastelColor
    public var emoji: String?

    public init(
        id: UUID = UUID(),
        firstName: String,
        birthDate: BirthDate,
        color: PastelColor,
        emoji: String? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.birthDate = birthDate
        self.color = color
        self.emoji = emoji
    }
}
