import AppKit

enum ToolButtonStyle {
    case close      // 24px, red hover
    case icon       // 28px, standard hover
    case tool       // 30px, purple active
    case trash      // 28px, red hover
}

final class ToolButton: NSView {

    var onClick: (() -> Void)?
    var isActive: Bool = false { didSet { needsDisplay = true } }
    // VIB-202: Trash enabled/disabled state
    var isEnabled: Bool = true { didSet { needsDisplay = true } }

    private let style: ToolButtonStyle
    private let iconDrawer: (NSRect, NSColor) -> Void
    private var isHovered: Bool = false { didSet { needsDisplay = true } }

    var buttonSize: CGFloat {
        switch style {
        case .close: return DesignTokens.closeButtonSize
        case .icon, .trash: return DesignTokens.iconButtonSize
        case .tool: return DesignTokens.toolButtonSize
        }
    }

    init(style: ToolButtonStyle, tooltip: String, iconDrawer: @escaping (NSRect, NSColor) -> Void) {
        self.style = style
        self.iconDrawer = iconDrawer
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: 0, height: 0)))
        toolTip = tooltip
        let size = buttonSize
        setFrameSize(NSSize(width: size, height: size))
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let rect = bounds
        let bgColor: NSColor
        let iconColor: NSColor

        switch style {
        case .close:
            bgColor = isHovered ? DesignTokens.closeHoverBg : .clear
            iconColor = isHovered ? DesignTokens.closeIconHover : DesignTokens.iconDefault
        case .trash:
            if !isEnabled {
                bgColor = .clear
                iconColor = DesignTokens.iconDefault.withAlphaComponent(0.12)
            } else if isHovered {
                bgColor = DesignTokens.trashHoverBg
                iconColor = DesignTokens.red
            } else {
                bgColor = .clear
                iconColor = DesignTokens.iconDefault
            }
        case .tool:
            if isActive {
                bgColor = DesignTokens.toolActiveBg
                iconColor = DesignTokens.purpleLight
            } else {
                bgColor = isHovered ? DesignTokens.buttonHoverBg : .clear
                iconColor = isHovered ? DesignTokens.iconHover : DesignTokens.iconDefault
            }
        case .icon:
            bgColor = isHovered ? DesignTokens.buttonHoverBg : .clear
            iconColor = isHovered ? DesignTokens.iconHover : DesignTokens.iconDefault
        }

        // Draw circular background
        let circlePath = NSBezierPath(ovalIn: rect)
        bgColor.setFill()
        circlePath.fill()

        // Draw icon
        let iconSize: CGFloat
        switch style {
        case .close: iconSize = 10
        case .icon, .trash: iconSize = 14
        case .tool: iconSize = 15
        }
        let iconRect = NSRect(
            x: rect.midX - iconSize / 2,
            y: rect.midY - iconSize / 2,
            width: iconSize,
            height: iconSize
        )

        context.saveGState()
        iconDrawer(iconRect, iconColor)
        context.restoreGState()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    // VIB-169: Accept first click even when panel isn't key window
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        onClick?()
    }
}
