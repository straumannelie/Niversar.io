import Foundation

public enum ReminderMessage {
    static let templates = [
        "🎉🥳 C'est l'anniversaire de [Prénom] [Emoji] aujourd'hui !",
        "🎉🥳 [Prénom] [Emoji] souffle ses bougies aujourd'hui, pense à lui écrire !",
        "🎉🥳 Aujourd'hui c'est le jour de [Prénom] [Emoji], tu sais ce qu'il te reste à faire !",
        "🎉🥳 [Prénom] [Emoji] a un an de plus aujourd'hui !",
        "🎉🥳 Happy birthday [Prénom] [Emoji], don't forget to wish them well !",
        "🎉🥳 [Prénom] [Emoji] devient plus vieux aujourd'hui... pense à le lui rappeler !",
        "🎉🥳 Alerte gâteau : [Prénom] [Emoji] fête son anniversaire aujourd'hui !",
        "🎉🥳 Breaking news : [Prénom] [Emoji] a survécu à une année de plus. Envoie-lui un message !",
        "🎉🥳 Mission du jour : souhaiter un joyeux anniversaire à [Prénom] [Emoji]. "
            + "Ce message s'autodétruira à minuit.",
        "🎉🥳 Hoje é o dia de [Prénom] [Emoji] ! Parabéns, et pense à lui écrire !",
    ]

    public static func body(for birthday: Birthday, year: Int) -> String {
        let template = templates[templateIndex(id: birthday.id, year: year)]
        return render(template, firstName: birthday.firstName, emoji: birthday.emoji)
    }

    static func templateIndex(id: UUID, year: Int) -> Int {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in "\(id.uuidString)-\(year)".utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100_0000_01b3
        }
        return Int(hash % UInt64(templates.count))
    }

    static func render(_ template: String, firstName: String, emoji: String?) -> String {
        let trimmedEmoji = emoji?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let withEmoji =
            trimmedEmoji.isEmpty
            ? template.replacingOccurrences(of: " [Emoji]", with: "")
            : template.replacingOccurrences(of: "[Emoji]", with: trimmedEmoji)
        return withEmoji.replacingOccurrences(of: "[Prénom]", with: firstName)
    }
}
