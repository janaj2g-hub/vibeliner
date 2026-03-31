import AppKit

final class CircleRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        for annotation in annotations where annotation.type == .circle {
            guard case .circle(let center, let radius) = annotation.position else { continue }
            CircleRenderer.drawCircleShape(in: context, center: center, radius: radius, number: annotation.number, badgePos: annotation.badgePosition)
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {}

    static func drawCircleShape(in context: CGContext, center: CGPoint, radius: CGFloat, number: Int, badgePos: CGPoint) {
        let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)

        // Fill
        context.setFillColor(DesignTokens.redFill.cgColor)
        context.fillEllipse(in: circleRect)

        // Stroke
        context.setStrokeColor(DesignTokens.red.cgColor)
        context.setLineWidth(DesignTokens.strokeWidth)
        context.strokeEllipse(in: circleRect)

        // Badge on perimeter
        let badgeRadius = DesignTokens.badgeDiameter / 2
        context.setFillColor(DesignTokens.red.cgColor)
        let badgeRect = CGRect(
            x: badgePos.x - badgeRadius, y: badgePos.y - badgeRadius,
            width: DesignTokens.badgeDiameter, height: DesignTokens.badgeDiameter
        )
        context.fillEllipse(in: badgeRect)

        if number > 0 {
            let numStr = "\(number)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [.font: DesignTokens.badgeFont, .foregroundColor: NSColor.white]
            let textSize = numStr.size(withAttributes: attrs)
            let textRect = CGRect(x: badgePos.x - textSize.width / 2, y: badgePos.y - textSize.height / 2, width: textSize.width, height: textSize.height)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            numStr.draw(in: textRect, withAttributes: attrs)
            NSGraphicsContext.restoreGraphicsState()
        }
    }
}
