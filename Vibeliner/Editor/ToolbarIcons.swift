import AppKit

enum ToolbarIconGeometry {
    static let viewBox: CGFloat = 15

    static func point(in rect: NSRect, _ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(
            x: rect.minX + (x / viewBox) * rect.width,
            y: rect.maxY - (y / viewBox) * rect.height
        )
    }

    static func outlineRect(in rect: NSRect, inset: CGFloat = 1.25) -> NSRect {
        rect.insetBy(dx: inset, dy: inset)
    }
}

extension ToolbarView {

    // MARK: - Icon drawing functions

    /// Pin icon: filled circle + stake, 15×15 viewBox, same pattern as all other tool icons.
    /// Uses currentColor — no special colors, no counter.
    static func drawPinIcon(_ rect: NSRect, _ color: NSColor) {
        // Filled circle at (7.5, 5), r=3.5 in 15×15 viewBox
        let center = ToolbarIconGeometry.point(in: rect, 7.5, 5)
        let r = 3.5 * (rect.width / ToolbarIconGeometry.viewBox)
        let circle = NSBezierPath(ovalIn: NSRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        color.setFill()
        circle.fill()
        // Stake line from (7.5, 9) to (7.5, 14)
        let stake = NSBezierPath()
        stake.move(to: ToolbarIconGeometry.point(in: rect, 7.5, 9))
        stake.line(to: ToolbarIconGeometry.point(in: rect, 7.5, 14))
        stake.lineWidth = 1.8 * (rect.width / ToolbarIconGeometry.viewBox)
        stake.lineCapStyle = .round
        color.setStroke()
        stake.stroke()
    }

    static func drawArrowIcon(_ rect: NSRect, _ color: NSColor) {
        let path = NSBezierPath()
        // Diagonal line
        path.move(to: ToolbarIconGeometry.point(in: rect, 2, 13))
        path.line(to: ToolbarIconGeometry.point(in: rect, 13, 2))
        // Arrowhead chevron
        path.move(to: ToolbarIconGeometry.point(in: rect, 8, 2))
        path.line(to: ToolbarIconGeometry.point(in: rect, 13, 2))
        path.line(to: ToolbarIconGeometry.point(in: rect, 13, 7))
        path.lineWidth = 1.4
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        color.setStroke()
        path.stroke()
    }

    static func drawLineIcon(_ rect: NSRect, _ color: NSColor) {
        let path = NSBezierPath()
        // Diagonal line — same angle as arrow but no arrowhead
        path.move(to: ToolbarIconGeometry.point(in: rect, 2, 13))
        path.line(to: ToolbarIconGeometry.point(in: rect, 13, 2))
        path.lineWidth = 1.4
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()
    }

    static func drawRectIcon(_ rect: NSRect, _ color: NSColor) {
        let inset = ToolbarIconGeometry.outlineRect(in: rect)
        let path = NSBezierPath(roundedRect: inset, xRadius: 2, yRadius: 2)
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }

    static func drawCircleIcon(_ rect: NSRect, _ color: NSColor) {
        let inset = ToolbarIconGeometry.outlineRect(in: rect)
        let path = NSBezierPath(ovalIn: inset)
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }

    static func drawFreehandIcon(_ rect: NSRect, _ color: NSColor) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX, y: rect.midY))
        path.curve(to: NSPoint(x: rect.midX, y: rect.midY),
                   controlPoint1: NSPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY),
                   controlPoint2: NSPoint(x: rect.midX - rect.width * 0.1, y: rect.minY))
        path.curve(to: NSPoint(x: rect.maxX, y: rect.midY),
                   controlPoint1: NSPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY),
                   controlPoint2: NSPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY))
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }

    static func iconDrawer(for tool: AnnotationToolType) -> (NSRect, NSColor) -> Void {
        switch tool {
        case .select:
            return { rect, color in
                let w = rect.width
                let h = rect.height
                func pt(_ sx: CGFloat, _ sy: CGFloat) -> NSPoint {
                    NSPoint(x: rect.minX + sx / 15 * w, y: rect.maxY - sy / 15 * h)
                }
                let path = NSBezierPath()
                path.move(to: pt(3, 2))
                path.line(to: pt(12, 7.5))
                path.line(to: pt(8, 8.5))
                path.line(to: pt(10.5, 13))
                path.line(to: pt(9, 13.8))
                path.line(to: pt(6.5, 9.3))
                path.line(to: pt(3.5, 12.3))
                path.close()
                color.setFill()
                path.fill()
                color.setStroke()
                path.lineWidth = 0.5
                path.lineJoinStyle = .round
                path.stroke()
            }
        case .pin:
            return drawPinIcon
        case .arrow:
            return drawArrowIcon
        case .line:
            return drawLineIcon
        case .rectangle:
            return drawRectIcon
        case .circle:
            return drawCircleIcon
        case .freehand:
            return drawFreehandIcon
        }
    }
}
