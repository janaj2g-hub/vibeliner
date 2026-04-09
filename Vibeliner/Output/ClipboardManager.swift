import AppKit

final class ClipboardManager {

    static func copyPromptToClipboard(annotations: [Annotation], captureFolder: URL, captureStore: CaptureStore? = nil) {
        let prompt = PromptGenerator.clipboardPrompt(annotations: annotations, captureFolder: captureFolder, captureStore: captureStore)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt, forType: .string)
    }

    static func copyImageToClipboard(original: NSImage, annotations: [Annotation], canvasSize: CGSize, allImages: [NSImage]? = nil) {
        let image: NSImage
        // VIB-297: Multi-image composite when 2+ images
        if let allImages = allImages, allImages.count >= 2 {
            let captureImages = allImages.enumerated().map { i, img in
                CaptureImage(sourceImage: img, title: "Image \(i + 1)", role: .observed, originalSize: img.size, index: i)
            }
            image = CompositeStitcher.stitch(images: captureImages, annotations: annotations, canvasSize: canvasSize) ?? original
        } else {
            image = ScreenshotExporter.exportAnnotatedScreenshot(original: original, annotations: annotations, canvasSize: canvasSize)
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}
