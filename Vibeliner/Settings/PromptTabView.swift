import AppKit

final class PromptTabView: NSView, NSTextViewDelegate, NSTextFieldDelegate {

    // MARK: - Sub-tab model

    private enum PromptSubTab: Int, CaseIterable {
        case preamble, tools, footer, multiImage

        var title: String {
            switch self {
            case .preamble:   return "Preamble"
            case .tools:      return "Tools"
            case .footer:     return "Footer"
            case .multiImage: return "Multi-image"
            }
        }
    }

    private struct PromptDrafts {
        var preamble: String
        var footer: String
        var toolDescriptions: [String: String]
        var roles: [RoleConfig]

        static func current() -> PromptDrafts {
            PromptDrafts(
                preamble: ConfigManager.shared.preamble,
                footer: ConfigManager.shared.footer,
                toolDescriptions: ConfigManager.shared.toolDescriptions,
                roles: ConfigManager.shared.roles
            )
        }
    }

    // MARK: - Views

    private let rootStack = NSStackView()
    private let previewView = PromptPreviewView(frame: .zero)
    private let editFrame = NSView()
    private let editStack = NSStackView()
    private let editHeaderLabel = SettingsUI.sectionTitle("Edit Prompt Sections")
    private let saveButton = SettingsPillButton(title: "Save", target: nil, action: nil)
    private let segmentedControl = SettingsSegmentedControl(items: PromptSubTab.allCases.map(\.title))
    private let activeContentStack = NSStackView()
    private let resetButton = NSButton(title: "Reset to default", target: nil, action: nil)

    // MARK: - State

    private var drafts = PromptDrafts.current()
    private var activeSubTab: PromptSubTab = .preamble
    private weak var preambleEditor: NSTextView?
    private weak var footerEditor: NSTextView?
    private var toolFields: [String: SettingsTextField] = [:]
    private var roleFields: [String: SettingsTextField] = [:]
    private var contentLoaded = false
    private var savedResetTimer: Timer?

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        buildLayout()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        buildLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshTabAppearance()
    }

    // VIB-388: Re-style when re-attached to window after tab switching.
    // Cached tab views miss appearance notifications while detached.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { refreshTabAppearance() }
    }

    private func refreshTabAppearance() {
        SettingsUI.styleFrameSurface(editFrame)
        // Rebuild the active sub-tab so NSTextView colors and editor container
        // layer colors re-resolve for the new appearance
        if contentLoaded {
            selectSubTab(activeSubTab)
            refreshPreview()
        }
    }

    func loadContent() {
        guard !contentLoaded else { return }
        contentLoaded = true
        refreshPreview()
        selectSubTab(.preamble, syncDrafts: false)
    }

    // MARK: - Layout

    private func buildLayout() {
        rootStack.orientation = .vertical
        rootStack.alignment = .leading
        rootStack.spacing = 20
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.settingsContentPadding),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.settingsContentPadding),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.settingsContentPadding),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.settingsContentPadding),
        ])

        // Preview section
        previewView.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(previewView)
        NSLayoutConstraint.activate([
            previewView.heightAnchor.constraint(equalToConstant: 188),
            previewView.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
        ])

        // Edit frame
        SettingsUI.styleFrameSurface(editFrame)
        editFrame.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(editFrame)
        editFrame.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        editStack.orientation = .vertical
        editStack.alignment = .leading
        editStack.spacing = 14
        editStack.translatesAutoresizingMaskIntoConstraints = false
        editFrame.addSubview(editStack)

        NSLayoutConstraint.activate([
            editStack.topAnchor.constraint(equalTo: editFrame.topAnchor, constant: DesignTokens.settingsFramePadding),
            editStack.leadingAnchor.constraint(equalTo: editFrame.leadingAnchor, constant: DesignTokens.settingsFramePadding),
            editStack.trailingAnchor.constraint(equalTo: editFrame.trailingAnchor, constant: -DesignTokens.settingsFramePadding),
            editStack.bottomAnchor.constraint(equalTo: editFrame.bottomAnchor, constant: -DesignTokens.settingsFramePadding),
        ])

        // Header row
        saveButton.target = self
        saveButton.action = #selector(saveAllPromptSections)
        saveButton.widthAnchor.constraint(equalToConstant: 108).isActive = true

        let headerRow = NSStackView()
        headerRow.orientation = .horizontal
        headerRow.alignment = .centerY
        headerRow.spacing = 12
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        headerRow.addArrangedSubview(editHeaderLabel)
        headerRow.addArrangedSubview(spacer)
        headerRow.addArrangedSubview(saveButton)
        editStack.addArrangedSubview(headerRow)
        headerRow.widthAnchor.constraint(equalTo: editStack.widthAnchor).isActive = true

        // Segmented control
        let segmentedRow = NSView()
        segmentedRow.translatesAutoresizingMaskIntoConstraints = false
        segmentedRow.addSubview(segmentedControl)
        editStack.addArrangedSubview(segmentedRow)

        NSLayoutConstraint.activate([
            segmentedRow.widthAnchor.constraint(equalTo: editStack.widthAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: segmentedRow.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: segmentedRow.topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: segmentedRow.bottomAnchor),
            segmentedControl.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            segmentedControl.widthAnchor.constraint(equalTo: segmentedRow.widthAnchor, multiplier: 0.75),
        ])

        segmentedControl.onSelectionChanged = { [weak self] index in
            guard let tab = PromptSubTab(rawValue: index) else { return }
            self?.selectSubTab(tab)
        }

        // Active content area
        activeContentStack.orientation = .vertical
        activeContentStack.alignment = .leading
        activeContentStack.spacing = 14
        activeContentStack.translatesAutoresizingMaskIntoConstraints = false
        editStack.addArrangedSubview(activeContentStack)
        activeContentStack.widthAnchor.constraint(equalTo: editStack.widthAnchor).isActive = true

        // Reset button row
        resetButton.isBordered = false
        resetButton.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        resetButton.contentTintColor = DesignTokens.settingsPillText
        resetButton.target = self
        resetButton.action = #selector(resetCurrentPromptSection)
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        let resetRow = NSStackView()
        resetRow.orientation = .horizontal
        resetRow.alignment = .centerY
        resetRow.spacing = 8
        resetRow.translatesAutoresizingMaskIntoConstraints = false

        let resetSpacer = NSView()
        resetSpacer.translatesAutoresizingMaskIntoConstraints = false
        resetSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        resetSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        resetRow.addArrangedSubview(resetSpacer)
        resetRow.addArrangedSubview(resetButton)
        editStack.addArrangedSubview(resetRow)
        resetRow.widthAnchor.constraint(equalTo: editStack.widthAnchor).isActive = true
    }

    // MARK: - Sub-tab switching

    private func selectSubTab(_ tab: PromptSubTab, syncDrafts: Bool = true) {
        if syncDrafts { captureActiveDrafts() }

        activeSubTab = tab
        if segmentedControl.selectedIndex != tab.rawValue {
            segmentedControl.setSelectedIndex(tab.rawValue)
        }

        activeContentStack.arrangedSubviews.forEach { view in
            activeContentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        toolFields.removeAll()
        roleFields.removeAll()
        preambleEditor = nil
        footerEditor = nil

        switch tab {
        case .preamble:   buildPreambleContent()
        case .tools:      buildToolsContent()
        case .footer:     buildFooterContent()
        case .multiImage: buildMultiImageContent()
        }
    }

    private func buildPreambleContent() {
        let description = SettingsUI.bodyCopy(
            "Text before the annotation list. [Screenshot Path] inserts the image path. "
            + "[Tool Description] auto-generates based on tools used."
        )
        let editor = makeEditor(text: drafts.preamble)
        preambleEditor = findTextView(in: editor)
        preambleEditor?.delegate = self

        activeContentStack.addArrangedSubview(description)
        activeContentStack.addArrangedSubview(editor)

        NSLayoutConstraint.activate([
            editor.heightAnchor.constraint(equalToConstant: 140),
            editor.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor),
        ])
    }

    private func buildToolsContent() {
        let description = SettingsUI.bodyCopy(
            "Each tool's description feeds into [Tool Description] when that tool is used. "
            + "The tool type also appears in brackets next to each annotation."
        )
        activeContentStack.addArrangedSubview(description)

        let rowsStack = NSStackView()
        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = 10
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        activeContentStack.addArrangedSubview(rowsStack)

        for (title, key) in toolRows() {
            let row = makeToolRow(title: title, key: key)
            rowsStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor).isActive = true
        }
    }

    private func buildFooterContent() {
        let description = SettingsUI.bodyCopy("Text after the annotation list. Leave empty for no footer.")
        let editor = makeEditor(text: drafts.footer)
        footerEditor = findTextView(in: editor)
        footerEditor?.delegate = self

        activeContentStack.addArrangedSubview(description)
        activeContentStack.addArrangedSubview(editor)

        NSLayoutConstraint.activate([
            editor.heightAnchor.constraint(equalToConstant: 100),
            editor.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor),
        ])
    }

    private func buildMultiImageContent() {
        let description = SettingsUI.bodyCopy(
            "Configure roles for multi-image prompts. Each role has a name, description, and color."
        )
        activeContentStack.addArrangedSubview(description)

        let rowsStack = NSStackView()
        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = 10
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        activeContentStack.addArrangedSubview(rowsStack)

        for (i, role) in drafts.roles.enumerated() {
            let row = makeDynamicRoleRow(index: i, role: role)
            rowsStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor).isActive = true
        }

        // "+ Add role" button
        let addBtn = SettingsPillButton(title: drafts.roles.count >= 10 ? "Maximum 10 roles" : "+ Add role", target: self, action: #selector(addRoleClicked))
        addBtn.isEnabled = drafts.roles.count < 10
        addBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        activeContentStack.addArrangedSubview(addBtn)
    }

    private func makeDynamicRoleRow(index: Int, role: RoleConfig) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let swatchColor = DesignTokens.roleColor(forHex: role.colorHex)
        let swatch = RoleSwatchView(color: swatchColor)
        swatch.onClicked = { [weak self] swatchView in
            self?.showColorPopover(for: index, swatch: swatchView)
        }

        let nameField = SettingsTextField()
        nameField.stringValue = role.name
        nameField.placeholderString = "Role name"
        nameField.delegate = self
        nameField.identifier = NSUserInterfaceItemIdentifier("rolename_\(index)")
        nameField.translatesAutoresizingMaskIntoConstraints = false

        let descField = SettingsTextField()
        descField.stringValue = role.description
        descField.placeholderString = "Description for LLM prompt"
        descField.delegate = self
        descField.identifier = NSUserInterfaceItemIdentifier("roledesc_\(index)")
        descField.translatesAutoresizingMaskIntoConstraints = false

        let deleteBtn = NSButton(title: "×", target: self, action: #selector(deleteRoleClicked(_:)))
        deleteBtn.tag = index
        deleteBtn.isBordered = false
        deleteBtn.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        deleteBtn.contentTintColor = .tertiaryLabelColor
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(swatch)
        row.addSubview(nameField)
        row.addSubview(descField)
        row.addSubview(deleteBtn)

        swatch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),

            swatch.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 8),
            swatch.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            swatch.widthAnchor.constraint(equalToConstant: 14),
            swatch.heightAnchor.constraint(equalToConstant: 14),

            nameField.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 8),
            nameField.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            nameField.widthAnchor.constraint(equalToConstant: 120),
            nameField.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),

            descField.leadingAnchor.constraint(equalTo: nameField.trailingAnchor, constant: 8),
            descField.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            descField.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),

            deleteBtn.leadingAnchor.constraint(equalTo: descField.trailingAnchor, constant: 8),
            deleteBtn.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            deleteBtn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            deleteBtn.widthAnchor.constraint(equalToConstant: 22),
        ])

        return row
    }

    @objc private func addRoleClicked() {
        guard drafts.roles.count < 10 else { return }
        // Pick next unused preset color, cycling through all 8
        let usedHexes = Set(drafts.roles.map { $0.colorHex.lowercased() })
        let nextColor = DesignTokens.rolePresetColors.first { !usedHexes.contains($0.hex.lowercased()) }?.hex
            ?? DesignTokens.rolePresetColors[drafts.roles.count % DesignTokens.rolePresetColors.count].hex
        drafts.roles.append(RoleConfig(name: "New role", description: "", colorHex: nextColor))
        selectSubTab(.multiImage)
        refreshPreview()
    }

    @objc private func deleteRoleClicked(_ sender: NSButton) {
        let index = sender.tag
        guard index < drafts.roles.count else { return }
        drafts.roles.remove(at: index)
        selectSubTab(.multiImage)
        refreshPreview()
    }

    private var activeColorPopover: NSPopover?

    private func showColorPopover(for roleIndex: Int, swatch: RoleSwatchView) {
        // Dismiss any existing popover
        activeColorPopover?.close()
        activeColorPopover = nil

        let popover = NSPopover()
        popover.behavior = .transient
        // VIB-389: Fast popover — no animation delay
        popover.animates = false

        // Build content: color circles in a single row
        let contentView = NSView()
        contentView.wantsLayer = true
        let dotSize: CGFloat = 22
        let gap: CGFloat = 6
        let padding: CGFloat = 10
        let totalWidth = CGFloat(DesignTokens.rolePresetColors.count) * dotSize + CGFloat(DesignTokens.rolePresetColors.count - 1) * gap + padding * 2
        let totalHeight = dotSize + padding * 2
        contentView.frame = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)

        for (colorIdx, preset) in DesignTokens.rolePresetColors.enumerated() {
            let dot = NSButton(frame: NSRect(
                x: padding + CGFloat(colorIdx) * (dotSize + gap),
                y: padding,
                width: dotSize,
                height: dotSize
            ))
            // VIB-389: Clear title to prevent "Bu" text from NSButton default
            dot.title = ""
            dot.isBordered = false
            dot.wantsLayer = true
            dot.layer?.cornerRadius = dotSize / 2
            dot.layer?.backgroundColor = preset.color.cgColor
            let isSelected = preset.hex.lowercased() == drafts.roles[roleIndex].colorHex.lowercased()
            // VIB-389: Visible selection indicator — thick white border + subtle unselected border
            dot.layer?.borderWidth = isSelected ? 2.5 : 0.5
            dot.layer?.borderColor = isSelected
                ? NSColor.white.cgColor
                : NSColor(white: 0, alpha: 0.1).cgColor
            dot.target = self
            dot.action = #selector(colorPopoverDotClicked(_:))
            dot.tag = roleIndex * 100 + colorIdx
            contentView.addSubview(dot)
        }

        let vc = NSViewController()
        vc.view = contentView
        vc.preferredContentSize = NSSize(width: totalWidth, height: totalHeight)
        popover.contentViewController = vc
        activeColorPopover = popover

        popover.show(relativeTo: swatch.bounds, of: swatch, preferredEdge: .minY)
    }

    @objc private func colorPopoverDotClicked(_ sender: NSButton) {
        let roleIndex = sender.tag / 100
        let colorIndex = sender.tag % 100
        guard roleIndex < drafts.roles.count, colorIndex < DesignTokens.rolePresetColors.count else { return }
        drafts.roles[roleIndex].colorHex = DesignTokens.rolePresetColors[colorIndex].hex
        activeColorPopover?.close()
        activeColorPopover = nil
        selectSubTab(.multiImage)
        refreshPreview()
    }

    // MARK: - Helpers

    /// Finds the NSTextView inside an editor container (container → scroll → textView).
    private func findTextView(in container: NSView) -> NSTextView? {
        for sub in container.subviews {
            if let scroll = sub as? NSScrollView {
                return scroll.documentView as? NSTextView
            }
        }
        return nil
    }

    /// Creates an editable text box with visible field surface styling.
    /// Returns a wrapper NSView (not the scroll view directly) so the
    /// rounded-rect background and border are visible around the editor.
    private func makeEditor(text: String) -> NSView {
        // Outer container provides the visible field surface (bg + border + radius)
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        SettingsUI.styleFieldSurface(container)

        // Scroll view inside the container
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.hasHorizontalScroller = false
        scroll.borderType = .noBorder
        container.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
        ])

        // Text view
        let textView = NSTextView()
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .labelColor
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.string = text
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.insertionPointColor = DesignTokens.purpleLight

        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false

        scroll.documentView = textView

        return container
    }

    private static let toolRowHeight: CGFloat = 40

    private func makeToolRow(title: String, key: String) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let icon = ToolIconView(toolKey: key)
        let nameLabel = SettingsUI.regularLabel(title)
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let field = SettingsTextField()
        field.stringValue = drafts.toolDescriptions[key] ?? ""
        field.delegate = self
        field.identifier = NSUserInterfaceItemIdentifier(key)
        field.translatesAutoresizingMaskIntoConstraints = false
        toolFields[key] = field

        row.addSubview(icon)
        row.addSubview(nameLabel)
        row.addSubview(field)

        icon.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),

            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),
            icon.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 80),

            field.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 14),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),
        ])

        return row
    }

    private func toolRows() -> [(String, String)] {
        [("Pin", "pin"), ("Arrow", "arrow"), ("Rectangle", "rectangle"),
         ("Circle", "circle"), ("Freehand", "freehand")]
    }

    // MARK: - Data

    private func captureActiveDrafts() {
        switch activeSubTab {
        case .preamble:
            drafts.preamble = preambleEditor?.string ?? drafts.preamble
        case .tools:
            for (key, field) in toolFields {
                drafts.toolDescriptions[key] = field.stringValue
            }
        case .footer:
            drafts.footer = footerEditor?.string ?? drafts.footer
        case .multiImage:
            // Role drafts are updated in real-time via field delegates
            break
        }
    }

    private func refreshPreview() {
        var roleDescs: [String: String] = [:]
        for role in drafts.roles { roleDescs[role.name.lowercased()] = role.description }
        previewView.refresh(
            preamble: drafts.preamble,
            footer: drafts.footer,
            toolDescriptions: drafts.toolDescriptions,
            roleDescriptions: roleDescs
        )
    }

    @objc private func saveAllPromptSections() {
        captureActiveDrafts()
        ConfigManager.shared.preamble = drafts.preamble
        ConfigManager.shared.footer = drafts.footer
        ConfigManager.shared.toolDescriptions = drafts.toolDescriptions
        ConfigManager.shared.roles = drafts.roles
        ConfigManager.shared.save()
        refreshPreview()

        // Flash "Saved" green confirmation (matches editor toolbar copy buttons)
        savedResetTimer?.invalidate()
        saveButton.title = "Saved"
        saveButton.contentTintColor = DesignTokens.copiedGreenText
        // VIB-388: Use appearance-safe helpers so colors resolve correctly on theme change
        saveButton.setLayerBackground(DesignTokens.copiedGreenBg)
        saveButton.setLayerBorder(DesignTokens.copiedGreenBorder)

        savedResetTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.saveButton.title = "Save"
            self?.saveButton.contentTintColor = DesignTokens.settingsPillText
            self?.saveButton.setLayerBackground(DesignTokens.settingsPillFill)
            self?.saveButton.setLayerBorder(DesignTokens.settingsPillBorder)
        }
    }

    @objc private func resetCurrentPromptSection() {
        switch activeSubTab {
        case .preamble:
            drafts.preamble = Self.defaultPreamble
            preambleEditor?.string = Self.defaultPreamble
        case .tools:
            drafts.toolDescriptions = Self.defaultToolDescriptions
            for (key, value) in Self.defaultToolDescriptions {
                toolFields[key]?.stringValue = value
            }
        case .footer:
            drafts.footer = Self.defaultFooter
            footerEditor?.string = Self.defaultFooter
        case .multiImage:
            drafts.roles = RoleConfig.defaultRoles
            selectSubTab(.multiImage)
        }
        refreshPreview()
    }

    // MARK: - NSTextViewDelegate / NSTextFieldDelegate

    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView {
            if textView === preambleEditor {
                drafts.preamble = textView.string
            } else if textView === footerEditor {
                drafts.footer = textView.string
            }
            refreshPreview()
        }
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSTextField,
              let key = field.identifier?.rawValue else { return }
        if key.hasPrefix("rolename_"), let idx = Int(key.dropFirst(9)) {
            guard idx < drafts.roles.count else { return }
            drafts.roles[idx].name = field.stringValue
        } else if key.hasPrefix("roledesc_"), let idx = Int(key.dropFirst(9)) {
            guard idx < drafts.roles.count else { return }
            drafts.roles[idx].description = field.stringValue
        } else {
            drafts.toolDescriptions[key] = field.stringValue
        }
        refreshPreview()
    }

    // MARK: - Defaults

    private static let defaultPreamble = "This is a screenshot of my running app. View it at [Screenshot Path]\n\n[Tool Description] Each annotation has a number and a description.\n\nFix each issue:"

    private static let defaultFooter = "Make the changes and verify they match the design."

    private static let defaultToolDescriptions: [String: String] = [
        "pin": "points to a specific issue",
        "arrow": "points at or between elements",
        "rectangle": "highlights a region or container",
        "circle": "calls out a specific element",
        "freehand": "marks an irregular area",
    ]

}

// MARK: - Tool icon view

private final class ToolIconView: NSView {

    private let toolKey: String

    init(toolKey: String) {
        self.toolKey = toolKey
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        SettingsUI.styleFieldSurface(self)
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
        switch toolKey {
        case "pin":      ToolbarView.drawPinIcon(iconRect, color)
        case "arrow":    ToolbarView.drawArrowIcon(iconRect, color)
        case "rectangle": ToolbarView.drawRectIcon(iconRect, color)
        case "circle":   ToolbarView.drawCircleIcon(iconRect, color)
        case "freehand": ToolbarView.drawFreehandIcon(iconRect, color)
        default: break
        }
    }
}

// MARK: - Role swatch view

private final class RoleSwatchView: NSView {

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
        let path = NSBezierPath(ovalIn: bounds)
        swatchColor.setFill()
        path.fill()
        // VIB-338: Hover border indicates clickability
        if isHovered {
            NSColor.separatorColor.setStroke()
            path.lineWidth = 1
            path.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        onClicked?(self)
    }
}
