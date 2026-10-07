import BirthdayKit
import Foundation
import Observation

struct StorageAlert: Equatable {
    let title: String
    let message: String
}

@MainActor
@Observable
final class BirthdayStore {
    private(set) var birthdays: [Birthday] = []
    private(set) var isLoaded = false
    var alert: StorageAlert?

    private let repository: BirthdayFileRepository

    init(repository: BirthdayFileRepository) {
        self.repository = repository
    }

    static func live() -> BirthdayStore {
        let fileURL = URL.applicationSupportDirectory
            .appending(path: "Niversario", directoryHint: .isDirectory)
            .appending(path: "birthdays.json")
        return BirthdayStore(repository: BirthdayFileRepository(fileURL: fileURL))
    }

    func loadIfNeeded() {
        guard !isLoaded else { return }
        do {
            birthdays = try repository.load()
            isLoaded = true
        } catch {
            alert = StorageAlert(
                title: "Impossible de lire tes anniversaires",
                message: "\(error.localizedDescription) Le fichier n'a pas été modifié et l'ajout est bloqué "
                    + "jusqu'à ce qu'il soit lisible."
            )
        }
    }

    func addOrReplace(_ birthday: Birthday) {
        update { $0.addingOrReplacing(birthday) }
    }

    func remove(id: UUID) {
        update { $0.removing(id: id) }
    }

    private func update(_ change: ([Birthday]) -> [Birthday]) {
        guard isLoaded else { return }
        birthdays = change(birthdays)
        do {
            try repository.save(birthdays)
        } catch {
            alert = StorageAlert(
                title: "Impossible d'enregistrer",
                message: "\(error.localizedDescription) La modification reste affichée et l'enregistrement "
                    + "sera retenté à la prochaine modification."
            )
        }
    }
}
