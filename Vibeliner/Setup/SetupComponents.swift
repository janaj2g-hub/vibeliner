import AppKit

/// so layer-backed CGColors can be re-applied with the new appearance.
class SetupContentView: NSView {
    var onAppearanceChange: (() -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onAppearanceChange?()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}

final class SetupDividerView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleDividerSurface(self, color: DesignTokens.setupBorder)
    }
}

final class SetupFooterSurfaceView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(self, background: DesignTokens.setupFooterBg, borderWidth: 0)
    }
}

enum SetupPillRole {
    case accent
    case success
    case ghost
}

class SetupPillButton: AppearanceAwareSurfaceButton {
    private let role: SetupPillRole
    private let heightValue: CGFloat
    private let horizontalPadding: CGFloat

    init(
        title: String,
        role: SetupPillRole,
        height: CGFloat,
        font: NSFont,
        horizontalPadding: CGFloat,
        target: AnyObject?,
        action: Selector?
    ) {
        self.role = role
        self.heightValue = height
        self.horizontalPadding = horizontalPadding
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        setButtonType(.momentaryPushIn)
        self.font = font
        wantsLayer = true
        cell?.lineBreakMode = .byClipping
        sizeToFit()
        updateButtonGeometry()
        refreshSurfaceAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    func updateButtonGeometry() {
        sizeToFit()
        let width = frame.width + horizontalPadding
        setFrameSize(NSSize(width: width, height: heightValue))
    }

    override func refreshSurfaceAppearance() {
        switch role {
        case .accent:
            contentTintColor = DesignTokens.pillButtonText
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.pillButtonBg,
                border: DesignTokens.pillButtonBorder,
                cornerRadius: heightValue / 2
            )
        case .success:
            contentTintColor = DesignTokens.setupGreenText
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.setupGreenBg,
                border: DesignTokens.setupGreenBorder,
                cornerRadius: heightValue / 2
            )
        case .ghost:
            contentTintColor = DesignTokens.setupTextSecondary
            SettingsUI.styleSurface(
                self,
                background: .clear,
                border: DesignTokens.setupBorder,
                cornerRadius: heightValue / 2
            )
        }
    }
}

final class SetupFooterButton: SetupPillButton {
    init(title: String, role: SetupPillRole, target: AnyObject?, action: Selector?) {
        let padding = role == .success ? DesignTokens.setupFooterPrimaryPadding : DesignTokens.setupFooterSecondaryPadding
        super.init(
            title: title,
            role: role,
            height: DesignTokens.setupFooterButtonHeight,
            font: DesignTokens.setupActionLabelFont,
            horizontalPadding: padding,
            target: target,
            action: action
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}

final class SetupCircleButton: AppearanceAwareSurfaceButton {
    init(title: String, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        setButtonType(.momentaryPushIn)
        font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        wantsLayer = true
        let size = DesignTokens.setupArrowSize
        setFrameSize(NSSize(width: size, height: size))
        refreshSurfaceAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        refreshSurfaceAppearance()
    }

    override func refreshSurfaceAppearance() {
        contentTintColor = DesignTokens.pillButtonText
        SettingsUI.styleSurface(
            self,
            background: DesignTokens.pillButtonBg,
            border: DesignTokens.pillButtonBorder,
            cornerRadius: bounds.height / 2
        )
    }
}

