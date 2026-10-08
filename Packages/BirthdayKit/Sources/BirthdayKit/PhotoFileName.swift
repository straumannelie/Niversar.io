import Foundation

public enum PhotoFileName {
    static let fileExtension = ".jpg"

    public static func make() -> String {
        UUID().uuidString + fileExtension
    }

    public static func isValid(_ fileName: String) -> Bool {
        guard fileName.hasSuffix(fileExtension) else { return false }
        return UUID(uuidString: String(fileName.dropLast(fileExtension.count))) != nil
    }

    public static func orphans(among fileNames: [String], referencedBy birthdays: [Birthday]) -> Set<String> {
        let referenced = Set(birthdays.compactMap(\.photoFileName))
        return Set(fileNames.filter { isValid($0) && !referenced.contains($0) })
    }
}
