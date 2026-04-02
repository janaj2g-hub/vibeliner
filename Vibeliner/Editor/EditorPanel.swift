import AppKit

final class EditorPanel: NSPanel, ToolbarDelegate {

    private let canvasView: ScreenshotCanvasView
    private let screenshotImage: NSImage
    private let toolbarView: ToolbarView
    private let statusPill: StatusPillView
    let annotationStore = AnnotationStore()
    private(set) var undoRedoManager: UndoRedoManager!
    private var canvasOverlay: CanvasView?
    private let pinTool = PinTool()
    private let arrowTool = ArrowTool()
    private let rectangleTool = RectangleTool()
    private let circleTool = CircleTool()
    private let freehandTool = FreehandTool()
    private let displayWidth: CGFloat
    private let displayHeight: CGFloat
    private var captureFolder: URL?
    private var autoSaveManager: AutoSaveManager?
    private var storeObserver: Any?
    private var keyMonitor: Any?

    init(image: NSImage, on screen: NSScreen, captureFolder: URL? = nil) {
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

        // Annotation canvas overlay
        let canvas = CanvasView(frame: NSRect(x: 0, y: 0, width: dw, height: dh), store: annotationStore)
        canvasView.addSubview(canvas)
        self.canvasOverlay = canvas

        // Undo/redo manager
        self.undoRedoManager = UndoRedoManager(store: annotationStore)

        // Wire tools
        pinTool.editorPanel = self
        arrowTool.editorPanel = self
        rectangleTool.editorPanel = self
        circleTool.editorPanel = self
        freehandTool.editorPanel = self
        canvas.activeTool = pinTool
        canvas.undoManager_ = undoRedoManager

        // Auto-save
        self.captureFolder = captureFolder
        if let folder = captureFolder {
            autoSaveManager = AutoSaveManager(
                store: annotationStore,
                captureFolder: folder,
                originalImage: image,
                canvasSize: NSSize(width: dw, height: dh)
            )
        }

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

        // Observe annotation changes
        storeObserver = NotificationCenter.default.addObserver(
            forName: .annotationsDidChange, object: annotationStore, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.toolbarView.updateAnnotationCount(self.annotationStore.count)
            self.statusPill.updateNoteCount(self.annotationStore.count)
            // Reset copy buttons to purple on any annotation change
            self.toolbarView.resetCopyState()
        }

        // Local key monitor for Esc and other shortcuts (nonactivating panel may not get keyDown)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }
            return self.handleKeyEvent(event) ? nil : event
        }
    }

    deinit {
        if let observer = storeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        if !handleKeyEvent(event) {
            super.keyDown(with: event)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        if keyCode == 53 { // Escape
            if let canvas = canvasOverlay, canvas.isEditingNote {
                canvas.cancelNoteEditing()
            } else {
                autoSaveManager?.saveNow()
                close()
            }
            return true
        } else if keyCode >= 18 && keyCode <= 23 && flags.isEmpty {
            let keyMap: [UInt16: AnnotationToolType] = [18: .pin, 19: .arrow, 20: .rectangle, 21: .circle, 23: .freehand]
            if let tool = keyMap[keyCode] {
                toolbarView.selectTool(tool)
                return true
            }
        } else if flags == .command && event.charactersIgnoringModifiers == "z" {
            toolbarView.delegate?.toolbarDidRequestUndo()
            return true
        } else if flags == [.command, .shift] && event.charactersIgnoringModifiers == "z" {
            toolbarView.delegate?.toolbarDidRequestRedo()
            return true
        } else if flags == .command && event.charactersIgnoringModifiers == "c" {
            toolbarView.delegate?.toolbarDidRequestCopyPrompt()
            return true
        } else if keyCode == 51 || keyCode == 117 {
            toolbarView.delegate?.toolbarDidRequestDelete()
            return true
        }
        return false
    }

    // MARK: - ToolbarDelegate

    func toolbarDidSelectTool(_ tool: AnnotationToolType) {
        switch tool {
        case .pin: canvasOverlay?.activeTool = pinTool
        case .arrow: canvasOverlay?.activeTool = arrowTool
        case .rectangle: canvasOverlay?.activeTool = rectangleTool
        case .circle: canvasOverlay?.activeTool = circleTool
        case .freehand: canvasOverlay?.activeTool = freehandTool
        }
    }

    func toolbarDidRequestClose() {
        autoSaveManager?.saveNow()
        close()
    }

    func toolbarDidRequestDelete() {
        // Delete the selected annotation (not the entire capture)
        if let selected = annotationStore.selectedAnnotation {
            undoRedoManager.record(.remove(annotation: selected))
            annotationStore.remove(id: selected.id)
        }
    }

    func toolbarDidRequestUndo() {
        undoRedoManager.undo()
    }

    func toolbarDidRequestRedo() {
        undoRedoManager.redo()
    }

    func toolbarDidRequestCopyPrompt() {
        guard let folder = captureFolder else { return }
        ClipboardManager.copyPromptToClipboard(annotations: annotationStore.annotations, captureFolder: folder)
        statusPill.showCopied(message: "Prompt copied")
        toolbarView.markCopyState(.prompt)
    }

    func toolbarDidRequestCopyImage() {
        let canvasSize = CGSize(width: displayWidth, height: displayHeight)
        ClipboardManager.copyImageToClipboard(original: screenshotImage, annotations: annotationStore.annotations, canvasSize: canvasSize)
        statusPill.showCopied(message: "Image copied")
        toolbarView.markCopyState(.image)
    }
}
