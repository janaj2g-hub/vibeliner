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
            self?.notesLayer.needsDisplay = true
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
