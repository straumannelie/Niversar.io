import BirthdayKit
import SwiftUI

struct UpcomingBirthdayCard: View {
    let upcoming: UpcomingBirthday

    @ScaledMetric private var dotSize = 12.0

    var body: some View {
        HStack(spacing: 16) {
            Text(upcoming.birthday.emoji ?? "🎂")
                .font(.largeTitle)
            VStack(alignment: .leading, spacing: 4) {
                Text(upcoming.birthday.firstName)
                    .font(.title3.bold())
                    .foregroundStyle(Color.textPrimary)
                Text(upcoming.label)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Circle()
                .fill(Color(upcoming.birthday.color))
                .frame(width: dotSize, height: dotSize)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color.appSurface, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(upcoming.accessibilityLabel)
    }
}

#Preview {
    if let birthDate = BirthDate(day: 1, month: 1, year: 1996),
        let birthday = Birthday(firstName: "Léa", birthDate: birthDate, color: .rose, emoji: "🌸"),
        let upcoming = [birthday].upcoming(limit: 1, from: .now, in: Calendar(identifier: .gregorian)).first
    {
        UpcomingBirthdayCard(upcoming: upcoming)
            .padding()
    }
}
