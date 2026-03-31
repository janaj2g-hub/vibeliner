import AppKit

final class ScreenshotExporter {

    private static let pinRenderer = PinRenderer()
    private static let arrowRenderer = ArrowRenderer()
    private static let rectangleRenderer = RectangleRenderer()
    private static let circleRenderer = CircleRenderer()
    private static let freehandRenderer = FreehandRenderer()

    static func exportAnnotatedScreenshot(original: NSImage, annotations: [Annotation], canvasSize: CGSize) -> NSImage {
        let imageSize = NSSize(width: original.size.width, height: original.size.height)
        let image = NSImage(size: imageSize)

        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return original
        }

        // Draw original screenshot
        original.draw(in: NSRect(origin: .zero, size: imageSize))

        // Scale context if canvas size differs from image size (Retina)
        let scaleX = imageSize.width / canvasSize.width
        let scaleY = imageSize.height / canvasSize.height
        context.scaleBy(x: scaleX, y: scaleY)

        // Draw marks only (no notes, no handles, no hover states)
        pinRenderer.drawMarks(in: context, annotations: annotations, canvasSize: canvasSize)
        arrowRenderer.drawMarks(in: context, annotations: annotations, canvasSize: canvasSize)
        rectangleRenderer.drawMarks(in: context, annotations: annotations, canvasSize: canvasSize)
        circleRenderer.drawMarks(in: context, annotations: annotations, canvasSize: canvasSize)
        freehandRenderer.drawMarks(in: context, annotations: annotations, canvasSize: canvasSize)

        image.unlockFocus()
        return image
    }

    static func saveExportedScreenshot(to folderURL: URL, original: NSImage, annotations: [Annotation], canvasSize: CGSize) {
        let composited = exportAnnotatedScreenshot(original: original, annotations: annotations, canvasSize: canvasSize)
        let fileURL = folderURL.appendingPathComponent("screenshot.png")
        let tempURL = folderURL.appendingPathComponent(".screenshot.png.tmp")
        _ = composited.savePNG(to: tempURL)
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.moveItem(at: tempURL, to: fileURL)
    }
}
