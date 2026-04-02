import AppKit

final class PinCounterIcon: NSView {

    var count: Int = 0 { didSet { needsDisplay = true } }
    var isActive: Bool = false { didSet { needsDisplay = true } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let color = isActive ? DesignTokens.purpleLight : DesignTokens.purpleLightInactive
        // VIB-164: Optically center the pin icon.
        // Icon is top-heavy (circle r=4.5 + stake ~4.5 in 15×15 viewBox).
        // Map prototype 15×15 viewBox into the 30×30 button, scaled to ~15×15 icon area.
        let circleRadius: CGFloat = 4.5 * (bounds.width / 15)
        let cx = bounds.midX
        // Visual center of pin is at about y=8 in 15×15 viewBox (between circle center y=5 and stake end y=14)
        // In AppKit y-up, we shift the icon center up by ~1px for optical balance
        let cy = bounds.midY + 1 * (bounds.height / 15)

        // Prototype SVG: circle cx=7.5 cy=5 r=4.5, line x1=7.5 y1=9.5 x2=7.5 y2=14
        // Map from 15×15 viewBox to icon rect
        let scale = bounds.width / 15
        let circCy = cy + (5 - 7.5) * scale  // circle center in mapped coords

        // Filled circle
        let circlePath = NSBezierPath(ovalIn: NSRect(
            x: cx - circleRadius, y: circCy - circleRadius,
            width: circleRadius * 2, height: circleRadius * 2
        ))
        color.setFill()
        circlePath.fill()

        // Stake line below circle
        let stakeTop = cy + (7.5 - 9.5) * scale  // y=9.5 in SVG y-down → lower in AppKit
        let stakeBottom = cy + (7.5 - 14) * scale  // y=14 in SVG y-down
        let stakePath = NSBezierPath()
        stakePath.move(to: NSPoint(x: cx, y: stakeTop))
        stakePath.line(to: NSPoint(x: cx, y: stakeBottom))
        stakePath.lineWidth = 1.8 * scale
        stakePath.lineCapStyle = .round
        color.setStroke()
        stakePath.stroke()

        // Counter number inside circle
        if count > 0 {
            let fontSize: CGFloat = count >= 10 ? 7 : 8
            let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
            let text = "\(count)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = NSRect(
                x: cx - textSize.width / 2,
                y: circCy - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
        }
    }
}
