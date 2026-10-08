import BirthdayKit
import SwiftUI

struct CalendarDayCell: View {
    let day: Int
    let isToday: Bool
    let birthdays: [Birthday]

    @ScaledMetric(relativeTo: .callout) private var diameter = 36.0

    var body: some View {
        Text(String(day))
            .font(.callout.weight(birthdays.isEmpty ? .regular : .bold))
            .monospacedDigit()
            .foregroundStyle(birthdays.isEmpty ? Color.textPrimary : Color.appBackground)
            .frame(width: diameter, height: diameter)
            .background { background }
            .overlay(alignment: .topTrailing) { counter }
    }

    @ViewBuilder
    private var background: some View {
        if let firstBirthday = birthdays.first {
            Circle()
                .fill(Color(firstBirthday.color))
                .overlay {
                    if isToday {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                            .padding(-3)
                    }
                }
        } else if isToday {
            Circle()
                .fill(Color.accentColor.opacity(0.3))
        }
    }

    @ViewBuilder
    private var counter: some View {
        if birthdays.count > 1 {
            Text(String(birthdays.count))
                .font(.caption2.bold())
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
                .padding(4)
                .background(Color.appSurfaceElevated, in: .circle)
                .offset(x: 8, y: -8)
        }
    }
}
