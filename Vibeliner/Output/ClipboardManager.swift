import AppKit

final class ClipboardManager {

    static func copyPromptToClipboard(annotations: [Annotation], captureFolder: URL, captureStore: CaptureStore? = nil) {
        let prompt = PromptGenerator.clipboardPrompt(annotations: annotations, captureFolder: captureFolder, captureStore: captureStore)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt, forType: .string)
    }

    static func copyImageToClipboard(original: NSImage, annotations: [Annotation], canvasSize: CGSize, captureImages: [CaptureImage]? = nil) {
        let image: NSImage
        // VIB-297/VIB-383: Multi-image composite using CaptureImage with actual roles
        if let captureImages = captureImages, captureImages.count >= 2 {
            image = CompositeStitcher.stitch(images: captureImages, annotations: annotations, canvasSize: canvasSize) ?? original
        } else {
            image = ScreenshotExporter.exportAnnotatedScreenshot(original: original, annotations: annotations, canvasSize: canvasSize)
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}
