import AppKit

final class LineTool: AnnotationTool {
    let toolType: AnnotationToolType = .line

    weak var editorPanel: EditorPanel?
    private var dragStart: CGPoint?
    private var dragEnd: CGPoint?

    var isActivelyDrawing: Bool { dragStart != nil }

    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        dragStart = point
        dragEnd = point
    }

    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        dragEnd = point
    }

    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard let start = dragStart else { return }
        let end = point
        dragStart = nil
        dragEnd = nil

        let distance = hypot(end.x - start.x, end.y - start.y)
        guard distance >= 20 else { return }

        var annotation = Annotation(
            type: .line,
            number: 0,
            position: .arrow(start: start, end: end),
            badgePosition: start
        )
        annotation.parentImageIndex = store.currentImageIndex
        annotation.parentImageID = store.currentImageID
        if let resolver = canvas.imageIndexAtPoint {
            let endIndex = resolver(end)
            if endIndex != annotation.parentImageIndex {
                annotation.endImageIndex = endIndex
                annotation.endImageID = canvas.imageIDAtPoint?(end)
            }
        }
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        editorPanel?.setRelativeCoords(for: added.id)
        canvas.openNoteEditor(for: added)
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        guard let start = dragStart, let end = dragEnd else {
            drawIdleGhost(at: point, in: context)
            return
        }
        context.saveGState()
        context.setAlpha(0.85)
        LineRenderer.drawLineShape(in: context, start: start, end: end, number: 0)
        context.restoreGState()
    }

    private func drawIdleGhost(at point: CGPoint, in context: CGContext) {
        // Purple anchor dot
        context.setFillColor(DesignTokens.ghostDotColor.cgColor)
        let r = DesignTokens.ghostDotRadius
        context.fillEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))

        // Dashed short line segment (no arrowhead) up-right at 45°
        let dir = CGFloat.pi / 4
        let gap: CGFloat = 12
        let lineLen: CGFloat = 14
        let startX = point.x + gap * cos(dir)
        let startY = point.y + gap * sin(dir)
        let endX = startX + lineLen * cos(dir)
        let endY = startY + lineLen * sin(dir)

        context.setStrokeColor(DesignTokens.ghostStrokeColor.cgColor)
        context.setLineWidth(DesignTokens.ghostStrokeWidth)
        context.setLineDash(phase: 0, lengths: DesignTokens.ghostDashPattern)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: startX, y: startY))
        context.addLine(to: CGPoint(x: endX, y: endY))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
    }
}
