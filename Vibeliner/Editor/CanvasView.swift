import AppKit

final class CanvasView: NSView, NotePillDelegate {

    enum CursorIntent {
        case hiddenForDrawing
        case visibleArrow
    }

    let marksLayer: MarksLayerView
    let notesLayer: NSView
    var activeTool: AnnotationTool? {
        didSet {
            marksLayer.ghostTool = activeTool
            refreshInteractionState()
        }
    }
    var selectTool: SelectTool?
    /// Filmstrip mode: fired on every canvas mouseDown with the local click point.
    var onBackgroundClick: ((CGPoint) -> Void)?
    /// VIB-333: Resolve a canvas point to the image index it's over. Set by EditorPanel in filmstrip mode.
    var imageIndexAtPoint: ((CGPoint) -> Int)?
    /// Stable image identity resolver for filmstrip ownership updates.
    var imageIDAtPoint: ((CGPoint) -> UUID?)?
    var onCursorIntentChanged: ((CursorIntent) -> Void)?
    var store: AnnotationStore
    var undoManager_: UndoRedoManager?
    var storeObserver: Any?
    var ghostPosition: CGPoint?
    var isPointerInsideCanvas = false

    // Note editing state (used by CanvasView+NoteEditing extension)
    var activeNoteField: NSTextField?
    var editingAnnotationId: UUID?
    var preEditNoteText: String?
    var noteFieldDelegate: CanvasNoteFieldDelegate?
    var shapeHoveredId: UUID?
    var pillHoveredId: UUID?
    var activeEditorPill: NSView?

    // VIB-354: Display-link-synchronized rendering — coalesce mouseDragged redraws
    var needsRedraw = false
    var dragTimer: Timer?

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
            // VIB-470: Recalculate ghost/cursor on selection changes.
            self?.refreshInteractionState()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        dragTimer?.invalidate()
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

    override func layout() {
        super.layout()
        marksLayer.frame = NSRect(origin: .zero, size: bounds.size)
        notesLayer.frame = NSRect(origin: .zero, size: bounds.size)
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updatePointerState(at: point, notifyActiveTool: true)
    }

    // Hit testing matching prototype ht() function
    // Priority: badge(12px) → arrow endpoint(10px) → rect corners(10px) → circle resize(10px) → body containment → freehand CPs(8px)
    func hitTestAnnotation(at point: CGPoint) -> UUID? {
        let bbMargin: CGFloat = 20
        for annotation in store.annotations.reversed() {
            // VIB-355: Bounding-box quick-reject — skip expensive distance math
            guard annotation.position.boundingRect.insetBy(dx: -bbMargin, dy: -bbMargin).contains(point) else { continue }

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

        // Filmstrip mode: forward click for cell selection
        onBackgroundClick?(point)

        // VIB-333: Set currentImageIndex based on where the click landed, not which cell is selected
        if let resolver = imageIndexAtPoint {
            store.currentImageIndex = resolver(point)
        }
        if let resolver = imageIDAtPoint {
            store.currentImageID = resolver(point)
        }

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

        activeTool?.mouseDown(at: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
        // VIB-354: Start drag timer for frame-synchronized redraws
        startDragTimer()
    }

    func handleEditHit(id: UUID, at point: CGPoint) {
        if let annotation = store.annotation(for: id) {
            // Open editor if pill is hovered or badge clicked with no note
            let badgeClicked = hypot(point.x - annotation.badgePosition.x, point.y - annotation.badgePosition.y) < 12
            if pillHoveredId == id || (badgeClicked && annotation.noteText.isEmpty) {
                openNoteEditor(for: annotation)
                return
            }
        }
        guard let undoMgr = undoManager_ else { return }
        store.select(id: id)
        marksLayer.selectedId = id
        window?.makeKey()
        // VIB-454: Make canvas first responder so KeyEventGuard doesn't find
        // a stale field editor (e.g., from title pill editing) that blocks
        // Backspace/Delete from reaching the delete handler.
        window?.makeFirstResponder(self)
        selectTool?.mouseDown(at: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
        startDragTimer()
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
        // VIB-354: Set dirty flag — the drag timer will coalesce into one draw per frame
        needsRedraw = true
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
        // VIB-354: Stop drag timer and do final redraw
        stopDragTimer()
        marksLayer.needsDisplay = true
    }

    // MARK: - VIB-354: Drag timer for frame-synchronized rendering

    func startDragTimer() {
        guard dragTimer == nil else { return }
        dragTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            guard let self, self.needsRedraw else { return }
            self.needsRedraw = false
            self.marksLayer.needsDisplay = true
        }
    }

    func stopDragTimer() {
        dragTimer?.invalidate()
        dragTimer = nil
        needsRedraw = false
    }

    override func mouseExited(with event: NSEvent) {
        updatePointerState(at: nil, notifyActiveTool: false)
    }

    func refreshNotePills() {
        NotePillRenderer.drawNotePills(in: notesLayer, annotations: store.annotations, canvasSize: bounds.size, hoveredId: pillHoveredId, selectedId: store.selectedAnnotation?.id, editingId: editingAnnotationId, delegate: self)
    }

}
