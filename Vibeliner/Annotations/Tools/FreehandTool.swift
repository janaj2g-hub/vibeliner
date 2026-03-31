import AppKit

final class FreehandTool: AnnotationTool {
    let toolType: AnnotationToolType = .freehand

    weak var editorPanel: EditorPanel?
    private var points: [CGPoint] = []
    private var isDrawing = false

    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        points = [point]
        isDrawing = true
    }

    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard isDrawing, let last = points.last else { return }
        let dist = hypot(point.x - last.x, point.y - last.y)
        if dist >= DesignTokens.freehandSampleInterval {
            points.append(point)
            canvas.marksLayer.needsDisplay = true
        }
    }

    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        isDrawing = false
        guard points.count >= DesignTokens.freehandMinPoints else {
            points.removeAll()
            return
        }

        let smoothed = catmullRomSmooth(points: points, passes: 3, tension: 0.5)
        let badgePos = smoothed.first ?? point

        let annotation = Annotation(
            type: .freehand,
            number: 0,
            position: .freehand(points: smoothed),
            badgePosition: badgePos
        )
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        points.removeAll()
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        guard isDrawing, points.count >= 2 else { return }
        context.saveGState()
        context.setAlpha(0.5)
        FreehandRenderer.drawFreehandPath(in: context, points: points)
        context.restoreGState()
    }

    // MARK: - Catmull-Rom smoothing

    private func catmullRomSmooth(points: [CGPoint], passes: Int, tension: CGFloat) -> [CGPoint] {
        var result = points
        for _ in 0..<passes {
            result = subdivide(result, tension: tension)
        }
        return result
    }

    private func subdivide(_ points: [CGPoint], tension: CGFloat) -> [CGPoint] {
        guard points.count >= 3 else { return points }
        var result: [CGPoint] = [points[0]]

        for i in 0..<points.count - 1 {
            let p0 = points[max(0, i - 1)]
            let p1 = points[i]
            let p2 = points[min(points.count - 1, i + 1)]
            let p3 = points[min(points.count - 1, i + 2)]

            let mid = CGPoint(
                x: (p1.x + p2.x) / 2 + tension * ((p2.x - p0.x) - (p3.x - p1.x)) / 16,
                y: (p1.y + p2.y) / 2 + tension * ((p2.y - p0.y) - (p3.y - p1.y)) / 16
            )
            result.append(mid)
            result.append(p2)
        }

        return result
    }
}
