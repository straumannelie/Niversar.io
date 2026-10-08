import SwiftUI
import UIKit

struct StoredPhoto<Placeholder: View>: View {
    let fileName: String?
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: fileName) {
            guard let fileName else {
                image = nil
                return
            }
            image = await PhotoStorage.live.loadPhotoData(fileName).flatMap(UIImage.init(data:))
        }
    }
}
