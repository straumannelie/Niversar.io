import BirthdayKit
import SwiftUI

struct DayBirthdaysView: View {
    let selectedDay: SelectedDay
    let store: BirthdayStore
    let today: Date
    let calendar: Calendar

    @Environment(\.dismiss) private var dismiss
    @State private var birthdayPendingDeletion: Birthday?
    @State private var presentedBirthday: PresentedBirthday?
    @Namespace private var zoomNamespace

    var body: some View {
        let people = selectedDay.month.birthdaysByDay(store.birthdays)[selectedDay.day] ?? []
        let upcoming = people.upcoming(limit: people.count, from: today, in: calendar)

        NavigationStack {
            List {
                ForEach(upcoming) { upcomingBirthday in
                    Button {
                        presentedBirthday = PresentedBirthday(
                            id: upcomingBirthday.id,
                            source: .row(upcomingBirthday.id)
                        )
                    } label: {
                        BirthdayRow(upcoming: upcomingBirthday)
                    }
                    .buttonStyle(.plain)
                    .matchedTransitionSource(id: ZoomSource.row(upcomingBirthday.id), in: zoomNamespace)
                    .listRowBackground(Color.appSurface)
                    .listRowSeparatorTint(Color.appSeparator)
                    .swipeActions(allowsFullSwipe: false) {
                        Button("Supprimer", systemImage: "trash") {
                            birthdayPendingDeletion = upcomingBirthday.birthday
                        }
                        .tint(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(selectedDay.month.dayTitle(selectedDay.day))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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
            .onChange(of: people.isEmpty) {
                if people.isEmpty {
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
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
