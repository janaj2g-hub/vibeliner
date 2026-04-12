import AppKit

final class FreehandTool: AnnotationTool {
    let toolType: AnnotationToolType = .freehand

    weak var editorPanel: EditorPanel?
    private var points: [CGPoint] = []
    private var isDrawing = false
    var isActivelyDrawing: Bool { isDrawing }  // VIB-221: expose for ghost suppression guard

    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        points = [point]
        isDrawing = true
    }

    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard isDrawing, let last = points.last else { return }
        let dist = hypot(point.x - last.x, point.y - last.y)
        if dist >= DesignTokens.freehandSampleInterval {
            points.append(point)
            // VIB-354: Removed needsDisplay — drag timer in CanvasView handles it
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

        var annotation = Annotation(
            type: .freehand,
            number: 0,
            position: .freehand(points: smoothed),
            badgePosition: badgePos
        )
        annotation.parentImageIndex = store.currentImageIndex
        annotation.parentImageID = store.currentImageID
        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        // VIB-339: Store relative coords for layout-safe positioning
        editorPanel?.setRelativeCoords(for: added.id)
        points.removeAll()
        canvas.openNoteEditor(for: added)
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        guard isDrawing, points.count >= 2 else {
            // Idle ghost: 3 fading trailing dots + purple anchor dot
            // AppKit: "trailing behind" = lower x, lower y (negative offsets from prototype web coords)
            let dots: [(dx: CGFloat, dy: CGFloat, r: CGFloat, a: CGFloat)] = [
                (-7, -6, 1.3, 0.08),
                (-4, -3.5, 1.5, 0.13),
                (0, -1, 1.7, 0.20)
            ]
            for dot in dots {
                context.setFillColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: dot.a).cgColor)
                context.fillEllipse(in: CGRect(x: point.x + dot.dx - dot.r, y: point.y + dot.dy - dot.r, width: dot.r * 2, height: dot.r * 2))
            }
            let r = DesignTokens.ghostDotRadius
            context.setFillColor(DesignTokens.ghostDotColor.cgColor)
            context.fillEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))
            return
        }
        context.saveGState()
        context.setAlpha(0.85)
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
