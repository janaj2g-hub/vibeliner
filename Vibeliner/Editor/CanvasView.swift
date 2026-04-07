import AppKit

final class CanvasView: NSView, NotePillDelegate {

    let marksLayer: MarksLayerView
    let notesLayer: NSView
    var activeTool: AnnotationTool?
    var selectTool: SelectTool?
    var store: AnnotationStore
    var undoManager_: UndoRedoManager?
    /// VIB-294: Reference to the filmstrip grid for title pill hit-testing.
    weak var filmstripGrid: FilmstripGridView?
    /// VIB-269: Reference to capture store for image prefix computation.
    weak var captureStore: CaptureStore?
    /// VIB-271: Called when user clicks on an image area (not annotation) in composite mode.
    var onImageClicked: ((Int) -> Void)?
    private var storeObserver: Any?
    private var ghostPosition: CGPoint?

    init(frame: NSRect, store: AnnotationStore) {
        self.store = store
        marksLayer = MarksLayerView(frame: NSRect(origin: .zero, size: frame.size), store: store)
        marksLayer.wantsLayer = true
        marksLayer.layer?.masksToBounds = true

        notesLayer = NSView(frame: NSRect(origin: .zero, size: frame.size))
        notesLayer.wantsLayer = true
        notesLayer.layer?.masksToBounds = false

        super.init(frame: NSRect(origin: .zero, size: frame.size))
        // VIB-167: CanvasView must not clip notes layer
        wantsLayer = true
        layer?.masksToBounds = false

        addSubview(marksLayer)
        addSubview(notesLayer)

        storeObserver = NotificationCenter.default.addObserver(
            forName: .annotationsDidChange, object: store, queue: .main
        ) { [weak self] _ in
            self?.marksLayer.needsDisplay = true
            self?.refreshNotePills()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    /// VIB-296: Resize marksLayer and notesLayer to match the canvas bounds.
    /// Without this, switching to filmstrip mode leaves the sublayers at the
    /// original single-image size, causing annotations to clip or misplace.
    override func layout() {
        super.layout()
        marksLayer.frame = bounds
        notesLayer.frame = bounds
    }

    /// VIB-294: Pass through mouse events that land on title pill areas.
    /// The canvas overlay sits above the filmstrip grid in z-order, intercepting
    /// all events. Title pills need to receive clicks for name editing and role changes.
    override func hitTest(_ point: NSPoint) -> NSView? {
        if let grid = filmstripGrid, grid.isComposite {
            for cell in grid.cellViews {
                let pill = cell.titlePill
                guard !pill.isHidden else { continue }
                // Convert pill frame from pill's superview (the cell) to our superview's coordinate space
                let pillInCell = pill.frame
                let pillInGrid = cell.convert(pillInCell, to: grid)
                // Grid and canvas are siblings in the same container — convert through superview
                let pillInContainer = grid.convert(pillInGrid, to: superview)
                if pillInContainer.contains(point) {
                    return nil  // pass through to the pill below
                }
            }
        }
        return super.hitTest(point)
    }

    // MARK: - VIB-268: Image frame provider

    /// Returns image frames in canvas (non-flipped) coordinate space.
    /// In single-image mode: returns the canvas bounds as a single frame.
    /// In composite mode: converts FilmstripGridView's image frames to canvas coords.
    func imageFramesInCanvasCoords() -> [CGRect] {
        guard let grid = filmstripGrid, grid.isComposite else {
            // Single image: the entire canvas is the image
            return [bounds]
        }

        return grid.imageFrames.map { gridRect in
            // Convert rect corners from grid's flipped coordinate space
            // to canvas's non-flipped coordinate space via NSView.convert
            let topLeft = grid.convert(gridRect.origin, to: self)
            let bottomRight = grid.convert(
                CGPoint(x: gridRect.maxX, y: gridRect.maxY), to: self
            )
            return CGRect(
                x: min(topLeft.x, bottomRight.x),
                y: min(topLeft.y, bottomRight.y),
                width: abs(bottomRight.x - topLeft.x),
                height: abs(bottomRight.y - topLeft.y)
            )
        }
    }

    deinit {
        if let observer = storeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeAlways, .mouseEnteredAndExited], owner: self))
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        ghostPosition = point
        activeTool?.mouseMoved(to: point, in: self)
        marksLayer.ghostPosition = point
        marksLayer.ghostTool = activeTool

        // Hit-test for shape hover (must run before cursor/ghost logic)
        let oldHovered = shapeHoveredId
        shapeHoveredId = hitTestAnnotation(at: point)
        if shapeHoveredId != oldHovered {
            marksLayer.hoveredId = shapeHoveredId
            refreshNotePills()
        }

        // VIB-314: In composite mode, check if mouse is over an actual image area
        // (not a filmstrip gap, title pill, or padding). Ghost only shows over images.
        let isOverGap: Bool
        if let grid = filmstripGrid, grid.isComposite {
            let pointInGrid = convert(point, to: grid)
            isOverGap = !grid.imageFrames.contains { $0.contains(pointInGrid) }
        } else {
            isOverGap = false  // Single image mode: ghost works everywhere
        }

        // VIB-221: Suppress ghost when hovering annotation with drawing tool (unless mid-stroke)
        // VIB-314: Also suppress when over filmstrip gap/pill area
        let isDrawingToolActive = activeTool?.toolType.isDrawingTool == true
        let isHoveringAnnotation = (shapeHoveredId != nil || pillHoveredId != nil)
        let isActivelyDrawing = activeTool?.isActivelyDrawing == true
        let shouldSuppressGhost = isDrawingToolActive && !isActivelyDrawing && (isHoveringAnnotation || isOverGap)
        marksLayer.suppressGhost = shouldSuppressGhost

        // VIB-201/VIB-221/VIB-223/VIB-314: Cursor management
        // Use setHiddenUntilMouseMoves(true) instead of hide() — it auto-unhides when
        // the cursor enters a different NSView (e.g. toolbar), avoiding reference-count imbalance.
        if isDrawingToolActive && !isEditingNote {
            if shouldSuppressGhost {
                NSCursor.unhide()
                NSCursor.arrow.set()
            } else {
                NSCursor.setHiddenUntilMouseMoves(true)
            }
        } else {
            NSCursor.unhide()
        }

        marksLayer.needsDisplay = true
    }

    // Hit testing matching prototype ht() function
    // Priority: badge(12px) → arrow endpoint(10px) → rect corners(10px) → circle resize(10px) → body containment → freehand CPs(8px)
    private func hitTestAnnotation(at point: CGPoint) -> UUID? {
        for annotation in store.annotations.reversed() {
            // Badge proximity (12px)
            if hypot(point.x - annotation.badgePosition.x, point.y - annotation.badgePosition.y) < 12 {
                return annotation.id
            }

            switch annotation.position {
            case .arrow(_, let end):
                // Arrow endpoint (10px)
                if hypot(point.x - end.x, point.y - end.y) < 10 {
                    return annotation.id
                }

            case .rectangle(let origin, let size):
                // Rectangle corners (10px)
                let corners = [
                    CGPoint(x: origin.x, y: origin.y),
                    CGPoint(x: origin.x + size.width, y: origin.y),
                    CGPoint(x: origin.x, y: origin.y + size.height),
                    CGPoint(x: origin.x + size.width, y: origin.y + size.height)
                ]
                for corner in corners {
                    if hypot(point.x - corner.x, point.y - corner.y) < 10 {
                        return annotation.id
                    }
                }
                // Body containment (±5px)
                if point.x >= origin.x - 5 && point.x <= origin.x + size.width + 5 &&
                   point.y >= origin.y - 5 && point.y <= origin.y + size.height + 5 {
                    return annotation.id
                }

            case .circle(let center, let radius):
                // Opposite handle (10px)
                let bx = annotation.badgePosition.x
                let by = annotation.badgePosition.y
                let ox = center.x * 2 - bx
                let oy = center.y * 2 - by
                if hypot(point.x - ox, point.y - oy) < 10 {
                    return annotation.id
                }
                // Body containment
                if hypot(point.x - center.x, point.y - center.y) < radius + 8 {
                    return annotation.id
                }

            case .freehand(let pts):
                // Control point proximity (8px)
                for cp in pts {
                    if hypot(point.x - cp.x, point.y - cp.y) < 8 {
                        return annotation.id
                    }
                }

            case .pin:
                break // badge already checked above
            }
        }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        marksLayer.suppressGhost = false

        // VIB-193: Click outside editing pill = commit text
        if isEditingNote {
            let clickInPill = activeEditorPill.map { $0.frame.contains(point) } ?? false
            if !clickInPill {
                confirmNoteEditing()
                return  // Don't process as a tool action
            }
        }

        guard let undoMgr = undoManager_ else { return }

        // VIB-217: When a drawing tool is active, check for hits on existing annotations first
        if let tool = activeTool, tool.toolType != .select {
            if let hitId = hitTestAnnotation(at: point) {
                handleEditHit(id: hitId, at: point)
                return
            }
            // No hit — if a shape was previously selected, deselect it first
            if marksLayer.selectedId != nil {
                store.deselectAll()
                marksLayer.selectedId = nil
                marksLayer.needsDisplay = true
            }
            // Fall through to activeTool?.mouseDown (creates new shape)
        }

        // VIB-271: When select tool is active and no annotation is hit in composite mode,
        // check if user clicked on an image area → report as image selection.
        if let tool = activeTool, tool.toolType == .select {
            let hitAnnotation = hitTestAnnotation(at: point)
            if hitAnnotation == nil, let grid = filmstripGrid, grid.isComposite {
                let pointInGrid = convert(point, to: grid)
                if let imgIdx = grid.imageIndex(at: pointInGrid) {
                    onImageClicked?(imgIdx)
                    return
                }
            }
        }

        activeTool?.mouseDown(at: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
    }

    private func handleEditHit(id: UUID, at point: CGPoint) {
        if pillHoveredId == id, let annotation = store.annotation(for: id) {
            openNoteEditor(for: annotation)
            return
        }
        guard let undoMgr = undoManager_ else { return }
        store.select(id: id)
        marksLayer.selectedId = id
        window?.makeKey()
        selectTool?.mouseDown(at: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
        refreshNotePills()
    }

    override func mouseDragged(with event: NSEvent) {
        // VIB-193: Don't intercept drags while editing — let text field handle selection
        if isEditingNote { return }
        let point = convert(event.locationInWindow, from: nil)
        guard let undoMgr = undoManager_ else { return }
        // VIB-217: Route drags through selectTool when a shape is selected with a drawing tool
        if let tool = activeTool, tool.toolType != .select, marksLayer.selectedId != nil {
            selectTool?.mouseDragged(to: point, in: self, store: store, undoManager: undoMgr)
        } else {
            activeTool?.mouseDragged(to: point, in: self, store: store, undoManager: undoMgr)
        }
        marksLayer.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        // VIB-193: Don't intercept mouseUp while editing
        if isEditingNote { return }
        let point = convert(event.locationInWindow, from: nil)
        guard let undoMgr = undoManager_ else { return }
        // VIB-217: Mirror drag routing for mouseUp
        if let tool = activeTool, tool.toolType != .select, marksLayer.selectedId != nil {
            selectTool?.mouseUp(at: point, in: self, store: store, undoManager: undoMgr)
        } else {
            activeTool?.mouseUp(at: point, in: self, store: store, undoManager: undoMgr)
        }
        marksLayer.needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.unhide()
        marksLayer.suppressGhost = false
        ghostPosition = nil
        marksLayer.ghostPosition = nil
        marksLayer.needsDisplay = true
    }

    func refreshNotePills() {
        let prefixes = computeImagePrefixes()
        NotePillRenderer.drawNotePills(in: notesLayer, annotations: store.annotations, canvasSize: bounds.size, hoveredId: pillHoveredId, selectedId: store.selectedAnnotation?.id, editingId: editingAnnotationId, delegate: self, imagePrefixes: prefixes)
    }

    /// VIB-269: Compute image prefix strings for annotations in composite mode.
    /// Returns a map of annotation ID → prefix string (e.g., "Image 2" or "Image 1 → Image 3").
    private func computeImagePrefixes() -> [UUID: String] {
        guard let capStore = captureStore, capStore.isComposite else { return [:] }
        var prefixes: [UUID: String] = [:]
        let images = capStore.images
        for a in store.annotations {
            let parentIdx = a.parentImageIndex
            let parentTitle = parentIdx < images.count ? images[parentIdx].title : "Image \(parentIdx + 1)"
            if case .arrow = a.position, let endIdx = a.endImageIndex, endIdx != parentIdx {
                let endTitle = endIdx < images.count ? images[endIdx].title : "Image \(endIdx + 1)"
                prefixes[a.id] = "\(parentTitle) → \(endTitle)"
            } else {
                prefixes[a.id] = parentTitle
            }
        }
        return prefixes
    }

    // MARK: - NotePillDelegate

    func notePillHovered(annotationId: UUID?) {
        let oldPillHovered = pillHoveredId
        pillHoveredId = annotationId
        if pillHoveredId != oldPillHovered {
            // VIB-203/215: Do NOT set marksLayer.hoveredId here — pill hover is independent from shape hover
            // VIB-221: Suppress ghost when pill hovered with drawing tool active
            let isDrawingToolActive = activeTool?.toolType.isDrawingTool == true
            marksLayer.suppressGhost = isDrawingToolActive && (pillHoveredId != nil || shapeHoveredId != nil)
            marksLayer.needsDisplay = true
            refreshNotePills()
            // VIB-221: Show arrow cursor when pill hovered with drawing tool
            if isDrawingToolActive && !isEditingNote && pillHoveredId != nil {
                NSCursor.unhide()
                NSCursor.arrow.set()
            }
        }
    }

    func notePillClicked(annotationId: UUID) {
        // Clicking a note pill opens it for editing
        guard let annotation = store.annotation(for: annotationId) else { return }
        openNoteEditor(for: annotation)
    }

    var activeNoteField: NSTextField?
    private var editingAnnotationId: UUID?
    private var noteFieldDelegate: CanvasNoteFieldDelegate?
    // VIB-215: Separate shape hover (drives marksLayer halo) from pill hover (drives pill highlight)
    private var shapeHoveredId: UUID?
    private var pillHoveredId: UUID?

    private var activeEditorPill: NSView?

    func openNoteEditor(for annotation: Annotation) {
        NSCursor.unhide()  // VIB-201: Restore cursor when editor opens
        activeNoteField?.removeFromSuperview()
        activeEditorPill?.removeFromSuperview()

        // VIB-162: Get raw placement with anchor, apply anchor using EDITING pill width
        let placement = NotePillRenderer.notePlacementForEditing(for: annotation)
        let maxPillW: CGFloat = 180  // VIB-209: match resting pill max width to prevent reflow on commit
        // VIB-192 (attempt 5): Configure temp field with wrapping to get correct multi-line height
        // VIB-269: Account for image prefix width in composite mode
        let estPrefixW: CGFloat
        if let capStore = captureStore, capStore.isComposite {
            // number (~12) + gap (4) + image prefix (~50) + gap (7) = ~73
            estPrefixW = 70
        } else {
            estPrefixW = 20  // just number prefix
        }
        let estTextX: CGFloat = 12 + estPrefixW + 7  // prefix area + gap
        let maxTextW = maxPillW - estTextX - 12
        let tempField = NSTextField(labelWithString: annotation.noteText)
        tempField.font = DesignTokens.noteTextFont
        tempField.maximumNumberOfLines = 0
        tempField.lineBreakMode = .byWordWrapping
        tempField.cell?.wraps = true
        // VIB-204 (attempt 2): Use cellSize(forBounds:) — same pattern that works in NotePillView.init
        let cellBounds = NSRect(x: 0, y: 0, width: maxTextW, height: CGFloat.greatestFiniteMagnitude)
        let fittedSize = tempField.cell?.cellSize(forBounds: cellBounds) ?? NSSize(width: maxTextW, height: 16)
        let pillH = max(DesignTokens.noteHeight, fittedSize.height + 8)
        // Apply anchor transform with the EDITING pill width (200px, not resting 130px)
        let pillPos = NotePillRenderer.anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: maxPillW, pillHeight: pillH)

        let pillContainer = NSView(frame: NSRect(x: pillPos.x, y: pillPos.y, width: maxPillW, height: pillH))
        pillContainer.wantsLayer = true
        pillContainer.layer?.masksToBounds = false

        // Shadow
        pillContainer.layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
        pillContainer.layer?.shadowOffset = CGSize(width: 0, height: -1)
        pillContainer.layer?.shadowRadius = 4
        pillContainer.layer?.shadowOpacity = 1

        // VIB-197: Use PillChromeBuilder for blur, tint, and prefix (single source of truth)
        let chrome = PillChromeBuilder.build(size: NSSize(width: maxPillW, height: pillH), number: annotation.number)
        pillContainer.layer?.addSublayer(chrome.blurLayer)
        // Apply editing state colors directly
        chrome.tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.961, blue: 0.961, alpha: 0.92).cgColor
        chrome.tintView.layer?.borderColor = DesignTokens.red.cgColor
        pillContainer.addSubview(chrome.tintView)
        pillContainer.addSubview(chrome.prefixLabel)

        // VIB-197: Use PillChromeBuilder for editable text field
        let numberLabel = chrome.prefixLabel
        var totalPrefixWidth = numberLabel.frame.width

        // VIB-269: Add non-editable image prefix label in composite mode
        if let capStore = captureStore, capStore.isComposite {
            let images = capStore.images
            let parentIdx = annotation.parentImageIndex
            let parentTitle = parentIdx < images.count ? images[parentIdx].title : "Image \(parentIdx + 1)"
            let prefixText: String
            if case .arrow = annotation.position, let endIdx = annotation.endImageIndex, endIdx != parentIdx {
                let endTitle = endIdx < images.count ? images[endIdx].title : "Image \(endIdx + 1)"
                prefixText = "\(parentTitle) → \(endTitle):"
            } else {
                prefixText = "\(parentTitle):"
            }
            let imgPrefixLabel = NSTextField(labelWithString: prefixText)
            imgPrefixLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
            imgPrefixLabel.textColor = DesignTokens.notePrefixColor
            imgPrefixLabel.isBezeled = false
            imgPrefixLabel.drawsBackground = false
            imgPrefixLabel.sizeToFit()
            imgPrefixLabel.frame.origin = NSPoint(
                x: numberLabel.frame.maxX + 4,
                y: (pillH - imgPrefixLabel.frame.height) / 2
            )
            pillContainer.addSubview(imgPrefixLabel)
            totalPrefixWidth = numberLabel.frame.width + 4 + imgPrefixLabel.frame.width
        }

        let textField = PillChromeBuilder.createEditableTextField(
            pillWidth: maxPillW, pillHeight: pillH,
            text: annotation.noteText, prefixWidth: totalPrefixWidth
        )

        // Red caret color
        if let fieldEditor = textField.window?.fieldEditor(true, for: textField) as? NSTextView {
            fieldEditor.insertionPointColor = DesignTokens.red
        }

        let delegate = CanvasNoteFieldDelegate(canvas: self)
        self.noteFieldDelegate = delegate
        textField.delegate = delegate
        textField.target = delegate
        textField.action = #selector(CanvasNoteFieldDelegate.confirmNote(_:))

        pillContainer.addSubview(textField)

        // VIB-204 (attempt 3): Set editingAnnotationId BEFORE adding pill to view
        // so refreshNotePills() removes the resting pill (no ghost behind editing pill)
        editingAnnotationId = annotation.id
        refreshNotePills()

        notesLayer.addSubview(pillContainer)
        activeNoteField = textField
        activeEditorPill = pillContainer

        // VIB-193: Force panel to become key so makeFirstResponder works
        DispatchQueue.main.async { [weak self, weak textField] in
            guard let self, let window = self.window, let tf = textField else { return }
            window.makeKeyAndOrderFront(nil)  // Must be key window for first responder
            window.makeFirstResponder(tf)
            if let fieldEditor = window.fieldEditor(true, for: tf) as? NSTextView {
                fieldEditor.insertionPointColor = DesignTokens.red
                // VIB-192 (attempt 5): Place cursor at END of text, not select-all
                fieldEditor.setSelectedRange(NSRange(location: fieldEditor.string.count, length: 0))
            }
        }
    }

    /// VIB-162: Resize editing pill as text grows
    func resizeEditingPill() {
        guard let pill = activeEditorPill, let field = activeNoteField else { return }
        let minH = DesignTokens.noteHeight
        // VIB-204: Get LIVE text from the field editor, not stale stringValue
        let liveText: String
        if let fieldEditor = field.currentEditor() as? NSTextView {
            liveText = fieldEditor.string
        } else {
            liveText = field.stringValue
        }
        guard !liveText.isEmpty else { return }
        // Measure with a temp label matching the editing field's wrapping config
        let measurer = NSTextField(labelWithString: liveText)
        measurer.font = DesignTokens.noteTextFont
        measurer.maximumNumberOfLines = 0
        measurer.lineBreakMode = .byWordWrapping
        measurer.cell?.wraps = true
        // VIB-204 (attempt 2): Use cellSize(forBounds:) — same pattern that works in NotePillView.init
        let cellBounds = NSRect(x: 0, y: 0, width: field.frame.width, height: CGFloat.greatestFiniteMagnitude)
        let fittedSize = measurer.cell?.cellSize(forBounds: cellBounds) ?? NSSize(width: field.frame.width, height: 16)
        let newH = max(minH, fittedSize.height + 8)

        if abs(pill.frame.height - newH) > 1 {
            let heightDelta = newH - pill.frame.height
            pill.frame.origin.y -= heightDelta  // keep top edge fixed (AppKit y-up)
            pill.setFrameSize(NSSize(width: pill.frame.width, height: newH))
            for sub in pill.subviews {
                if sub.layer?.cornerRadius == DesignTokens.noteCornerRadius {
                    sub.frame = NSRect(origin: .zero, size: pill.frame.size)
                }
            }
            if let blurLayer = pill.layer?.sublayers?.first(where: { $0.cornerRadius == DesignTokens.noteCornerRadius }) {
                blurLayer.frame = NSRect(origin: .zero, size: pill.frame.size)
            }
            field.frame = NSRect(x: field.frame.origin.x, y: 4, width: field.frame.width, height: newH - 8)
            for sub in pill.subviews {
                if let label = sub as? NSTextField, label.font?.pointSize == 8 {
                    label.frame.origin.y = (newH - label.frame.height) / 2
                    break
                }
            }
        }
    }

    func confirmNoteEditing() {
        guard let id = editingAnnotationId, let field = activeNoteField else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            store.remove(id: id)
        } else {
            store.update(id: id, noteText: text)
            if let _ = store.annotation(for: id) {
                undoManager_?.record(.editText(id: id, oldText: "", newText: text))
            }
        }
        activeEditorPill?.removeFromSuperview()
        activeEditorPill = nil
        activeNoteField = nil
        editingAnnotationId = nil
        noteFieldDelegate = nil
        refreshNotePills()
        if activeTool?.toolType.isDrawingTool == true {
            marksLayer.ghostTool = activeTool
        }
        marksLayer.needsDisplay = true
    }

    func cancelNoteEditing() {
        guard let id = editingAnnotationId else { return }
        if let annotation = store.annotation(for: id), annotation.noteText.isEmpty {
            store.remove(id: id)
        }
        activeEditorPill?.removeFromSuperview()
        activeEditorPill = nil
        activeNoteField = nil
        editingAnnotationId = nil
        noteFieldDelegate = nil
        refreshNotePills()
        if activeTool?.toolType.isDrawingTool == true {
            marksLayer.ghostTool = activeTool
        }
        marksLayer.needsDisplay = true
    }

    var isEditingNote: Bool { activeNoteField != nil }
}

// MARK: - Note field delegate

final class CanvasNoteFieldDelegate: NSObject, NSTextFieldDelegate {
    weak var canvas: CanvasView?

    init(canvas: CanvasView) {
        self.canvas = canvas
        super.init()
    }

    @objc func confirmNote(_ sender: NSTextField) {
        canvas?.confirmNoteEditing()
    }

    // VIB-162: Resize pill on text changes so all text is visible
    func controlTextDidChange(_ obj: Notification) {
        canvas?.resizeEditingPill()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            canvas?.cancelNoteEditing()
            return true
        }
        return false
    }
}

// MARK: - Marks Layer (draws annotations + ghost)

final class MarksLayerView: NSView {

    var ghostPosition: CGPoint?
    var ghostTool: AnnotationTool?
    var hoveredId: UUID?
    var selectedId: UUID?
    var suppressGhost: Bool = false  // VIB-221: set true when hovering annotation with drawing tool
    private let store: AnnotationStore
    private let pinRenderer = PinRenderer()
    private let arrowRenderer = ArrowRenderer()
    private let rectangleRenderer = RectangleRenderer()
    private let circleRenderer = CircleRenderer()
    private let freehandRenderer = FreehandRenderer()

    init(frame: NSRect, store: AnnotationStore) {
        self.store = store
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // VIB-216 Pass 1: Draw all shapes WITHOUT badges (so hover halo renders beneath badges)
        pinRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        arrowRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        rectangleRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        circleRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        freehandRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)

        // VIB-216 Pass 2: Draw hover glow
        if let hId = hoveredId, let annotation = store.annotations.first(where: { $0.id == hId }) {
            let bp = annotation.badgePosition

            // Badge glow (keep existing)
            let glowRadius = DesignTokens.badgeDiameter / 2 + 7 // prototype: badgeR + 7
            context.setFillColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.08).cgColor)
            context.fillEllipse(in: CGRect(x: bp.x - glowRadius, y: bp.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2))

            // VIB-203: Shape halo — draw thicker/warmer version behind the shape with soft shadow
            context.saveGState()
            context.setShadow(offset: .zero, blur: 6, color: NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.20).cgColor)

            switch annotation.position {
            case .pin:
                // Stake halo
                let stakeTopY = bp.y - DesignTokens.badgeDiameter / 2
                let stakeBottomY = stakeTopY - DesignTokens.stakeLength
                context.setStrokeColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.3).cgColor)
                context.setLineWidth(6)
                context.setLineCap(.round)
                context.move(to: CGPoint(x: bp.x, y: stakeTopY))
                context.addLine(to: CGPoint(x: bp.x, y: stakeBottomY))
                context.strokePath()

            case .rectangle(let origin, let size):
                context.setFillColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.14).cgColor)
                let path = CGPath(roundedRect: CGRect(origin: origin, size: size), cornerWidth: 3, cornerHeight: 3, transform: nil)
                context.addPath(path)
                context.fillPath()
                context.setStrokeColor(DesignTokens.red.cgColor)
                context.setLineWidth(3)
                context.addPath(path)
                context.strokePath()

            case .circle(let center, let radius):
                context.setFillColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.14).cgColor)
                let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                context.fillEllipse(in: circleRect)
                context.setStrokeColor(DesignTokens.red.cgColor)
                context.setLineWidth(3)
                context.strokeEllipse(in: circleRect)

            case .arrow(let start, let end):
                let dx = end.x - start.x, dy = end.y - start.y
                let len = hypot(dx, dy)
                guard len > 0 else { break }
                let ux = dx / len, uy = dy / len
                let lineStart = CGPoint(x: start.x + ux * 9, y: start.y + uy * 9)
                context.setStrokeColor(DesignTokens.red.cgColor)
                context.setLineWidth(3.5)
                context.setLineCap(.round)
                context.move(to: lineStart)
                context.addLine(to: end)
                context.strokePath()

            case .freehand(let pts):
                guard pts.count >= 2 else { break }
                context.setStrokeColor(DesignTokens.red.cgColor)
                context.setLineWidth(3.5)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.move(to: pts[0])
                for i in 1..<pts.count { context.addLine(to: pts[i]) }
                context.strokePath()
            }

            context.restoreGState()
        }

        // VIB-216 Pass 3: Draw all badges on top of hover halo
        let badgeRadius = DesignTokens.badgeDiameter / 2
        for annotation in store.annotations {
            let bp: CGPoint
            if annotation.type == .pin {
                // Pin badge is clamped to canvas bounds
                bp = CGPoint(
                    x: max(badgeRadius, min(bounds.width - badgeRadius, annotation.badgePosition.x)),
                    y: max(badgeRadius, min(bounds.height - badgeRadius, annotation.badgePosition.y))
                )
            } else {
                bp = annotation.badgePosition
            }
            BadgeRenderer.drawBadge(at: bp, number: annotation.number, in: context)
        }

        // Draw selected state: dashed purple ring + handles
        if let sId = selectedId, let annotation = store.annotations.first(where: { $0.id == sId }) {
            let bp = annotation.badgePosition
            let ringRadius = DesignTokens.badgeDiameter / 2 + 5 // prototype: badgeR + 5

            // Dashed purple ring: #AFA9EC, 1.5px, dash 3,2
            context.setStrokeColor(DesignTokens.purpleLight.cgColor)
            context.setLineWidth(1.5)
            context.setLineDash(phase: 0, lengths: [3, 2])
            context.strokeEllipse(in: CGRect(x: bp.x - ringRadius, y: bp.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
            context.setLineDash(phase: 0, lengths: []) // reset dash

            // Draw handles per tool type
            switch annotation.position {
            case .arrow(_, let end):
                drawHandle(in: context, at: end)
            case .rectangle(let origin, let size):
                let corners = [
                    CGPoint(x: origin.x, y: origin.y),
                    CGPoint(x: origin.x + size.width, y: origin.y),
                    CGPoint(x: origin.x, y: origin.y + size.height),
                    CGPoint(x: origin.x + size.width, y: origin.y + size.height)
                ]
                for corner in corners {
                    // Skip badge corner
                    if hypot(corner.x - bp.x, corner.y - bp.y) > 5 {
                        drawHandle(in: context, at: corner)
                    }
                }
            case .circle(let center, _):
                // Opposite handle
                let ox = center.x * 2 - bp.x
                let oy = center.y * 2 - bp.y
                drawHandle(in: context, at: CGPoint(x: ox, y: oy))
            case .freehand(let pts):
                for pt in pts {
                    drawHandle(in: context, at: pt)
                }
            case .pin:
                break
            }
        }

        // Draw ghost preview (VIB-221: suppressed when hovering existing annotation)
        if let pos = ghostPosition, let tool = ghostTool, !suppressGhost {
            tool.drawGhost(at: pos, in: context)
        }
    }

    /// Handle: white circle, 5px radius, #AFA9EC 2px border
    private func drawHandle(in context: CGContext, at point: CGPoint) {
        let r: CGFloat = 5
        let handleRect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.setFillColor(NSColor.white.cgColor)
        context.fillEllipse(in: handleRect)
        context.setStrokeColor(DesignTokens.purpleLight.cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [])
        context.strokeEllipse(in: handleRect)
    }
}
