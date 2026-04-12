import AppKit

protocol AnnotationTool: AnyObject {
    var toolType: AnnotationToolType { get }
    var isActivelyDrawing: Bool { get }
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
    /// VIB-221: True when a stroke is actively in progress (prevents ghost suppression mid-stroke)
    var isActivelyDrawing: Bool { false }
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
        var annotation = Annotation(
            type: .pin, number: 0, noteText: "",
            position: .pin(tip: point),
            badgePosition: CGPoint(x: point.x, y: point.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2)
        )
        annotation.parentImageIndex = store.currentImageIndex
        annotation.parentImageID = store.currentImageID
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        // VIB-339: Store relative coords for layout-safe positioning
        editorPanel?.setRelativeCoords(for: added.id)
        canvas.openNoteEditor(for: added)
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        // Purple anchor dot at cursor
        context.setFillColor(DesignTokens.ghostDotColor.cgColor)
        let r = DesignTokens.ghostDotRadius
        context.fillEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))

        // Dashed badge circle above the dot (AppKit: higher y = visually above)
        let badgeCenterY = point.y + 16
        context.setStrokeColor(DesignTokens.ghostStrokeColor.cgColor)
        context.setLineWidth(DesignTokens.ghostStrokeWidth)
        context.setLineDash(phase: 0, lengths: DesignTokens.ghostDashPattern)
        context.strokeEllipse(in: CGRect(x: point.x - 5, y: badgeCenterY - 5, width: 10, height: 10))

        // Dashed stake line from badge bottom to just above dot
        context.move(to: CGPoint(x: point.x, y: badgeCenterY - 5))
        context.addLine(to: CGPoint(x: point.x, y: point.y + 2))
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
    }
}
