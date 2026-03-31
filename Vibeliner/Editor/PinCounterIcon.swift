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
        let circleRadius: CGFloat = 10
        let cx = bounds.midX
        let cy = bounds.midY + 3

        // Filled circle
        let circlePath = NSBezierPath(ovalIn: NSRect(
            x: cx - circleRadius, y: cy - circleRadius,
            width: circleRadius * 2, height: circleRadius * 2
        ))
        color.setFill()
        circlePath.fill()

        // Stake line below circle
        let stakePath = NSBezierPath()
        stakePath.move(to: NSPoint(x: cx, y: cy - circleRadius))
        stakePath.line(to: NSPoint(x: cx, y: cy - circleRadius - 6))
        stakePath.lineWidth = 1.8
        stakePath.lineCapStyle = .round
        color.setStroke()
        stakePath.stroke()

        // Counter number
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
                y: cy - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
        }
    }
}
