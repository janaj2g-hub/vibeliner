import AppKit
import ImageIO

/// VIB-356: Efficient image downsampling using CGImageSource.
/// Decodes only enough data for the target pixel size — avoids loading
/// full-resolution screenshots into memory for small thumbnails.
enum ImageUtils {

    /// Load a downsampled image from a file URL.
    /// - Parameters:
    ///   - url: The image file URL.
    ///   - maxPixelSize: Maximum width or height in pixels.
    /// - Returns: A downsampled NSImage, or nil if the source is invalid.
    static func downsampledImage(at url: URL, maxPixelSize: CGFloat) -> NSImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
