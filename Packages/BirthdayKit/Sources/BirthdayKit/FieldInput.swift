public enum FieldInput<Value: Sendable & Hashable>: Sendable, Hashable {
    case empty
    case valid(Value)
    case invalid

    public init(_ text: String, parse: (String) -> Value?) {
        guard let trimmed = Birthday.normalizedText(text) else {
            self = .empty
            return
        }
        self = parse(trimmed).map(Self.valid) ?? .invalid
    }

    public var value: Value? {
        if case .valid(let value) = self {
            return value
        }
        return nil
    }

    public var isInvalid: Bool {
        self == .invalid
    }
}
