import BirthdayKit
import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class ReminderScheduler {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private var rescheduling: Task<Void, Never>?
    private let calendar = Calendar(identifier: .gregorian)

    var isDenied: Bool {
        authorizationStatus == .denied
    }

    private var canSchedule: Bool {
        [.authorized, .provisional, .ephemeral].contains(authorizationStatus)
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorizationIfNeeded() async {
        await refreshAuthorizationStatus()
        guard authorizationStatus == .notDetermined else { return }
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        await refreshAuthorizationStatus()
    }

    func reschedule(_ birthdays: [Birthday], now: Date, time: TimeOfDay) async {
        let previous = rescheduling
        previous?.cancel()
        let task = Task {
            await previous?.value
            await replacePendingReminders(with: birthdays, now: now, time: time)
        }
        rescheduling = task
        await task.value
    }

    private func replacePendingReminders(with birthdays: [Birthday], now: Date, time: TimeOfDay) async {
        guard !Task.isCancelled else { return }
        let center = UNUserNotificationCenter.current()
        let plan = ReminderPlanner.plan(for: birthdays, now: now, calendar: calendar, time: time)
        center.removeAllPendingNotificationRequests()

        await refreshAuthorizationStatus()
        guard canSchedule else { return }
        for reminder in plan.reminders {
            guard !Task.isCancelled else { return }
            try? await center.add(Self.request(for: reminder))
        }
    }

    private static func request(for reminder: Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.dateComponents, repeats: false)
        return UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
    }
}
