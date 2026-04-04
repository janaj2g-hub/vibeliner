import AppKit

final class FreehandRenderer: AnnotationRenderer {

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize) {
        drawMarks(in: context, annotations: annotations, canvasSize: canvasSize, drawBadge: true)
    }

    func drawMarks(in context: CGContext, annotations: [Annotation], canvasSize: NSSize, drawBadge: Bool) {
        for annotation in annotations where annotation.type == .freehand {
            guard case .freehand(let points) = annotation.position else { continue }

            FreehandRenderer.drawFreehandPath(in: context, points: points)

            // Badge at first point
            if drawBadge, let first = points.first {
                BadgeRenderer.drawBadge(at: first, number: annotation.number, in: context)
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
