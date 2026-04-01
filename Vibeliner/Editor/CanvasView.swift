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
        marksLayer.needsDisplay = true
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
        NotePillRenderer.drawNotePills(in: notesLayer, annotations: store.annotations, canvasSize: bounds.size)
    }

    private var activeNoteField: NSTextField?
    private var editingAnnotationId: UUID?

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

        let noteDelegate = CanvasNoteFieldDelegate(canvas: self)
        textField.delegate = noteDelegate
        textField.target = noteDelegate
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
        store.update(id: id, noteText: field.stringValue)
        field.removeFromSuperview()
        activeNoteField = nil
        editingAnnotationId = nil
        refreshNotePills()
    }

    func cancelNoteEditing() {
        guard let id = editingAnnotationId else { return }
        // If note text is empty, remove the annotation
        if let annotation = store.annotation(for: id), annotation.noteText.isEmpty {
            store.remove(id: id)
        }
        activeNoteField?.removeFromSuperview()
        activeNoteField = nil
        editingAnnotationId = nil
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

        // Draw ghost preview
        if let pos = ghostPosition, let tool = ghostTool {
            tool.drawGhost(at: pos, in: context)
        }
    }
}
