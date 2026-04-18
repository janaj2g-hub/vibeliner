import AppKit

enum SettingsUI {

    static func sectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = DesignTokens.fontLabel
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        return label
    }

    static func bodyCopy(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = DesignTokens.fontBody
        label.textColor = .tertiaryLabelColor
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        return label
    }

    static func rowTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = DesignTokens.fontLabel
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        return label
    }

    static func regularLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .labelColor
        label.alignment = .left
        return label
    }

    static func fieldLabel(_ text: String, monospaced: Bool = false) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = monospaced
            ? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            : DesignTokens.fontMonoBody
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.maximumNumberOfLines = 1
        return label
    }

    static func divider() -> NSView {
        let view = AppearanceSafeDivider()
        view.translatesAutoresizingMaskIntoConstraints = false

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 1 / scale)
        ])

        return view
    }

    /// Apply field surface styling. Call again from viewDidChangeEffectiveAppearance
    /// to refresh CGColor values when dark/light mode changes.
    static func styleFieldSurface(_ view: NSView, cornerRadius: CGFloat = 10) {
        styleSurface(
            view,
            background: DesignTokens.settingsFieldSurface,
            border: DesignTokens.settingsFieldBorder,
            cornerRadius: cornerRadius
        )
    }

    static func styleFrameSurface(_ view: NSView) {
        styleSurface(
            view,
            background: DesignTokens.settingsFrameSurface,
            border: NSColor.separatorColor,
            cornerRadius: DesignTokens.settingsFrameRadius
        )
    }

    static func stylePreviewSurface(_ view: NSView) {
        styleSurface(
            view,
            background: DesignTokens.settingsPreviewSurface,
            border: DesignTokens.settingsFieldBorder,
            cornerRadius: DesignTokens.settingsFrameRadius
        )
    }

    static func styleSegmentedTrackSurface(_ view: NSView) {
        styleSurface(
            view,
            background: DesignTokens.segmentedTrack,
            border: DesignTokens.segmentedTrackBorder,
            cornerRadius: DesignTokens.pillButtonHeight / 2
        )
    }

    static func styleSegmentedHighlightSurface(_ view: NSView) {
        styleSurface(
            view,
            background: DesignTokens.segmentedActiveFill,
            border: DesignTokens.segmentedActiveBorder,
            cornerRadius: (DesignTokens.pillButtonHeight - (DesignTokens.settingsSegmentedInset * 2)) / 2
        )
    }

    static func styleDividerSurface(_ view: NSView, color: NSColor = .separatorColor) {
        view.wantsLayer = true
        view.setLayerBackground(color)
    }

    static func styleSurface(
        _ view: NSView,
        background: NSColor,
        border: NSColor? = nil,
        cornerRadius: CGFloat = 0,
        borderWidth: CGFloat = 1
    ) {
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        if let border {
            view.layer?.borderWidth = borderWidth
            view.setLayerBorder(border)
        } else {
            view.layer?.borderWidth = 0
            view.layer?.borderColor = nil
        }
        view.setLayerBackground(background)
    }

    static func makeSection(title: String, contentView: NSView, labelWidth: CGFloat = DesignTokens.settingsSectionLabelWidth) -> NSView {
        let label = rowTitle(title)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(equalToConstant: labelWidth)
        ])

        let row = NSStackView(views: [label, contentView])
        row.orientation = .horizontal
        row.alignment = .top
        row.distribution = .fill
        row.spacing = 28
        row.translatesAutoresizingMaskIntoConstraints = false

        return row
    }
}

// MARK: - Appearance-safe layer color helper

extension NSView {
    /// Set a layer color property using the view's current effective appearance.
    /// Must be called from viewDidChangeEffectiveAppearance or after the view is in the hierarchy.
    func setLayerBackground(_ color: NSColor) {
        wantsLayer = true
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.backgroundColor = color.cgColor
        }
    }

    func setLayerBorder(_ color: NSColor) {
        wantsLayer = true
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.borderColor = color.cgColor
        }
    }
}

class AppearanceAwareSurfaceView: NSView {
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        refreshSurfaceAppearance()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshSurfaceAppearance()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshSurfaceAppearance()
    }

    func refreshSurfaceAppearance() {}
}

class AppearanceAwareSurfaceButton: NSButton {
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        refreshSurfaceAppearance()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshSurfaceAppearance()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshSurfaceAppearance()
    }

    func refreshSurfaceAppearance() {}
}

// MARK: - Pill button (Save, Change, etc.)

