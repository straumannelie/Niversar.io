import BirthdayKit
import SwiftUI

struct SelectedDay: Identifiable, Hashable {
    let month: CalendarMonth
    let day: Int

    var id: Self { self }
}

struct BirthdayCalendar: View {
    let birthdays: [Birthday]
    let currentMonth: CalendarMonth
    let todayDay: Int
    let onSelectDay: (SelectedDay) -> Void

    @State private var visibleMonth: CalendarMonth?

    init(
        birthdays: [Birthday],
        currentMonth: CalendarMonth,
        todayDay: Int,
        onSelectDay: @escaping (SelectedDay) -> Void
    ) {
        self.birthdays = birthdays
        self.currentMonth = currentMonth
        self.todayDay = todayDay
        self.onSelectDay = onSelectDay
        _visibleMonth = State(initialValue: currentMonth)
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(currentMonth.surrounding(), id: \.self) { month in
                    MonthPage(
                        month: month,
                        birthdaysByDay: month.birthdaysByDay(birthdays),
                        todayDay: month == currentMonth ? todayDay : nil
                    ) { day in
                        onSelectDay(SelectedDay(month: month, day: day))
                    }
                    .padding(.horizontal)
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $visibleMonth)
        .sensoryFeedback(.selection, trigger: visibleMonth) { oldMonth, newMonth in
            oldMonth != nil && newMonth != nil
        }
        .overlay(alignment: .topTrailing) {
            if let visibleMonth, visibleMonth != currentMonth {
                Button("Aujourd'hui") {
                    withAnimation {
                        self.visibleMonth = currentMonth
                    }
                }
                .buttonStyle(.glass)
                .controlSize(.small)
                .padding(.top, 10)
                .padding(.trailing, 28)
            }
        }
    }
}
