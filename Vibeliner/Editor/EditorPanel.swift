import AppKit

final class EditorPanel: NSPanel, ToolbarDelegate {

    private let canvasView: ScreenshotCanvasView
    private let screenshotImage: NSImage
    private let toolbarView: ToolbarView
    private let statusPill: StatusPillView
    let annotationStore = AnnotationStore()
    private(set) var undoRedoManager: UndoRedoManager!
    private var canvasOverlay: CanvasView?
    private let selectTool = SelectTool()
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

        // Undo/redo manager
        self.undoRedoManager = UndoRedoManager(store: annotationStore)

        // Wire tools
        selectTool.editorPanel = self
        pinTool.editorPanel = self
        arrowTool.editorPanel = self
        rectangleTool.editorPanel = self
        circleTool.editorPanel = self
        freehandTool.editorPanel = self
        canvas.activeTool = pinTool  // Default to pin tool
        canvas.undoManager_ = undoRedoManager
        canvas.selectTool = selectTool  // VIB-217: click-through edit

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

        // VIB-191: Toolbar centered above canvas (using canvasY for correct vertical offset)
        let toolbarX = (totalWidth - toolbarView.frame.width) / 2
        let toolbarY = canvasY + dh + (toolbarGap - DesignTokens.toolbarHeight) / 2
        toolbarView.setFrameOrigin(NSPoint(x: toolbarX, y: toolbarY))
        toolbarView.delegate = self
        container.addSubview(toolbarView)

        // VIB-191: Status pill below canvas
        statusPill.updateDimensions(width: Int(image.size.width), height: Int(image.size.height))
        let pillX = (totalWidth - statusPill.frame.width) / 2
        let pillY = canvasY - 32 - statusPill.frame.height
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
            // VIB-202: Enable trash only when an annotation is selected
            self.toolbarView.updateTrashState(hasSelection: self.annotationStore.selectedAnnotation != nil)
        }

        // VIB-193: Key monitor — when editing, only intercept Escape BEFORE handleKeyEvent
        // This ensures Cmd+C/V/A pass directly to the text field's field editor
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }

            // When editing a note, only intercept Escape. ALL other keys pass through untouched.
            if let canvas = self.canvasOverlay, canvas.isEditingNote {
                if event.keyCode == 53 { // Escape
                    canvas.cancelNoteEditing()
                    return nil  // consumed
                }
                return event  // pass through to text field (Cmd+C/V/A, arrows, etc.)
            }

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

    /// VIB-205: During note editing, directly invoke clipboard/undo actions on the
    /// field editor and return true to swallow the event. This prevents it from
    /// reaching AppKit's main menu validation (which beeps on borderless panels).
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let canvas = canvasOverlay, canvas.isEditingNote {
            if let activeField = canvas.activeNoteField,
               let fieldEditor = fieldEditor(false, for: activeField) as? NSTextView {
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let chars = event.charactersIgnoringModifiers ?? ""
                if flags == .command {
                    switch chars {
                    case "c": fieldEditor.copy(nil); return true
                    case "v": fieldEditor.paste(nil); return true
                    case "x": fieldEditor.cut(nil); return true
                    case "a": fieldEditor.selectAll(nil); return true
                    case "z": fieldEditor.undoManager?.undo(); return true
                    default: break
                    }
                } else if flags.contains(.command) && flags.contains(.shift) && chars.lowercased() == "z" {
                    fieldEditor.undoManager?.redo()
                    return true
                }
            }
            // VIB-205 (attempt 2): Do NOT swallow unhandled key equivalents —
            // arrow keys and other combos must pass through to the responder chain
            return false
        }
        // VIB-205 (attempt 4): Handle non-editing Cmd+key here too —
        // performKeyEquivalent fires before the key monitor on borderless panels,
        // so handleKeyEvent never sees these events.
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chars = event.charactersIgnoringModifiers ?? ""
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

    override func keyDown(with event: NSEvent) {
        if !handleKeyEvent(event) {
            super.keyDown(with: event)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
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

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        if keyCode == 53 { // Escape
            // VIB-213: If a shape is selected, deselect it and hide handles — do NOT close
            if let canvas = canvasOverlay, canvas.marksLayer.selectedId != nil {
                annotationStore.deselectAll()
                canvas.marksLayer.selectedId = nil
                canvas.marksLayer.needsDisplay = true
                canvas.refreshNotePills()
                return true
            }
            autoSaveManager?.saveNow()
            close()
            return true
        } else if keyCode >= 18 && keyCode <= 23 && flags.isEmpty {
            let keyMap: [UInt16: AnnotationToolType] = [18: .select, 19: .pin, 20: .arrow, 21: .rectangle, 22: .circle, 23: .freehand]
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
            if !(canvasOverlay?.isEditingNote ?? false) {
                toolbarView.delegate?.toolbarDidRequestCopyPrompt()
                return true
            }
        } else if keyCode == 51 || keyCode == 117 { // Delete/Backspace
            toolbarView.delegate?.toolbarDidRequestDelete()
            return true
        }
        return false
    }

    // MARK: - ToolbarDelegate

    func toolbarDidSelectTool(_ tool: AnnotationToolType) {
        switch tool {
        case .select: canvasOverlay?.activeTool = selectTool
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
