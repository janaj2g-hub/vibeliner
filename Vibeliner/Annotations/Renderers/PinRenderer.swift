import AppKit

protocol AnnotationRenderer {
    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize)
    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize)
}

final class PinRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        drawMarks(in: context, annotations: annotations, canvasSize: canvasSize, drawBadge: true)
    }

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize, drawBadge: Bool) {
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

            // Badge circle + number
            if drawBadge {
                BadgeRenderer.drawBadge(at: CGPoint(x: clampedX, y: clampedY), number: annotation.number, in: context)
            }

            // Hover glow
            if annotation.isSelected {
                context.setFillColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.15).cgColor)
                let glowR = badgeRadius + 6
                let glowRect = CGRect(x: clampedX - glowR, y: clampedY - glowR, width: glowR * 2, height: glowR * 2)
                context.fillEllipse(in: glowRect)
            }
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {
        // Note pills are drawn as subviews — managed separately during interaction
        // This method can be used for static rendering in future
    }
}
