import AppKit

// MARK: - Tool icon view

final class ToolIconView: AppearanceAwareFieldView {

    private let tool: AnnotationToolType

    init(tool: AnnotationToolType) {
        self.tool = tool
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let iconSize: CGFloat = 16
        let iconRect = NSRect(
            x: bounds.midX - (iconSize / 2),
            y: bounds.midY - (iconSize / 2),
            width: iconSize,
            height: iconSize
        )
        let color = NSColor.secondaryLabelColor
        switch tool {
        case .pin: ToolbarView.drawPinIcon(iconRect, color)
        case .arrow: ToolbarView.drawArrowIcon(iconRect, color)
        case .line: ToolbarView.drawLineIcon(iconRect, color)
        case .rectangle: ToolbarView.drawRectIcon(iconRect, color)
        case .circle: ToolbarView.drawCircleIcon(iconRect, color)
        case .freehand: ToolbarView.drawFreehandIcon(iconRect, color)
        case .select: break
        }
    }
}

final class AppearanceAwareFrameSurfaceView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleFrameSurface(self)
    }
}

final class PromptDraftStateView: AppearanceAwareSurfaceView {

    enum State {
        case saved
        case unsaved
    }

    private let label = NSTextField(labelWithString: "")
    private var state: State = .saved

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false

        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])

        setState(.saved)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setState(_ state: State) {
        self.state = state
        label.stringValue = state == .saved ? "Saved settings" : "Unsaved draft"
        invalidateIntrinsicContentSize()
        refreshSurfaceAppearance()
    }

    override var intrinsicContentSize: NSSize {
        let labelSize = label.intrinsicContentSize
        return NSSize(width: labelSize.width + 20, height: max(24, labelSize.height + 12))
    }

    override func refreshSurfaceAppearance() {
        // VIB-448: Plain status text — no pill border or fill
        switch state {
        case .saved:
            label.textColor = .tertiaryLabelColor
        case .unsaved:
            label.textColor = DesignTokens.pillButtonText
        }
        SettingsUI.styleSurface(self, background: .clear, cornerRadius: 0, borderWidth: 0)
    }
}

// MARK: - Role swatch view

final class RoleSwatchView: NSView {

    var onClicked: ((RoleSwatchView) -> Void)?
    private let swatchColor: NSColor
    private var isHovered = false

    init(color: NSColor) {
        self.swatchColor = color
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let outerRect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let outerPath = NSBezierPath(ovalIn: outerRect)
        let colorRect = bounds.insetBy(dx: 2.5, dy: 2.5)
        let colorPath = NSBezierPath(ovalIn: colorRect)

        NSColor.windowBackgroundColor.setFill()
        outerPath.fill()
        swatchColor.setFill()
        colorPath.fill()

        DesignTokens.roleSwatchInnerBorder.setStroke()
        colorPath.lineWidth = 1
        colorPath.stroke()

        (isHovered ? DesignTokens.roleSwatchSelectedRing : DesignTokens.roleSwatchOutline).setStroke()
        outerPath.lineWidth = isHovered ? 1.5 : 1
        outerPath.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        onClicked?(self)
    }
}
