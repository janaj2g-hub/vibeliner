import AppKit

final class ClipboardManager {

    /// VIB-357: Guard against double-click during async stitching
    private static var isStitching = false

    static func copyPromptToClipboard(annotations: [Annotation], captureFolder: URL, captureSession: CaptureSession? = nil) {
        let prompt = PromptGenerator.clipboardPrompt(annotations: annotations, captureFolder: captureFolder, captureSession: captureSession)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prompt, forType: .string)
    }

    static func copyImageToClipboard(original: NSImage, annotations: [Annotation], canvasSize: CGSize, captureSession: CaptureSession? = nil, completion: (() -> Void)? = nil) {
        if let captureSession, captureSession.isMultiImage {
            // VIB-357: Stitch off main thread to avoid UI freeze
            guard !isStitching else { return }
            isStitching = true

            DispatchQueue.global(qos: .userInitiated).async {
                let compositeImage = CompositeStitcher.stitch(images: captureSession.images, annotations: annotations, canvasSize: canvasSize) ?? original

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
