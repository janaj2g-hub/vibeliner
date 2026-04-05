import AppKit

final class PromptTabView: NSView, NSTextViewDelegate, NSTextFieldDelegate {

    // MARK: - Sub-tab model

    private enum PromptSubTab: Int, CaseIterable {
        case preamble, tools, footer

        var title: String {
            switch self {
            case .preamble: return "Preamble"
            case .tools:    return "Tools"
            case .footer:   return "Footer"
            }
        }
    }

    private struct PromptDrafts {
        var preamble: String
        var footer: String
        var toolDescriptions: [String: String]

        static func current() -> PromptDrafts {
            PromptDrafts(
                preamble: ConfigManager.shared.preamble,
                footer: ConfigManager.shared.footer,
                toolDescriptions: ConfigManager.shared.toolDescriptions
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
    private var contentLoaded = false

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

    /// Called by SettingsWindowController after the view is in the hierarchy.
    /// Loads preview data and selects the first sub-tab.
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
        rootStack.spacing = 24
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
            previewView.heightAnchor.constraint(equalToConstant: 288),
            previewView.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
        ])

        // Edit frame
        SettingsUI.styleFrameSurface(editFrame)
        editFrame.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(editFrame)
        editFrame.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        editStack.orientation = .vertical
        editStack.alignment = .leading
        editStack.spacing = 18
        editStack.translatesAutoresizingMaskIntoConstraints = false
        editFrame.addSubview(editStack)

        NSLayoutConstraint.activate([
            editStack.topAnchor.constraint(equalTo: editFrame.topAnchor, constant: DesignTokens.settingsFramePadding),
            editStack.leadingAnchor.constraint(equalTo: editFrame.leadingAnchor, constant: DesignTokens.settingsFramePadding),
            editStack.trailingAnchor.constraint(equalTo: editFrame.trailingAnchor, constant: -DesignTokens.settingsFramePadding),
            editStack.bottomAnchor.constraint(equalTo: editFrame.bottomAnchor, constant: -DesignTokens.settingsFramePadding),
        ])

        // Header row: "Edit Prompt Sections" + Save button
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

        // Segmented control row
        let segmentedRow = NSView()
        segmentedRow.translatesAutoresizingMaskIntoConstraints = false
        segmentedRow.addSubview(segmentedControl)
        editStack.addArrangedSubview(segmentedRow)

        let segmentWidth = min(360, 360) // explicit constant
        NSLayoutConstraint.activate([
            segmentedRow.widthAnchor.constraint(equalTo: editStack.widthAnchor),
            segmentedControl.centerXAnchor.constraint(equalTo: segmentedRow.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: segmentedRow.topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: segmentedRow.bottomAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: CGFloat(segmentWidth)),
        ])

        segmentedControl.onSelectionChanged = { [weak self] index in
            guard let tab = PromptSubTab(rawValue: index) else { return }
            self?.selectSubTab(tab)
        }

        // Active content area (swapped per sub-tab)
        activeContentStack.orientation = .vertical
        activeContentStack.alignment = .leading
        activeContentStack.spacing = 18
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

        // Clear active content
        activeContentStack.arrangedSubviews.forEach { view in
            activeContentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        toolFields.removeAll()
        preambleEditor = nil
        footerEditor = nil

        switch tab {
        case .preamble: buildPreambleContent()
        case .tools:    buildToolsContent()
        case .footer:   buildFooterContent()
        }
    }

    private func buildPreambleContent() {
        let description = SettingsUI.bodyCopy(
            "Text before the annotation list. [Screenshot Path] inserts the image path. "
            + "[Tool Description] auto-generates based on tools used."
        )
        let editor = makeEditor(text: drafts.preamble)
        preambleEditor = editor.documentView as? NSTextView
        preambleEditor?.delegate = self

        NSLayoutConstraint.activate([
            editor.heightAnchor.constraint(equalToConstant: 184),
            editor.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor),
        ])

        activeContentStack.addArrangedSubview(description)
        activeContentStack.addArrangedSubview(editor)
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
        rowsStack.spacing = 14
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        for (title, key) in toolRows() {
            rowsStack.addArrangedSubview(makeToolRow(title: title, key: key))
        }

        activeContentStack.addArrangedSubview(rowsStack)
    }

    private func buildFooterContent() {
        let description = SettingsUI.bodyCopy("Text after the annotation list. Leave empty for no footer.")
        let editor = makeEditor(text: drafts.footer)
        footerEditor = editor.documentView as? NSTextView
        footerEditor?.delegate = self

        NSLayoutConstraint.activate([
            editor.heightAnchor.constraint(equalToConstant: 160),
            editor.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor),
        ])

        activeContentStack.addArrangedSubview(description)
        activeContentStack.addArrangedSubview(editor)
    }

    // MARK: - Helpers

    private func makeEditor(text: String) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.borderType = .noBorder
        SettingsUI.styleFieldSurface(scroll)

        let textView = NSTextView()
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.isRichText = false
        textView.isEditable = true
        textView.drawsBackground = false
        textView.string = text
        textView.textContainerInset = NSSize(width: 10, height: 12)
        scroll.documentView = textView

        return scroll
    }

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
            row.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor),
            row.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),

            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),
            icon.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 92),

            field.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 16),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),
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
        }
    }

    private func refreshPreview() {
        previewView.refresh(
            preamble: drafts.preamble,
            footer: drafts.footer,
            toolDescriptions: drafts.toolDescriptions
        )
    }

    @objc private func saveAllPromptSections() {
        captureActiveDrafts()
        ConfigManager.shared.preamble = drafts.preamble
        ConfigManager.shared.footer = drafts.footer
        ConfigManager.shared.toolDescriptions = drafts.toolDescriptions
        ConfigManager.shared.save()
        refreshPreview()
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
        drafts.toolDescriptions[key] = field.stringValue
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
