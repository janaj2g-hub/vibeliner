import AppKit

final class EditorToolController {
    let selectTool = SelectTool()

    private let pinTool = PinTool()
    private let arrowTool = ArrowTool()
    private let lineTool = LineTool()
    private let rectangleTool = RectangleTool()
    private let circleTool = CircleTool()
    private let freehandTool = FreehandTool()
    private lazy var toolsByType: [AnnotationToolType: AnnotationTool] = [
        .select: selectTool,
        .pin: pinTool,
        .arrow: arrowTool,
        .line: lineTool,
        .rectangle: rectangleTool,
        .circle: circleTool,
        .freehand: freehandTool,
    ]

    init(editorPanel: EditorPanel) {
        selectTool.editorPanel = editorPanel
        pinTool.editorPanel = editorPanel
        arrowTool.editorPanel = editorPanel
        lineTool.editorPanel = editorPanel
        rectangleTool.editorPanel = editorPanel
        circleTool.editorPanel = editorPanel
        freehandTool.editorPanel = editorPanel
    }

    func configure(canvas: CanvasView, undoManager: UndoRedoManager, defaultTool: AnnotationToolType = .pin) {
        canvas.undoManager_ = undoManager
        canvas.selectTool = selectTool
        select(defaultTool, on: canvas)
    }

    func select(_ tool: AnnotationToolType, on canvas: CanvasView?) {
        canvas?.activeTool = toolsByType[tool] ?? selectTool
    }
}

final class EditorCursorController {
    private var windowIsActive = true
    private var chromeHovering = false
    private var canvasIntent: CanvasView.CursorIntent = .visibleArrow

    func setWindowActive(_ isActive: Bool) {
        windowIsActive = isActive
        apply(resetStack: !isActive)
    }

    func setChromeHovering(_ isHovering: Bool) {
        chromeHovering = isHovering
        apply()
    }

    func setCanvasIntent(_ intent: CanvasView.CursorIntent) {
        canvasIntent = intent
        apply()
    }

    private func apply(resetStack: Bool = false) {
        let shouldHideCursor = windowIsActive
            && !chromeHovering
            && canvasIntent == .hiddenForDrawing
        if shouldHideCursor {
            CursorManager.shared.hideCursor()
        } else if resetStack {
            CursorManager.shared.forceShow()
        } else {
            CursorManager.shared.showArrowCursor()
        }
    }
}

