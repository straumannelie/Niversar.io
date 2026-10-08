import BirthdayKit
import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class ReminderScheduler {
    static let testIdentifierPrefix = "debug-test-"

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var unschedulableNames: [String] = []
    private(set) var failedNames: [String] = []

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
        unschedulableNames = plan.unschedulable.map(\.firstName)

        let pendingIdentifiers = await center.pendingNotificationRequests().map(\.identifier)
        center.removePendingNotificationRequests(
            withIdentifiers: pendingIdentifiers.filter { !$0.hasPrefix(Self.testIdentifierPrefix) }
        )

        await refreshAuthorizationStatus()
        guard canSchedule else {
            failedNames = []
            return
        }
        var failed: [String] = []
        for reminder in plan.reminders {
            guard !Task.isCancelled else { return }
            do {
                try await center.add(Self.request(for: reminder))
            } catch {
                failed.append(reminder.birthday.firstName)
            }
        }
        failedNames = failed
    }

    private static func request(for reminder: Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.dateComponents, repeats: false)
        return UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
    }

    #if DEBUG
        func pendingReminders() async -> [PendingReminder] {
            await UNUserNotificationCenter.current().pendingNotificationRequests()
                .map(PendingReminder.init)
                .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
        }

        func scheduleTest(for birthday: Birthday, now: Date) async throws {
            await requestAuthorizationIfNeeded()
            let content = UNMutableNotificationContent()
            content.title = ReminderPlanner.title
            content.body = ReminderMessage.body(for: birthday, year: calendar.component(.year, from: now))
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            let identifier = Self.testIdentifierPrefix + UUID().uuidString
            try await UNUserNotificationCenter.current()
                .add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    #endif
}

#if DEBUG
    struct PendingReminder: Identifiable {
        let id: String
        let date: Date?
        let body: String

        init(request: UNNotificationRequest) {
            id = request.identifier
            body = request.content.body
            date =
                (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                ?? (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
        }
    }
#endif
