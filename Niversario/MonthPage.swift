import BirthdayKit
import SwiftUI

struct MonthPage: View {
    let month: CalendarMonth
    let birthdaysByDay: [Int: [Birthday]]
    let todayDay: Int?
    let zoomNamespace: Namespace.ID
    let onSelectDay: (Int) -> Void

    private static let displayedWeekCount = 6

    var body: some View {
        let weeks = month.weeks

        VStack(alignment: .leading, spacing: 12) {
            Text(month.title)
                .font(.title2.bold())
                .foregroundStyle(Color(month.color))
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 0) {
                ForEach(Array(CalendarMonth.weekdayInitials.enumerated()), id: \.offset) { _, initial in
                    Text(initial)
                        .font(.caption.bold())
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                ForEach(0..<Self.displayedWeekCount, id: \.self) { weekIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { weekdayIndex in
                            dayView(Self.day(in: weeks, week: weekIndex, weekday: weekdayIndex))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.appSurface, in: .rect(cornerRadius: 24))
    }

    @ViewBuilder
    private func dayView(_ day: Int?) -> some View {
        if let day {
            let birthdays = birthdaysByDay[day] ?? []
            let cell = CalendarDayCell(day: day, isToday: day == todayDay, birthdays: birthdays)
            if birthdays.isEmpty {
                cell
            } else {
                Button {
                    onSelectDay(day)
                } label: {
                    cell
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: ZoomSource.day(month, day), in: zoomNamespace)
                .accessibilityLabel(month.birthdayAccessibilityLabel(day: day, firstNames: birthdays.map(\.firstName)))
            }
        } else {
            CalendarDayCell(day: 0, isToday: false, birthdays: [])
                .hidden()
        }
    }

    private static func day(in weeks: [[Int?]], week: Int, weekday: Int) -> Int? {
        guard weeks.indices.contains(week), weeks[week].indices.contains(weekday) else { return nil }
        return weeks[week][weekday]
    }
}
