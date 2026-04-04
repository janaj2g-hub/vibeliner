import AppKit

final class CircleTool: AnnotationTool {
    let toolType: AnnotationToolType = .circle

    weak var editorPanel: EditorPanel?
    private var center: CGPoint?
    private var currentRadius: CGFloat = 0
    private var releasePoint: CGPoint?

    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        center = point
        currentRadius = 0
    }

    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard let c = center else { return }
        currentRadius = hypot(point.x - c.x, point.y - c.y)
        releasePoint = point
        canvas.marksLayer.needsDisplay = true
    }

    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard let c = center else { return }
        let radius = hypot(point.x - c.x, point.y - c.y)
        center = nil
        currentRadius = 0

        guard radius >= 10 else { return }

        let annotation = Annotation(
            type: .circle,
            number: 0,
            position: .circle(center: c, radius: radius),
            badgePosition: point
        )
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        canvas.openNoteEditor(for: added)
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        guard let c = center, currentRadius > 0 else {
            // Idle ghost: purple dot at center, dashed circle r=10
            let r = DesignTokens.ghostDotRadius
            context.setFillColor(DesignTokens.ghostDotColor.cgColor)
            context.fillEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))

            context.setStrokeColor(DesignTokens.ghostStrokeColor.cgColor)
            context.setLineWidth(DesignTokens.ghostStrokeWidth)
            context.setLineDash(phase: 0, lengths: DesignTokens.ghostDashPattern)
            context.strokeEllipse(in: CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20))
            context.setLineDash(phase: 0, lengths: [])
            return
        }
        context.saveGState()
        context.setAlpha(0.85)
        CircleRenderer.drawCircleShape(in: context, center: c, radius: currentRadius, number: 0, badgePos: releasePoint ?? point)
        context.restoreGState()
    }
}
