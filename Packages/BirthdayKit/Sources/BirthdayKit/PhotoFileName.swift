import Foundation

public enum PhotoFileName {
    static let fileExtension = ".jpg"

    public static func isValid(_ fileName: String) -> Bool {
        guard fileName.hasSuffix(fileExtension) else { return false }
        return UUID(uuidString: String(fileName.dropLast(fileExtension.count))) != nil
    }
}
