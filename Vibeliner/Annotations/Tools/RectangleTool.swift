import AppKit

final class RectangleTool: AnnotationTool {
    let toolType: AnnotationToolType = .rectangle

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

        let rect = rectFromPoints(start, end)
        guard rect.width >= 15, rect.height >= 15 else { return }

        let annotation = Annotation(
            type: .rectangle,
            number: 0,
            position: .rectangle(origin: rect.origin, size: rect.size),
            badgePosition: start
        )
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        guard let start = dragStart, let end = dragEnd else { return }
        context.saveGState()
        context.setAlpha(0.5)
        let rect = rectFromPoints(start, end)
        RectangleRenderer.drawRectShape(in: context, rect: rect, number: 0, badgePos: start)
        context.restoreGState()
    }

    private func rectFromPoints(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(
            x: min(a.x, b.x), y: min(a.y, b.y),
            width: abs(a.x - b.x), height: abs(a.y - b.y)
        )
    }
}
