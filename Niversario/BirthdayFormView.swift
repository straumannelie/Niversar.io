import BirthdayKit
import PhotosUI
import SwiftUI

struct BirthdayFormView: View {
    private static let emojiChoices = [
        "🎂", "🎁", "🎈", "🥳", "🌸", "🌻", "🌈", "🦋", "🐶", "🐱", "🌊", "🌍",
        "⭐️", "🔥", "💜", "🎸", "🎨", "📚", "🎮", "⚽️", "✈️", "☕️", "🍕", "🍷",
    ]

    private let editedBirthday: Birthday?
    private let onSave: (Birthday) -> Void
    private let years: [Int]
    private let initialContent: FormContent

    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String
    @State private var nickname: String
    @State private var day: Int
    @State private var month: Int
    @State private var year: Int?
    @State private var emoji: String?
    @State private var color: PastelColor
    @State private var isColorChosen: Bool
    @State private var note: String
    @State private var photoFileName: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var photoError: String?
    @State private var createdPhotoFileNames: [String] = []
    @State private var isConfirmingDiscard = false
    @FocusState private var focusedField: TextFieldID?

    init(editing birthday: Birthday? = nil, today: Date, calendar: Calendar, onSave: @escaping (Birthday) -> Void) {
        editedBirthday = birthday
        self.onSave = onSave
        years = Array((1900...calendar.component(.year, from: today)).reversed())
        let initialMonth = birthday?.birthDate.month ?? calendar.component(.month, from: today)
        let initial = FormContent(
            firstName: birthday?.firstName ?? "",
            nickname: birthday?.nickname ?? "",
            day: birthday?.birthDate.day ?? calendar.component(.day, from: today),
            month: initialMonth,
            year: birthday?.birthDate.year,
            emoji: birthday?.emoji,
            color: birthday?.color ?? PastelColor(month: initialMonth) ?? .rose,
            note: birthday?.note ?? "",
            photoFileName: birthday?.photoFileName
        )
        initialContent = initial
        _firstName = State(initialValue: initial.firstName)
        _nickname = State(initialValue: initial.nickname)
        _day = State(initialValue: initial.day)
        _month = State(initialValue: initial.month)
        _year = State(initialValue: initial.year)
        _emoji = State(initialValue: initial.emoji)
        _color = State(initialValue: initial.color)
        _isColorChosen = State(initialValue: birthday != nil)
        _note = State(initialValue: initial.note)
        _photoFileName = State(initialValue: initial.photoFileName)
    }

    private var currentContent: FormContent {
        FormContent(
            firstName: firstName,
            nickname: nickname,
            day: day,
            month: month,
            year: year,
            emoji: emoji,
            color: color,
            note: note,
            photoFileName: photoFileName
        )
    }

    private var hasChanges: Bool {
        currentContent != initialContent || isProcessingPhoto
    }

    private var isEditing: Bool {
        editedBirthday != nil
    }

    private var birthDate: BirthDate? {
        BirthDate(day: day, month: month, year: year)
    }

    private var displayedEmojis: [String] {
        guard let initialEmoji = initialContent.emoji, !Self.emojiChoices.contains(initialEmoji) else {
            return Self.emojiChoices
        }
        return [initialEmoji] + Self.emojiChoices
    }

    private var birthday: Birthday? {
        guard let birthDate, !isProcessingPhoto else { return nil }
        return Birthday(
            id: editedBirthday?.id ?? UUID(),
            firstName: firstName,
            birthDate: birthDate,
            color: color,
            emoji: emoji,
            nickname: nickname,
            note: note,
            photoFileName: photoFileName
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                if !isEditing {
                    Section {
                        Text("C'est qui la prochaine star du gâteau ? 🎂")
                            .font(.title3.bold())
                            .foregroundStyle(Color.textPrimary)
                            .listRowBackground(Color.clear)
                    }
                }

                Section("Prénom") {
                    TextField("Prénom", text: $firstName)
                        .focused($focusedField, equals: .firstName)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                }
                .listRowBackground(Color.appSurface)

                Section {
                    photoRow
                } header: {
                    Text("Photo")
                } footer: {
                    if let photoError {
                        errorText(photoError)
                    }
                }
                .listRowBackground(Color.appSurface)

                Section("Surnom") {
                    TextField("Surnom (facultatif)", text: $nickname)
                        .focused($focusedField, equals: .nickname)
                        .submitLabel(.done)
                }
                .listRowBackground(Color.appSurface)

                Section {
                    BirthDateWheels(day: $day, month: $month, year: $year, years: years)
                } header: {
                    Text("Date de naissance")
                } footer: {
                    if let year, birthDate == nil {
                        Text("\(String(year)) n'est pas bissextile : choisis une autre année ou « Sans année ».")
                    }
                }
                .listRowBackground(Color.appSurface)

                Section {
                    emojiGrid
                } header: {
                    Text("Emoji")
                } footer: {
                    Text("Sans choix, c'est 🎂 qui s'affiche.")
                }
                .listRowBackground(Color.appSurface)

                Section("Couleur") {
                    colorPicker
                }
                .listRowBackground(Color.appSurface)

                Section("Note") {
                    TextField("Idées cadeaux, goûts, souvenirs…", text: $note, axis: .vertical)
                        .focused($focusedField, equals: .note)
                        .lineLimit(3...8)
                }
                .listRowBackground(Color.appSurface)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .background(Color.appBackground)
            .navigationTitle(isEditing ? "Modifier" : "Nouvel anniversaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", role: .cancel, action: cancel)
                        .confirmationDialog(
                            "Abandonner les modifications ?",
                            isPresented: $isConfirmingDiscard,
                            titleVisibility: .visible
                        ) {
                            Button("Abandonner", role: .destructive, action: discard)
                            Button("Continuer la saisie", role: .cancel) {}
                        }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Text(isEditing ? "Enregistrer" : "Ajouter")
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.accentColor)
                    .disabled(birthday == nil)
                }
                .sharedBackgroundVisibility(.hidden)
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") {
                        focusedField = nil
                    }
                }
            }
            .onChange(of: photoItem) {
                guard let photoItem else { return }
                Task { await importPhoto(from: photoItem) }
            }
            .onChange(of: month) {
                if !isColorChosen, let monthColor = PastelColor(month: month) {
                    color = monthColor
                }
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }

    private var photoRow: some View {
        HStack(spacing: 16) {
            StoredPhoto(fileName: photoFileName) {
                Image(systemName: "person.crop.square")
                    .font(.largeTitle)
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(width: 64, height: 80)
            .background(Color.appSurfaceElevated)
            .clipShape(.rect(cornerRadius: 12))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                PhotosPicker(
                    photoFileName == nil ? "Ajouter une photo" : "Remplacer la photo",
                    selection: $photoItem,
                    matching: .images
                )
                .buttonStyle(.borderless)
                if photoFileName != nil {
                    Button("Retirer la photo", role: .destructive) {
                        photoFileName = nil
                    }
                    .buttonStyle(.borderless)
                }
            }
            .disabled(isProcessingPhoto)

            Spacer(minLength: 0)
            if isProcessingPhoto {
                ProgressView()
            }
        }
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        isProcessingPhoto = true
        photoError = nil
        defer {
            isProcessingPhoto = false
            photoItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                photoError = "Cette photo n'a pas pu être chargée."
                return
            }
            let fileName = try await PhotoStorage.live.saveResizedPhoto(from: data)
            createdPhotoFileNames.append(fileName)
            photoFileName = fileName
        } catch {
            photoError = "Cette photo n'a pas pu être enregistrée."
        }
    }

    private var emojiGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 8) {
            ForEach(displayedEmojis, id: \.self) { choice in
                let isSelected = emoji == choice
                Button {
                    emoji = isSelected ? nil : choice
                } label: {
                    Text(choice)
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .overlay {
                            if isSelected {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 2.5)
                                    .frame(width: 46, height: 46)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private var colorPicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(PastelColor.allCases, id: \.self) { pastelColor in
                Button {
                    color = pastelColor
                    isColorChosen = true
                } label: {
                    Circle()
                        .fill(Color(pastelColor))
                        .frame(width: 32, height: 32)
                        .padding(4)
                        .overlay {
                            if color == pastelColor {
                                Circle().stroke(Color.textPrimary, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(pastelColor.displayName)
                .accessibilityAddTraits(color == pastelColor ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func errorText(_ message: String) -> some View {
        Text(message)
            .foregroundStyle(.red)
    }

    private func save() {
        guard let birthday else { return }
        createdPhotoFileNames
            .filter { $0 != birthday.photoFileName }
            .forEach(PhotoStorage.live.delete)
        onSave(birthday)
        dismiss()
    }

    private func cancel() {
        if hasChanges {
            isConfirmingDiscard = true
        } else {
            discard()
        }
    }

    private func discard() {
        createdPhotoFileNames.forEach(PhotoStorage.live.delete)
        dismiss()
    }
}

private struct FormContent: Equatable {
    let firstName: String
    let nickname: String
    let day: Int
    let month: Int
    let year: Int?
    let emoji: String?
    let color: PastelColor
    let note: String
    let photoFileName: String?
}

private enum TextFieldID: Hashable {
    case firstName
    case nickname
    case note
}
