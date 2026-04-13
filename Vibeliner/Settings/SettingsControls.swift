import AppKit

final class SettingsPillButton: AppearanceAwareSurfaceButton {

    init(title: String, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        font = DesignTokens.settingsPillFont
        contentTintColor = DesignTokens.settingsPillText
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        setButtonType(.momentaryPushIn)
        refreshColors()

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: DesignTokens.settingsPillHeight)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func refreshColors() {
        contentTintColor = DesignTokens.settingsPillText
        SettingsUI.styleSurface(
            self,
            background: DesignTokens.settingsPillFill,
            border: DesignTokens.settingsPillBorder,
            cornerRadius: DesignTokens.settingsPillHeight / 2
        )
    }

    override func refreshSurfaceAppearance() {
        refreshColors()
    }
}

// MARK: - Text field with vertical centering and field surface

final class SettingsTextField: NSTextField {

    init(monospaced: Bool = true) {
        super.init(frame: .zero)
        let savedFont = monospaced
            ? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            : DesignTokens.settingsFieldFont
        cell = VerticallyCenteredTextFieldCell()
        // VIB-338: Replacing the cell resets isEditable to false (NSTextFieldCell default).
        // Re-enable so role name/description fields are actually editable.
        isEditable = true
        isSelectable = true
        font = savedFont
        textColor = .labelColor
        isBordered = false
        drawsBackground = false
        focusRingType = .none
        translatesAutoresizingMaskIntoConstraints = false
        SettingsUI.styleFieldSurface(self)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        SettingsUI.styleFieldSurface(self)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        SettingsUI.styleFieldSurface(self)
    }
}

// MARK: - Hotkey key pill row

final class SettingsKeyPillRow: NSStackView {

    init() {
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 8
        alignment = .centerY
        distribution = .fillProportionally
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init(coder: NSCoder) { fatalError() }

    func setKeys(_ keys: [String]) {
        arrangedSubviews.forEach { view in
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for key in keys {
            let label = NSTextField(labelWithString: key)
            label.font = DesignTokens.settingsPillFont
            label.textColor = DesignTokens.settingsPillText
            label.alignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            let container = AppearanceAwareFieldView()
            container.translatesAutoresizingMaskIntoConstraints = false
            SettingsUI.styleFieldSurface(container, cornerRadius: 10)
            container.addSubview(label)

            let width = max(44, CGFloat(key.count) * 10 + 18)
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: width),
                container.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])

            addArrangedSubview(container)
        }
    }
}

final class SettingsSegmentedTrackView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleSegmentedTrackSurface(self)
    }
}

final class SettingsSegmentedHighlightView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleSegmentedHighlightSurface(self)
    }
}

// MARK: - Segmented control (Preamble/Tools/Footer + Light/Dark/System)

final class SettingsSegmentedControl: NSView {

    enum Style {
        case primary
        case secondary

        var font: NSFont {
            switch self {
            case .primary:
                return DesignTokens.settingsSegmentedPrimaryFont
            case .secondary:
                return DesignTokens.settingsSegmentedSecondaryFont
            }
        }
    }

    var onSelectionChanged: ((Int) -> Void)?

    private let style: Style
    private let items: [String]
    private let trackView = SettingsSegmentedTrackView()
    private let highlightView = SettingsSegmentedHighlightView()
    private let stackView = NSStackView()
    private var buttons: [NSButton] = []
    private(set) var selectedIndex: Int = 0

    init(items: [String], selectedIndex: Int = 0, style: Style = .primary) {
        self.selectedIndex = selectedIndex
        self.style = style
        self.items = items
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupTrack()
        configureButtons(items)
        updateButtonStates()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        updateHighlightFrame()
    }

    override var intrinsicContentSize: NSSize {
        let itemWidth = items.reduce(CGFloat.zero) { partialResult, item in
            partialResult + buttonWidth(for: item)
        }
        let spacing = CGFloat(max(items.count - 1, 0)) * stackView.spacing
        let insets = DesignTokens.settingsSegmentedInset * 2
        return NSSize(
            width: itemWidth + spacing + insets,
            height: DesignTokens.settingsSegmentedHeight
        )
    }

    func setSelectedIndex(_ index: Int, notify: Bool = true) {
        guard index >= 0, index < buttons.count else { return }
        selectedIndex = index
        updateButtonStates()
        needsLayout = true
        if notify { onSelectionChanged?(index) }
    }

    private func setupTrack() {
        trackView.translatesAutoresizingMaskIntoConstraints = false
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .fill
        stackView.spacing = 4

        addSubview(trackView)
        trackView.addSubview(highlightView)
        trackView.addSubview(stackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: DesignTokens.settingsSegmentedHeight),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: DesignTokens.settingsSegmentedInset),
            stackView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: -DesignTokens.settingsSegmentedInset),
            stackView.topAnchor.constraint(equalTo: trackView.topAnchor, constant: DesignTokens.settingsSegmentedInset),
            stackView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor, constant: -DesignTokens.settingsSegmentedInset)
        ])
    }

    private func configureButtons(_ items: [String]) {
        for (index, item) in items.enumerated() {
            let button = NSButton(title: item, target: self, action: #selector(buttonClicked(_:)))
            button.isBordered = false
            button.font = style.font
            button.tag = index
            button.focusRingType = .none
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            buttons.append(button)
            stackView.addArrangedSubview(button)

            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(greaterThanOrEqualToConstant: buttonWidth(for: item))
            ])
        }
    }

    private func updateButtonStates() {
        for (index, button) in buttons.enumerated() {
            let isActive = index == selectedIndex
            button.contentTintColor = isActive ? DesignTokens.settingsSegmentedActiveText : DesignTokens.settingsSegmentedInactiveText
            button.font = isActive
                ? NSFont.systemFont(ofSize: style.font.pointSize, weight: .semibold)
                : style.font
        }
    }

    private func updateHighlightFrame() {
        guard selectedIndex < buttons.count else { return }
        let button = buttons[selectedIndex]
        let targetFrame = button.superview?.convert(button.frame, to: trackView) ?? .zero
        let inset = DesignTokens.settingsSegmentedInset
        highlightView.frame = NSRect(
            x: targetFrame.minX,
            y: inset,
            width: targetFrame.width,
            height: DesignTokens.settingsSegmentedHeight - (inset * 2)
        )
    }

    @objc private func buttonClicked(_ sender: NSButton) {
        setSelectedIndex(sender.tag)
    }

    private func buttonWidth(for title: String) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: style.font]
        let measuredWidth = ceil((title as NSString).size(withAttributes: attributes).width)
        return measuredWidth + (DesignTokens.settingsSegmentedItemPadding * 2)
    }
}

// MARK: - Appearance-aware field view (refreshes layer colors on theme change)

class AppearanceAwareFieldView: AppearanceAwareSurfaceView {
    var fieldCornerRadius: CGFloat = 10

    override func refreshSurfaceAppearance() {
        SettingsUI.styleFieldSurface(self, cornerRadius: fieldCornerRadius)
    }
}

// MARK: - Appearance-safe divider (VIB-388: re-resolves separatorColor on theme change)

final class AppearanceSafeDivider: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleDividerSurface(self)
    }
}
