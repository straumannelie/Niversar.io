import BirthdayKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

struct ContentView: View {
    let store: BirthdayStore
    let reminders: ReminderScheduler

    @Environment(\.scenePhase) private var scenePhase
    @State private var today = Date.now
    @State private var isAddingBirthday = false
    @State private var selectedDay: SelectedDay?
    @State private var presentedBirthday: PresentedBirthday?
    @State private var addedBirthdaysCount = 0
    @State private var isImportingBackup = false
    @State private var pendingImport: [Birthday]?
    @State private var importMessage: StorageAlert?
    @Namespace private var zoomNamespace
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
            .background(Color.appBackground)
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
            .navigationTitle("Niversar.io")
            .toolbar {
                ToolbarItem(placement: .largeTitle) {
                    title
                }
                ToolbarItem(placement: .topBarTrailing) {
                    backupMenu
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
            .sheet(item: $presentedBirthday) { presented in
                BirthdayDetailView(birthdayID: presented.id, store: store, today: today, calendar: calendar)
                    .zoomTransition(from: presented.source, in: zoomNamespace)
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

    private func select(_ day: SelectedDay) {
        let people = day.month.birthdaysByDay(store.birthdays)[day.day] ?? []
        if people.count == 1, let person = people.first {
            presentedBirthday = PresentedBirthday(id: person.id, source: .day(day.month, day.day))
        } else {
            selectedDay = day
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

    private var backupMenu: some View {
        Menu("Plus d'options", systemImage: "ellipsis") {
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
        }
        .disabled(!store.isLoaded)
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
