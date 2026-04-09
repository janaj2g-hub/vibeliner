import AppKit

final class ArrowTool: AnnotationTool {
    let toolType: AnnotationToolType = .arrow

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
        canvas.marksLayer.needsDisplay = true
    }

    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard let start = dragStart else { return }
        let end = point
        dragStart = nil
        dragEnd = nil

        let distance = hypot(end.x - start.x, end.y - start.y)
        guard distance >= 20 else { return }

        var annotation = Annotation(
            type: .arrow,
            number: 0,
            position: .arrow(start: start, end: end),
            badgePosition: start
        )
        annotation.parentImageIndex = store.currentImageIndex
        // VIB-333: Set endImageIndex from arrow end point for cross-image arrows
        if let resolver = canvas.imageIndexAtPoint {
            let endIndex = resolver(end)
            if endIndex != annotation.parentImageIndex {
                annotation.endImageIndex = endIndex
            }
        }
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        canvas.openNoteEditor(for: added)
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        guard let start = dragStart, let end = dragEnd else {
            drawIdleGhost(at: point, in: context)
            return
        }
        context.saveGState()
        context.setAlpha(0.85)
        ArrowRenderer.drawArrowShape(in: context, start: start, end: end, number: 0)
        context.restoreGState()
    }

    private func drawIdleGhost(at point: CGPoint, in context: CGContext) {
        // Purple anchor dot
        context.setFillColor(DesignTokens.ghostDotColor.cgColor)
        let r = DesignTokens.ghostDotRadius
        context.fillEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))

        // Dashed chevron ahead (up-right at 45°). AppKit: both x and y increase for up-right.
        let dir = CGFloat.pi / 4
        let gap: CGFloat = 12
        let armLen: CGFloat = 11.9
        let chevAngle: CGFloat = 28 * .pi / 180
        let tipX = point.x + (gap + 3) * cos(dir)
        let tipY = point.y + (gap + 3) * sin(dir)
        let backAngle = dir + .pi
        let c1x = tipX + armLen * cos(backAngle + chevAngle)
        let c1y = tipY + armLen * sin(backAngle + chevAngle)
        let c2x = tipX + armLen * cos(backAngle - chevAngle)
        let c2y = tipY + armLen * sin(backAngle - chevAngle)

        context.setStrokeColor(DesignTokens.ghostStrokeColor.cgColor)
        context.setLineWidth(DesignTokens.ghostStrokeWidth)
        context.setLineDash(phase: 0, lengths: DesignTokens.ghostDashPattern)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: CGPoint(x: c1x, y: c1y))
        context.addLine(to: CGPoint(x: tipX, y: tipY))
        context.addLine(to: CGPoint(x: c2x, y: c2y))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
    }
}
