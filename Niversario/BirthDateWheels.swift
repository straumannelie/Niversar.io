import BirthdayKit
import SwiftUI

struct BirthDateWheels: View {
    @Binding var day: Int
    @Binding var month: Int
    @Binding var year: Int?
    let years: [Int]

    private static let monthNames: [String] = {
        let locale = Locale(identifier: "fr_FR")
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar.standaloneMonthSymbols.map { $0.capitalized(with: locale) }
    }()

    var body: some View {
        HStack(spacing: 0) {
            Picker("Jour", selection: $day) {
                ForEach(1...BirthDate.maximumDay(inMonth: month), id: \.self) { day in
                    Text(String(day)).tag(day)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()

            Picker("Mois", selection: $month) {
                ForEach(Array(Self.monthNames.enumerated()), id: \.offset) { index, name in
                    Text(name).tag(index + 1)
                }
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
            .clipped()

            Picker("Année", selection: $year) {
                Text("Sans année").tag(Int?.none)
                ForEach(years, id: \.self) { year in
                    Text(String(year)).tag(Int?.some(year))
                }
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
            .clipped()
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .onChange(of: month) {
            day = min(day, BirthDate.maximumDay(inMonth: month))
        }
    }
}
