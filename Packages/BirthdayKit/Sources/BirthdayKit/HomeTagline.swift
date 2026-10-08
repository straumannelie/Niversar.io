import Foundation

public enum HomeTagline {
    public static func text(for birthdays: [Birthday], today: Date, calendar: Calendar) -> String {
        guard let next = birthdays.upcoming(limit: 1, from: today, in: calendar).first else {
            return "C'est qui la prochaine star du gâteau ? 🎂"
        }
        switch next.daysRemaining {
        case 0:
            return "🎉 C'est le jour J 🎉"
        case 1:
            return "🎂 demain"
        default:
            return "🎂 dans \(next.daysRemaining) jours"
        }
    }
}
