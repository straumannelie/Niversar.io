import BirthdayKit
import SwiftUI

struct BirthdayFormView: View {
    private static let suggestedEmojis = ["🎂", "🎁", "🌸", "⭐️", "🔥", "💜", "🐶", "🌍", "🎸", "⚽️", "☕️", "🍕"]

    private let editedBirthday: Birthday?
    private let onSave: (Birthday) -> Void
    private let years: [Int]

    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String
    @State private var nickname: String
    @State private var day: Int
    @State private var month: Int
    @State private var year: Int?
    @State private var emoji: String
    @State private var color: PastelColor
    @State private var isColorChosen: Bool
    @State private var instagram: String
    @State private var note: String

    init(editing birthday: Birthday? = nil, today: Date, calendar: Calendar, onSave: @escaping (Birthday) -> Void) {
        editedBirthday = birthday
        self.onSave = onSave
        years = Array((1900...calendar.component(.year, from: today)).reversed())
        let initialMonth = birthday?.birthDate.month ?? calendar.component(.month, from: today)
        _firstName = State(initialValue: birthday?.firstName ?? "")
        _nickname = State(initialValue: birthday?.nickname ?? "")
        _day = State(initialValue: birthday?.birthDate.day ?? calendar.component(.day, from: today))
        _month = State(initialValue: initialMonth)
        _year = State(initialValue: birthday?.birthDate.year)
        _emoji = State(initialValue: birthday?.emoji ?? "")
        _color = State(initialValue: birthday?.color ?? PastelColor(month: initialMonth) ?? .rose)
        _isColorChosen = State(initialValue: birthday != nil)
        _instagram = State(initialValue: birthday?.instagram?.username ?? "")
        _note = State(initialValue: birthday?.note ?? "")
    }

    private var isEditing: Bool {
        editedBirthday != nil
    }

    private var birthDate: BirthDate? {
        BirthDate(day: day, month: month, year: year)
    }

    private var emojiInput: FieldInput<String> {
        FieldInput(emoji, parse: Birthday.singleEmoji)
    }

    private var instagramInput: FieldInput<InstagramHandle> {
        FieldInput(instagram, parse: InstagramHandle.init)
    }

    private var birthday: Birthday? {
        guard let birthDate, !emojiInput.isInvalid, !instagramInput.isInvalid else { return nil }
        return Birthday(
            id: editedBirthday?.id ?? UUID(),
            firstName: firstName,
            birthDate: birthDate,
            color: color,
            emoji: emojiInput.value,
            nickname: nickname,
            note: note,
            instagram: instagramInput.value,
            photoFileName: editedBirthday?.photoFileName
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
                        .textContentType(.givenName)
                        .submitLabel(.done)
                }
                .listRowBackground(Color.appSurface)

                Section("Surnom") {
                    TextField("Surnom (facultatif)", text: $nickname)
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
                    emojiSuggestions
                    TextField("Autre emoji", text: $emoji)
                } header: {
                    Text("Emoji")
                } footer: {
                    if emojiInput.isInvalid {
                        errorText("Un seul emoji, par exemple 🎂.")
                    }
                }
                .listRowBackground(Color.appSurface)

                Section("Couleur") {
                    colorPicker
                }
                .listRowBackground(Color.appSurface)

                Section {
                    TextField("Pseudo ou lien du profil", text: $instagram)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Instagram")
                } footer: {
                    if instagramInput.isInvalid {
                        errorText("Pseudo invalide : lettres, chiffres, point et tiret bas, 30 caractères au maximum.")
                    }
                }
                .listRowBackground(Color.appSurface)

                Section("Note") {
                    TextField("Idées cadeaux, goûts, souvenirs…", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }
                .listRowBackground(Color.appSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(isEditing ? "Modifier" : "Nouvel anniversaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter 🎉", action: save)
                        .disabled(birthday == nil)
                }
            }
            .onChange(of: month) {
                if !isColorChosen, let monthColor = PastelColor(month: month) {
                    color = monthColor
                }
            }
        }
    }

    private var emojiSuggestions: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Self.suggestedEmojis, id: \.self) { suggestion in
                    Button {
                        emoji = emojiInput.value == suggestion ? "" : suggestion
                    } label: {
                        Text(suggestion)
                            .font(.title2)
                            .padding(6)
                            .background {
                                if emojiInput.value == suggestion {
                                    Circle().fill(Color.appSurfaceElevated)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(emojiInput.value == suggestion ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
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
        onSave(birthday)
        dismiss()
    }
}
