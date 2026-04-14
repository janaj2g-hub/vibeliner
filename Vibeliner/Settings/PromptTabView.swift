import AppKit

final class PromptTabView: NSView, NSTextViewDelegate, NSTextFieldDelegate {

    // MARK: - Sub-tab model

    enum PromptSubTab: Int, CaseIterable {
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

    struct PromptDrafts: Equatable {
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

    let rootStack = NSStackView()
    let previewView = PromptPreviewView(frame: .zero)
    let editFrame = AppearanceAwareFrameSurfaceView()
    let editStack = NSStackView()
    let editHeaderLabel = SettingsUI.sectionTitle("Edit Prompt Sections")
    let saveButton = SettingsPillButton(title: "Save changes", target: nil, action: nil)
    let draftStateView = PromptDraftStateView()
    let draftHelperLabel = SettingsUI.bodyCopy("")
    let segmentedControl = SettingsSegmentedControl(items: PromptSubTab.allCases.map(\.title), style: .secondary)
    let activeContentStack = NSStackView()
    let resetButton = NSButton(title: "Reset to default", target: nil, action: nil)

    // MARK: - State

    var drafts = PromptDrafts.current()
    var activeSubTab: PromptSubTab = .preamble
    weak var preambleEditor: NSTextView?
    weak var footerEditor: NSTextView?
    var toolFields: [String: SettingsTextField] = [:]
    var roleFields: [String: SettingsTextField] = [:]
    var contentLoaded = false
    var activeColorPopover: NSPopover?

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

    func refreshTabAppearance() {
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
        updateDraftStateUI()
    }

    // MARK: - Layout

    func buildLayout() {
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
        previewView.widthAnchor.constraint(equalTo: rootStack.widthAnchor).isActive = true

        // Edit frame
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
        saveButton.setAccessibilityLabel("Save prompt sections")
        saveButton.setAccessibilityRole(.button)

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
        headerRow.addArrangedSubview(draftStateView)
        headerRow.addArrangedSubview(saveButton)
        editStack.addArrangedSubview(headerRow)
        headerRow.widthAnchor.constraint(equalTo: editStack.widthAnchor).isActive = true

        draftHelperLabel.translatesAutoresizingMaskIntoConstraints = false
        editStack.addArrangedSubview(draftHelperLabel)
        draftHelperLabel.widthAnchor.constraint(equalTo: editStack.widthAnchor).isActive = true

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
            segmentedControl.leadingAnchor.constraint(greaterThanOrEqualTo: segmentedRow.leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(lessThanOrEqualTo: segmentedRow.trailingAnchor, constant: -12),
        ])

        segmentedControl.setAccessibilityLabel("Prompt section selector")
        segmentedControl.setAccessibilityRole(.radioGroup)
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
        resetButton.contentTintColor = DesignTokens.pillButtonText
        resetButton.target = self
        resetButton.action = #selector(resetCurrentPromptSection)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.setAccessibilityLabel("Reset to default")
        resetButton.setAccessibilityRole(.button)

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

}
