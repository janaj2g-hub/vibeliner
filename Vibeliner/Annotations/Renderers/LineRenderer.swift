import AppKit

final class LineRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        drawMarks(in: context, annotations: annotations, canvasSize: canvasSize, drawBadge: true)
    }

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize, drawBadge: Bool) {
        for annotation in annotations where annotation.type == .line {
            guard case .arrow(let start, let end) = annotation.position else { continue }
            LineRenderer.drawLineShape(in: context, start: start, end: end, number: annotation.number, drawBadge: drawBadge)
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {}

    static func drawLineShape(in context: CGContext, start: CGPoint, end: CGPoint, number: Int, drawBadge: Bool = true) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 0 else { return }

        let ux = dx / length
        let uy = dy / length
        let badgeRadius = DesignTokens.badgeDiameter / 2

        // Line from badge edge to endpoint — no arrowhead
        let lineStart = CGPoint(x: start.x + ux * badgeRadius, y: start.y + uy * badgeRadius)

        context.setStrokeColor(DesignTokens.red.cgColor)
        context.setLineWidth(DesignTokens.strokeWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.move(to: lineStart)
        context.addLine(to: end)
        context.strokePath()

        // Badge at start
        if drawBadge {
            BadgeRenderer.drawBadge(at: start, number: number, in: context)
        }
    }
}
