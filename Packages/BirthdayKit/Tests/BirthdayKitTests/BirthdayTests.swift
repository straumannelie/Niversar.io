import BirthdayKit
import Foundation
import Testing

struct BirthdayTests {
    @Test("Prénom vide ou composé d'espaces refusé", arguments: ["", " ", "   ", "\n", " \t\n "])
    func blankFirstNameIsRejected(firstName: String) throws {
        #expect(Birthday.normalizedFirstName(firstName) == nil)
        #expect(Birthday(firstName: firstName, birthDate: try birthDate(1, 1), color: .rose) == nil)
    }

    @Test(
        "Prénom nettoyé des espaces en début et fin",
        arguments: [("Léa", "Léa"), ("  Léa ", "Léa"), ("Léa\n", "Léa"), (" Marie Anne ", "Marie Anne")]
    )
    func firstNameIsTrimmed(firstName: String, expected: String) throws {
        let birthday = try birthday(firstName, birthDate(1, 1))
        #expect(birthday.firstName == expected)
    }

    @Test("Ajouter une personne nouvelle la place en fin de liste")
    func addingAppendsNewBirthday() throws {
        let adam = try birthday("Adam", birthDate(25, 6))
        let lina = try birthday("Lina", birthDate(1, 1))

        let birthdays = [adam].addingOrReplacing(lina)

        #expect(birthdays == [adam, lina])
    }

    @Test("Ajouter une personne existante la remplace à sa place")
    func addingReplacesExistingBirthday() throws {
        let adam = try birthday("Adam", birthDate(25, 6))
        let lina = try birthday("Lina", birthDate(1, 1))
        let renamedAdam = try birthday("Adam Junior", birthDate(26, 6), id: adam.id)

        let birthdays = [adam, lina].addingOrReplacing(renamedAdam)

        #expect(birthdays == [renamedAdam, lina])
    }

    @Test("Supprimer par id")
    func removingById() throws {
        let adam = try birthday("Adam", birthDate(25, 6))
        let lina = try birthday("Lina", birthDate(1, 1))

        #expect([adam, lina].removing(id: adam.id) == [lina])
        #expect([adam, lina].removing(id: UUID()) == [adam, lina])
    }

    @Test(
        "Couleur pastel du mois",
        arguments: zip(1...12, PastelColor.allCases)
    )
    func pastelColorOfMonth(month: Int, expected: PastelColor) {
        #expect(PastelColor(month: month) == expected)
    }

    @Test("Pas de couleur pour un mois invalide", arguments: [0, 13, -1])
    func noPastelColorForInvalidMonth(month: Int) {
        #expect(PastelColor(month: month) == nil)
    }

    @Test("Nombre de jours proposés par mois, 29 février compris", arguments: [(1, 31), (2, 29), (4, 30), (12, 31)])
    func maximumDayInMonth(month: Int, expected: Int) {
        #expect(BirthDate.maximumDay(inMonth: month) == expected)
    }
}
