import AppKit

// Bespoke border alphas for the secondary toolbar button (+ Add image,
// New capture). These don't align with the neutral ladder (idle 0.15/0.20,
// hover 0.25/0.35) and stay file-local per VIB-509. Kept as file-scoped
// `static let` to avoid re-resolving the dynamicColor on every call.
private enum SecondaryToolbarBorder {
    static let idle = DesignTokens.dynamicColor(
        dark: NSColor(white: 1, alpha: 0.20),
        light: NSColor(white: 0, alpha: 0.15)
    )
    static let hover = DesignTokens.dynamicColor(
        dark: NSColor(white: 1, alpha: 0.35),
        light: NSColor(white: 0, alpha: 0.25)
    )
}

// MARK: - Mode Toggle

final class ModeToggleView: NSView {

    var onModeChange: ((String) -> Void)?

    private let ideLabel = NSTextField(labelWithString: "IDE")
    private let appLabel = NSTextField(labelWithString: "App")
    private let highlightView = ToolbarModeToggleHighlightView()
    private var currentMode: String

    // Prototype: container height 28, borderRadius 14, bg rgba(255,255,255,0.06), padding 2
    // Segments: height 24, borderRadius 12, padding 0 12px, fontSize 9 weight 600
    private let segW: CGFloat = 36
    private let containerH: CGFloat = 28

    override init(frame frameRect: NSRect) {
        currentMode = ConfigManager.shared.copyMode
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: segW * 2 + 4, height: containerH)))
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        wantsLayer = true
        SettingsUI.styleSurface(self, background: DesignTokens.neutralHairline.withAlphaComponent(0.03), cornerRadius: 14, borderWidth: 0)
        addSubview(highlightView)

        for label in [ideLabel, appLabel] {
            label.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
            label.alignment = .center
            label.isBezeled = false
            label.drawsBackground = false
            label.isEditable = false
            label.isSelectable = false
            label.usesSingleLineMode = true
            label.cell?.isScrollable = false
            label.cell?.wraps = false
            addSubview(label)
        }

        // Labels positioned to vertically center the 9px text within 24px segments
        // Segments are at y=2 within the 28px container
        let labelH: CGFloat = 14  // enough for 9px font
        let labelY: CGFloat = 2 + (24 - labelH) / 2  // center within segment
        ideLabel.frame = NSRect(x: 2, y: labelY, width: segW, height: labelH)
        appLabel.frame = NSRect(x: 2 + segW, y: labelY, width: segW, height: labelH)

        updateAppearance()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshToggleColors()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshToggleColors()
    }

    private func refreshToggleColors() {
        SettingsUI.styleSurface(self, background: DesignTokens.neutralHairline.withAlphaComponent(0.03), cornerRadius: 14, borderWidth: 0)
        highlightView.refreshSurfaceAppearance()
        updateAppearance()
    }

    private func updateAppearance() {
        if currentMode == "ide" {
            highlightView.frame = NSRect(x: 2, y: 2, width: segW, height: 24)
            ideLabel.textColor = DesignTokens.purpleBrand
            appLabel.textColor = DesignTokens.neutralStrong
        } else {
            highlightView.frame = NSRect(x: 2 + segW, y: 2, width: segW, height: 24)
            appLabel.textColor = DesignTokens.purpleBrand
            ideLabel.textColor = DesignTokens.neutralStrong
        }
    }

    override func mouseDown(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        currentMode = localPoint.x < bounds.midX ? "ide" : "app"
        updateAppearance()
        onModeChange?(currentMode)
    }
}

final class ToolbarModeToggleHighlightView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(self, background: DesignTokens.purpleSubtle, cornerRadius: 12, borderWidth: 0)
    }
}

// MARK: - Copy Pill Button

final class CopyPillButton: NSView {

    var onClick: (() -> Void)?
    private let label: NSTextField
    private let originalTitle: String
    private var isHovered = false { didSet { needsDisplay = true; updateAppearance() } }
    private(set) var isCopied = false
    private var revertTimer: Timer?

    init(title: String) {
        self.originalTitle = title
        label = NSTextField(labelWithString: title)
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = true
        layer?.borderWidth = 1.5

        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = DesignTokens.purpleBrand
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        addSubview(label)

        label.sizeToFit()
        let w = label.frame.width + 28  // padding 0 14px each side = 28
        let h: CGFloat = 28
        setFrameSize(NSSize(width: w, height: h))
        label.frame = NSRect(x: 14, y: (h - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)

        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    func showCopied() {
        isCopied = true
        label.stringValue = "✓ Copied"
        centerLabel()
        updateAppearance()
        revertTimer?.invalidate()
        revertTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.resetState()
        }
    }

    func resetState() {
        revertTimer?.invalidate()
        isCopied = false
        label.stringValue = originalTitle
        centerLabel()
        updateAppearance()
    }

    private func centerLabel() {
        label.sizeToFit()
        let h = frame.height
        label.frame = NSRect(
            x: (frame.width - label.frame.width) / 2,
            y: (h - label.frame.height) / 2,
            width: label.frame.width,
            height: label.frame.height
        )
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateAppearance()
    }

    private func updateAppearance() {
        if isCopied {
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.copiedGreenBg,
                border: DesignTokens.copiedGreenBorder,
                cornerRadius: 14,
                borderWidth: 1.5
            )
            label.textColor = DesignTokens.copiedGreenText
        } else {
            let borderColor = isHovered ? DesignTokens.purpleHover : DesignTokens.purpleBrand
            let bgColor: NSColor = isHovered
                ? DesignTokens.dynamicColor(
                    dark: DesignTokens.purpleHover.withAlphaComponent(0.35),
                    light: DesignTokens.purpleBrand.withAlphaComponent(0.12)
                )
                : DesignTokens.purpleStrong
            SettingsUI.styleSurface(
                self,
                background: bgColor,
                border: borderColor,
                cornerRadius: 14,
                borderWidth: 1.5
            )
            label.textColor = isHovered ? DesignTokens.purpleHover : DesignTokens.purpleBrand
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func mouseDown(with event: NSEvent) { onClick?() }
}

// MARK: - VIB-330: Secondary Pill Button

/// Subtle outlined pill button for secondary actions (+ Add image, New capture).
/// Uses `toolbarSecondary*` design tokens — neutral border/text, no purple, fully opaque.
final class SecondaryPillButton: NSView {

    var onClick: (() -> Void)?
    var isButtonEnabled: Bool = true {
        didSet { updateAppearance() }
    }
    private let label: NSTextField
    private var isHovered = false { didSet { updateAppearance() } }

    init(title: String) {
        label = NSTextField(labelWithString: title)
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 13
        layer?.masksToBounds = true
        layer?.borderWidth = 1

        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        addSubview(label)

        label.sizeToFit()
        let w = label.frame.width + 24  // 12px padding each side
        let h: CGFloat = 26
        setFrameSize(NSSize(width: w, height: h))
        label.frame = NSRect(
            x: 12,
            y: (h - label.frame.height) / 2,
            width: label.frame.width,
            height: label.frame.height
        )

        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func updateAppearance() {
        if !isButtonEnabled {
            label.textColor = DesignTokens.neutralStrong.withAlphaComponent(0.3)
            SettingsUI.styleSurface(
                self,
                background: .clear,
                border: SecondaryToolbarBorder.idle.withAlphaComponent(0.15),
                cornerRadius: 13
            )
        } else if isHovered {
            label.textColor = DesignTokens.neutralStrong
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.neutralHairline.withAlphaComponent(0.05),
                border: SecondaryToolbarBorder.hover,
                cornerRadius: 13
            )
        } else {
            label.textColor = DesignTokens.neutralStrong
            SettingsUI.styleSurface(
                self,
                background: .clear,
                border: SecondaryToolbarBorder.idle,
                cornerRadius: 13
            )
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateAppearance()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func mouseDown(with event: NSEvent) {
        guard isButtonEnabled else { return }
        onClick?()
    }
}
