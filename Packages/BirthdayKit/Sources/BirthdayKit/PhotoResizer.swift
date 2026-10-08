import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum PhotoResizerError: Error, Equatable {
    case unreadableImage
    case encodingFailed
}

public enum PhotoResizer {
    public static let maximumPixelSize = 1200
    public static let jpegQuality = 0.8

    public static func resizedJPEG(
        from data: Data,
        maximumPixelSize: Int = maximumPixelSize,
        quality: Double = jpegQuality
    ) throws(PhotoResizerError) -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { throw .unreadableImage }
        let thumbnailOptions: [CFString: NSNumber] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: NSNumber(value: maximumPixelSize),
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            throw .unreadableImage
        }
        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output as CFMutableData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else { throw .encodingFailed }
        let destinationOptions: [CFString: NSNumber] = [
            kCGImageDestinationLossyCompressionQuality: NSNumber(value: quality)
        ]
        CGImageDestinationAddImage(destination, image, destinationOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw .encodingFailed }
        return output as Data
    }

    public static func thumbnail(
        from data: Data,
        shortSidePixelSize: Int
    ) throws(PhotoResizerError) -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?,
            let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
            let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
            width > 0, height > 0
        else { throw .unreadableImage }
        let longSide = max(width, height)
        let shortSide = min(width, height)
        let requestedLongSide = (max(shortSidePixelSize, 1) * longSide + shortSide - 1) / shortSide
        let thumbnailOptions: [CFString: NSNumber] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: NSNumber(value: min(requestedLongSide, longSide)),
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            throw .unreadableImage
        }
        return image
    }
}
