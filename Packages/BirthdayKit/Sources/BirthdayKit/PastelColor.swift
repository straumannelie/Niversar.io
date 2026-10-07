public enum PastelColor: String, Codable, CaseIterable, Sendable {
    case rose
    case peach
    case lemon
    case mint
    case sky
    case lavender
    case orchid
    case aqua
    case blush
    case lime
    case periwinkle
    case apricot

    public init?(month: Int) {
        guard (1...12).contains(month) else { return nil }
        self = Self.allCases[month - 1]
    }
}
