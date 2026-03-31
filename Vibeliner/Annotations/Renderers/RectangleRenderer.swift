import AppKit

final class RectangleRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        for annotation in annotations where annotation.type == .rectangle {
            guard case .rectangle(let origin, let size) = annotation.position else { continue }
            let rect = CGRect(origin: origin, size: size)
            RectangleRenderer.drawRectShape(in: context, rect: rect, number: annotation.number, badgePos: annotation.badgePosition)
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {}

    static func drawRectShape(in context: CGContext, rect: CGRect, number: Int, badgePos: CGPoint) {
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
