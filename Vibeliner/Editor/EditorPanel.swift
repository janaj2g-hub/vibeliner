import AppKit

final class EditorPanel: NSPanel {

    private let canvasView: ScreenshotCanvasView
    private let screenshotImage: NSImage

    init(image: NSImage, on screen: NSScreen) {
        self.screenshotImage = image
        self.canvasView = ScreenshotCanvasView(image: image)

        // Calculate display size — scale down if larger than screen usable area
        let screenFrame = screen.visibleFrame
        let maxWidth = screenFrame.width * 0.9
        let maxHeight = screenFrame.height * 0.85
        var displayWidth = CGFloat(image.size.width)
        var displayHeight = CGFloat(image.size.height)

        if displayWidth > maxWidth || displayHeight > maxHeight {
            let scaleX = maxWidth / displayWidth
            let scaleY = maxHeight / displayHeight
            let scale = min(scaleX, scaleY)
            displayWidth *= scale
            displayHeight *= scale
        }

        let contentRect = NSRect(
            x: screenFrame.midX - displayWidth / 2,
            y: screenFrame.midY - displayHeight / 2,
            width: displayWidth,
            height: displayHeight
        )

        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false

        canvasView.frame = NSRect(origin: .zero, size: NSSize(width: displayWidth, height: displayHeight))
        canvasView.autoresizingMask = [.width, .height]
        contentView = canvasView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            close()
        } else {
            super.keyDown(with: event)
        }
    }
}
