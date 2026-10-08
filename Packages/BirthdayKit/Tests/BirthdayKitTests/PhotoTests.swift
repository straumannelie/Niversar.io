import BirthdayKit
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

struct PhotoTests {
    @Test(
        "Réduction à 1200 px sur le plus grand côté, en JPEG",
        arguments: [(3000, 2000, 1200, 800), (2000, 3000, 800, 1200), (1200, 1200, 1200, 1200), (800, 600, 800, 600)]
    )
    func resizesToMaximumPixelSize(width: Int, height: Int, expectedWidth: Int, expectedHeight: Int) throws {
        let png = try Self.pngImage(width: width, height: height)

        let jpeg = try PhotoResizer.resizedJPEG(from: png)

        let source = try #require(CGImageSourceCreateWithData(jpeg as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(CGImageSourceGetType(source) as String? == UTType.jpeg.identifier)
        #expect(image.width == expectedWidth)
        #expect(image.height == expectedHeight)
    }

    @Test("Données qui ne sont pas une image : erreur")
    func unreadableImage() {
        #expect(throws: PhotoResizerError.unreadableImage) {
            try PhotoResizer.resizedJPEG(from: Data("pas une image".utf8))
        }
    }

    @Test("Nom de fichier généré : UUID.jpg, différent à chaque fois")
    func generatedFileName() {
        let first = PhotoFileName.make()
        let second = PhotoFileName.make()

        #expect(PhotoFileName.isValid(first))
        #expect(first.hasSuffix(".jpg"))
        #expect(first != second)
    }

    @Test("Orphelins : photos non référencées, autres fichiers ignorés")
    func orphans() throws {
        let referenced = PhotoFileName.make()
        let orphan = PhotoFileName.make()
        let zoe = try #require(
            Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .rose, photoFileName: referenced)
        )
        let adam = try birthday("Adam", birthDate(1, 1))

        let orphans = PhotoFileName.orphans(
            among: [referenced, orphan, ".DS_Store", "notes.txt", "photo.jpg"],
            referencedBy: [zoe, adam]
        )

        #expect(orphans == [orphan])
    }

    @Test("Orphelins : aucune personne, toutes les photos sont orphelines ; aucun fichier, aucun orphelin")
    func orphansEdgeCases() throws {
        let photo = PhotoFileName.make()
        let zoe = try #require(
            Birthday(firstName: "Zoé", birthDate: try birthDate(3, 5), color: .rose, photoFileName: photo))

        #expect(PhotoFileName.orphans(among: [photo], referencedBy: []) == [photo])
        #expect(PhotoFileName.orphans(among: [], referencedBy: [zoe]).isEmpty)
    }

    private static func pngImage(width: Int, height: Int) throws -> Data {
        let context = try #require(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(red: 0.3, green: 0.8, blue: 0.6, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let output = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(output as CFMutableData, UTType.png.identifier as CFString, 1, nil)
        )
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return output as Data
    }
}
