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
    private var captureStore: CaptureStore?
    private var autoSaveManager: AutoSaveManager?
    private var filmstripGridView: FilmstripGridView?
    private var storeObserver: Any?
    private var keyMonitor: Any?
    /// VIB-271: Currently selected image index in the filmstrip (for deletion).
    /// Mutually exclusive with annotation selection.
    private var selectedImageIndex: Int?

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
        // VIB-271: Wire image undo delegate
        undoRedoManager.imageUndoDelegate = self

        // VIB-271: Wire image click callback for image selection
        canvas.onImageClicked = { [weak self] index in
            self?.selectImage(at: index)
        }

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

        // VIB-268: Wire image frame provider for relative coordinate system.
        // The store computes image-relative positions automatically on add/update.
        annotationStore.imageFrameProvider = { [weak canvas] in
            canvas?.imageFramesInCanvasCoords() ?? []
        }

        // Auto-save
        self.captureFolder = captureFolder
        if let folder = captureFolder {
            let capture = CaptureStore(image: image)
            self.captureStore = capture
            // VIB-269: Wire capture store for image prefix computation in note pills.
            canvas.captureStore = capture
            autoSaveManager = AutoSaveManager(
                store: annotationStore,
                captureFolder: folder,
                originalImage: image,
                canvasSize: NSSize(width: dw, height: dh),
                captureStore: capture
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
            // VIB-202/VIB-271: Enable trash when annotation OR image is selected
            let hasAnnotationSel = self.annotationStore.selectedAnnotation != nil
            // VIB-271: If an annotation is selected, clear image selection (mutual exclusion)
            if hasAnnotationSel && self.selectedImageIndex != nil {
                self.deselectImage()
            }
            self.toolbarView.updateTrashState(hasSelection: hasAnnotationSel || self.selectedImageIndex != nil)
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

            // VIB-311: Centralized text field guard — prevents backspace/delete/number
            // keys from being intercepted when any text field is editing.
            guard KeyEventGuard.shouldHandleShortcut(in: self) else { return event }

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

        // VIB-311: Centralized text field guard — if a title pill or other text
        // field is editing, don't intercept Cmd+C/Z (let the field handle them).
        guard KeyEventGuard.shouldHandleShortcut(in: self) else { return false }

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

        // VIB-311: Centralized text field guard — if any text field or field editor
        // is the first responder, pass all key events through to it.
        guard KeyEventGuard.shouldHandleShortcut(in: self) else { return false }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        if keyCode == 53 { // Escape
            // VIB-271: If an image is selected, deselect it — do NOT close
            if selectedImageIndex != nil {
                deselectImage()
                toolbarView.updateTrashState(hasSelection: false)
                return true
            }
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
        // VIB-271: If an image is selected (not an annotation), delete the image
        if let imgIdx = selectedImageIndex {
            deleteImage(at: imgIdx)
            return
        }
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
        ClipboardManager.copyPromptToClipboard(annotations: annotationStore.annotations, captureFolder: folder, captureStore: captureStore)
        statusPill.showCopied(message: "Prompt copied")
        toolbarView.markCopyState(.prompt)
    }

    func toolbarDidRequestCopyImage() {
        // VIB-309: Use the filmstrip grid size as canvas size in composite mode,
        // since annotations are positioned in the grid's coordinate space.
        let canvasSize: CGSize
        if let grid = filmstripGridView {
            canvasSize = grid.frame.size
        } else {
            canvasSize = CGSize(width: displayWidth, height: displayHeight)
        }
        ClipboardManager.copyImageToClipboard(original: screenshotImage, annotations: annotationStore.annotations, canvasSize: canvasSize, captureStore: captureStore)
        statusPill.showCopied(message: "Image copied")
        toolbarView.markCopyState(.image)
    }

    // MARK: - VIB-262: Add image

    func toolbarDidRequestAddImage() {
        // VIB-297: Max 6 images for horizontal scroll filmstrip
        guard let store = captureStore, store.images.count < 6 else { return }

        // Auto-save before capture
        autoSaveManager?.saveNow()

        // VIB-288: Hide editor completely during capture (not just dim)
        orderOut(nil)

        // Start add-image capture
        CaptureCoordinator.shared.startAddImageCapture { [weak self] newImage in
            guard let self else { return }

            // VIB-282: All images default to .observed — user changes manually
            let count = store.images.count
            store.addImage(newImage, title: "Image \(count + 1)", role: .observed)

            // VIB-288: Restore editor after capture
            self.alphaValue = 1.0
            self.makeKeyAndOrderFront(nil)

            // VIB-268: Clear undo stack — layout changed, old absolute positions are stale
            self.undoRedoManager.clearStacks()

            // VIB-261: Switch to filmstrip view
            self.refreshFilmstrip()

            // Update status pill
            self.updateStatusForMultiImage()

            // Update toolbar add button state
            self.toolbarView.updateAddImageState(imageCount: store.images.count)
        }

        // VIB-288: Handle Escape cancel — CaptureCoordinator.cancelCapture clears
        // the completion handler, so we need to restore the editor when capture is dismissed.
        // The CaptureCoordinator calls dismissOverlays on cancel, but doesn't call our completion.
        // Register a one-shot observer: if the capture overlay windows disappear without
        // calling our completion, restore the editor.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            // If editor is still hidden (orderOut) and capture coordinator is no longer capturing,
            // it means the user cancelled. Restore the editor.
            if !self.isVisible {
                // Check periodically until either our completion fires or capture ends
                self.pollForCaptureCancel()
            }
        }
    }

    /// VIB-288: Poll to detect if capture was cancelled (Escape) so we can restore the editor.
    private func pollForCaptureCancel() {
        // If editor became visible (completion handler already restored it), stop polling
        guard !isVisible else { return }

        // Check if capture overlay windows still exist
        let captureActive = NSApp.windows.contains { $0 is CaptureOverlayWindow && $0.isVisible }
        if !captureActive {
            // Capture ended without calling our completion = cancelled
            makeKeyAndOrderFront(nil)
            return
        }

        // Still capturing — check again soon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.pollForCaptureCancel()
        }
    }

    // MARK: - VIB-261: Filmstrip view wiring

    /// VIB-297: Create or update the horizontal scroll filmstrip when in composite mode (2+ images).
    /// Hides the single-image canvasView and shows the filmstrip grid instead.
    /// The annotation overlay is reparented onto the filmstrip so tools remain functional.
    private func refreshFilmstrip() {
        guard let store = captureStore, store.isComposite else { return }
        guard let container = contentView else { return }

        if filmstripGridView == nil {
            // First time entering composite mode — create the filmstrip
            let grid = FilmstripGridView(frame: canvasView.frame)
            grid.wantsLayer = true

            // Wire callbacks to update the data model
            grid.onTitleChanged = { [weak self] idx, title in
                self?.captureStore?.updateTitle(at: idx, title: title)
                // VIB-269: Refresh note pills so image prefixes update with the new title
                self?.canvasOverlay?.refreshNotePills()
            }
            grid.onRoleChanged = { [weak self] idx, role in
                self?.captureStore?.updateRole(at: idx, role: role)
            }

            // VIB-271: Wire image selection callback
            grid.onImageSelected = { [weak self] idx in
                self?.selectImage(at: idx)
            }

            // Insert filmstrip where the canvasView is
            container.addSubview(grid, positioned: .above, relativeTo: canvasView)

            // Hide the single-image canvas view (but NOT the annotation overlay)
            canvasView.isHidden = true

            // VIB-289: Reparent annotation overlay as a sibling ABOVE the grid in the container.
            if let canvas = canvasOverlay {
                canvas.removeFromSuperview()
                container.addSubview(canvas, positioned: .above, relativeTo: grid)
                // VIB-294: Give canvas a reference to the grid for title pill hit-testing
                canvas.filmstripGrid = grid
            }

            self.filmstripGridView = grid
        }

        guard let grid = filmstripGridView, let screen = self.screen ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let maxWidth = min(screenFrame.width * 0.85, 1600)

        // VIB-297: Compute row height from available vertical space.
        // Available = editor body minus toolbar, status pill, padding, pill area.
        let toolbarGap: CGFloat = 48
        let bottomGap: CGFloat = 44
        let overflowPad: CGFloat = 200
        let padding = DesignTokens.filmstripPadding
        let gap = DesignTokens.filmstripGap
        let pillH = FilmCellView.pillAreaHeight
        let maxAvailableH = screenFrame.height * 0.55
        let computedRowH = maxAvailableH - toolbarGap - bottomGap - pillH - padding * 2
        let rowH = min(max(computedRowH, LayoutCalculator.minRowHeight), LayoutCalculator.maxRowHeight)

        // VIB-313: Compute actual content width so filmstrip background hugs images tightly.
        // No extra dark space beyond the padding on each side.
        let sizes = store.images.map { $0.originalSize }
        let (_, totalContentWidth) = LayoutCalculator.computeFrames(
            imageSizes: sizes,
            rowHeight: rowH,
            gap: gap,
            titlePillTotalHeight: pillH
        )
        let contentWidth = totalContentWidth + padding * 2
        let gridWidth = min(contentWidth, maxWidth)

        grid.rowHeight = rowH
        grid.setFrameSize(NSSize(width: gridWidth, height: grid.frame.height))

        // Configure with current images
        grid.configure(with: store.images)

        // Compute final filmstrip height (row + pill + padding)
        let filmH = rowH + pillH + padding * 2

        // Resize grid to final size
        grid.setFrameSize(NSSize(width: gridWidth, height: filmH))

        // VIB-309: Update auto-save canvas size to match the grid frame,
        // so annotations export in the correct coordinate space.
        autoSaveManager?.canvasSize = NSSize(width: gridWidth, height: filmH)

        // Resize editor window to fit
        resizeWindowForFilmstrip(filmstripHeight: filmH, filmstripWidth: gridWidth)

        // VIB-268: Recalculate annotation positions for the new layout.
        // Must happen after resize so image frames are in their final positions.
        annotationStore.recalculateAbsolutePositions()
    }

    /// VIB-297: Resize the editor window for the horizontal scroll filmstrip.
    /// Fixed height (single row), wide enough for comfortable viewing.
    /// VIB-313: filmstripWidth parameter controls the grid width (content-hugging).
    private func resizeWindowForFilmstrip(filmstripHeight: CGFloat, filmstripWidth: CGFloat? = nil) {
        guard let screen = self.screen ?? NSScreen.main else { return }

        let toolbarGap: CGFloat = 48
        let bottomGap: CGFloat = 44
        let shadowPad: CGFloat = 24
        let overflowPad: CGFloat = 200
        let screenFrame = screen.visibleFrame

        // VIB-313: Use actual filmstrip width if provided, otherwise compute from screen
        let gridWidth = filmstripWidth ?? min(screenFrame.width * 0.85, 1600)
        let newTotalWidth = max(gridWidth, toolbarView.frame.width) + overflowPad * 2

        // VIB-297: Fixed height — single row, no multi-row growth
        let newTotalHeight = filmstripHeight + toolbarGap + bottomGap + shadowPad + overflowPad

        let newFrame = NSRect(
            x: screenFrame.midX - newTotalWidth / 2,
            y: screenFrame.midY - newTotalHeight / 2,
            width: newTotalWidth,
            height: newTotalHeight
        )

        setFrame(newFrame, display: true, animate: false)
        contentView?.setFrameSize(newFrame.size)

        // Resize and reposition grid
        let gridX = (newTotalWidth - gridWidth) / 2
        let canvasY = bottomGap + overflowPad / 2
        filmstripGridView?.setFrameOrigin(NSPoint(x: gridX, y: canvasY))
        filmstripGridView?.setFrameSize(NSSize(width: gridWidth, height: filmstripHeight))
        filmstripGridView?.needsLayout = true

        // Reposition toolbar above filmstrip
        let toolbarY = canvasY + filmstripHeight + (toolbarGap - DesignTokens.toolbarHeight) / 2
        toolbarView.setFrameOrigin(NSPoint(
            x: (newTotalWidth - toolbarView.frame.width) / 2,
            y: toolbarY
        ))

        // Reposition status pill below filmstrip
        let pillX = (newTotalWidth - statusPill.frame.width) / 2
        let pillY = canvasY - 32 - statusPill.frame.height
        statusPill.setFrameOrigin(NSPoint(x: pillX, y: pillY))

        // VIB-289: Resize annotation overlay to match the filmstrip grid frame
        if let canvas = canvasOverlay, let grid = filmstripGridView {
            canvas.frame = grid.frame
        }
    }

    /// VIB-266: Update the status pill for current image count.
    func updateStatusForMultiImage() {
        guard let store = captureStore else { return }
        if store.isComposite {
            let imgCount = store.images.count
            let noteCount = annotationStore.count
            let imgText = imgCount == 1 ? "1 image" : "\(imgCount) images"
            let noteText = noteCount == 1 ? "1 note" : "\(noteCount) notes"
            statusPill.updateCompositeText("composite \u{00B7} \(imgText) \u{00B7} \(noteText)")
        }
    }

    // MARK: - VIB-271: Image selection and deletion

    /// Select an image in the filmstrip. Mutually exclusive with annotation selection.
    private func selectImage(at index: Int) {
        // Deselect any selected annotation
        if annotationStore.selectedAnnotation != nil {
            annotationStore.deselectAll()
            canvasOverlay?.marksLayer.selectedId = nil
            canvasOverlay?.marksLayer.needsDisplay = true
        }

        selectedImageIndex = index
        filmstripGridView?.selectedImageIndex = index
        // Enable trash button for image deletion
        toolbarView.updateTrashState(hasSelection: true)
    }

    /// Clear image selection without selecting anything else.
    private func deselectImage() {
        selectedImageIndex = nil
        filmstripGridView?.selectedImageIndex = nil
    }

    /// Delete the image at the given index from the composite.
    private func deleteImage(at index: Int) {
        guard let store = captureStore, index < store.images.count else { return }

        // Snapshot for undo
        let deletedImage = store.images[index]
        let removedAnnotations = annotationStore.removeAnnotations(forImageIndex: index)

        // Clear image selection
        deselectImage()

        // Remove image from data model
        store.removeImage(at: index)

        // Shift annotation indices down for images above the deleted one
        annotationStore.shiftImageIndices(above: index)

        // Record undo action (before any UI transitions)
        undoRedoManager.record(.removeImage(
            image: deletedImage,
            annotations: removedAnnotations,
            imageIndex: index
        ))

        // Handle transitions
        if store.images.isEmpty {
            // 1→0: Close the editor
            autoSaveManager?.saveNow()
            close()
            return
        }

        if store.isSingleImage {
            // 2→1: Transition back to single-image mode
            transitionToSingleImage()
        } else {
            // N→N-1 (still composite): refresh filmstrip
            refreshFilmstrip()
        }

        // Update UI
        updateStatusForMultiImage()
        toolbarView.updateAddImageState(imageCount: store.images.count)
        toolbarView.updateTrashState(hasSelection: false)

        // Clean up stale image files and trigger auto-save
        if let folder = captureFolder {
            store.cleanupStaleImageFiles(in: folder)
        }
        autoSaveManager?.saveNow()
    }

    /// VIB-271: Transition from 2-image composite back to single-image mode.
    private func transitionToSingleImage() {
        guard let store = captureStore, store.isSingleImage else { return }
        guard let container = contentView else { return }

        // Animate title pills out
        filmstripGridView?.updatePillVisibility(show: false, animated: true)

        // Tear down filmstrip after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }

            // Remove filmstrip grid
            self.filmstripGridView?.removeFromSuperview()
            self.filmstripGridView = nil

            // Show single-image canvas view
            self.canvasView.isHidden = false

            // Reparent annotation overlay back onto canvasView
            if let canvas = self.canvasOverlay {
                canvas.removeFromSuperview()
                self.canvasView.addSubview(canvas)
                canvas.filmstripGrid = nil
                canvas.frame = NSRect(origin: .zero, size: self.canvasView.frame.size)
            }

            // Resize window back to single-image size
            self.resizeWindowForSingleImage()

            // Recalculate annotation positions for single-image layout
            self.annotationStore.recalculateAbsolutePositions()

            // Update auto-save canvas size
            self.autoSaveManager?.canvasSize = NSSize(
                width: self.displayWidth, height: self.displayHeight
            )

            // Update status pill
            if let img = store.images.first {
                self.statusPill.updateDimensions(
                    width: Int(img.originalSize.width),
                    height: Int(img.originalSize.height)
                )
            }
        }
    }

    /// VIB-271: Resize the editor window back to single-image dimensions.
    private func resizeWindowForSingleImage() {
        guard let screen = self.screen ?? NSScreen.main else { return }

        let toolbarGap: CGFloat = 48
        let bottomGap: CGFloat = 44
        let shadowPad: CGFloat = 24
        let overflowPad: CGFloat = 200
        let screenFrame = screen.visibleFrame
        let dw = displayWidth
        let dh = displayHeight

        let totalHeight = dh + toolbarGap + bottomGap + shadowPad + overflowPad
        let totalWidth = max(dw, toolbarView.frame.width) + overflowPad * 2

        let newFrame = NSRect(
            x: screenFrame.midX - totalWidth / 2,
            y: screenFrame.midY - totalHeight / 2,
            width: totalWidth,
            height: totalHeight
        )

        setFrame(newFrame, display: true, animate: true)
        contentView?.setFrameSize(newFrame.size)

        // Reposition canvas
        let canvasX = overflowPad + (totalWidth - overflowPad * 2 - dw) / 2
        let canvasY = bottomGap + overflowPad / 2
        canvasView.frame = NSRect(x: canvasX, y: canvasY, width: dw, height: dh)

        // Reposition toolbar
        let toolbarY = canvasY + dh + (toolbarGap - DesignTokens.toolbarHeight) / 2
        toolbarView.setFrameOrigin(NSPoint(
            x: (totalWidth - toolbarView.frame.width) / 2,
            y: toolbarY
        ))

        // Reposition status pill
        let pillX = (totalWidth - statusPill.frame.width) / 2
        let pillY = canvasY - 32 - statusPill.frame.height
        statusPill.setFrameOrigin(NSPoint(x: pillX, y: pillY))

        // Resize annotation overlay to match canvas
        canvasOverlay?.frame = NSRect(origin: .zero, size: NSSize(width: dw, height: dh))
    }
}

// MARK: - VIB-271: ImageUndoDelegate

extension EditorPanel: ImageUndoDelegate {

    func undoImageDeletion(image: CaptureImage, annotations: [Annotation], at index: Int) {
        guard let store = captureStore else { return }

        // Shift existing annotation indices up to make room
        annotationStore.shiftImageIndicesUp(at: index)

        // Re-insert the image at its original index
        store.insertImage(image, at: index)

        // Restore the removed annotations
        annotationStore.restoreAnnotations(annotations)

        // Rebuild the filmstrip (or transition from single→composite)
        if store.isComposite {
            refreshFilmstrip()
        }

        // Update UI
        updateStatusForMultiImage()
        toolbarView.updateAddImageState(imageCount: store.images.count)
        autoSaveManager?.saveNow()
    }

    func redoImageDeletion(at index: Int, removedAnnotations: [Annotation]) {
        guard let store = captureStore, index < store.images.count else { return }

        // Remove annotations for this image
        _ = annotationStore.removeAnnotations(forImageIndex: index)

        // Remove the image
        store.removeImage(at: index)

        // Shift annotation indices down
        annotationStore.shiftImageIndices(above: index)

        // Handle transitions
        if store.images.isEmpty {
            autoSaveManager?.saveNow()
            close()
            return
        }

        if store.isSingleImage {
            transitionToSingleImage()
        } else {
            refreshFilmstrip()
        }

        updateStatusForMultiImage()
        toolbarView.updateAddImageState(imageCount: store.images.count)

        if let folder = captureFolder {
            store.cleanupStaleImageFiles(in: folder)
        }
        autoSaveManager?.saveNow()
    }
}
