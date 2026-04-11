import AppKit

final class ClipboardManager {

    /// VIB-357: Guard against double-click during async stitching
    private static var isStitching = false

    static func copyPromptToClipboard(annotations: [Annotation], captureFolder: URL, captureStore: CaptureStore? = nil) {
        let prompt = PromptGenerator.clipboardPrompt(annotations: annotations, captureFolder: captureFolder, captureStore: captureStore)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt, forType: .string)
    }

    static func copyImageToClipboard(original: NSImage, annotations: [Annotation], canvasSize: CGSize, captureImages: [CaptureImage]? = nil, completion: (() -> Void)? = nil) {
        // VIB-297/VIB-383: Multi-image composite using CaptureImage with actual roles
        if let captureImages = captureImages, captureImages.count >= 2 {
            // VIB-357: Stitch off main thread to avoid UI freeze
            guard !isStitching else { return }
            isStitching = true

            DispatchQueue.global(qos: .userInitiated).async {
                let compositeImage = CompositeStitcher.stitch(images: captureImages, annotations: annotations, canvasSize: canvasSize) ?? original

                DispatchQueue.main.async {
                    isStitching = false
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([compositeImage])
                    completion?()
                }
            }
        } else {
            let image = ScreenshotExporter.exportAnnotatedScreenshot(original: original, annotations: annotations, canvasSize: canvasSize)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([image])
            completion?()
        }
    }
}
