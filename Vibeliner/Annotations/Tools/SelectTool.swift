import AppKit

/// Select tool — click to select annotations, drag badges to move, drag handles to resize.
/// Matches prototype tool === 0 behavior from final_Shape_Behavior_vibeliner_editor.jsx
final class SelectTool: AnnotationTool {
    let toolType: AnnotationToolType = .select

    weak var editorPanel: EditorPanel?
    private var dragState: DragState?

    private enum DragState {
        case movingAnnotation(id: UUID, startX: CGFloat, startY: CGFloat)
        case resizingHandle(id: UUID, part: String)
    }

    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        let hit = hitTest(at: point, in: store)

        if let hit = hit {
            store.select(id: hit.id)
            canvas.marksLayer.selectedId = hit.id
            // VIB-213: Make panel key so Esc key events are delivered via key monitor
            canvas.window?.makeKey()

            if hit.part == "badge" || hit.part == "body" {
                // Start drag to move entire annotation
                dragState = .movingAnnotation(id: hit.id, startX: point.x, startY: point.y)
            } else {
                // Start handle drag to resize
                dragState = .resizingHandle(id: hit.id, part: hit.part)
            }
        } else {
            // Click on empty space — deselect
            store.deselectAll()
            canvas.marksLayer.selectedId = nil
            dragState = nil
        }

        canvas.marksLayer.needsDisplay = true
        canvas.refreshNotePills()
    }

    func mouseMoved(to point: CGPoint, in canvas: CanvasView) {
        // Hover detection
        let hit = hitTest(at: point, in: canvas.store)
        let oldHovered = canvas.marksLayer.hoveredId
        canvas.marksLayer.hoveredId = hit?.id
        if canvas.marksLayer.hoveredId != oldHovered {
            canvas.marksLayer.needsDisplay = true
            canvas.refreshNotePills()
        }
    }

    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard let state = dragState else { return }

        switch state {
        case .movingAnnotation(let id, let startX, let startY):
            let dx = point.x - startX
            let dy = point.y - startY
            guard let annotation = store.annotation(for: id) else { return }

            var newBadge = CGPoint(x: annotation.badgePosition.x + dx, y: annotation.badgePosition.y + dy)
            // Clamp badge to canvas
            let br = DesignTokens.badgeDiameter / 2
            newBadge.x = max(br, min(canvas.bounds.width - br, newBadge.x))
            newBadge.y = max(br, min(canvas.bounds.height - br, newBadge.y))

            store.updateBadgePosition(id: id, badgePosition: newBadge)

            // Also move the shape position
            switch annotation.position {
            case .pin(let tip):
                store.updatePosition(id: id, position: .pin(tip: CGPoint(x: tip.x + dx, y: tip.y + dy)))
            case .arrow(let start, let end):
                store.updatePosition(id: id, position: .arrow(
                    start: CGPoint(x: start.x + dx, y: start.y + dy),
                    end: CGPoint(x: end.x + dx, y: end.y + dy)
                ))
            case .rectangle(let origin, let size):
                store.updatePosition(id: id, position: .rectangle(
                    origin: CGPoint(x: origin.x + dx, y: origin.y + dy),
                    size: size
                ))
            case .circle(let center, let radius):
                store.updatePosition(id: id, position: .circle(
                    center: CGPoint(x: center.x + dx, y: center.y + dy),
                    radius: radius
                ))
            case .freehand(let pts):
                let moved = pts.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
                store.updatePosition(id: id, position: .freehand(points: moved))
            }

            dragState = .movingAnnotation(id: id, startX: point.x, startY: point.y)

        case .resizingHandle(let id, let part):
            guard let annotation = store.annotation(for: id) else { return }

            if part == "aEnd", case .arrow(let start, _) = annotation.position {
                store.updatePosition(id: id, position: .arrow(start: start, end: point))
            } else if part.hasPrefix("rc:"), case .rectangle(let origin, let size) = annotation.position {
                // Rectangle corner resize — opposite corner stays fixed
                // Corner indices: 0=origin, 1=(origin.x+w, origin.y), 2=(origin.x, origin.y+h), 3=(origin.x+w, origin.y+h)
                let ci = Int(part.dropFirst(3)) ?? 0
                var nx = origin.x, ny = origin.y, nw = size.width, nh = size.height
                switch ci {
                case 0: // Dragging origin corner: opposite is (rx+rw, ry+rh)
                    nx = point.x; ny = point.y
                    nw = (origin.x + size.width) - point.x
                    nh = (origin.y + size.height) - point.y
                case 1: // Dragging (rx+rw, ry): opposite is (rx, ry+rh)
                    ny = point.y
                    nw = point.x - origin.x
                    nh = (origin.y + size.height) - point.y
                case 2: // Dragging (rx, ry+rh): opposite is (rx+rw, ry)
                    nx = point.x
                    nw = (origin.x + size.width) - point.x
                    nh = point.y - origin.y
                case 3: // Dragging (rx+rw, ry+rh): opposite is (rx, ry)
                    nw = point.x - origin.x
                    nh = point.y - origin.y
                default: break
                }
                // Minimum size 10x10
                if nw > 10 && nh > 10 {
                    let newOrigin = CGPoint(x: nx, y: ny)
                    let newSize = CGSize(width: nw, height: nh)
                    store.updatePosition(id: id, position: .rectangle(origin: newOrigin, size: newSize))

                    // Update badge to follow its corner
                    // Determine which corner the badge is closest to and snap it there
                    let corners = [
                        CGPoint(x: nx, y: ny),                   // 0
                        CGPoint(x: nx + nw, y: ny),              // 1
                        CGPoint(x: nx, y: ny + nh),              // 2
                        CGPoint(x: nx + nw, y: ny + nh)          // 3
                    ]
                    // Find which corner the badge was originally on (the one NOT being dragged,
                    // and NOT the two adjacent to the dragged corner — it's the fourth corner
                    // from the perspective of the original rect)
                    // Simpler: badge stays at its original corner index. Determine badge corner
                    // from old position.
                    let bp = annotation.badgePosition
                    let oldCorners = [
                        CGPoint(x: origin.x, y: origin.y),
                        CGPoint(x: origin.x + size.width, y: origin.y),
                        CGPoint(x: origin.x, y: origin.y + size.height),
                        CGPoint(x: origin.x + size.width, y: origin.y + size.height)
                    ]
                    var badgeCornerIdx = 0
                    var minDist = CGFloat.greatestFiniteMagnitude
                    for (i, c) in oldCorners.enumerated() {
                        let d = hypot(bp.x - c.x, bp.y - c.y)
                        if d < minDist { minDist = d; badgeCornerIdx = i }
                    }
                    store.updateBadgePosition(id: id, badgePosition: corners[badgeCornerIdx])
                }
            } else if part == "cR", case .circle(let center, _) = annotation.position {
                let newRadius = max(10, hypot(point.x - center.x, point.y - center.y))
                // Move badge to maintain its angular position on the new perimeter
                let oldDist = hypot(annotation.badgePosition.x - center.x, annotation.badgePosition.y - center.y)
                if oldDist > 0 {
                    let ux = (annotation.badgePosition.x - center.x) / oldDist
                    let uy = (annotation.badgePosition.y - center.y) / oldDist
                    store.updateBadgePosition(id: id, badgePosition: CGPoint(x: center.x + ux * newRadius, y: center.y + uy * newRadius))
                }
                store.updatePosition(id: id, position: .circle(center: center, radius: newRadius))
            } else if part.hasPrefix("cp:"), case .freehand(let pts) = annotation.position {
                let idx = Int(part.dropFirst(3)) ?? 0
                if idx >= 0 && idx < pts.count {
                    var newPts = pts
                    newPts[idx] = point
                    if idx == 0 {
                        store.updateBadgePosition(id: id, badgePosition: point)
                    }
                    store.updatePosition(id: id, position: .freehand(points: newPts))
                }
            }
        }

        // VIB-354: Removed needsDisplay — drag timer in CanvasView handles it
        canvas.refreshNotePills()
    }

    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        // VIB-333: Update parentImageIndex if annotation was dragged to a different image
        if case .movingAnnotation(let id, _, _) = dragState,
           let resolver = canvas.imageIndexAtPoint,
           let annotation = store.annotation(for: id) {
            let newIndex = resolver(annotation.badgePosition)
            if newIndex != annotation.parentImageIndex {
                store.updateParentImageIndex(id: id, index: newIndex)
            }
            // VIB-339: Recalculate relative coords from new absolute position
            editorPanel?.setRelativeCoords(for: id)
        }
        // VIB-339: Also update relative coords after handle resize
        if case .resizingHandle(let id, _) = dragState {
            editorPanel?.setRelativeCoords(for: id)
        }
        dragState = nil
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        // Select tool has no ghost preview
    }

    // MARK: - Hit testing (matches prototype ht() function)

    struct HitResult {
        let id: UUID
        let part: String  // "badge", "body", "aEnd", "rc:N", "cR", "cp:N"
    }

    private func hitTest(at point: CGPoint, in store: AnnotationStore) -> HitResult? {
        for annotation in store.annotations.reversed() {
            // Badge proximity (12px)
            if hypot(point.x - annotation.badgePosition.x, point.y - annotation.badgePosition.y) < 12 {
                return HitResult(id: annotation.id, part: "badge")
            }

            switch annotation.position {
            case .arrow(_, let end):
                if hypot(point.x - end.x, point.y - end.y) < 10 {
                    return HitResult(id: annotation.id, part: "aEnd")
                }
            case .rectangle(let origin, let size):
                // Corner handles — skip the badge corner (it returns "badge" from the check above)
                let bp = annotation.badgePosition
                let corners = [
                    (CGPoint(x: origin.x, y: origin.y), 0),
                    (CGPoint(x: origin.x + size.width, y: origin.y), 1),
                    (CGPoint(x: origin.x, y: origin.y + size.height), 2),
                    (CGPoint(x: origin.x + size.width, y: origin.y + size.height), 3)
                ]
                for (corner, idx) in corners {
                    // Skip if this corner is the badge corner
                    if hypot(corner.x - bp.x, corner.y - bp.y) < 5 { continue }
                    if hypot(point.x - corner.x, point.y - corner.y) < 10 {
                        return HitResult(id: annotation.id, part: "rc:\(idx)")
                    }
                }
                // Body containment (±5px)
                if point.x >= origin.x - 5 && point.x <= origin.x + size.width + 5 &&
                   point.y >= origin.y - 5 && point.y <= origin.y + size.height + 5 {
                    return HitResult(id: annotation.id, part: "body")
                }
            case .circle(let center, let radius):
                let bx = annotation.badgePosition.x, by = annotation.badgePosition.y
                let ox = center.x * 2 - bx, oy = center.y * 2 - by
                if hypot(point.x - ox, point.y - oy) < 10 {
                    return HitResult(id: annotation.id, part: "cR")
                }
                if hypot(point.x - center.x, point.y - center.y) < radius + 8 {
                    return HitResult(id: annotation.id, part: "body")
                }
            case .freehand(let pts):
                for (j, cp) in pts.enumerated() {
                    if hypot(point.x - cp.x, point.y - cp.y) < 8 {
                        return HitResult(id: annotation.id, part: "cp:\(j)")
                    }
                }
            case .pin:
                break
            }
        }
        return nil
    }
}
