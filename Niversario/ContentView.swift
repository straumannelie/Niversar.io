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
    @State private var selectedDay: SelectedDay?
    @State private var addedBirthdaysCount = 0
    #if DEBUG
        @State private var isShowingScheduledReminders = false
    #endif

    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {
        let nextBirthdays = store.birthdays.upcoming(limit: 2, from: today, in: calendar)

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if reminders.isDenied {
                        NotificationsDisabledBanner()
                            .padding()
                            .background(Color.appSurface, in: .rect(cornerRadius: 16))
                            .padding(.horizontal)
                    }
                    if store.isLoaded && store.birthdays.isEmpty {
                        ContentUnavailableView(
                            "Aucun anniversaire pour l'instant",
                            systemImage: "birthday.cake",
                            description: Text("Appuie sur + pour ajouter le premier")
                        )
                    } else {
                        ForEach(nextBirthdays) { upcomingBirthday in
                            UpcomingBirthdayCard(upcoming: upcomingBirthday)
                                .padding(.horizontal)
                        }
                    }
                    BirthdayCalendar(
                        birthdays: store.birthdays,
                        currentMonth: CalendarMonth.containing(today, in: calendar),
                        todayDay: calendar.component(.day, from: today)
                    ) { day in
                        selectedDay = day
                    }
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
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
                BirthdayFormView(today: today, calendar: calendar) { birthday in
                    store.addOrReplace(birthday)
                    addedBirthdaysCount += 1
                    Task { await reminders.requestAuthorizationIfNeeded() }
                }
            }
            .sheet(item: $selectedDay) { day in
                DayBirthdaysView(selectedDay: day, store: store, today: today, calendar: calendar)
            }
            #if DEBUG
                .sheet(isPresented: $isShowingScheduledReminders) {
                    ScheduledRemindersDebugView(reminders: reminders, birthdays: store.birthdays)
                }
            #endif
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
