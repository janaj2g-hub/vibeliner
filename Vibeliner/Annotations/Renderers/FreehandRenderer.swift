import AppKit

final class FreehandRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        for annotation in annotations where annotation.type == .freehand {
            guard case .freehand(let points) = annotation.position else { continue }

            FreehandRenderer.drawFreehandPath(in: context, points: points)

            // Badge at first point
            if let first = points.first {
                let badgeRadius = DesignTokens.badgeDiameter / 2
                context.setFillColor(DesignTokens.red.cgColor)
                let badgeRect = CGRect(
                    x: first.x - badgeRadius, y: first.y - badgeRadius,
                    width: DesignTokens.badgeDiameter, height: DesignTokens.badgeDiameter
                )
                context.fillEllipse(in: badgeRect)

                if annotation.number > 0 {
                    let numStr = "\(annotation.number)" as NSString
                    let attrs: [NSAttributedString.Key: Any] = [.font: DesignTokens.badgeFont, .foregroundColor: NSColor.white]
                    let textSize = numStr.size(withAttributes: attrs)
                    let textRect = CGRect(x: first.x - textSize.width / 2, y: first.y - textSize.height / 2, width: textSize.width, height: textSize.height)
                    NSGraphicsContext.saveGraphicsState()
                    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
                    numStr.draw(in: textRect, withAttributes: attrs)
                    NSGraphicsContext.restoreGraphicsState()
                }
            }
        }
    }

    func drawNotes(in view: NSView, annotations: [Annotation], canvasSize: NSSize) {}

    static func drawFreehandPath(in context: CGContext, points: [CGPoint]) {
        guard points.count >= 2 else { return }

        context.setStrokeColor(DesignTokens.red.cgColor)
        context.setLineWidth(DesignTokens.strokeWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.move(to: points[0])

        if points.count == 2 {
            context.addLine(to: points[1])
        } else {
            // Draw smooth curve using Catmull-Rom to cubic bezier conversion
            for i in 0..<points.count - 1 {
                let p0 = points[max(0, i - 1)]
                let p1 = points[i]
                let p2 = points[min(points.count - 1, i + 1)]
                let p3 = points[min(points.count - 1, i + 2)]

                // Matches prototype catmull() function: /12 divisor
                let cp1 = CGPoint(
                    x: p1.x + (p2.x - p0.x) / 12,
                    y: p1.y + (p2.y - p0.y) / 12
                )
                let cp2 = CGPoint(
                    x: p2.x - (p3.x - p1.x) / 12,
                    y: p2.y - (p3.y - p1.y) / 12
                )

                context.addCurve(to: p2, control1: cp1, control2: cp2)
            }
        }

        context.strokePath()
    }
}
