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
