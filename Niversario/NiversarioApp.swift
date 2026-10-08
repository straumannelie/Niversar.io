import SwiftUI
import UserNotifications

@main
struct NiversarioApp: App {
    @State private var store = BirthdayStore.live()
    @State private var reminders = ReminderScheduler()
    private let notificationPresenter = ForegroundNotificationPresenter()

    init() {
        UNUserNotificationCenter.current().delegate = notificationPresenter
        #if DEBUG
            if LaunchOptions.isDemo {
                _store = State(initialValue: .demo(today: .now, calendar: Calendar(identifier: .gregorian)))
            }
        #endif
    }

    private static var isDemo: Bool {
        #if DEBUG
            LaunchOptions.isDemo
        #else
            false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store, reminders: reminders, schedulesReminders: !Self.isDemo)
                .preferredColorScheme(.dark)
        }
    }
}
