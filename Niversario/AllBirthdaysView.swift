import BirthdayKit
import SwiftUI

struct AllBirthdaysView: View {
    let store: BirthdayStore
    let today: Date
    let calendar: Calendar

    @Environment(\.dismiss) private var dismiss
    @State private var query = AllBirthdaysView.initialQuery
    @State private var presentedBirthday: PresentedBirthday?
    @State private var birthdayPendingDeletion: Birthday?
    @Namespace private var zoomNamespace
    @ScaledMetric(relativeTo: .body) private var avatarSize = 44.0

    private static var initialQuery: String {
        #if DEBUG
            LaunchOptions.searchQuery
        #else
            ""
        #endif
    }

    var body: some View {
        let sections = store.birthdays.matching(query).monthSections(from: today, in: calendar)

        NavigationStack {
            List {
                ForEach(sections) { section in
                    Section {
                        ForEach(section.entries) { upcoming in
                            row(upcoming)
                        }
                    } header: {
                        Text(section.month.title)
                            .font(.headline)
                            .foregroundStyle(Color(section.month.color))
                    }
                }
            }
            .overlay {
                if sections.isEmpty {
                    if Birthday.normalizedText(query) == nil {
                        ContentUnavailableView(
                            "Aucun anniversaire pour l'instant",
                            systemImage: "birthday.cake",
                            description: Text("Appuie sur + pour ajouter le premier")
                        )
                    } else {
                        ContentUnavailableView.search(text: query)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Tous les anniversaires")
            .navigationSubtitle(peopleCount)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Prénom ou surnom")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
            .sheet(item: $presentedBirthday) { presented in
                BirthdayDetailView(birthdayID: presented.id, store: store, today: today, calendar: calendar)
                    .zoomTransition(from: presented.source, in: zoomNamespace)
            }
            .alert(
                deletionTitle,
                isPresented: isConfirmingDeletion,
                presenting: birthdayPendingDeletion
            ) { birthday in
                Button("Supprimer", role: .destructive) {
                    store.remove(id: birthday.id)
                }
                Button("Annuler", role: .cancel) {}
            }
        }
    }

    private func row(_ upcoming: UpcomingBirthday) -> some View {
        Button {
            presentedBirthday = PresentedBirthday(id: upcoming.id, source: .row(upcoming.id))
        } label: {
            HStack(spacing: 12) {
                PhotoAvatar(birthday: upcoming.birthday, diameter: avatarSize)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(upcoming.birthday.firstName)
                            .font(.body.bold())
                            .foregroundStyle(Color.textPrimary)
                        if let nickname = upcoming.birthday.nickname {
                            Text(nickname)
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    Text("\(upcoming.birthday.birthDate.dayTitle) · \(upcoming.label)")
                        .font(.footnote)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(upcoming.accessibilityLabel), \(upcoming.birthday.birthDate.dayTitle)")
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: ZoomSource.row(upcoming.id), in: zoomNamespace)
        .listRowBackground(Color.appSurface)
        .listRowSeparatorTint(Color.appSeparator)
        .swipeActions(allowsFullSwipe: false) {
            Button("Supprimer", systemImage: "trash") {
                birthdayPendingDeletion = upcoming.birthday
            }
            .tint(.red)
        }
    }

    private var peopleCount: String {
        let count = store.birthdays.count
        return "\(count) \(count < 2 ? "personne" : "personnes")"
    }

    private var deletionTitle: String {
        birthdayPendingDeletion.map { "Supprimer \($0.firstName) ?" } ?? ""
    }

    private var isConfirmingDeletion: Binding<Bool> {
        Binding(
            get: { birthdayPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    birthdayPendingDeletion = nil
                }
            }
        )
    }
}
