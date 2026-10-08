import Foundation

extension [Birthday] {
    public func addingOrReplacing(_ birthday: Birthday) -> [Birthday] {
        var result = self
        if let index = result.firstIndex(where: { $0.id == birthday.id }) {
            result[index] = birthday
        } else {
            result.append(birthday)
        }
        return result
    }

    public func removing(id: UUID) -> [Birthday] {
        filter { $0.id != id }
    }
}

extension Birthday {
    static func isOrderedByFirstName(_ lhs: Birthday, _ rhs: Birthday) -> Bool {
        let nameOrder = lhs.firstName.compare(
            rhs.firstName,
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "fr_FR")
        )
        if nameOrder != .orderedSame {
            return nameOrder == .orderedAscending
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
