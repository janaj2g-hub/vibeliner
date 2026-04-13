import AppKit

// MARK: - Marks Layer (draws annotations + ghost)

final class MarksLayerView: NSView {

    var ghostPosition: CGPoint?
    var ghostTool: AnnotationTool?
    var hoveredId: UUID?
    var selectedId: UUID?
    var suppressGhost: Bool = false  // VIB-221: set true when hovering annotation with drawing tool
    private let store: AnnotationStore
    private let pinRenderer = PinRenderer()
    private let arrowRenderer = ArrowRenderer()
    private let lineRenderer = LineRenderer()
    private let rectangleRenderer = RectangleRenderer()
    private let circleRenderer = CircleRenderer()
    private let freehandRenderer = FreehandRenderer()

    init(frame: NSRect, store: AnnotationStore) {
        self.store = store
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // VIB-216 Pass 1: Draw all shapes WITHOUT badges (so hover halo renders beneath badges)
        pinRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        arrowRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        lineRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        rectangleRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        circleRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)
        freehandRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size, drawBadge: false)

        // VIB-216 Pass 2: Draw hover glow
        if let hId = hoveredId, let annotation = store.annotations.first(where: { $0.id == hId }) {
            let bp = annotation.badgePosition

            // Badge glow (keep existing)
            let glowRadius = DesignTokens.badgeDiameter / 2 + 7 // prototype: badgeR + 7
            context.setFillColor(DesignTokens.editorAnnotationHoverFill.cgColor)
            context.fillEllipse(in: CGRect(x: bp.x - glowRadius, y: bp.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2))

            // VIB-203: Shape halo — draw thicker/warmer version behind the shape with soft shadow
            context.saveGState()
            context.setShadow(offset: .zero, blur: 6, color: DesignTokens.editorAnnotationHoverShadow.cgColor)

            switch annotation.position {
            case .pin:
                // Stake halo
                let stakeTopY = bp.y - DesignTokens.badgeDiameter / 2
                let stakeBottomY = stakeTopY - DesignTokens.stakeLength
                context.setStrokeColor(DesignTokens.editorAnnotationHoverStroke.cgColor)
                context.setLineWidth(6)
                context.setLineCap(.round)
                context.move(to: CGPoint(x: bp.x, y: stakeTopY))
                context.addLine(to: CGPoint(x: bp.x, y: stakeBottomY))
                context.strokePath()

            case .rectangle(let origin, let size):
                context.setFillColor(DesignTokens.editorAnnotationHoverShapeFill.cgColor)
                let path = CGPath(roundedRect: CGRect(origin: origin, size: size), cornerWidth: 3, cornerHeight: 3, transform: nil)
                context.addPath(path)
                context.fillPath()
                context.setStrokeColor(DesignTokens.red.cgColor)
                context.setLineWidth(3)
                context.addPath(path)
                context.strokePath()

            case .circle(let center, let radius):
                context.setFillColor(DesignTokens.editorAnnotationHoverShapeFill.cgColor)
                let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                context.fillEllipse(in: circleRect)
                context.setStrokeColor(DesignTokens.red.cgColor)
                context.setLineWidth(3)
                context.strokeEllipse(in: circleRect)

            case .arrow(let start, let end):
                let dx = end.x - start.x, dy = end.y - start.y
                let len = hypot(dx, dy)
                guard len > 0 else { break }
                let ux = dx / len, uy = dy / len
                let lineStart = CGPoint(x: start.x + ux * 9, y: start.y + uy * 9)
                context.setStrokeColor(DesignTokens.red.cgColor)
                context.setLineWidth(3.5)
                context.setLineCap(.round)
                context.move(to: lineStart)
                context.addLine(to: end)
                context.strokePath()

            case .freehand(let pts):
                guard pts.count >= 2 else { break }
                context.setStrokeColor(DesignTokens.red.cgColor)
                context.setLineWidth(3.5)
                context.setLineCap(.round)
                context.setLineJoin(.round)
                context.move(to: pts[0])
                for i in 1..<pts.count { context.addLine(to: pts[i]) }
                context.strokePath()
            }

            context.restoreGState()
        }

        // VIB-216 Pass 3: Draw all badges on top of hover halo
        let badgeRadius = DesignTokens.badgeDiameter / 2
        for annotation in store.annotations {
            let bp: CGPoint
            if annotation.type == .pin {
                // Pin badge is clamped to canvas bounds
                bp = CGPoint(
                    x: max(badgeRadius, min(bounds.width - badgeRadius, annotation.badgePosition.x)),
                    y: max(badgeRadius, min(bounds.height - badgeRadius, annotation.badgePosition.y))
                )
            } else {
                bp = annotation.badgePosition
            }
            BadgeRenderer.drawBadge(at: bp, number: annotation.number, in: context)
        }

        // Draw selected state: dashed purple ring + handles
        if let sId = selectedId, let annotation = store.annotations.first(where: { $0.id == sId }) {
            let bp = annotation.badgePosition
            let ringRadius = DesignTokens.badgeDiameter / 2 + 5 // prototype: badgeR + 5

            // Dashed purple ring: #AFA9EC, 1.5px, dash 3,2
            context.setStrokeColor(DesignTokens.purpleLight.cgColor)
            context.setLineWidth(1.5)
            context.setLineDash(phase: 0, lengths: [3, 2])
            context.strokeEllipse(in: CGRect(x: bp.x - ringRadius, y: bp.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
            context.setLineDash(phase: 0, lengths: []) // reset dash

            // Draw handles per tool type
            switch annotation.position {
            case .arrow(_, let end):
                drawHandle(in: context, at: end)
            case .rectangle(let origin, let size):
                let corners = [
                    CGPoint(x: origin.x, y: origin.y),
                    CGPoint(x: origin.x + size.width, y: origin.y),
                    CGPoint(x: origin.x, y: origin.y + size.height),
                    CGPoint(x: origin.x + size.width, y: origin.y + size.height)
                ]
                for corner in corners {
                    // Skip badge corner
                    if hypot(corner.x - bp.x, corner.y - bp.y) > 5 {
                        drawHandle(in: context, at: corner)
                    }
                }
            case .circle(let center, _):
                // Opposite handle
                let ox = center.x * 2 - bp.x
                let oy = center.y * 2 - bp.y
                drawHandle(in: context, at: CGPoint(x: ox, y: oy))
            case .freehand(let pts):
                for pt in pts {
                    drawHandle(in: context, at: pt)
                }
            case .pin:
                break
            }
        }

        // Draw ghost preview (VIB-221: suppressed when hovering existing annotation)
        if let pos = ghostPosition, let tool = ghostTool, !suppressGhost {
            tool.drawGhost(at: pos, in: context)
        }
    }

    /// Handle: white circle, 5px radius, #AFA9EC 2px border
    private func drawHandle(in context: CGContext, at point: CGPoint) {
        let r: CGFloat = 5
        let handleRect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.setFillColor(NSColor.white.cgColor)
        context.fillEllipse(in: handleRect)
        context.setStrokeColor(DesignTokens.purpleLight.cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [])
        context.strokeEllipse(in: handleRect)
    }
}
