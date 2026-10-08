import BirthdayKit
import Foundation
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
    let zoomNamespace: Namespace.ID
    let onSelectDay: (SelectedDay) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visibleMonth: CalendarMonth?

    init(
        birthdays: [Birthday],
        currentMonth: CalendarMonth,
        todayDay: Int,
        zoomNamespace: Namespace.ID,
        onSelectDay: @escaping (SelectedDay) -> Void
    ) {
        self.birthdays = birthdays
        self.currentMonth = currentMonth
        self.todayDay = todayDay
        self.zoomNamespace = zoomNamespace
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
                        todayDay: month == currentMonth ? todayDay : nil,
                        zoomNamespace: zoomNamespace
                    ) { day in
                        onSelectDay(SelectedDay(month: month, day: day))
                    }
                    .padding(.horizontal)
                    .containerRelativeFrame(.horizontal)
                    .scrollTransition(.interactive, axis: .horizontal) { [reduceMotion] content, phase in
                        WheelEffect.apply(to: content, progress: reduceMotion ? 0 : phase.value)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
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

private nonisolated enum WheelEffect {
    static let maximumAngleInDegrees = 10.0
    static let axisDistanceBelowCenter = 1_400.0
    static let scaleReduction = 0.08
    static let opacityReduction = 0.4

    static func apply(to content: EmptyVisualEffect, progress: Double) -> some VisualEffect {
        let angleInDegrees = maximumAngleInDegrees * progress
        let dropAlongArc = axisDistanceBelowCenter * (1 - cos(angleInDegrees * .pi / 180))
        return
            content
            .rotationEffect(.degrees(angleInDegrees))
            .offset(y: dropAlongArc)
            .scaleEffect(1 - scaleReduction * abs(progress))
            .opacity(1 - opacityReduction * abs(progress))
    }
}
