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
        contentTintColor = DesignTokens.pillButtonText
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
        contentTintColor = DesignTokens.pillButtonText
        SettingsUI.styleSurface(
            self,
            background: DesignTokens.pillButtonBg,
            border: DesignTokens.pillButtonBorder,
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
            label.textColor = DesignTokens.pillButtonText
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

    // VIB-434: Forward clicks on track gaps/inset to the nearest button
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard bounds.contains(point) else { super.mouseDown(with: event); return }
        for (index, btn) in stackView.arrangedSubviews.enumerated() {
            let frame = stackView.convert(btn.frame, to: self)
            if point.x >= frame.minX && point.x < frame.maxX {
                setSelectedIndex(index)
                return
            }
        }
        super.mouseDown(with: event)
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

// MARK: - Underline Tab Strip (VIB-431)

final class UnderlineTabStripView: NSView {

    var onSelectionChanged: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    private let items: [String]
    private var buttons: [NSButton] = []
    private var hoverTrackingAreas: [NSTrackingArea] = []
    private var hoveredIndex: Int? = nil
    private let underlineView = NSView()
    private let dividerView = AppearanceSafeDivider()
    private let stackView = NSStackView()

    private let tabFont = NSFont.systemFont(ofSize: 12, weight: .regular)
    private let tabFontActive = NSFont.systemFont(ofSize: 12, weight: .medium)

    private static let tabHPadding: CGFloat = 24
    private static let underlineHeight: CGFloat = 2

    /// Appearance-aware: active text color
    private static let activeTextColor = NSColor(name: nil) { appearance in
        DesignTokens.isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.9)
            : NSColor.labelColor
    }

    /// Appearance-aware: inactive text color
    private static let inactiveTextColor = NSColor(name: nil) { appearance in
        DesignTokens.isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.35)
            : NSColor.secondaryLabelColor
    }

    /// Appearance-aware: hovered inactive text color
    private static let hoverTextColor = NSColor(name: nil) { appearance in
        DesignTokens.isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.6)
            : NSColor.labelColor
    }

    /// Appearance-aware: divider color
    private static let dividerColor = NSColor(name: nil) { appearance in
        DesignTokens.isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.08)
            : NSColor.separatorColor
    }

    init(items: [String], selectedIndex: Int = 0) {
        self.items = items
        self.selectedIndex = selectedIndex
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildLayout()
        updateButtonStates()
    }

    required init?(coder: NSCoder) { fatalError() }

    func setSelectedIndex(_ index: Int, notify: Bool = true) {
        guard index >= 0, index < buttons.count else { return }
        selectedIndex = index
        updateButtonStates()
        needsLayout = true
        if notify { onSelectionChanged?(index) }
    }

    override func layout() {
        super.layout()
        updateUnderlineFrame()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshColors()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshColors()
    }

    // MARK: - Build

    private func buildLayout() {
        stackView.orientation = .horizontal
        stackView.alignment = .bottom
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        underlineView.wantsLayer = true
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(underlineView)

        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)

        for (index, item) in items.enumerated() {
            let button = NSButton(title: item, target: self, action: #selector(tabClicked(_:)))
            button.isBordered = false
            button.font = tabFont
            button.tag = index
            button.focusRingType = .none
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)

            // VIB-434: Use TabWrapperView so clicks anywhere in the padded
            // area forward to the button (not just on the text label).
            let wrapper = TabWrapperView()
            wrapper.translatesAutoresizingMaskIntoConstraints = false
            wrapper.targetButton = button
            wrapper.addSubview(button)

            // Generous tap target: 12px top + 10px bottom padding
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: Self.tabHPadding),
                button.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -Self.tabHPadding),
                button.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 12),
                button.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -10),
            ])

            // Accessibility
            button.setAccessibilityRole(.radioButton)
            button.setAccessibilityLabel(item)

            buttons.append(button)
            stackView.addArrangedSubview(wrapper)
        }

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(Self.underlineHeight + 0.5)),

            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        // Set up hover tracking on wrappers
        for wrapper in stackView.arrangedSubviews {
            let area = NSTrackingArea(
                rect: .zero,
                options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            wrapper.addTrackingArea(area)
            hoverTrackingAreas.append(area)
        }
    }

    // MARK: - State

    private func updateButtonStates() {
        for (index, button) in buttons.enumerated() {
            let isActive = index == selectedIndex
            let isHovered = index == hoveredIndex
            button.contentTintColor = isActive
                ? Self.activeTextColor
                : (isHovered ? Self.hoverTextColor : Self.inactiveTextColor)
            button.font = isActive ? tabFontActive : tabFont
            button.setAccessibilityValue(isActive ? "selected" : "")
        }
    }

    private func updateUnderlineFrame() {
        guard selectedIndex < stackView.arrangedSubviews.count else { return }
        let wrapper = stackView.arrangedSubviews[selectedIndex]
        let wrapperFrame = stackView.convert(wrapper.frame, to: self)
        underlineView.frame = NSRect(
            x: wrapperFrame.minX,
            y: 0.5,  // sits on top of the divider
            width: wrapperFrame.width,
            height: Self.underlineHeight
        )
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.underlineView.layer?.backgroundColor = DesignTokens.purpleLight.cgColor
        }
    }

    private func refreshColors() {
        updateButtonStates()
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.underlineView.layer?.backgroundColor = DesignTokens.purpleLight.cgColor
        }
        SettingsUI.styleDividerSurface(dividerView, color: Self.dividerColor)
    }

    // MARK: - Hover

    override func mouseEntered(with event: NSEvent) {
        guard let index = wrapperIndex(for: event) else { return }
        hoveredIndex = index
        updateButtonStates()
    }

    override func mouseExited(with event: NSEvent) {
        hoveredIndex = nil
        updateButtonStates()
    }

    private func wrapperIndex(for event: NSEvent) -> Int? {
        let point = convert(event.locationInWindow, from: nil)
        for (index, wrapper) in stackView.arrangedSubviews.enumerated() {
            let frame = stackView.convert(wrapper.frame, to: self)
            if frame.contains(point) { return index }
        }
        return nil
    }

    // MARK: - Click

    @objc private func tabClicked(_ sender: NSButton) {
        setSelectedIndex(sender.tag)
    }
}

// VIB-434: Wrapper view that forwards clicks on padding area to the tab button
private class TabWrapperView: NSView {
    weak var targetButton: NSButton?

    override func mouseDown(with event: NSEvent) {
        // Forward clicks anywhere in the wrapper to the button's action
        targetButton?.performClick(self)
    }
}

// MARK: - Settings Toggle Control (VIB-432, VIB-433)

final class SettingsToggleControl: NSView {

    var onSelectionChanged: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    private let items: [String]
    private var buttons: [NSButton] = []
    private let trackView = NSView()
    private let highlightView = NSView()
    private let stackView = NSStackView()

    private static let controlHeight: CGFloat = 28
    private static let inset: CGFloat = 2
    private static let segmentHeight: CGFloat = controlHeight - inset * 2

    init(items: [String], selectedIndex: Int = 0) {
        self.items = items
        self.selectedIndex = selectedIndex
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildLayout()
        updateStates()
    }

    required init?(coder: NSCoder) { fatalError() }

    func setSelectedIndex(_ index: Int, notify: Bool = true) {
        guard index >= 0, index < buttons.count, index != selectedIndex else { return }
        selectedIndex = index
        updateStates()
        needsLayout = true
        if notify { onSelectionChanged?(index) }
    }

    override func layout() {
        super.layout()
        updateHighlightFrame()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshColors()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshColors()
    }

    override var intrinsicContentSize: NSSize {
        let font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let totalTextW = items.reduce(CGFloat.zero) { result, item in
            result + ceil((item as NSString).size(withAttributes: attributes).width) + 24
        }
        let spacing = CGFloat(max(items.count - 1, 0)) * stackView.spacing
        let insets = Self.inset * 2
        return NSSize(width: totalTextW + spacing + insets, height: Self.controlHeight)
    }

    // MARK: - Build

    private func buildLayout() {
        trackView.wantsLayer = true
        trackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trackView)

        highlightView.wantsLayer = true
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(highlightView)

        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(stackView)

        for (index, item) in items.enumerated() {
            let button = NSButton(title: item, target: self, action: #selector(segmentClicked(_:)))
            button.isBordered = false
            button.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
            button.tag = index
            button.focusRingType = .none
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setContentHuggingPriority(.defaultLow, for: .horizontal)
            button.setAccessibilityRole(.radioButton)
            button.setAccessibilityLabel(item)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Self.controlHeight),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: Self.inset),
            stackView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: -Self.inset),
            stackView.topAnchor.constraint(equalTo: trackView.topAnchor, constant: Self.inset),
            stackView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor, constant: -Self.inset),
        ])
    }

    // MARK: - State

    private func updateStates() {
        for (index, button) in buttons.enumerated() {
            let isActive = index == selectedIndex
            button.contentTintColor = isActive ? .white : DesignTokens.toolbarToggleInactiveText
            button.setAccessibilityValue(isActive ? "selected" : "")
        }
    }

    private func updateHighlightFrame() {
        guard selectedIndex < stackView.arrangedSubviews.count else { return }
        let button = stackView.arrangedSubviews[selectedIndex]
        let targetFrame = button.superview?.convert(button.frame, to: trackView) ?? .zero
        highlightView.frame = NSRect(
            x: targetFrame.minX,
            y: Self.inset,
            width: targetFrame.width,
            height: Self.segmentHeight
        )
        highlightView.layer?.cornerRadius = Self.segmentHeight / 2
    }

    private func refreshColors() {
        let cr = Self.controlHeight / 2
        trackView.layer?.cornerRadius = cr
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.trackView.layer?.backgroundColor = DesignTokens.toolbarToggleBg.cgColor
            self.highlightView.layer?.backgroundColor = DesignTokens.purpleDark.cgColor
        }
        updateStates()
    }

    // VIB-434: Forward clicks on track gaps/inset to the nearest segment
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard bounds.contains(point) else { super.mouseDown(with: event); return }
        // Find which segment column the click falls in
        for (index, seg) in stackView.arrangedSubviews.enumerated() {
            let frame = stackView.convert(seg.frame, to: self)
            if point.x >= frame.minX && point.x < frame.maxX {
                setSelectedIndex(index)
                return
            }
        }
        // Fallback: pick closest segment
        if !buttons.isEmpty {
            let trackLocal = convert(point, to: stackView)
            var bestIndex = 0
            var bestDist = CGFloat.greatestFiniteMagnitude
            for (index, seg) in stackView.arrangedSubviews.enumerated() {
                let dist = abs(seg.frame.midX - trackLocal.x)
                if dist < bestDist { bestDist = dist; bestIndex = index }
            }
            setSelectedIndex(bestIndex)
        }
    }

    @objc private func segmentClicked(_ sender: NSButton) {
        setSelectedIndex(sender.tag)
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
