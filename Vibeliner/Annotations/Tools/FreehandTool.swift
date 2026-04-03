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

        // VIB-177: smooth → store ALL smoothed points (NOT aggressively downsampled)
        // Downsampling to 10 points made strokes jagged. Store full smoothed set.
        let smoothed = Self.smoothPoints(points, passes: 3)
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
        context.setAlpha(0.6)
        // VIB-177: Apply smoothing to ghost preview too for visual consistency
        let ghostSmoothed = points.count >= 4 ? Self.smoothPoints(points, passes: 1) : points
        FreehandRenderer.drawFreehandPath(in: context, points: ghostSmoothed)
        context.restoreGState()
    }

    // MARK: - Smoothing (matches prototype sm() function)
    // 3 passes of weighted average: prev * 0.25 + current * 0.5 + next * 0.25

    /// 3-pass weighted average smoothing. Static so VisualTestHarness can use it.
    static func smoothPoints(_ pts: [CGPoint], passes: Int) -> [CGPoint] {
        var result = pts
        for _ in 0..<passes {
            var smoothed = [result[0]]
            for i in 1..<result.count - 1 {
                smoothed.append(CGPoint(
                    x: result[i - 1].x * 0.25 + result[i].x * 0.5 + result[i + 1].x * 0.25,
                    y: result[i - 1].y * 0.25 + result[i].y * 0.5 + result[i + 1].y * 0.25
                ))
            }
            smoothed.append(result[result.count - 1])
            result = smoothed
        }
        return result
    }

}
