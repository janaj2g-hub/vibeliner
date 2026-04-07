import AppKit

final class ClipboardManager {

    static func copyPromptToClipboard(annotations: [Annotation], captureFolder: URL, captureStore: CaptureStore? = nil) {
        let prompt = PromptGenerator.clipboardPrompt(annotations: annotations, captureFolder: captureFolder, captureStore: captureStore)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt, forType: .string)
    }

    static func copyImageToClipboard(original: NSImage, annotations: [Annotation], canvasSize: CGSize, captureStore: CaptureStore? = nil) {
        let image: NSImage
        if let store = captureStore, store.isComposite,
           let composite = CompositeStitcher.stitch(images: store.images, annotations: annotations, canvasSize: canvasSize) {
            // VIB-264: Multi-image — copy the stitched composite
            image = composite
        } else {
            // Single image — existing behavior
            image = ScreenshotExporter.exportAnnotatedScreenshot(original: original, annotations: annotations, canvasSize: canvasSize)
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
}
