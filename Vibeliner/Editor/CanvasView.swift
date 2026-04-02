import AppKit

final class CanvasView: NSView {

    let marksLayer: MarksLayerView
    let notesLayer: NSView
    var activeTool: AnnotationTool?
    var store: AnnotationStore
    var undoManager_: UndoRedoManager?
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

        // Hit-test for hover
        let oldHovered = hoveredAnnotationId
        hoveredAnnotationId = hitTestAnnotation(at: point)
        if hoveredAnnotationId != oldHovered {
            marksLayer.hoveredId = hoveredAnnotationId
            refreshNotePills()
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
        guard let undoMgr = undoManager_ else { return }
        activeTool?.mouseDown(at: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let undoMgr = undoManager_ else { return }
        activeTool?.mouseDragged(to: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let undoMgr = undoManager_ else { return }
        activeTool?.mouseUp(at: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        ghostPosition = nil
        marksLayer.ghostPosition = nil
        marksLayer.needsDisplay = true
    }

    func refreshNotePills() {
        NotePillRenderer.drawNotePills(in: notesLayer, annotations: store.annotations, canvasSize: bounds.size, hoveredId: hoveredAnnotationId, selectedId: store.selectedAnnotation?.id, editingId: editingAnnotationId)
    }

    private var activeNoteField: NSTextField?
    private var editingAnnotationId: UUID?
    private var noteFieldDelegate: CanvasNoteFieldDelegate?
    private(set) var hoveredAnnotationId: UUID?

    func openNoteEditor(for annotation: Annotation) {
        activeNoteField?.removeFromSuperview()

        let pillPos = NotePillRenderer.notePillPosition(for: annotation, canvasSize: bounds.size)

        let textField = NSTextField()
        textField.font = DesignTokens.noteTextFont
        textField.textColor = NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 1.0)
        textField.backgroundColor = DesignTokens.redNoteBg
        textField.isBordered = true
        textField.wantsLayer = true
        textField.layer?.borderColor = DesignTokens.red.cgColor
        textField.layer?.borderWidth = 1
        textField.layer?.cornerRadius = DesignTokens.noteCornerRadius
        textField.focusRingType = .none
        textField.frame = NSRect(x: pillPos.x, y: pillPos.y, width: 180, height: DesignTokens.noteHeight)
        textField.placeholderString = "Add note..."
        textField.stringValue = annotation.noteText
        textField.identifier = NSUserInterfaceItemIdentifier("noteEditor")

        let delegate = CanvasNoteFieldDelegate(canvas: self)
        self.noteFieldDelegate = delegate
        textField.delegate = delegate
        textField.target = delegate
        textField.action = #selector(CanvasNoteFieldDelegate.confirmNote(_:))

        notesLayer.addSubview(textField)
        editingAnnotationId = annotation.id
        activeNoteField = textField

        // Make the field first responder via the window
        DispatchQueue.main.async { [weak self, weak textField] in
            guard let window = self?.window, let tf = textField else { return }
            window.makeFirstResponder(tf)
        }
    }

    func confirmNoteEditing() {
        guard let id = editingAnnotationId, let field = activeNoteField else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            // Empty text on confirm → remove the annotation and renumber
            store.remove(id: id)
        } else {
            store.update(id: id, noteText: text)
        }
        field.removeFromSuperview()
        activeNoteField = nil
        editingAnnotationId = nil
        noteFieldDelegate = nil
        refreshNotePills()
        marksLayer.needsDisplay = true
    }

    func cancelNoteEditing() {
        guard let id = editingAnnotationId else { return }
        if let annotation = store.annotation(for: id), annotation.noteText.isEmpty {
            store.remove(id: id)
        }
        activeNoteField?.removeFromSuperview()
        activeNoteField = nil
        editingAnnotationId = nil
        noteFieldDelegate = nil
        refreshNotePills()
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

        // Draw all annotations
        pinRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)
        arrowRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)
        rectangleRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)
        circleRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)
        freehandRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)

        // Draw hover glow
        if let hId = hoveredId, let annotation = store.annotations.first(where: { $0.id == hId }) {
            let bp = annotation.badgePosition
            let glowRadius = DesignTokens.badgeDiameter / 2 + 7 // prototype: badgeR + 7
            context.setFillColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.08).cgColor)
            context.fillEllipse(in: CGRect(x: bp.x - glowRadius, y: bp.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2))
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

        // Draw ghost preview
        if let pos = ghostPosition, let tool = ghostTool {
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
