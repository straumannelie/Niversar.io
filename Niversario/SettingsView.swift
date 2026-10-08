import BirthdayKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

struct SettingsView: View {
    static let reminderTimeKey = "reminderMinutesSinceMidnight"
    private static let sourceCodeURL = URL(string: "https://github.com/straumannelie/Niversar.io")

    let store: BirthdayStore
    let reminders: ReminderScheduler
    let today: Date
    let calendar: Calendar

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(SettingsView.reminderTimeKey) private var reminderMinutes =
        ReminderPlanner.defaultTime.minutesSinceMidnight
    @State private var isImportingBackup = false
    @State private var pendingImport: [Birthday]?
    @State private var importMessage: StorageAlert?

    var body: some View {
        NavigationStack {
            Form {
                notificationsSection
                reminderTimeSection
                backupSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
            .fileImporter(isPresented: $isImportingBackup, allowedContentTypes: [.json]) { result in
                readBackup(result)
            }
            .alert(
                BirthdayMerge.confirmationQuestion(importedCount: pendingImport?.count ?? 0),
                isPresented: isConfirmingImport,
                presenting: pendingImport
            ) { imported in
                Button("Importer") {
                    importBackup(imported)
                }
                Button("Annuler", role: .cancel) {}
            } message: { _ in
                Text("Les nouvelles personnes sont ajoutées, celles déjà présentes sont mises à jour.")
            }
            .task {
                await reminders.refreshAuthorizationStatus()
            }
        }
        .alert(
            importMessage?.title ?? "",
            isPresented: isShowingImportMessage,
            presenting: importMessage
        ) { _ in
            Button("OK") {}
        } message: { message in
            Text(message.message)
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            LabeledContent("État", value: notificationStatus)
            Button("Ouvrir les réglages de notification", systemImage: "gear") {
                guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
                openURL(url)
            }
        }
        .listRowBackground(Color.appSurface)
    }

    private var reminderTimeSection: some View {
        Section {
            DatePicker("Heure", selection: reminderTime, displayedComponents: .hourAndMinute)
                .environment(\.locale, Locale(identifier: "fr_FR"))
        } header: {
            Text("Heure du rappel")
        } footer: {
            Text("Chaque anniversaire est rappelé le jour J à cette heure.")
        }
        .listRowBackground(Color.appSurface)
    }

    private var backupSection: some View {
        Section {
            ShareLink(
                item: BirthdayBackup(
                    birthdays: store.birthdays,
                    fileName: BirthdayArchive.backupFileName(on: today, in: calendar)
                ),
                preview: SharePreview("Sauvegarde Niversar.io")
            ) {
                Label("Exporter une sauvegarde", systemImage: "square.and.arrow.up")
            }
            .disabled(store.birthdays.isEmpty)
            Button("Importer une sauvegarde", systemImage: "square.and.arrow.down") {
                isImportingBackup = true
            }
        } header: {
            Text("Sauvegarde")
        } footer: {
            Text("Fichier JSON au format de l'app, sans les photos.")
        }
        .disabled(!store.isLoaded)
        .listRowBackground(Color.appSurface)
    }

    private var aboutSection: some View {
        Section("À propos") {
            LabeledContent("Version", value: appVersion)
            if let sourceCodeURL = Self.sourceCodeURL {
                Link(destination: sourceCodeURL) {
                    Label("Code source sur GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
        }
        .listRowBackground(Color.appSurface)
    }

    private var notificationStatus: String {
        switch reminders.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            "Activées"
        case .denied:
            "Désactivées"
        case .notDetermined:
            "Pas encore demandées"
        @unknown default:
            "Inconnu"
        }
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                let time = TimeOfDay(minutesSinceMidnight: reminderMinutes)
                return calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: today) ?? today
            },
            set: { date in
                let time = TimeOfDay(
                    hour: calendar.component(.hour, from: date),
                    minute: calendar.component(.minute, from: date)
                )
                reminderMinutes = time.minutesSinceMidnight
            }
        )
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func readBackup(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            pendingImport = try BirthdayArchive(data: Data(contentsOf: url)).birthdays
        } catch {
            importMessage = StorageAlert(
                title: "Import impossible",
                message: "\(error.localizedDescription) Rien n'a été modifié."
            )
        }
    }

    private func importBackup(_ imported: [Birthday]) {
        guard let merge = store.importBirthdays(imported) else { return }
        importMessage = StorageAlert(title: "Import terminé", message: merge.summary)
    }

    private var isConfirmingImport: Binding<Bool> {
        Binding(
            get: { pendingImport != nil },
            set: { isPresented in
                if !isPresented {
                    pendingImport = nil
                }
            }
        )
    }

    private var isShowingImportMessage: Binding<Bool> {
        Binding(
            get: { importMessage != nil },
            set: { isPresented in
                if !isPresented {
                    importMessage = nil
                }
            }
        )
    }
}
