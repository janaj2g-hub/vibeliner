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

    // MARK: - Multi-image state
    private var images: [NSImage] = []
    private var imageRoles: [String] = []
    private var imageTitles: [String] = []
    private var filmstripView: FilmstripGridView?
    private var isFilmstripMode = false
    private var singleImageWindowFrame: NSRect?
    private var singleImageToolbarOrigin: NSPoint?
    private var singleImagePillOrigin: NSPoint?

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

        // Track images for multi-image support
        self.images = [image]
        self.imageRoles = ["observed"]
        self.imageTitles = ["Image 1"]

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

        // VIB-193 / VIB-326: Key monitor — use KeyEventGuard to detect ANY text editing,
        // not just canvas note editing. This prevents backspace/delete from being swallowed
        // when the title pill or other text inputs are active.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }

            // VIB-326: Broad guard — if ANY text field/editor is first responder, pass through.
            // Only intercept Escape for note editing cancellation.
            if !KeyEventGuard.shouldHandleShortcut(in: self) {
                if event.keyCode == 53, let canvas = self.canvasOverlay, canvas.isEditingNote {
                    canvas.cancelNoteEditing()
                    return nil  // consumed
                }
                return event  // pass through to text field (Cmd+C/V/A, arrows, backspace, etc.)
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

    // VIB-318: Safety nets — always restore cursor on deactivation or close
    override func resignKey() {
        super.resignKey()
        CursorManager.shared.forceShow()
    }

    override func close() {
        // VIB-326: Remove key monitor on close, not just deinit.
        // Prevents stale monitor from intercepting keys in the next editor.
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        CursorManager.shared.forceShow()
        super.close()
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
        // VIB-239: Cmd+W closes editor (replaces old Escape-closes behavior)
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
        } else if keyCode >= 18 && keyCode <= 23 && flags.isEmpty {
            let keyMap: [UInt16: AnnotationToolType] = [18: .select, 19: .pin, 20: .arrow, 21: .rectangle, 22: .circle, 23: .freehand]
            if let tool = keyMap[keyCode] {
                toolbarView.selectTool(tool)
                // VIB-334: Show cursor when switching to select tool via keyboard
                if tool == .select {
                    CursorManager.shared.showCursor()
                }
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
        // VIB-268: Pass CaptureStore so prompt includes "Image N:" prefixes in filmstrip mode
        let store = isFilmstripMode ? buildCaptureStore() : nil
        ClipboardManager.copyPromptToClipboard(annotations: annotationStore.annotations, captureFolder: folder, captureStore: store)
        statusPill.showCopied(message: "Prompt copied")
        toolbarView.markCopyState(.prompt)
    }

    /// Build a CaptureStore from the current multi-image state for prompt generation.
    private func buildCaptureStore() -> CaptureStore {
        let captureImages = images.enumerated().map { i, img in
            let title = i < imageTitles.count ? imageTitles[i] : "Image \(i + 1)"
            let roleStr = i < imageRoles.count ? imageRoles[i] : "observed"
            return CaptureImage(
                sourceImage: img,
                title: title,
                role: ImageRole.from(string: roleStr),
                originalSize: img.size,
                index: i
            )
        }
        return CaptureStore(images: captureImages)
    }

    func toolbarDidRequestNewCapture() {
        autoSaveManager?.saveNow()
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            CaptureCoordinator.shared.startCapture()
        }
    }

    func toolbarDidRequestCopyImage() {
        // VIB-372: Use actual canvas bounds — in filmstrip mode this is the imageAreaRect
        // (wider than the primary image), not displayWidth × displayHeight.
        let canvasSize = canvasOverlay?.bounds.size ?? CGSize(width: displayWidth, height: displayHeight)
        // VIB-383: Pass CaptureImage array with actual roles for composite stitching
        let captureImgs: [CaptureImage]? = isFilmstripMode ? buildCaptureStore().images : nil
        ClipboardManager.copyImageToClipboard(original: screenshotImage, annotations: annotationStore.annotations, canvasSize: canvasSize, captureImages: captureImgs)
        statusPill.showCopied(message: "Image copied")
        toolbarView.markCopyState(.image)
    }

    // MARK: - VIB-262/329: Add image

    func toolbarDidRequestAddImage() {
        guard images.count < 12 else { return }

        // Auto-save before hiding
        autoSaveManager?.saveNow()

        // VIB-329: Hide editor completely so it doesn't appear in the screenshot
        orderOut(nil)

        // Start add-image capture with cancel handler to restore editor
        CaptureCoordinator.shared.startAddImageCapture(
            completion: { [weak self] newImage in
                guard let self else { return }

                // Add the new image
                self.images.append(newImage)
                self.imageRoles.append("observed")
                self.imageTitles.append("Image \(self.images.count)")

                // Restore editor
                self.alphaValue = 1.0
                self.makeKeyAndOrderFront(nil)

                // Transition to filmstrip if going from 1→2, or refresh if already in filmstrip
                if self.images.count >= 2 {
                    if !self.isFilmstripMode {
                        self.transitionToFilmstrip()
                    } else {
                        self.refreshFilmstrip()
                    }
                }

                // VIB-297/VIB-383: Keep auto-save manager in sync for composite export
                self.autoSaveManager?.allImages = self.images
                self.autoSaveManager?.imageRoles = self.imageRoles
                self.autoSaveManager?.imageTitles = self.imageTitles

                // Update add image button state
                self.toolbarView.updateAddImageState(imageCount: self.images.count)
            },
            onCancel: { [weak self] in
                // VIB-329: Restore editor after canceled add-image capture
                self?.alphaValue = 1.0
                self?.makeKeyAndOrderFront(nil)
            }
        )
    }

    // MARK: - Filmstrip transition

    private func transitionToFilmstrip() {
        isFilmstripMode = true
        guard contentView != nil else { return }

        // Save original layout for restoration
        if singleImageWindowFrame == nil {
            singleImageWindowFrame = frame
            singleImageToolbarOrigin = toolbarView.frame.origin
            singleImagePillOrigin = statusPill.frame.origin
        }

        canvasView.isHidden = true
        layoutFilmstripMode(newFilmstrip: true)

        // Wire canvas click-through for cell selection (VIB-271: only with select tool)
        canvasOverlay?.onBackgroundClick = { [weak self] point in
            guard let self, let canvas = self.canvasOverlay, let filmstrip = self.filmstripView else { return }
            // Only switch filmstrip selection when the select tool is active
            guard self.toolbarView.selectedTool == .select else { return }
            let contentPoint = canvas.convert(point, to: filmstrip.scrollableContentView)
            filmstrip.selectCellAtPoint(contentPoint)
            self.filmstripCellSelected(filmstrip.selectedIndex)
        }

        // VIB-333: Resolve click point to image index for annotation assignment
        canvasOverlay?.imageIndexAtPoint = { [weak self] point in
            guard let self, let canvas = self.canvasOverlay, let filmstrip = self.filmstripView else { return 0 }
            let contentPoint = canvas.convert(point, to: filmstrip.scrollableContentView)
            return filmstrip.imageIndexAtPoint(contentPoint)
        }

        statusPill.updateNoteCount(annotationStore.count)
    }

    private func refreshFilmstrip() {
        layoutFilmstripMode(newFilmstrip: false)
    }

    /// Shared layout engine for filmstrip mode. Resizes the window, positions
    /// the filmstrip, toolbar, and status pill, and attaches the canvas overlay.
    private func layoutFilmstripMode(newFilmstrip: Bool) {
        guard let container = contentView, let screen = self.screen ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let overflowPad: CGFloat = 200
        let toolbarGap: CGFloat = 48
        let bottomGap: CGFloat = 44
        let shadowPad: CGFloat = 24
        let gap = DesignTokens.filmstripGap
        let pillTotalH = DesignTokens.titlePillHeight + DesignTokens.titlePillGap
        let imageSizes = images.map { $0.size }

        // VIB-339: Window grows to accommodate images — up to 85% of screen width.
        // Images should never shrink more than ~15% from single-image display.
        let maxFilmstripW = screenFrame.width * 0.85 - overflowPad * 2

        // Compute row height at max width (respects 250px min cell width)
        let rowHeight = FilmstripGridView.computeFittingRowHeight(
            imageSizes: imageSizes,
            availableWidth: maxFilmstripW,
            availableHeight: LayoutCalculator.maxRowHeight,
            gap: gap
        )

        // Content width at this row height
        let (_, contentWidth) = LayoutCalculator.computeFrames(
            imageSizes: imageSizes, rowHeight: rowHeight, gap: gap, titlePillTotalHeight: pillTotalH
        )

        // Filmstrip dimensions: fit content up to max, scroll for the rest
        let filmstripWidth = min(contentWidth, maxFilmstripW)
        let filmstripHeight = rowHeight + pillTotalH

        // Window dimensions
        let winWidth = max(filmstripWidth, toolbarView.frame.width) + overflowPad * 2
        let winHeight = filmstripHeight + toolbarGap + bottomGap + shadowPad + overflowPad
        // VIB-339: Center window on screen, clamp to visible area
        let winX = max(screenFrame.minX, min(screenFrame.maxX - winWidth, screenFrame.midX - winWidth / 2))
        let winY = max(screenFrame.minY, min(screenFrame.maxY - winHeight, screenFrame.midY - winHeight / 2))
        let newFrame = NSRect(
            x: winX,
            y: winY,
            width: winWidth,
            height: winHeight
        )
        setFrame(newFrame, display: true, animate: false)
        container.frame = NSRect(origin: .zero, size: newFrame.size)

        // Filmstrip position: centered horizontally
        let filmstripX = (winWidth - filmstripWidth) / 2
        let filmstripY = bottomGap + overflowPad / 2

        if newFilmstrip {
            // Create filmstrip
            let filmstrip = FilmstripGridView(frame: NSRect(
                x: filmstripX, y: filmstripY, width: filmstripWidth, height: filmstripHeight
            ))
            filmstrip.setImages(images, roles: imageRoles, selectedIndex: images.count - 1)
            filmstrip.onCellSelected = { [weak self] index in
                self?.filmstripCellSelected(index)
            }
            filmstrip.onRoleChanged = { [weak self] index, newRole in
                guard let self, index < self.imageRoles.count else { return }
                self.imageRoles[index] = newRole.name.lowercased()
                // VIB-383: Sync role change to auto-save manager
                self.autoSaveManager?.imageRoles = self.imageRoles
            }
            filmstrip.onTitleChanged = { [weak self] index, newTitle in
                guard let self, index < self.imageTitles.count else { return }
                self.imageTitles[index] = newTitle
                // VIB-383: Sync title change to auto-save manager
                self.autoSaveManager?.imageTitles = self.imageTitles
            }
            filmstrip.onDeleteImage = { [weak self] index in
                self?.removeImageAtIndex(index)
            }
            canvasOverlay?.removeFromSuperview()
            container.addSubview(filmstrip)
            self.filmstripView = filmstrip
        } else if let filmstrip = filmstripView {
            // Update existing filmstrip
            canvasOverlay?.removeFromSuperview()
            filmstrip.frame = NSRect(
                x: filmstripX, y: filmstripY, width: filmstripWidth, height: filmstripHeight
            )
            let idx = min(filmstrip.selectedIndex, images.count - 1)
            filmstrip.setImages(images, roles: imageRoles, selectedIndex: idx)
        }

        guard let filmstrip = filmstripView else { return }

        // Reposition toolbar above filmstrip
        let toolbarX = (winWidth - toolbarView.frame.width) / 2
        let toolbarY = filmstripY + filmstripHeight + (toolbarGap - DesignTokens.toolbarHeight) / 2
        toolbarView.setFrameOrigin(NSPoint(x: toolbarX, y: toolbarY))

        // Status pill 32px below filmstrip
        let pillX = (winWidth - statusPill.frame.width) / 2
        let pillY = filmstripY - 32 - statusPill.frame.height
        statusPill.setFrameOrigin(NSPoint(x: pillX, y: pillY))

        // Canvas overlay in filmstrip's scrollable content view
        canvasOverlay?.frame = filmstrip.imageAreaRect
        filmstrip.scrollableContentView.addSubview(canvasOverlay ?? NSView())
        canvasOverlay?.updateTrackingAreas()

        // VIB-372: Update auto-save canvas size to match the actual filmstrip canvas bounds
        autoSaveManager?.canvasSize = filmstrip.imageAreaRect.size

        // VIB-339: Recalculate annotation positions after layout change
        recalculateAnnotationPositions()
    }

    private func removeImageAtIndex(_ index: Int) {
        guard index < images.count, images.count > 1 else { return }

        // VIB-271: Clean up annotations belonging to the deleted image
        annotationStore.removeAnnotations(forImageIndex: index)
        annotationStore.shiftImageIndices(above: index)

        images.remove(at: index)
        imageRoles.remove(at: index)
        if index < imageTitles.count { imageTitles.remove(at: index) }

        if images.count == 1 {
            transitionBackToSingleImage()
        } else {
            refreshFilmstrip()
        }

        canvasOverlay?.marksLayer.needsDisplay = true
        canvasOverlay?.refreshNotePills()
        autoSaveManager?.allImages = images.count > 1 ? images : nil
        autoSaveManager?.imageRoles = imageRoles
        autoSaveManager?.imageTitles = imageTitles
        toolbarView.updateAddImageState(imageCount: images.count)
    }

    private func transitionBackToSingleImage() {
        isFilmstripMode = false

        filmstripView?.removeFromSuperview()
        filmstripView = nil

        // Restore original window frame and positions
        if let originalFrame = singleImageWindowFrame {
            setFrame(originalFrame, display: true, animate: false)
            contentView?.frame = NSRect(origin: .zero, size: originalFrame.size)
        }
        if let origin = singleImageToolbarOrigin {
            toolbarView.setFrameOrigin(origin)
        }
        if let origin = singleImagePillOrigin {
            statusPill.setFrameOrigin(origin)
        }
        singleImageWindowFrame = nil
        singleImageToolbarOrigin = nil
        singleImagePillOrigin = nil

        canvasView.isHidden = false
        canvasOverlay?.removeFromSuperview()
        canvasOverlay?.frame = NSRect(x: 0, y: 0, width: displayWidth, height: displayHeight)
        canvasOverlay?.onBackgroundClick = nil
        canvasOverlay?.imageIndexAtPoint = nil
        canvasView.addSubview(canvasOverlay ?? NSView())
        canvasOverlay?.updateTrackingAreas()

        annotationStore.currentImageIndex = 0

        // VIB-339: Recalculate annotation positions after returning to single-image
        recalculateAnnotationPositions()
    }

    private func filmstripCellSelected(_ index: Int) {
        // VIB-269: Track which image is active so new annotations get the right parentImageIndex
        annotationStore.currentImageIndex = index
    }

    // MARK: - VIB-339: Coordinate system helpers

    /// Returns the image frame for the given index in CanvasView-local coordinates.
    /// In single-image mode, this is the full canvas bounds.
    /// In filmstrip mode, this is the cell's image area relative to imageAreaRect.
    func imageFrameInCanvas(at index: Int) -> NSRect {
        if let filmstrip = filmstripView, isFilmstripMode {
            return filmstrip.imageCellFrameInCanvas(at: index)
        }
        // Single image: entire canvas
        return canvasOverlay?.bounds ?? NSRect(x: 0, y: 0, width: displayWidth, height: displayHeight)
    }

    /// VIB-339: Recalculate absolute annotation positions from their stored relative
    /// coordinates after any layout change (filmstrip transition, add/delete image, resize).
    private func recalculateAnnotationPositions() {
        annotationStore.recalculateAbsolutePositions { [weak self] imageIndex in
            self?.imageFrameInCanvas(at: imageIndex) ?? .zero
        }
        canvasOverlay?.marksLayer.needsDisplay = true
        canvasOverlay?.refreshNotePills()
    }

    /// VIB-339: Compute and store relative coordinates for an annotation,
    /// given its current absolute position. Called after creation and after drag.
    func setRelativeCoords(for annotationId: UUID) {
        guard let annotation = annotationStore.annotation(for: annotationId) else { return }
        let imageFrame = imageFrameInCanvas(at: annotation.parentImageIndex)

        let endFrame: CGRect?
        if let endIdx = annotation.endImageIndex {
            endFrame = imageFrameInCanvas(at: endIdx)
        } else {
            endFrame = nil
        }

        let relPos = CoordinateConverter.positionToRelative(
            annotation.position, parentFrame: imageFrame, endFrame: endFrame
        )
        let relBadge = CoordinateConverter.absoluteToRelative(
            point: annotation.badgePosition, imageFrame: imageFrame
        )
        annotationStore.setRelativeCoords(id: annotationId, relativePosition: relPos, relativeBadgePosition: relBadge)
    }
}
