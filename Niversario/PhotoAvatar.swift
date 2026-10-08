import BirthdayKit
import SwiftUI
import UIKit

@MainActor
final class PhotoThumbnailCache {
    static let shared = PhotoThumbnailCache()

    private let images = NSCache<NSString, UIImage>()

    func cachedImage(for fileName: String, shortSidePixelSize: Int) -> UIImage? {
        images.object(forKey: Self.key(fileName, shortSidePixelSize))
    }

    func image(for fileName: String, shortSidePixelSize: Int, scale: CGFloat) async -> UIImage? {
        if let cached = cachedImage(for: fileName, shortSidePixelSize: shortSidePixelSize) {
            return cached
        }
        guard let cgImage = await PhotoStorage.live.thumbnail(fileName, shortSidePixelSize: shortSidePixelSize) else {
            return nil
        }
        let image = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
        images.setObject(image, forKey: Self.key(fileName, shortSidePixelSize))
        return image
    }

    private static func key(_ fileName: String, _ shortSidePixelSize: Int) -> NSString {
        "\(fileName)@\(shortSidePixelSize)" as NSString
    }
}

struct PhotoAvatar: View {
    let birthday: Birthday
    let diameter: CGFloat

    @Environment(\.displayScale) private var displayScale
    @State private var loadedImage: UIImage?

    private var shortSidePixelSize: Int {
        Int((diameter * displayScale).rounded(.up))
    }

    var body: some View {
        let image =
            loadedImage
            ?? birthday.photoFileName.flatMap {
                PhotoThumbnailCache.shared.cachedImage(for: $0, shortSidePixelSize: shortSidePixelSize)
            }

        ZStack {
            Circle()
                .fill(Color(birthday.color))
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: diameter, height: diameter)
                    .clipShape(.circle)
            } else {
                Text(String(birthday.firstName.prefix(1)).uppercased())
                    .font(.title2.bold())
                    .foregroundStyle(Color.appBackground)
            }
        }
        .frame(width: diameter, height: diameter)
        .overlay {
            Circle()
                .strokeBorder(Color(birthday.color), lineWidth: 2.5)
        }
        .accessibilityHidden(true)
        .task(id: "\(birthday.photoFileName ?? "")@\(shortSidePixelSize)") {
            guard let fileName = birthday.photoFileName else {
                loadedImage = nil
                return
            }
            loadedImage = await PhotoThumbnailCache.shared.image(
                for: fileName,
                shortSidePixelSize: shortSidePixelSize,
                scale: displayScale
            )
        }
    }
}
