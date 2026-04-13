import AppKit

// MARK: - Appearance-aware content view

class TourContentView: NSView {
    var onAppearanceChange: (() -> Void)?
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}

/// NSButton subclass that forwards mouse enter/exit for hover tracking.
class HoverButton: NSButton {
    var onMouseEntered: (() -> Void)?
    var onMouseExited: (() -> Void)?
    private var hoverTrackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        hoverTrackingArea = trackingArea
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEntered?()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExited?()
    }
}

/// VIB-382: Custom-drawn pill that bypasses NSButton rendering quirks.
/// Draws text, border, and background manually in draw(_:) so it is always visible.
class ExitTourPillView: NSView {

    var onClicked: (() -> Void)?

    var isHovered = false {
        didSet { needsDisplay = true }
    }

    private let title = "Exit tour"
    private let hPad: CGFloat = 14
    private let vPad: CGFloat = 5
    private var trackingArea: NSTrackingArea?

    override var intrinsicContentSize: NSSize {
        let attrs: [NSAttributedString.Key: Any] = [.font: DesignTokens.tourExitFont]
        let textSize = (title as NSString).size(withAttributes: attrs)
        return NSSize(width: ceil(textSize.width) + hPad * 2, height: ceil(textSize.height) + vPad * 2)
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }

    override func mouseDown(with event: NSEvent) {
        onClicked?()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let borderColor = isHovered ? DesignTokens.tourGhostButtonHoverBorder : DesignTokens.tourGhostButtonBorder
        let textColor = isHovered ? DesignTokens.tourGhostButtonHoverText : DesignTokens.tourGhostButtonText

        // Pill border
        let pillRect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: bounds.height / 2, cornerHeight: bounds.height / 2, transform: nil)
        ctx.addPath(pillPath)
        ctx.setStrokeColor(borderColor.cgColor)
        ctx.setLineWidth(1)
        ctx.strokePath()

        // Text centered
        let attrs: [NSAttributedString.Key: Any] = [
            .font: DesignTokens.tourExitFont,
            .foregroundColor: textColor,
        ]
        let str = NSAttributedString(string: title, attributes: attrs)
        let textSize = str.size()
        let textX = (bounds.width - textSize.width) / 2
        let textY = (bounds.height - textSize.height) / 2
        str.draw(at: NSPoint(x: textX, y: textY))
    }
}
