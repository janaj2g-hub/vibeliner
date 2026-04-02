import AppKit

/// VIB-164: Simple pin icon — filled circle + stake, no counter number.
/// Uses currentColor via isActive toggle for state changes.
final class PinCounterIcon: NSView {

    var count: Int = 0 { didSet { /* count no longer displayed */ } }
    var isActive: Bool = false { didSet { needsDisplay = true } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let color = isActive ? DesignTokens.purpleLight : DesignTokens.purpleLightInactive

        // Prototype SVG: circle cx=7.5 cy=5 r=4.5, line y1=9.5 y2=14 in 15×15 viewBox
        // Map to bounds (30×30 button)
        let scale = bounds.width / 15
        let cx = bounds.midX
        let cy = bounds.midY + 1 * scale  // optical center shift

        let circR: CGFloat = 4.5 * scale
        let circCy = cy + (5 - 7.5) * scale

        // Filled circle
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: cx - circR, y: circCy - circR, width: circR * 2, height: circR * 2)).fill()

        // Stake line
        let stakeTop = cy + (7.5 - 9.5) * scale
        let stakeBottom = cy + (7.5 - 14) * scale
        let stake = NSBezierPath()
        stake.move(to: NSPoint(x: cx, y: stakeTop))
        stake.line(to: NSPoint(x: cx, y: stakeBottom))
        stake.lineWidth = 1.8 * scale
        stake.lineCapStyle = .round
        color.setStroke()
        stake.stroke()
    }
}
