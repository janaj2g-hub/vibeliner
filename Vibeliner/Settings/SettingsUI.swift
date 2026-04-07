import AppKit

enum SettingsUI {

    static func sectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = DesignTokens.settingsSectionFont
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        return label
    }

    static func bodyCopy(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = DesignTokens.settingsBodyFont
        label.textColor = .tertiaryLabelColor
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        return label
    }

    static func rowTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = DesignTokens.settingsSectionFont
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
            : DesignTokens.settingsFieldFont
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingMiddle
        label.maximumNumberOfLines = 1
        return label
    }

    static func divider() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.separatorColor.cgColor

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 1 / scale)
        ])

        return view
    }

    /// Apply field surface styling. Call again from viewDidChangeEffectiveAppearance
    /// to refresh CGColor values when dark/light mode changes.
    static func styleFieldSurface(_ view: NSView, cornerRadius: CGFloat = 10) {
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.borderWidth = 1
        view.setLayerBackground(DesignTokens.settingsFieldSurface)
        view.setLayerBorder(DesignTokens.settingsFieldBorder)
    }

    static func styleFrameSurface(_ view: NSView) {
        view.wantsLayer = true
        view.layer?.cornerRadius = DesignTokens.settingsFrameRadius
        view.layer?.borderWidth = 1
        view.setLayerBackground(DesignTokens.settingsFrameSurface)
        view.setLayerBorder(NSColor.separatorColor)
    }

    static func stylePreviewSurface(_ view: NSView) {
        view.wantsLayer = true
        view.layer?.cornerRadius = DesignTokens.settingsFrameRadius
        view.layer?.borderWidth = 1
        view.setLayerBackground(DesignTokens.settingsPreviewSurface)
        view.setLayerBorder(DesignTokens.settingsFieldBorder)
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

// MARK: - Pill button (Save, Change, etc.)

final class SettingsPillButton: NSButton {

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
        layer?.cornerRadius = DesignTokens.settingsPillHeight / 2
        layer?.borderWidth = 1
        refreshColors()

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: DesignTokens.settingsPillHeight)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshColors()
    }

    func refreshColors() {
        contentTintColor = DesignTokens.settingsPillText
        setLayerBackground(DesignTokens.settingsPillFill)
        setLayerBorder(DesignTokens.settingsPillBorder)
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

// MARK: - Segmented control (Preamble/Tools/Footer + Light/Dark/System)

final class SettingsSegmentedControl: NSView {

    var onSelectionChanged: ((Int) -> Void)?

    private let trackView = NSView()
    private let highlightView = NSView()
    private let stackView = NSStackView()
    private var buttons: [NSButton] = []
    private(set) var selectedIndex: Int = 0

    init(items: [String], selectedIndex: Int = 0) {
        self.selectedIndex = selectedIndex
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

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshColors()
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

        trackView.wantsLayer = true
        trackView.layer?.cornerRadius = DesignTokens.settingsSegmentedHeight / 2
        trackView.layer?.borderWidth = 1

        highlightView.wantsLayer = true
        highlightView.layer?.cornerRadius = (DesignTokens.settingsSegmentedHeight - (DesignTokens.settingsSegmentedInset * 2)) / 2
        highlightView.layer?.borderWidth = 1

        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .fillEqually
        stackView.spacing = 2

        addSubview(trackView)
        trackView.addSubview(highlightView)
        trackView.addSubview(stackView)

        refreshColors()

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

    private func refreshColors() {
        trackView.setLayerBackground(DesignTokens.settingsSegmentedTrack)
        trackView.setLayerBorder(NSColor.separatorColor)
        highlightView.setLayerBackground(DesignTokens.settingsSegmentedActive)
        highlightView.setLayerBorder(DesignTokens.settingsPillBorder)
    }

    private func configureButtons(_ items: [String]) {
        for (index, item) in items.enumerated() {
            let button = NSButton(title: item, target: self, action: #selector(buttonClicked(_:)))
            button.isBordered = false
            button.font = DesignTokens.settingsSectionFont
            button.tag = index
            button.focusRingType = .none
            button.translatesAutoresizingMaskIntoConstraints = false
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
    }

    private func updateButtonStates() {
        for (index, button) in buttons.enumerated() {
            button.contentTintColor = index == selectedIndex ? .labelColor : .secondaryLabelColor
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
}

// MARK: - Appearance-aware field view (refreshes layer colors on theme change)

final class AppearanceAwareFieldView: NSView {
    var fieldCornerRadius: CGFloat = 10

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        SettingsUI.styleFieldSurface(self, cornerRadius: fieldCornerRadius)
    }
}
