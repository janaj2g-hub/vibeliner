import AppKit

protocol AnnotationTool: AnyObject {
    var toolType: AnnotationToolType { get }
    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager)
    func mouseMoved(to point: CGPoint, in canvas: CanvasView)
    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager)
    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager)
    func drawGhost(at point: CGPoint, in context: CGContext)
}

extension AnnotationTool {
    func mouseMoved(to point: CGPoint, in canvas: CanvasView) {}
    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {}
    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {}
    func drawGhost(at point: CGPoint, in context: CGContext) {}
}

final class PinTool: AnnotationTool {
    let toolType: AnnotationToolType = .pin
    weak var editorPanel: EditorPanel?

    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        // Check if clicking an existing annotation for selection
        for annotation in store.annotations.reversed() where annotation.type == .pin {
            if case .pin(let tip) = annotation.position {
                let badgeCenter = CGPoint(x: tip.x, y: tip.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2)
                if hypot(point.x - badgeCenter.x, point.y - badgeCenter.y) <= DesignTokens.badgeDiameter {
                    store.select(id: annotation.id)
                    return
                }
            }
        }

        store.deselectAll()
        let annotation = Annotation(
            type: .pin, number: 0, noteText: "",
            position: .pin(tip: point),
            badgePosition: CGPoint(x: point.x, y: point.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2)
        )
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        canvas.openNoteEditor(for: added)
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        context.saveGState()
        context.setAlpha(0.5)
        let tip = point
        let badgeCenterY = tip.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2
        let badgeRadius = DesignTokens.badgeDiameter / 2

        context.setStrokeColor(DesignTokens.red.cgColor)
        context.setLineWidth(DesignTokens.stakeWidth)
        context.setLineCap(.round)
        context.move(to: tip)
        context.addLine(to: CGPoint(x: tip.x, y: tip.y + DesignTokens.stakeLength))
        context.strokePath()

        context.setFillColor(DesignTokens.red.cgColor)
        context.fillEllipse(in: CGRect(x: tip.x - badgeRadius, y: badgeCenterY - badgeRadius, width: DesignTokens.badgeDiameter, height: DesignTokens.badgeDiameter))
        context.restoreGState()
    }
}
