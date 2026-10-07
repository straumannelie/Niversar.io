import SwiftUI
import UserNotifications

@main
struct NiversarioApp: App {
    @State private var store = BirthdayStore.live()
    @State private var reminders = ReminderScheduler()
    private let notificationPresenter = ForegroundNotificationPresenter()

    init() {
        UNUserNotificationCenter.current().delegate = notificationPresenter
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store, reminders: reminders)
                .preferredColorScheme(.dark)
        }
    }
}
