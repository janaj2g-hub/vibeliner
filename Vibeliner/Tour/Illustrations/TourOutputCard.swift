import AppKit

/// Rounded rect container for tour illustrations.
/// Shows a label pill at top (e.g. "screenshot.png") and a public content area below.
final class TourOutputCard: NSView {

    private let labelText: String
    /// Public content area for callers to add child views.
    let contentArea: NSView

    private let cardRadius: CGFloat = 6
    private let cardPadding: CGFloat = 10
    private let labelHeight: CGFloat = 20
    private let labelSpacing: CGFloat = 6

    init(label: String) {
        self.labelText = label
        self.contentArea = NSView()
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = cardRadius
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.03).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = DesignTokens.chromeBorder.cgColor

        contentArea.wantsLayer = true
        addSubview(contentArea)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        // Content area fills below the label pill
        let contentY: CGFloat = cardPadding
        let contentH = h - cardPadding - labelHeight - labelSpacing - cardPadding
        contentArea.frame = CGRect(
            x: cardPadding,
            y: contentY,
            width: w - cardPadding * 2,
            height: max(0, contentH)
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let w = bounds.width
        let h = bounds.height

        // Label pill at top
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: DesignTokens.tourTextSecondary,
        ]
        let str = NSAttributedString(string: labelText, attributes: attrs)
        let textSize = str.size()
        let pillW = textSize.width + 16
        let pillX = cardPadding
        let pillY = h - cardPadding - labelHeight

        let pillRect = CGRect(x: pillX, y: pillY, width: pillW, height: labelHeight)

        // Pill background
        ctx.setFillColor(NSColor(white: 1.0, alpha: 0.04).cgColor)
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(pillPath)
        ctx.fillPath()

        // Pill border
        ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.08).cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(pillPath)
        ctx.strokePath()

        // Pill text
        str.draw(at: NSPoint(
            x: pillRect.midX - textSize.width / 2,
            y: pillRect.midY - textSize.height / 2
        ))
    }
}
