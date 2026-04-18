import AppKit

/// Shared badge rendering — red circle with white number. Used by all 5 annotation renderers.
enum BadgeRenderer {

    static func drawBadge(at center: CGPoint, number: Int, in context: CGContext) {
        let radius = DesignTokens.badgeDiameter / 2

        // Red filled circle
        context.setFillColor(DesignTokens.red.cgColor)
        let badgeRect = CGRect(
            x: center.x - radius, y: center.y - radius,
            width: DesignTokens.badgeDiameter, height: DesignTokens.badgeDiameter
        )
        context.fillEllipse(in: badgeRect)

        // White number centered in badge
        guard number > 0 else { return }
        let numStr = "\(number)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: DesignTokens.fontNumberSm,
            .foregroundColor: NSColor.white
        ]
        let textSize = numStr.size(withAttributes: attrs)
        let textRect = CGRect(
            x: center.x - textSize.width / 2,
            y: center.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        numStr.draw(in: textRect, withAttributes: attrs)
        NSGraphicsContext.restoreGraphicsState()
    }
}
