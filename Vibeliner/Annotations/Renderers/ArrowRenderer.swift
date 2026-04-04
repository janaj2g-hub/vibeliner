import AppKit

final class ArrowRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        drawMarks(in: context, annotations: annotations, canvasSize: canvasSize, drawBadge: true)
    }

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize, drawBadge: Bool) {
        for annotation in annotations where annotation.type == .arrow {
            guard case .arrow(let start, let end) = annotation.position else { continue }
            ArrowRenderer.drawArrowShape(in: context, start: start, end: end, number: annotation.number, drawBadge: drawBadge)
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {}

    static func drawArrowShape(in context: CGContext, start: CGPoint, end: CGPoint, number: Int, drawBadge: Bool = true) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0 else { return }

        let ux = dx / length
        let uy = dy / length
        let badgeRadius = DesignTokens.badgeDiameter / 2

        // Line from badge edge to endpoint
        let lineStart = CGPoint(x: start.x + ux * badgeRadius, y: start.y + uy * badgeRadius)

        context.setStrokeColor(DesignTokens.red.cgColor)
        context.setLineWidth(DesignTokens.strokeWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: lineStart)
        context.addLine(to: end)
        context.strokePath()

        // Chevron at endpoint
        let chevronLen = DesignTokens.arrowChevronLength
        let chevronAngle = DesignTokens.arrowChevronAngle * .pi / 180
        let backAngle = atan2(-uy, -ux)

        let arm1 = CGPoint(
            x: end.x + chevronLen * cos(backAngle + chevronAngle),
            y: end.y + chevronLen * sin(backAngle + chevronAngle)
        )
        let arm2 = CGPoint(
            x: end.x + chevronLen * cos(backAngle - chevronAngle),
            y: end.y + chevronLen * sin(backAngle - chevronAngle)
        )

        context.move(to: arm1)
        context.addLine(to: end)
        context.addLine(to: arm2)
        context.strokePath()

        // Badge at start
        if drawBadge {
            BadgeRenderer.drawBadge(at: start, number: number, in: context)
        }
    }
}
