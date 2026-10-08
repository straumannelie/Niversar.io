import BirthdayKit
import SwiftUI

struct PresentedBirthday: Identifiable, Hashable {
    let id: UUID
    let source: ZoomSource
}

struct BirthdayDetailView: View {
    let birthdayID: UUID
    let store: BirthdayStore
    let today: Date
    let calendar: Calendar

    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var isConfirmingDeletion = false
    @State private var savedEditsCount = 0
    @ScaledMetric(relativeTo: .largeTitle) private var initialSize = 140.0

    private var birthday: Birthday? {
        store.birthdays.first { $0.id == birthdayID }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let birthday, let upcoming = [birthday].upcoming(limit: 1, from: today, in: calendar).first {
                    content(birthday: birthday, upcoming: upcoming)
                }
            }
            .background(Color.appBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: savedEditsCount)
        .onChange(of: birthday == nil) {
            if birthday == nil {
                dismiss()
            }
        }
    }

    private func content(birthday: Birthday, upcoming: UpcomingBirthday) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero(birthday: birthday, upcoming: upcoming)

                VStack(alignment: .leading, spacing: 12) {
                    if let note = birthday.note {
                        noteCard(note)
                    }
                    Button {
                        isEditing = true
                    } label: {
                        Label("Modifier", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)

                    Button(role: .destructive) {
                        isConfirmingDeletion = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .tint(.red)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $isEditing) {
            BirthdayFormView(editing: birthday, today: today, calendar: calendar) { editedBirthday in
                store.addOrReplace(editedBirthday)
                savedEditsCount += 1
            }
        }
        .alert("Supprimer \(birthday.firstName) ?", isPresented: $isConfirmingDeletion) {
            Button("Supprimer", role: .destructive) {
                store.remove(id: birthday.id)
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private func hero(birthday: Birthday, upcoming: UpcomingBirthday) -> some View {
        Color.appSurface
            .aspectRatio(4 / 5, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                StoredPhoto(fileName: birthday.photoFileName) {
                    Text(String(birthday.firstName.prefix(1)).uppercased())
                        .font(.system(size: initialSize, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(birthday.color))
                }
            }
            .clipped()
            .overlay(alignment: .bottom) {
                heroBanner(birthday: birthday, upcoming: upcoming)
            }
            .accessibilityElement(children: .combine)
    }

    private func heroBanner(birthday: Birthday, upcoming: UpcomingBirthday) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Capsule()
                .fill(Color(birthday.color))
                .frame(width: 48, height: 5)
                .accessibilityHidden(true)
            Text(birthday.firstName)
                .font(.largeTitle.bold())
                .foregroundStyle(Color.textPrimary)
            HStack(spacing: 8) {
                if let age = birthday.birthDate.age(on: today, in: calendar) {
                    DetailBadge(text: UpcomingBirthday.ageLabel(age))
                }
                DetailBadge(text: birthday.birthDate.dayTitle)
            }
            if let nickname = birthday.nickname {
                Text(nickname)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary.opacity(0.8))
            }
            DetailBadge(text: upcoming.countdown, tint: Color(birthday.color))
        }
        .padding()
        .padding(.top, 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [.clear, Color.appBackground.opacity(0.85), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func noteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Note")
                .font(.caption.bold())
                .foregroundStyle(Color.textSecondary)
            Text(note)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: .rect(cornerRadius: 16))
    }
}

private struct DetailBadge: View {
    let text: String
    var tint: Color?

    var body: some View {
        Text(text)
            .font(.subheadline.bold())
            .foregroundStyle(tint == nil ? Color.textPrimary : Color.appBackground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint ?? Color.appSurfaceElevated, in: .capsule)
    }
}
