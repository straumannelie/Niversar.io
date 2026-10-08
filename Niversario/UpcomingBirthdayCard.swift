import BirthdayKit
import SwiftUI

struct UpcomingBirthdayCard: View {
    let upcoming: UpcomingBirthday

    @ScaledMetric private var dotSize = 12.0
    @ScaledMetric(relativeTo: .title) private var avatarSize = 52.0

    private var pastel: Color {
        Color(upcoming.birthday.color)
    }

    private var isToday: Bool {
        upcoming.daysRemaining == 0
    }

    var body: some View {
        HStack(spacing: 12) {
            PhotoAvatar(birthday: upcoming.birthday, diameter: avatarSize)
            VStack(alignment: .leading, spacing: 4) {
                Text(upcoming.birthday.firstName)
                    .font(.title3.bold())
                    .foregroundStyle(Color.textPrimary)
                Text(upcoming.label)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text(upcoming.birthday.emoji ?? "🎂")
                    .font(.title3)
                Circle()
                    .fill(Color(upcoming.birthday.color))
                    .frame(width: dotSize, height: dotSize)
                    .accessibilityHidden(true)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(pastel.opacity(0.12))
                }
        }
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color("AccentColor"), lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(upcoming.accessibilityLabel)
    }
}

extension View {
    func birthdayTodayGlow(_ isActive: Bool) -> some View {
        compositingGroup()
            .shadow(color: isActive ? Color("AccentColor").opacity(0.5) : .clear, radius: 12)
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
