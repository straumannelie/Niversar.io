import Foundation

public struct InstagramHandle: Sendable, Hashable {
    static let maximumLength = 30
    private static let instagramHosts: Set<String> = ["instagram.com", "www.instagram.com", "m.instagram.com"]
    private static let allowedCharacters = Set("abcdefghijklmnopqrstuvwxyz0123456789._")

    public let username: String
    public let profileURL: URL

    public init?(_ input: String) {
        guard let candidate = Self.candidateUsername(from: input) else { return nil }
        let username = candidate.lowercased()
        guard (1...Self.maximumLength).contains(username.count),
            username.allSatisfy(Self.allowedCharacters.contains),
            let profileURL = URL(string: "https://instagram.com/\(username)")
        else { return nil }
        self.username = username
        self.profileURL = profileURL
    }

    private static func candidateUsername(from input: String) -> String? {
        guard let trimmed = Birthday.normalizedText(input) else { return nil }
        guard trimmed.lowercased().contains("instagram.com") else {
            return trimmed.hasPrefix("@") ? String(trimmed.dropFirst()) : trimmed
        }
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: withScheme),
            let host = components.host?.lowercased(),
            instagramHosts.contains(host)
        else { return nil }
        let pathComponents = components.path.split(separator: "/")
        guard pathComponents.count == 1, let username = pathComponents.first else { return nil }
        return String(username)
    }
}

extension InstagramHandle: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let username = try container.decode(String.self)
        guard let handle = InstagramHandle(username) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Pseudo Instagram invalide")
        }
        self = handle
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(username)
    }
}
