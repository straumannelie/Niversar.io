import BirthdayKit
import SwiftUI
import UIKit
import UserNotifications

struct ContentView: View {
    let store: BirthdayStore
    let reminders: ReminderScheduler
    var schedulesReminders = true

    @Environment(\.scenePhase) private var scenePhase
    @State private var today = Date.now
    @State private var isAddingBirthday = false
    @State private var selectedDay: SelectedDay?
    @State private var presentedBirthday: PresentedBirthday?
    @State private var addedBirthdaysCount = 0
    @State private var isShowingSettings = false
    @State private var isShowingAllBirthdays = false
    @AppStorage(SettingsView.reminderTimeKey) private var reminderMinutes =
        ReminderPlanner.defaultTime.minutesSinceMidnight
    @Namespace private var zoomNamespace
    @ScaledMetric(relativeTo: .largeTitle) private var titleCakeSize = 38.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var titleCakeBounces = 0
    #if DEBUG
        @State private var debugEditedBirthday: Birthday?
        @State private var hasOpenedLaunchScreen = false
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
                            Button {
                                presentedBirthday = PresentedBirthday(
                                    id: upcomingBirthday.id,
                                    source: .card(upcomingBirthday.id)
                                )
                            } label: {
                                UpcomingBirthdayCard(upcoming: upcomingBirthday)
                            }
                            .buttonStyle(.plain)
                            .matchedTransitionSource(id: ZoomSource.card(upcomingBirthday.id), in: zoomNamespace) {
                                $0.clipShape(.rect(cornerRadius: 20))
                            }
                            .birthdayTodayGlow(upcomingBirthday.daysRemaining == 0)
                            .padding(.horizontal)
                        }
                    }
                    BirthdayCalendar(
                        birthdays: store.birthdays,
                        currentMonth: CalendarMonth.containing(today, in: calendar),
                        todayDay: calendar.component(.day, from: today),
                        zoomNamespace: zoomNamespace
                    ) { day in
                        select(day)
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
                ToolbarItem(placement: .largeSubtitle) {
                    Text(HomeTagline.text(for: store.birthdays, today: today, calendar: calendar))
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tous les anniversaires", systemImage: "list.bullet") {
                        isShowingAllBirthdays = true
                    }
                    .disabled(!store.isLoaded)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Réglages", systemImage: "gearshape") {
                        isShowingSettings = true
                    }
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
            .sheet(isPresented: $isShowingAllBirthdays) {
                AllBirthdaysView(store: store, today: today, calendar: calendar)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(store: store, reminders: reminders, today: today, calendar: calendar)
            }
            .sheet(item: $selectedDay) { day in
                DayBirthdaysView(selectedDay: day, store: store, today: today, calendar: calendar)
            }
            .sheet(item: $presentedBirthday) { presented in
                BirthdayDetailView(birthdayID: presented.id, store: store, today: today, calendar: calendar)
                    .zoomTransition(from: presented.source, in: zoomNamespace)
            }
            #if DEBUG
                .sheet(item: $debugEditedBirthday) { birthday in
                    BirthdayFormView(editing: birthday, today: today, calendar: calendar) { editedBirthday in
                        store.addOrReplace(editedBirthday)
                    }
                }
                .onChange(of: store.isLoaded, initial: true) {
                    openLaunchScreen()
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
        .onChange(of: hasBirthdayToday, initial: true) {
            if hasBirthdayToday, !reduceMotion, titleCakeBounces == 0 {
                titleCakeBounces += 1
            }
        }
        .onChange(of: scenePhase, initial: true) {
            guard scenePhase == .active else { return }
            today = .now
            store.loadIfNeeded()
            Task { await reminders.refreshAuthorizationStatus() }
        }
        .task(id: reminderInputs) {
            guard store.isLoaded, schedulesReminders else { return }
            await reminders.reschedule(
                store.birthdays,
                now: today,
                time: TimeOfDay(minutesSinceMidnight: reminderMinutes)
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            today = .now
        }
    }

    #if DEBUG
        private func openLaunchScreen() {
            guard store.isLoaded, !hasOpenedLaunchScreen, let screen = LaunchOptions.screen else { return }
            hasOpenedLaunchScreen = true
            let first = store.birthdays.upcoming(limit: 1, from: today, in: calendar).first
            switch screen {
            case .form:
                isAddingBirthday = true
            case .edit:
                debugEditedBirthday = first?.birthday
            case .detail:
                if let first {
                    presentedBirthday = PresentedBirthday(id: first.id, source: .card(first.id))
                }
            case .day:
                selectedDay = firstSharedDay
            case .settings:
                isShowingSettings = true
            case .list:
                isShowingAllBirthdays = true
            }
        }

        private var firstSharedDay: SelectedDay? {
            let sharedDate = store.birthdays.first { birthday in
                store.birthdays.contains {
                    $0.id != birthday.id && $0.birthDate.day == birthday.birthDate.day
                        && $0.birthDate.month == birthday.birthDate.month
                }
            }?.birthDate
            return sharedDate.map {
                SelectedDay(
                    month: CalendarMonth(year: calendar.component(.year, from: today), month: $0.month),
                    day: $0.day
                )
            }
        }
    #endif

    private func select(_ day: SelectedDay) {
        let people = day.month.birthdaysByDay(store.birthdays)[day.day] ?? []
        if people.count == 1, let person = people.first {
            presentedBirthday = PresentedBirthday(id: person.id, source: .day(day.month, day.day))
        } else {
            selectedDay = day
        }
    }

    private var title: some View {
        HStack(spacing: 10) {
            Image(.titleCake)
                .resizable()
                .scaledToFit()
                .frame(width: titleCakeSize, height: titleCakeSize)
                .keyframeAnimator(initialValue: 0.0, trigger: titleCakeBounces) { cake, offset in
                    cake.offset(y: offset)
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(-12, duration: 0.18)
                        SpringKeyframe(0, duration: 0.5, spring: .bouncy(extraBounce: 0.3))
                    }
                }
                .accessibilityHidden(true)
            Text("Niversar.io")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hasBirthdayToday: Bool {
        store.birthdays.upcoming(limit: 1, from: today, in: calendar).first?.daysRemaining == 0
    }

    private var reminderInputs: ReminderInputs {
        ReminderInputs(
            birthdays: store.birthdays,
            today: today,
            isLoaded: store.isLoaded,
            authorizationStatus: reminders.authorizationStatus,
            reminderMinutes: reminderMinutes
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
    let reminderMinutes: Int
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
