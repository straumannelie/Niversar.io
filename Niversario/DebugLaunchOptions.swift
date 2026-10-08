#if DEBUG
    import BirthdayKit
    import Foundation

    enum DebugScreen: String {
        case form
        case edit
        case detail
        case day
    }

    enum LaunchOptions {
        static var isDemo: Bool {
            ProcessInfo.processInfo.arguments.contains("-demo")
        }

        static var hasNoBirthdayToday: Bool {
            ProcessInfo.processInfo.arguments.contains("-demoNoToday")
        }

        static var monthOffset: Int {
            UserDefaults.standard.integer(forKey: "monthOffset")
        }

        static var screen: DebugScreen? {
            UserDefaults.standard.string(forKey: "screen").flatMap(DebugScreen.init(rawValue:))
        }
    }

    enum DemoData {
        static func birthdays(today: Date, calendar: Calendar) -> [Birthday] {
            [
                person(
                    "Léa", inDays: LaunchOptions.hasNoBirthdayToday ? 5 : 0, year: 1996, color: .rose, emoji: "🌸",
                    nickname: "Lélé",
                    note: "Adore les pivoines et le chocolat noir.", today: today, calendar: calendar),
                person(
                    "Hugo", inDays: 3, year: nil, color: .sky, emoji: nil, nickname: nil,
                    note: nil, today: today, calendar: calendar),
                person(
                    "Inès", inDays: 12, year: 2000, color: .lavender, emoji: "🦋", nickname: nil,
                    note: nil, today: today, calendar: calendar),
                person(
                    "Noah", inDays: 12, year: 1988, color: .mint, emoji: "🎸", nickname: "Noé",
                    note: "Fan de jazz manouche.", today: today, calendar: calendar),
                person(
                    "Zoé", inDays: 40, year: 1992, color: .peach, emoji: "☕️", nickname: nil,
                    note: nil, today: today, calendar: calendar),
            ]
            .compactMap { $0 }
        }

        private static func person(
            _ firstName: String,
            inDays days: Int,
            year: Int?,
            color: PastelColor,
            emoji: String?,
            nickname: String?,
            note: String?,
            today: Date,
            calendar: Calendar
        ) -> Birthday? {
            guard let date = calendar.date(byAdding: .day, value: days, to: today),
                let birthDate = BirthDate(
                    day: calendar.component(.day, from: date),
                    month: calendar.component(.month, from: date),
                    year: year
                )
            else { return nil }
            return Birthday(
                firstName: firstName,
                birthDate: birthDate,
                color: color,
                emoji: emoji,
                nickname: nickname,
                note: note
            )
        }
    }
#endif
