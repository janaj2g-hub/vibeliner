import AppKit

final class ArrowTool: AnnotationTool {
    let toolType: AnnotationToolType = .arrow

    weak var editorPanel: EditorPanel?
    private var dragStart: CGPoint?
    private var dragEnd: CGPoint?

    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        dragStart = point
        dragEnd = point
    }

    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        dragEnd = point
        canvas.marksLayer.needsDisplay = true
    }

    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard let start = dragStart else { return }
        let end = point
        dragStart = nil
        dragEnd = nil

        let distance = hypot(end.x - start.x, end.y - start.y)
        guard distance >= 20 else { return }

        let annotation = Annotation(
            type: .arrow,
            number: 0,
            position: .arrow(start: start, end: end),
            badgePosition: start
        )
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        canvas.openNoteEditor(for: added)
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        guard let start = dragStart, let end = dragEnd else { return }
        context.saveGState()
        context.setAlpha(0.5)
        ArrowRenderer.drawArrowShape(in: context, start: start, end: end, number: 0)
        context.restoreGState()
    }
}
