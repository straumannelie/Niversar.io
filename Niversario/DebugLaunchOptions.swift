#if DEBUG
    import BirthdayKit
    import CoreGraphics
    import Foundation
    import ImageIO
    import UniformTypeIdentifiers

    enum DebugScreen: String {
        case form
        case edit
        case detail
        case day
        case settings
        case list
    }

    nonisolated enum LaunchOptions {
        static var isDemo: Bool {
            ProcessInfo.processInfo.arguments.contains("-demo")
        }

        static var hasNoBirthdayToday: Bool {
            ProcessInfo.processInfo.arguments.contains("-demoNoToday")
        }

        static var searchQuery: String {
            UserDefaults.standard.string(forKey: "search") ?? ""
        }

        static var monthOffset: Int {
            UserDefaults.standard.integer(forKey: "monthOffset")
        }

        static var screen: DebugScreen? {
            UserDefaults.standard.string(forKey: "screen").flatMap(DebugScreen.init(rawValue:))
        }
    }

    enum DemoData {
        static func birthdays(today: Date, calendar: Calendar, photos: PhotoStorage) -> [Birthday] {
            let leaPhoto = makePhoto(in: photos)
            return [
                person(
                    "Léa", inDays: LaunchOptions.hasNoBirthdayToday ? 5 : 0, year: 1996, color: .rose, emoji: "🌸",
                    nickname: "Lélé",
                    note: "Adore les pivoines et le chocolat noir.", photoFileName: leaPhoto, today: today,
                    calendar: calendar),
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
            photoFileName: String? = nil,
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
                note: note,
                photoFileName: photoFileName
            )
        }

        private static func makePhoto(in photos: PhotoStorage) -> String? {
            let width = 960
            let height = 1200
            guard
                let context = CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                ),
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [
                        CGColor(red: 1, green: 0.70, blue: 0.70, alpha: 1),
                        CGColor(red: 0.77, green: 0.70, blue: 1, alpha: 1),
                    ] as CFArray,
                    locations: [0, 1]
                )
            else { return nil }
            context.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: width, y: height),
                options: []
            )
            context.setFillColor(CGColor(red: 1, green: 0.94, blue: 0.64, alpha: 0.9))
            context.fillEllipse(in: CGRect(x: 300, y: 380, width: 360, height: 360))
            context.setFillColor(CGColor(red: 0.31, green: 0.81, blue: 0.63, alpha: 0.8))
            context.fillEllipse(in: CGRect(x: 180, y: 80, width: 600, height: 300))
            guard let image = context.makeImage() else { return nil }
            let png = NSMutableData()
            guard
                let destination = CGImageDestinationCreateWithData(
                    png as CFMutableData,
                    UTType.png.identifier as CFString,
                    1,
                    nil
                )
            else { return nil }
            CGImageDestinationAddImage(destination, image, nil)
            guard CGImageDestinationFinalize(destination),
                let jpeg = try? PhotoResizer.resizedJPEG(from: png as Data)
            else { return nil }
            let fileName = PhotoFileName.make()
            do {
                try FileManager.default.createDirectory(at: photos.directory, withIntermediateDirectories: true)
                try jpeg.write(to: photos.url(for: fileName), options: .atomic)
                return fileName
            } catch {
                return nil
            }
        }
    }
#endif
