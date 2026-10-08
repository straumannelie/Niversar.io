import BirthdayKit
import SwiftUI

extension Color {
    init(_ pastelColor: PastelColor) {
        switch pastelColor {
        case .rose: self.init(hex: 0xFFB3B3)
        case .peach: self.init(hex: 0xFFD4A3)
        case .lemon: self.init(hex: 0xFFF0A3)
        case .mint: self.init(hex: 0xB3F0B3)
        case .sky: self.init(hex: 0xA3D4FF)
        case .lavender: self.init(hex: 0xC4B3FF)
        case .orchid: self.init(hex: 0xFFB3E6)
        case .aqua: self.init(hex: 0xB3FFF0)
        case .blush: self.init(hex: 0xFFB3C6)
        case .lime: self.init(hex: 0xD4FFB3)
        case .periwinkle: self.init(hex: 0xB3C6FF)
        case .apricot: self.init(hex: 0xFFE0B3)
        }
    }

    private init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension PastelColor {
    var displayName: String {
        switch self {
        case .rose: "Rose"
        case .peach: "Pêche"
        case .lemon: "Citron"
        case .mint: "Menthe"
        case .sky: "Ciel"
        case .lavender: "Lavande"
        case .orchid: "Orchidée"
        case .aqua: "Aqua"
        case .blush: "Rose poudré"
        case .lime: "Citron vert"
        case .periwinkle: "Pervenche"
        case .apricot: "Abricot"
        }
    }
}
