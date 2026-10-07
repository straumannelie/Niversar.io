import BirthdayKit
import SwiftUI

struct NewBirthdayView: View {
    let onAdd: (Birthday) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var day: Int
    @State private var month: Int
    @State private var year: Int?
    private let years: [Int]

    init(today: Date, calendar: Calendar, onAdd: @escaping (Birthday) -> Void) {
        self.onAdd = onAdd
        _day = State(initialValue: calendar.component(.day, from: today))
        _month = State(initialValue: calendar.component(.month, from: today))
        years = Array((1900...calendar.component(.year, from: today)).reversed())
    }

    private var birthDate: BirthDate? {
        BirthDate(day: day, month: month, year: year)
    }

    private var canAdd: Bool {
        Birthday.normalizedFirstName(firstName) != nil && birthDate != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("C'est qui la prochaine star du gâteau ? 🎂")
                        .font(.title3.bold())
                        .foregroundStyle(Color.textPrimary)
                        .listRowBackground(Color.clear)
                }

                Section("Prénom") {
                    TextField("Prénom", text: $firstName)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                }
                .listRowBackground(Color.appSurface)

                Section {
                    BirthDateWheels(day: $day, month: $month, year: $year, years: years)
                } header: {
                    Text("Date de naissance")
                } footer: {
                    if let year, birthDate == nil {
                        Text("\(String(year)) n'est pas bissextile : choisis une autre année ou « Sans année ».")
                    }
                }
                .listRowBackground(Color.appSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Nouvel anniversaire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter 🎉", action: add)
                        .disabled(!canAdd)
                }
            }
        }
    }

    private func add() {
        guard
            let birthDate,
            let color = PastelColor(month: birthDate.month),
            let birthday = Birthday(firstName: firstName, birthDate: birthDate, color: color)
        else { return }
        onAdd(birthday)
        dismiss()
    }
}
