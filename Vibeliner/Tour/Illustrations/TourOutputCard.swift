import AppKit

/// Rounded rect container for tour illustrations.
/// Shows a label pill at top (e.g. "screenshot.png") and a public content area below.
final class TourOutputCard: NSView {

    private let labelText: String
    /// Public content area for callers to add child views.
    let contentArea: NSView

    private let labelHeight: CGFloat = 20
    private let labelSpacing: CGFloat = 8

    init(label: String) {
        self.labelText = label
        self.contentArea = NSView()
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = DesignTokens.tourOutputCardRadius
        layer?.masksToBounds = true
        layer?.backgroundColor = DesignTokens.tourOutputCardBg.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = DesignTokens.tourOutputCardBorder.cgColor

        contentArea.wantsLayer = true
        addSubview(contentArea)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        let pad = DesignTokens.tourOutputCardPadding

        // Content area fills below the label pill
        let contentY: CGFloat = pad
        let contentH = h - pad - labelHeight - labelSpacing - pad
        contentArea.frame = CGRect(
            x: pad,
            y: contentY,
            width: w - pad * 2,
            height: max(0, contentH)
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let w = bounds.width
        let h = bounds.height
        let pad = DesignTokens.tourOutputCardPadding

        // Label pill at top
        let attrs: [NSAttributedString.Key: Any] = [
            .font: DesignTokens.tourOutputLabelFont,
            .foregroundColor: DesignTokens.tourTextSecondary,
        ]
        let str = NSAttributedString(string: labelText, attributes: attrs)
        let textSize = str.size()
        let pillW = textSize.width + 16
        let pillX = pad
        let pillY = h - pad - labelHeight

        let pillRect = CGRect(x: pillX, y: pillY, width: pillW, height: labelHeight)

        // Pill background
        ctx.setFillColor(DesignTokens.tourOutputLabelBg.cgColor)
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(pillPath)
        ctx.fillPath()

        // Pill border
        ctx.setStrokeColor(DesignTokens.tourOutputLabelBorder.cgColor)
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
