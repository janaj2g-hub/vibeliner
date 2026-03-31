import AppKit

final class EditorPanel: NSPanel, ToolbarDelegate {

    private let canvasView: ScreenshotCanvasView
    private let screenshotImage: NSImage
    private let toolbarView: ToolbarView
    private let statusPill: StatusPillView
    private let displayWidth: CGFloat
    private let displayHeight: CGFloat

    init(image: NSImage, on screen: NSScreen) {
        self.screenshotImage = image
        self.canvasView = ScreenshotCanvasView(image: image)
        self.toolbarView = ToolbarView()
        self.statusPill = StatusPillView()

        // Calculate display size — scale down if larger than screen usable area
        let screenFrame = screen.visibleFrame
        let maxWidth = screenFrame.width * 0.9
        let maxHeight = screenFrame.height * 0.85
        var dw = CGFloat(image.size.width)
        var dh = CGFloat(image.size.height)

        if dw > maxWidth || dh > maxHeight {
            let scale = min(maxWidth / dw, maxHeight / dh)
            dw *= scale
            dh *= scale
        }

        self.displayWidth = dw
        self.displayHeight = dh

        // Window encompasses toolbar (48px above) + canvas + status pill area (44px below)
        let toolbarGap: CGFloat = 48
        let bottomGap: CGFloat = 44
        let totalHeight = dh + toolbarGap + bottomGap
        let totalWidth = max(dw, toolbarView.frame.width)

        let contentRect = NSRect(
            x: screenFrame.midX - totalWidth / 2,
            y: screenFrame.midY - totalHeight / 2,
            width: totalWidth,
            height: totalHeight
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

        let container = NSView(frame: NSRect(origin: .zero, size: contentRect.size))
        contentView = container

        // Canvas centered horizontally, above bottom gap
        let canvasX = (totalWidth - dw) / 2
        canvasView.frame = NSRect(x: canvasX, y: bottomGap, width: dw, height: dh)
        container.addSubview(canvasView)

        // Toolbar centered above canvas
        let toolbarX = (totalWidth - toolbarView.frame.width) / 2
        let toolbarY = bottomGap + dh + toolbarGap - DesignTokens.toolbarHeight
        toolbarView.setFrameOrigin(NSPoint(x: toolbarX, y: toolbarY))
        toolbarView.delegate = self
        container.addSubview(toolbarView)

        // Status pill below canvas
        statusPill.updateDimensions(width: Int(image.size.width), height: Int(image.size.height))
        let pillX = (totalWidth - statusPill.frame.width) / 2
        let pillY = bottomGap - statusPill.frame.height
        statusPill.setFrameOrigin(NSPoint(x: pillX, y: pillY))
        container.addSubview(statusPill)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        if keyCode == 53 { // Escape
            close()
        } else if keyCode >= 18 && keyCode <= 23 && flags.isEmpty {
            // Keys 1-5 for tool switching (keycodes 18=1, 19=2, 20=3, 21=4, 23=5)
            let keyMap: [UInt16: AnnotationToolType] = [18: .pin, 19: .arrow, 20: .rectangle, 21: .circle, 23: .freehand]
            if let tool = keyMap[keyCode] {
                toolbarView.selectTool(tool)
            }
        } else if flags == .command && event.charactersIgnoringModifiers == "z" {
            toolbarView.delegate?.toolbarDidRequestUndo()
        } else if flags == [.command, .shift] && event.charactersIgnoringModifiers == "z" {
            toolbarView.delegate?.toolbarDidRequestRedo()
        } else if flags == .command && event.charactersIgnoringModifiers == "c" {
            toolbarView.delegate?.toolbarDidRequestCopyPrompt()
        } else if keyCode == 51 || keyCode == 117 { // Delete / Forward Delete
            toolbarView.delegate?.toolbarDidRequestDelete()
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - ToolbarDelegate

    func toolbarDidSelectTool(_ tool: AnnotationToolType) {
        print("Tool selected: \(tool)")
    }

    func toolbarDidRequestClose() {
        close()
    }

    func toolbarDidRequestDelete() {
        print("Delete selected annotation")
    }

    func toolbarDidRequestUndo() {
        print("Undo")
    }

    func toolbarDidRequestRedo() {
        print("Redo")
    }

    func toolbarDidRequestCopyPrompt() {
        print("Copy Prompt")
    }

    func toolbarDidRequestCopyImage() {
        print("Copy Image")
    }
}
