import AppKit

final class EditorPanel: NSPanel, ToolbarDelegate {

    let canvasView: ScreenshotCanvasView
    let captureSession: CaptureSession
    let toolbarView: ToolbarView
    let statusPill: StatusPillView
    let annotationStore = AnnotationStore()
    let undoRedoManager: UndoRedoManager
    lazy var toolController = EditorToolController(editorPanel: self)
    let cursorController = EditorCursorController()
    var canvasOverlay: CanvasView?
    let displayWidth: CGFloat
    let displayHeight: CGFloat
    var captureFolder: URL?
    var autoSaveManager: AutoSaveManager?
    var storeObserver: Any?
    var keyMonitor: Any?

    // MARK: - Multi-image state
    var filmstripView: FilmstripGridView?
    var isFilmstripMode = false
    var singleImageWindowFrame: NSRect?
    var singleImageToolbarOrigin: NSPoint?
    var singleImagePillOrigin: NSPoint?

    var images: [NSImage] {
        captureSession.images.map(\.sourceImage)
    }

    init(image: NSImage, on screen: NSScreen, captureFolder: URL? = nil) {
        self.captureSession = CaptureSession(image: image)
        self.canvasView = ScreenshotCanvasView(image: image)
        self.toolbarView = ToolbarView()
        self.statusPill = StatusPillView()
        self.undoRedoManager = UndoRedoManager(store: annotationStore)

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

        // VIB-191: Add overflow padding so note pills can extend beyond canvas
        let toolbarGap: CGFloat = 48
        let bottomGap: CGFloat = 44
        let shadowPad: CGFloat = 24
        let overflowPad: CGFloat = 200  // room for pills to extend beyond canvas
        let totalHeight = dh + toolbarGap + bottomGap + shadowPad + overflowPad
        let totalWidth = max(dw, toolbarView.frame.width) + overflowPad * 2

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
        becomesKeyOnlyIfNeeded = true  // VIB-169: Accept first click without needing to become key first

        let container = NSView(frame: NSRect(origin: .zero, size: contentRect.size))
        container.wantsLayer = true
        container.layer?.masksToBounds = false  // VIB-165/167: Don't clip toolbar shadow or note overflow
        contentView = container

        // VIB-191: Canvas centered within the wider window (overflow padding on sides)
        let canvasX = overflowPad + (totalWidth - overflowPad * 2 - dw) / 2
        let canvasY = bottomGap + overflowPad / 2  // some overflow below too
        canvasView.frame = NSRect(x: canvasX, y: canvasY, width: dw, height: dh)
        container.addSubview(canvasView)

        // Annotation canvas overlay
        let canvas = CanvasView(frame: NSRect(x: 0, y: 0, width: dw, height: dh), store: annotationStore)
        canvasView.addSubview(canvas)
        self.canvasOverlay = canvas

        annotationStore.updateCurrentImage(id: captureSession.imageID(at: 0), index: 0)

        toolController.configure(canvas: canvas, undoManager: undoRedoManager)
        canvas.onCursorIntentChanged = { [weak self] intent in
            self?.cursorController.setCanvasIntent(intent)
        }

        // Auto-save
        self.captureFolder = captureFolder
        if let folder = captureFolder {
            autoSaveManager = AutoSaveManager(
                store: annotationStore,
                captureFolder: folder,
                session: captureSession,
                canvasSize: NSSize(width: dw, height: dh)
            )
        }

        // VIB-191: Toolbar centered above canvas (using canvasY for correct vertical offset)
        let toolbarX = (totalWidth - toolbarView.frame.width) / 2
        let toolbarY = canvasY + dh + (toolbarGap - DesignTokens.toolbarHeight) / 2
        toolbarView.setFrameOrigin(NSPoint(x: toolbarX, y: toolbarY))
        toolbarView.delegate = self
        toolbarView.onChromeHoverChanged = { [weak self] isHovering in
            self?.cursorController.setChromeHovering(isHovering)
        }
        container.addSubview(toolbarView)

        // VIB-191: Status pill below canvas
        statusPill.updateDimensions(width: Int(image.size.width), height: Int(image.size.height))
        let pillX = (totalWidth - statusPill.frame.width) / 2
        let pillY = canvasY - 32 - statusPill.frame.height
        statusPill.setFrameOrigin(NSPoint(x: pillX, y: pillY))
        container.addSubview(statusPill)

        installAnnotationObserver()
        installKeyMonitor()
    }

    deinit {
        if let observer = storeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func installAnnotationObserver() {
        storeObserver = NotificationCenter.default.addObserver(
            forName: .annotationsDidChange, object: annotationStore, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.toolbarView.updateAnnotationCount(self.annotationStore.count)
            self.statusPill.updateNoteCount(self.annotationStore.count)
            self.toolbarView.resetCopyState()
            self.toolbarView.updateTrashState(hasSelection: self.annotationStore.selectedAnnotation != nil)
        }
    }

    func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }
            if self.otherWindowOwnsActiveTextInput() {
                return event
            }
            if let routedEvent = self.routeTextOwnedKeyEvent(event) {
                return self.handleKeyEvent(routedEvent) ? nil : routedEvent
            }
            return nil
        }
    }

    override func becomeKey() {
        super.becomeKey()
        cursorController.setWindowActive(true)
        canvasOverlay?.refreshInteractionState()
    }

    override func resignKey() {
        super.resignKey()
        cursorController.setWindowActive(false)
    }

    override func close() {
        // VIB-326: Remove key monitor on close, not just deinit.
        // Prevents stale monitor from intercepting keys in the next editor.
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        cursorController.setWindowActive(false)
        super.close()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// VIB-205: During note editing, directly invoke clipboard/undo actions on the
    /// field editor and return true to swallow the event. This prevents it from
    /// reaching AppKit's main menu validation (which beeps on borderless panels).
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let textResponder = KeyEventGuard.activeTextResponder(in: self) {
            return handleTextResponderKeyEquivalent(event, textResponder: textResponder)
        }
        return handlePanelKeyEquivalent(event)
    }

    override func keyDown(with event: NSEvent) {
        if !handleKeyEvent(event) {
            super.keyDown(with: event)
        }
    }

    func otherWindowOwnsActiveTextInput() -> Bool {
        let keyWindow = NSApp.keyWindow
        return keyWindow !== self && !KeyEventGuard.shouldHandleShortcut(in: keyWindow)
    }

    func routeTextOwnedKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard KeyEventGuard.activeTextResponder(in: self) != nil else {
            return event
        }

        if event.keyCode == 53, canvasOverlay?.isEditingNote == true {
            canvasOverlay?.cancelNoteEditing()
            return nil
        }

        // Let NSTextView/NSTextField own their normal shortcuts and key handling.
        return event
    }

    func handleTextResponderKeyEquivalent(_ event: NSEvent, textResponder: NSTextView) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chars = event.charactersIgnoringModifiers ?? ""
        if flags == .command {
            switch chars {
            case "c": textResponder.copy(nil); return true
            case "v": textResponder.paste(nil); return true
            case "x": textResponder.cut(nil); return true
            case "a": textResponder.selectAll(nil); return true
            case "z": textResponder.undoManager?.undo(); return true
            default: return false
            }
        }
        if flags.contains(.command) && flags.contains(.shift) && chars.lowercased() == "z" {
            textResponder.undoManager?.redo()
            return true
        }
        return false
    }

    func handlePanelKeyEquivalent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chars = event.charactersIgnoringModifiers ?? ""
        if flags == .command && chars == "w" {
            autoSaveManager?.saveNow()
            close()
            return true
        }
        if flags == .command && chars == "c" {
            toolbarDidRequestCopyPrompt()
            return true
        }
        if flags == .command && chars == "z" {
            toolbarDidRequestUndo()
            return true
        }
        if flags.contains(.command) && flags.contains(.shift) && chars.lowercased() == "z" {
            toolbarDidRequestRedo()
            return true
        }
        return false
    }

    func handleKeyEvent(_ event: NSEvent) -> Bool {
        // When a note text field is editing, pass ALL key events through
        // except Escape (cancel) and Enter (confirm, handled by text field delegate).
        // This ensures backspace, arrow keys, etc. work in the text field.
        if let canvas = canvasOverlay, canvas.isEditingNote {
            if event.keyCode == 53 { // Escape
                canvas.cancelNoteEditing()
                return true
            }
            // Let the text field handle everything else (backspace, typing, etc.)
            return false
        }

        // VIB-326: Don't swallow keys when ANY text field is first responder
        // (covers title pill fields, search fields, etc. beyond annotation notes)
        guard KeyEventGuard.shouldHandleShortcut(in: self) else { return false }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        if keyCode == 53 { // Escape — VIB-239: cascade dismiss, never close
            // Priority 2: Deselect selected shape
            if let canvas = canvasOverlay, canvas.marksLayer.selectedId != nil {
                annotationStore.deselectAll()
                canvas.marksLayer.selectedId = nil
                canvas.marksLayer.needsDisplay = true
                canvas.refreshNotePills()
                return true
            }
            // Priority 3: Dearm active annotation tool → switch to select
            if toolbarView.selectedTool.isDrawingTool {
                toolbarView.selectTool(.select)
                canvasOverlay?.marksLayer.ghostTool = nil
                canvasOverlay?.marksLayer.ghostPosition = nil
                canvasOverlay?.marksLayer.needsDisplay = true
                return true
            }
            // Priority 4: No-op — editor stays open
            return true
        } else if keyCode == 51 || keyCode == 117 { // Delete/Backspace
            // VIB-326: Only consume the event when an action is actually performed.
            // Previously returned true unconditionally, swallowing backspace even
            // when no annotation was selected and filmstrip wasn't active.
            if annotationStore.selectedAnnotation != nil {
                toolbarView.delegate?.toolbarDidRequestDelete()
                return true
            } else if isFilmstripMode, images.count > 1 {
                removeImageAtIndex(filmstripView?.selectedIndex ?? 0)
                return true
            }
            return false
        } else if flags.isEmpty {
            if let tool = AnnotationToolType.tool(forShortcutKeyCode: keyCode) {
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
            if !(canvasOverlay?.isEditingNote ?? false) {
                toolbarView.delegate?.toolbarDidRequestCopyPrompt()
                return true
            }
        }
        return false
    }

}
