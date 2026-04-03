import AppKit

protocol AnnotationRenderer {
    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize)
    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize)
}

final class PinRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        for annotation in annotations where annotation.type == .pin {
            guard case .pin(let tip) = annotation.position else { continue }

            let badgeCenterX = annotation.badgePosition.x
            let badgeCenterY = annotation.badgePosition.y
            let badgeRadius = DesignTokens.badgeDiameter / 2

            // Clamp badge to canvas
            let clampedX = max(badgeRadius, min(canvasSize.width - badgeRadius, badgeCenterX))
            let clampedY = max(badgeRadius, min(canvasSize.height - badgeRadius, badgeCenterY))

            // VIB-167: Stake ALWAYS vertical — straight down from badge center
            let stakeTopY = clampedY - badgeRadius
            let stakeBottomY = stakeTopY - DesignTokens.stakeLength
            context.setStrokeColor(DesignTokens.red.cgColor)
            context.setLineWidth(DesignTokens.stakeWidth)
            context.setLineCap(.round)
            context.move(to: CGPoint(x: clampedX, y: stakeTopY))
            context.addLine(to: CGPoint(x: clampedX, y: stakeBottomY))
            context.strokePath()

            // Badge circle
            context.setFillColor(DesignTokens.red.cgColor)
            let badgeRect = CGRect(
                x: clampedX - badgeRadius,
                y: clampedY - badgeRadius,
                width: DesignTokens.badgeDiameter,
                height: DesignTokens.badgeDiameter
            )
            context.fillEllipse(in: badgeRect)

            // Badge number
            let numberStr = "\(annotation.number)" as NSString
            let font = DesignTokens.badgeFont
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white
            ]
            let textSize = numberStr.size(withAttributes: attrs)
            let textRect = CGRect(
                x: clampedX - textSize.width / 2,
                y: clampedY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )

            NSGraphicsContext.saveGraphicsState()
            let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = nsContext
            numberStr.draw(in: textRect, withAttributes: attrs)
            NSGraphicsContext.restoreGraphicsState()

            // Hover glow
            if annotation.isSelected {
                context.setFillColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.15).cgColor)
                let glowRect = badgeRect.insetBy(dx: -6, dy: -6)
                context.fillEllipse(in: glowRect)
            }
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {
        // Note pills are drawn as subviews — managed separately during interaction
        // This method can be used for static rendering in future
    }
}
