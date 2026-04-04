import AppKit

final class RectangleRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        drawMarks(in: context, annotations: annotations, canvasSize: canvasSize, drawBadge: true)
    }

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize, drawBadge: Bool) {
        for annotation in annotations where annotation.type == .rectangle {
            guard case .rectangle(let origin, let size) = annotation.position else { continue }
            let rect = CGRect(origin: origin, size: size)
            RectangleRenderer.drawRectShape(in: context, rect: rect, number: annotation.number, badgePos: annotation.badgePosition, drawBadge: drawBadge)
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {}

    static func drawRectShape(in context: CGContext, rect: CGRect, number: Int, badgePos: CGPoint, drawBadge: Bool = true) {
        let cornerRadius = DesignTokens.rectCornerRadius
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        // Fill
        context.setFillColor(DesignTokens.redFill.cgColor)
        context.addPath(path)
        context.fillPath()

        // Stroke
        context.setStrokeColor(DesignTokens.red.cgColor)
        context.setLineWidth(DesignTokens.strokeWidth)
        context.addPath(path)
        context.strokePath()

        // Badge at drag-start corner
        if drawBadge {
            BadgeRenderer.drawBadge(at: badgePos, number: number, in: context)
        }
    }
}
