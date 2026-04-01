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
        canvas.openNoteEditor(for: added)
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
        guard points.count >= 3 else { return points }

        // Catmull-Rom interpolation: generate smooth intermediate points
        var result: [CGPoint] = []
        let stepsPerSegment = 8

        for i in 0..<points.count - 1 {
            let p0 = points[max(0, i - 1)]
            let p1 = points[i]
            let p2 = points[min(points.count - 1, i + 1)]
            let p3 = points[min(points.count - 1, i + 2)]

            for step in 0..<stepsPerSegment {
                let t = CGFloat(step) / CGFloat(stepsPerSegment)
                let t2 = t * t
                let t3 = t2 * t

                let x = tension * (
                    (2 * p1.x) +
                    (-p0.x + p2.x) * t +
                    (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
                    (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3
                )
                let y = tension * (
                    (2 * p1.y) +
                    (-p0.y + p2.y) * t +
                    (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
                    (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3
                )
                result.append(CGPoint(x: x, y: y))
            }
        }

        // Add the last point
        if let last = points.last {
            result.append(last)
        }

        return result
    }
}
