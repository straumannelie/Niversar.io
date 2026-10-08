import BirthdayKit
import Foundation
import Testing

struct ReminderCase: Sendable, CustomTestStringConvertible {
    let testDescription: String
    let now: Day
    let nowHour: Int
    let nowMinute: Int
    let birthDay: Int
    let birthMonth: Int
    let expected: Day
}

struct ReminderPlannerTests {
    static let cases: [ReminderCase] = [
        ReminderCase(
            testDescription: "Jour J avant 9h00",
            now: Day(2026, 6, 15), nowHour: 8, nowMinute: 59, birthDay: 15, birthMonth: 6,
            expected: Day(2026, 6, 15)
        ),
        ReminderCase(
            testDescription: "Jour J à 9h00 pile",
            now: Day(2026, 6, 15), nowHour: 9, nowMinute: 0, birthDay: 15, birthMonth: 6,
            expected: Day(2027, 6, 15)
        ),
        ReminderCase(
            testDescription: "Jour J après 9h00",
            now: Day(2026, 6, 15), nowHour: 9, nowMinute: 1, birthDay: 15, birthMonth: 6,
            expected: Day(2027, 6, 15)
        ),
        ReminderCase(
            testDescription: "Veille au soir",
            now: Day(2026, 6, 14), nowHour: 23, nowMinute: 59, birthDay: 15, birthMonth: 6,
            expected: Day(2026, 6, 15)
        ),
        ReminderCase(
            testDescription: "31 décembre, anniversaire le 1er janvier",
            now: Day(2026, 12, 31), nowHour: 10, nowMinute: 0, birthDay: 1, birthMonth: 1,
            expected: Day(2027, 1, 1)
        ),
        ReminderCase(
            testDescription: "31 décembre après 9h00, anniversaire le 31 décembre",
            now: Day(2026, 12, 31), nowHour: 10, nowMinute: 0, birthDay: 31, birthMonth: 12,
            expected: Day(2027, 12, 31)
        ),
        ReminderCase(
            testDescription: "29 février en année bissextile",
            now: Day(2028, 2, 1), nowHour: 12, nowMinute: 0, birthDay: 29, birthMonth: 2,
            expected: Day(2028, 2, 29)
        ),
        ReminderCase(
            testDescription: "29 février en année non bissextile",
            now: Day(2027, 2, 1), nowHour: 12, nowMinute: 0, birthDay: 29, birthMonth: 2,
            expected: Day(2027, 2, 28)
        ),
        ReminderCase(
            testDescription: "Né un 29 février, le 28 février d'une année non bissextile après 9h00",
            now: Day(2027, 2, 28), nowHour: 10, nowMinute: 0, birthDay: 29, birthMonth: 2,
            expected: Day(2028, 2, 29)
        ),
        ReminderCase(
            testDescription: "Jour du passage à l'heure d'été",
            now: Day(2026, 3, 28), nowHour: 12, nowMinute: 0, birthDay: 29, birthMonth: 3,
            expected: Day(2026, 3, 29)
        ),
        ReminderCase(
            testDescription: "Jour du passage à l'heure d'été, avant 9h00 le jour même",
            now: Day(2026, 3, 29), nowHour: 8, nowMinute: 30, birthDay: 29, birthMonth: 3,
            expected: Day(2026, 3, 29)
        ),
        ReminderCase(
            testDescription: "Jour du passage à l'heure d'hiver",
            now: Day(2026, 10, 24), nowHour: 12, nowMinute: 0, birthDay: 25, birthMonth: 10,
            expected: Day(2026, 10, 25)
        ),
    ]

    @Test("Prochain rappel à 9h00", arguments: cases)
    func nextReminderAtNine(_ reminderCase: ReminderCase) throws {
        let lisbon = try Lisbon()
        let now = try lisbon.date(reminderCase.now, hour: reminderCase.nowHour, minute: reminderCase.nowMinute)
        let person = try birthday("Zoé", birthDate(reminderCase.birthDay, reminderCase.birthMonth))

        let plan = ReminderPlanner.plan(for: [person], now: now, calendar: lisbon.calendar)

        let reminder = try #require(plan.reminders.first)
        let expected = reminderCase.expected
        #expect(plan.reminders.count == 1)
        #expect(plan.unschedulable.isEmpty)
        #expect(
            reminder.dateComponents
                == DateComponents(year: expected.year, month: expected.month, day: expected.day, hour: 9, minute: 0)
        )
        #expect(lisbon.day(of: reminder.date) == expected)
        #expect(lisbon.calendar.component(.hour, from: reminder.date) == 9)
        #expect(lisbon.calendar.component(.minute, from: reminder.date) == 0)
        #expect(reminder.date > now)
        #expect(reminder.birthday == person)
        #expect(reminder.title == "Anniversaire 🎂")
        #expect(reminder.body.contains("Zoé"))
    }

    @Test("Limite de 64 avec 70 personnes : les 64 plus proches, triées par date")
    func keepsTheClosestSixtyFour() throws {
        let lisbon = try Lisbon()
        let now = try lisbon.date(Day(2026, 1, 1), hour: 12)
        let people = try (1...70).map { offset in
            let date = try #require(lisbon.calendar.date(byAdding: .day, value: offset, to: now))
            let day = lisbon.day(of: date)
            return try birthday("Personne \(offset)", birthDate(day.day, day.month))
        }

        let plan = ReminderPlanner.plan(for: people.reversed(), now: now, calendar: lisbon.calendar)

        #expect(plan.reminders.count == 64)
        #expect(plan.reminders.map(\.birthday.firstName) == (1...64).map { "Personne \($0)" })
        #expect(zip(plan.reminders, plan.reminders.dropFirst()).allSatisfy { $0.date <= $1.date })
        #expect(plan.unschedulable.isEmpty)
    }

    @Test("Tri par date, une seule occurrence par personne")
    func sortedWithOneReminderPerPerson() throws {
        let lisbon = try Lisbon()
        let people = [
            try birthday("Adam", birthDate(1, 1)),
            try birthday("Lina", birthDate(20, 6)),
            try birthday("Noé", birthDate(16, 6)),
        ]

        let plan = ReminderPlanner.plan(
            for: people,
            now: try lisbon.date(Day(2026, 6, 15)),
            calendar: lisbon.calendar
        )

        #expect(plan.reminders.map(\.birthday.firstName) == ["Noé", "Lina", "Adam"])
        #expect(
            plan.reminders.map { lisbon.day(of: $0.date) } == [Day(2026, 6, 16), Day(2026, 6, 20), Day(2027, 1, 1)])
    }

    @Test("Identifiants uniques, même pour des personnes nées le même jour, et stables")
    func identifiersAreUniqueAndStable() throws {
        let lisbon = try Lisbon()
        let people = try ["Adam", "Lina", "Noé"].map { try birthday($0, birthDate(20, 6)) }

        let january = ReminderPlanner.plan(
            for: people, now: try lisbon.date(Day(2026, 1, 1)), calendar: lisbon.calendar)
        let march = ReminderPlanner.plan(for: people, now: try lisbon.date(Day(2026, 3, 1)), calendar: lisbon.calendar)

        #expect(Set(january.reminders.map(\.id)).count == 3)
        #expect(Set(january.reminders.map(\.id)) == Set(march.reminders.map(\.id)))
    }

    @Test("L'identifiant change avec l'année du rappel")
    func identifierDependsOnYear() throws {
        let lisbon = try Lisbon()
        let person = try birthday("Zoé", birthDate(15, 6))

        let before = ReminderPlanner.plan(
            for: [person], now: try lisbon.date(Day(2026, 6, 1)), calendar: lisbon.calendar)
        let after = ReminderPlanner.plan(
            for: [person], now: try lisbon.date(Day(2026, 7, 1)), calendar: lisbon.calendar)

        #expect(before.reminders.map(\.id) != after.reminders.map(\.id))
    }

    @Test("Liste vide : aucun rappel")
    func emptyList() throws {
        let lisbon = try Lisbon()

        let plan = ReminderPlanner.plan(for: [], now: try lisbon.date(Day(2026, 6, 15)), calendar: lisbon.calendar)

        #expect(plan.reminders.isEmpty)
        #expect(plan.unschedulable.isEmpty)
    }

    @Test(
        "Autre heure de rappel : jour J avant et après l'heure",
        arguments: [
            (7, 30, 7, 29, 2026),
            (7, 30, 7, 30, 2027),
            (7, 30, 8, 0, 2027),
            (21, 0, 9, 0, 2026),
            (21, 0, 20, 59, 2026),
            (21, 0, 21, 0, 2027),
            (21, 0, 22, 15, 2027),
        ]
    )
    func customReminderTime(hour: Int, minute: Int, nowHour: Int, nowMinute: Int, expectedYear: Int) throws {
        let lisbon = try Lisbon()
        let now = try lisbon.date(Day(2026, 6, 15), hour: nowHour, minute: nowMinute)
        let person = try birthday("Zoé", birthDate(15, 6))

        let plan = ReminderPlanner.plan(
            for: [person],
            now: now,
            calendar: lisbon.calendar,
            time: TimeOfDay(hour: hour, minute: minute)
        )

        let reminder = try #require(plan.reminders.first)
        #expect(
            reminder.dateComponents
                == DateComponents(year: expectedYear, month: 6, day: 15, hour: hour, minute: minute)
        )
        #expect(lisbon.calendar.component(.hour, from: reminder.date) == hour)
        #expect(lisbon.calendar.component(.minute, from: reminder.date) == minute)
        #expect(reminder.date > now)
    }

    @Test(
        "Heure du rappel en minutes depuis minuit",
        arguments: [(540, 9, 0), (450, 7, 30), (1260, 21, 0), (0, 0, 0), (1439, 23, 59), (1440, 0, 0), (-30, 23, 30)]
    )
    func timeOfDayFromMinutes(minutes: Int, expectedHour: Int, expectedMinute: Int) {
        let time = TimeOfDay(minutesSinceMidnight: minutes)

        #expect(time == TimeOfDay(hour: expectedHour, minute: expectedMinute))
        #expect(TimeOfDay(minutesSinceMidnight: time.minutesSinceMidnight) == time)
    }

    @Test("Heure par défaut : 9h00")
    func defaultTime() {
        #expect(ReminderPlanner.defaultTime.minutesSinceMidnight == 540)
    }
}
