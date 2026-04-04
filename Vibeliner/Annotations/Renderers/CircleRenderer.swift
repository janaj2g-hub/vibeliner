import AppKit

final class CircleRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        drawMarks(in: context, annotations: annotations, canvasSize: canvasSize, drawBadge: true)
    }

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize, drawBadge: Bool) {
        for annotation in annotations where annotation.type == .circle {
            guard case .circle(let center, let radius) = annotation.position else { continue }
            CircleRenderer.drawCircleShape(in: context, center: center, radius: radius, number: annotation.number, badgePos: annotation.badgePosition, drawBadge: drawBadge)
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {}

    static func drawCircleShape(in context: CGContext, center: CGPoint, radius: CGFloat, number: Int, badgePos: CGPoint, drawBadge: Bool = true) {
        let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        // Fill
        context.setFillColor(DesignTokens.redFill.cgColor)
        context.fillEllipse(in: circleRect)

        // Stroke
        context.setStrokeColor(DesignTokens.red.cgColor)
        context.setLineWidth(DesignTokens.strokeWidth)
        context.strokeEllipse(in: circleRect)

        // Badge on perimeter
        if drawBadge {
            BadgeRenderer.drawBadge(at: badgePos, number: number, in: context)
        }
    }
}
