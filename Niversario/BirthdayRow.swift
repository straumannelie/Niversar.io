import BirthdayKit
import SwiftUI

struct BirthdayRow: View {
    let upcoming: UpcomingBirthday

    @ScaledMetric private var dotSize = 10.0

    var body: some View {
        HStack(spacing: 12) {
            Text(upcoming.birthday.emoji ?? "🎂")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(upcoming.birthday.firstName)
                    .font(.body.bold())
                    .foregroundStyle(Color.textPrimary)
                Text(upcoming.label)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Circle()
                .fill(Color(upcoming.birthday.color))
                .frame(width: dotSize, height: dotSize)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}
