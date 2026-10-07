import BirthdayKit
import Foundation
import Testing

struct BirthDateTests {
    @Test(
        "Dates invalides refusées",
        arguments: [
            (31, 4, nil), (31, 6, nil), (31, 9, nil), (31, 11, nil), (30, 2, nil),
            (29, 2, 2027), (29, 2, 1900), (0, 1, nil), (32, 1, nil), (-1, 5, nil),
            (1, 0, nil), (1, 13, nil), (1, 1, 0), (1, 1, -1990),
        ] as [(Int, Int, Int?)]
    )
    func invalidDatesAreRejected(day: Int, month: Int, year: Int?) {
        #expect(BirthDate(day: day, month: month, year: year) == nil)
    }

    @Test(
        "Dates valides acceptées",
        arguments: [
            (29, 2, nil), (29, 2, 2024), (29, 2, 2000), (28, 2, 2027),
            (30, 4, 1985), (31, 12, 1990), (1, 1, nil),
        ] as [(Int, Int, Int?)]
    )
    func validDatesAreAccepted(day: Int, month: Int, year: Int?) throws {
        let birthDate = try #require(BirthDate(day: day, month: month, year: year))
        #expect(birthDate.day == day)
        #expect(birthDate.month == month)
        #expect(birthDate.year == year)
    }

    @Test("Encodage puis décodage à l'identique", arguments: [nil, 1992] as [Int?])
    func codableRoundTrip(year: Int?) throws {
        let original = Birthday(firstName: "Zoé", birthDate: try birthDate(29, 2, year), color: .lavender, emoji: "🦄")
        let decoded = try JSONDecoder().decode(Birthday.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }

    @Test("Le décodage refuse une date invalide")
    func decodingRejectsInvalidDate() {
        let json = Data(#"{"day":31,"month":4}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(BirthDate.self, from: json)
        }
    }

    @Test("Douze couleurs pastel")
    func twelvePastelColors() {
        #expect(PastelColor.allCases.count == 12)
    }
}
