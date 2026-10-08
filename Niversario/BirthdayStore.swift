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
    private let photos: PhotoStorage

    init(repository: BirthdayFileRepository, photos: PhotoStorage = .live) {
        self.repository = repository
        self.photos = photos
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
            let referencingBirthdays = birthdays
            Task { await photos.deleteOrphans(referencedBy: referencingBirthdays) }
        } catch {
            alert = StorageAlert(
                title: "Impossible de lire tes anniversaires",
                message: "\(error.localizedDescription) Le fichier n'a pas été modifié et l'ajout est bloqué "
                    + "jusqu'à ce qu'il soit lisible."
            )
        }
    }

    func addOrReplace(_ birthday: Birthday) {
        let previousPhotoFileName = photoFileName(of: birthday.id)
        guard update({ $0.addingOrReplacing(birthday) }) else { return }
        if let previousPhotoFileName, previousPhotoFileName != birthday.photoFileName {
            photos.delete(previousPhotoFileName)
        }
    }

    func remove(id: UUID) {
        let previousPhotoFileName = photoFileName(of: id)
        guard update({ $0.removing(id: id) }) else { return }
        if let previousPhotoFileName {
            photos.delete(previousPhotoFileName)
        }
    }

    func importBirthdays(_ imported: [Birthday]) -> BirthdayMerge? {
        guard isLoaded else { return nil }
        let merge = birthdays.merging(imported, availablePhotoFileNames: photos.existingPhotoFileNames())
        guard update({ _ in merge.birthdays }) else { return nil }
        return merge
    }

    private func photoFileName(of id: UUID) -> String? {
        birthdays.first { $0.id == id }?.photoFileName
    }

    private func update(_ change: ([Birthday]) -> [Birthday]) -> Bool {
        guard isLoaded else { return false }
        birthdays = change(birthdays)
        do {
            try repository.save(birthdays)
            return true
        } catch {
            alert = StorageAlert(
                title: "Impossible d'enregistrer",
                message: "\(error.localizedDescription) La modification reste affichée et l'enregistrement "
                    + "sera retenté à la prochaine modification."
            )
            return false
        }
    }
}
