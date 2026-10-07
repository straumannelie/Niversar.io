import BirthdayKit
import SwiftUI
import UIKit
import UserNotifications

struct ContentView: View {
    let store: BirthdayStore
    let reminders: ReminderScheduler

    @Environment(\.scenePhase) private var scenePhase
    @State private var today = Date.now
    @State private var isAddingBirthday = false
    @State private var birthdayPendingDeletion: Birthday?
    @State private var addedBirthdaysCount = 0
    #if DEBUG
        @State private var isShowingScheduledReminders = false
    #endif

    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {
        let upcoming = store.birthdays.upcoming(limit: store.birthdays.count, from: today, in: calendar)

        NavigationStack {
            List {
                if reminders.isDenied {
                    Section {
                        NotificationsDisabledBanner()
                            .listRowBackground(Color.appSurface)
                    }
                }
                if !upcoming.isEmpty {
                    nextBirthdaysSection(Array(upcoming.prefix(2)))
                    allBirthdaysSection(upcoming)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .overlay {
                if store.isLoaded && store.birthdays.isEmpty {
                    ContentUnavailableView(
                        "Aucun anniversaire pour l'instant",
                        systemImage: "birthday.cake",
                        description: Text("Appuie sur + pour ajouter le premier")
                    )
                }
            }
            .navigationTitle("Niversar.io")
            .toolbar {
                ToolbarItem(placement: .largeTitle) {
                    title
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ajouter", systemImage: "plus") {
                        isAddingBirthday = true
                    }
                    .disabled(!store.isLoaded)
                }
            }
            .sheet(isPresented: $isAddingBirthday) {
                NewBirthdayView(today: today, calendar: calendar) { birthday in
                    store.addOrReplace(birthday)
                    addedBirthdaysCount += 1
                    Task { await reminders.requestAuthorizationIfNeeded() }
                }
            }
            #if DEBUG
                .sheet(isPresented: $isShowingScheduledReminders) {
                    ScheduledRemindersDebugView(reminders: reminders, birthdays: store.birthdays)
                }
            #endif
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
        .alert(
            store.alert?.title ?? "",
            isPresented: isShowingStorageAlert,
            presenting: store.alert
        ) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
        .sensoryFeedback(.success, trigger: addedBirthdaysCount)
        .onChange(of: scenePhase, initial: true) {
            guard scenePhase == .active else { return }
            today = .now
            store.loadIfNeeded()
            Task { await reminders.refreshAuthorizationStatus() }
        }
        .task(id: reminderInputs) {
            guard store.isLoaded else { return }
            await reminders.reschedule(store.birthdays, now: today)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            today = .now
        }
    }

    private func nextBirthdaysSection(_ nextBirthdays: [UpcomingBirthday]) -> some View {
        Section {
            ForEach(nextBirthdays) { upcomingBirthday in
                UpcomingBirthdayCard(upcoming: upcomingBirthday)
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
    }

    private func allBirthdaysSection(_ upcoming: [UpcomingBirthday]) -> some View {
        Section {
            ForEach(upcoming) { upcomingBirthday in
                BirthdayRow(upcoming: upcomingBirthday)
                    .listRowBackground(Color.appSurface)
                    .listRowSeparatorTint(Color.appSeparator)
                    .swipeActions(allowsFullSwipe: false) {
                        Button("Supprimer", systemImage: "trash") {
                            birthdayPendingDeletion = upcomingBirthday.birthday
                        }
                        .tint(.red)
                    }
            }
        } header: {
            Text("Tous les anniversaires")
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var title: some View {
        Text("Niversar.io")
            .font(.largeTitle.bold())
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            #if DEBUG
                .onLongPressGesture {
                    isShowingScheduledReminders = true
                }
            #endif
    }

    private var reminderInputs: ReminderInputs {
        ReminderInputs(
            birthdays: store.birthdays,
            today: today,
            isLoaded: store.isLoaded,
            authorizationStatus: reminders.authorizationStatus
        )
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

    private var isShowingStorageAlert: Binding<Bool> {
        Binding(
            get: { store.alert != nil },
            set: { isPresented in
                if !isPresented {
                    store.alert = nil
                }
            }
        )
    }
}

private struct ReminderInputs: Equatable {
    let birthdays: [Birthday]
    let today: Date
    let isLoaded: Bool
    let authorizationStatus: UNAuthorizationStatus
}

#Preview {
    ContentView(
        store: BirthdayStore(
            repository: BirthdayFileRepository(
                fileURL: URL.temporaryDirectory.appending(path: "preview-birthdays.json")
            )
        ),
        reminders: ReminderScheduler()
    )
}
