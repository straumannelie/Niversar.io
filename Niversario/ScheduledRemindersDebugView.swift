#if DEBUG
    import BirthdayKit
    import SwiftUI

    struct ScheduledRemindersDebugView: View {
        let reminders: ReminderScheduler
        let birthdays: [Birthday]

        @Environment(\.dismiss) private var dismiss
        @State private var pending: [PendingReminder] = []
        @State private var testMessage: String?

        var body: some View {
            NavigationStack {
                List {
                    Section {
                        Button("Tester dans 1 minute") {
                            Task { await scheduleTest() }
                        }
                        .disabled(birthdays.isEmpty)
                    } footer: {
                        if let testMessage {
                            Text(testMessage)
                        }
                    }

                    if !reminders.unschedulableNames.isEmpty || !reminders.failedNames.isEmpty {
                        Section("Problèmes") {
                            ForEach(reminders.unschedulableNames, id: \.self) { name in
                                Text("Date non calculable : \(name)")
                            }
                            ForEach(reminders.failedNames, id: \.self) { name in
                                Text("Programmation refusée : \(name)")
                            }
                        }
                    }

                    Section("\(pending.count) rappels programmés") {
                        ForEach(pending) { reminder in
                            VStack(alignment: .leading, spacing: 4) {
                                if let date = reminder.date {
                                    Text(
                                        date, format: .dateTime.weekday(.wide).day().month(.wide).year().hour().minute()
                                    )
                                    .font(.subheadline.bold())
                                }
                                Text(reminder.body)
                                    .font(.footnote)
                                    .foregroundStyle(Color.textSecondary)
                            }
                        }
                    }
                }
                .navigationTitle("Rappels programmés")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                }
                .task {
                    pending = await reminders.pendingReminders()
                }
            }
        }

        private func scheduleTest() async {
            guard let birthday = birthdays.randomElement() else { return }
            do {
                try await reminders.scheduleTest(for: birthday, now: .now)
                testMessage = "Rappel de \(birthday.firstName) programmé dans 1 minute."
            } catch {
                testMessage = "Échec : \(error.localizedDescription)"
            }
            pending = await reminders.pendingReminders()
        }
    }
#endif
