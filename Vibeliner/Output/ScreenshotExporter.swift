import AppKit

final class ScreenshotExporter {

    private static let pinRenderer = PinRenderer()
    private static let arrowRenderer = ArrowRenderer()
    private static let lineRenderer = LineRenderer()
    private static let rectangleRenderer = RectangleRenderer()
    private static let circleRenderer = CircleRenderer()
    private static let freehandRenderer = FreehandRenderer()

    static func exportAnnotatedScreenshot(original: NSImage, annotations: [Annotation], canvasSize: CGSize) -> NSImage {
        let imageSize = NSSize(width: original.size.width, height: original.size.height)

        // Get pixel dimensions for Retina support
        guard let cgOriginal = original.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return original
        }
        let pixelWidth = cgOriginal.width
        let pixelHeight = cgOriginal.height

        // Create CGBitmapContext (thread-safe, works off main thread)
        guard let bitmapContext = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return original
        }

        // Draw original screenshot into bitmap context
        bitmapContext.draw(cgOriginal, in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

        // Scale context for annotation rendering (canvas → pixel coordinates)
        let scaleX = CGFloat(pixelWidth) / canvasSize.width
        let scaleY = CGFloat(pixelHeight) / canvasSize.height
        bitmapContext.scaleBy(x: scaleX, y: scaleY)

        // Push NSGraphicsContext for any AppKit drawing in renderers
        let nsContext = NSGraphicsContext(cgContext: bitmapContext, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext

        // Draw marks only (no notes, no handles, no hover states)
        pinRenderer.drawMarks(in: bitmapContext, annotations: annotations, canvasSize: canvasSize)
        arrowRenderer.drawMarks(in: bitmapContext, annotations: annotations, canvasSize: canvasSize)
        lineRenderer.drawMarks(in: bitmapContext, annotations: annotations, canvasSize: canvasSize)
        rectangleRenderer.drawMarks(in: bitmapContext, annotations: annotations, canvasSize: canvasSize)
        circleRenderer.drawMarks(in: bitmapContext, annotations: annotations, canvasSize: canvasSize)
        freehandRenderer.drawMarks(in: bitmapContext, annotations: annotations, canvasSize: canvasSize)

        NSGraphicsContext.restoreGraphicsState()

        guard let finalCGImage = bitmapContext.makeImage() else {
            return original
        }

        return NSImage(cgImage: finalCGImage, size: imageSize)
    }

    static func saveExportedScreenshot(to folderURL: URL, original: NSImage, annotations: [Annotation], canvasSize: CGSize) {
        let composited = exportAnnotatedScreenshot(original: original, annotations: annotations, canvasSize: canvasSize)
        CaptureSession.saveAnnotatedImage(composited, to: folderURL)
    }
}
