import AppKit
import ServiceManagement

final class GeneralTabView: NSView {

    private let contentStack = NSStackView()
    private let hotkeyRow = SettingsKeyPillRow()
    private let folderPathLabel = SettingsUI.fieldLabel("", monospaced: true)
    // VIB-388: Use AppearanceAwareFieldView so the field re-styles itself
    // when re-attached to the hierarchy after tab switching
    private let folderFieldContainer = AppearanceAwareFieldView()
    private let loginCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let loginLabel = SettingsUI.regularLabel("Start Vibeliner when you log in")
    // VIB-433: Toggle-token segmented control for appearance
    private let appearanceControl = SettingsToggleControl(items: ["Light", "Dark", "System"])

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = DesignTokens.settingsSectionGap
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.settingsContentPadding),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.settingsContentPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.settingsContentPadding),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -DesignTokens.settingsContentPadding)
        ])

        let hotkeySection = makeHotkeySection()
        let firstDivider = SettingsUI.divider()
        let folderSection = makeFolderSection()
        let secondDivider = SettingsUI.divider()
        let otherSection = makeOtherSettingsSection()

        [hotkeySection, firstDivider, folderSection, secondDivider, otherSection].forEach { view in
            contentStack.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }
    }

    // MARK: - Sections

    private func makeHotkeySection() -> NSView {
        hotkeyRow.setKeys(HotkeyManager.shared.displayParts(for: ConfigManager.shared.hotkey))

        let changeButton = SettingsPillButton(title: "Change", target: self, action: #selector(changeHotkey))
        changeButton.widthAnchor.constraint(equalToConstant: 108).isActive = true
        changeButton.setAccessibilityLabel("Change hotkey")
        changeButton.setAccessibilityRole(.button)
        hotkeyRow.setAccessibilityLabel("Hotkey shortcut")
        hotkeyRow.setAccessibilityRole(.group)

        let content = NSStackView(views: [hotkeyRow, changeButton])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 18
        content.translatesAutoresizingMaskIntoConstraints = false

        return SettingsUI.makeSection(title: "Capture hotkey", contentView: content)
    }

    private func makeFolderSection() -> NSView {
        // Apply VerticallyCenteredTextFieldCell for proper vertical centering in the fixed-height box
        let savedPath = ConfigManager.shared.capturesFolder
        folderPathLabel.cell = VerticallyCenteredTextFieldCell()
        folderPathLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        folderPathLabel.textColor = .secondaryLabelColor
        folderPathLabel.lineBreakMode = .byTruncatingMiddle
        folderPathLabel.maximumNumberOfLines = 1
        folderPathLabel.stringValue = savedPath
        folderPathLabel.setAccessibilityLabel("Captures folder path")
        folderPathLabel.setAccessibilityRole(.staticText)

        folderFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        folderFieldContainer.addSubview(folderPathLabel)

        folderPathLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            folderFieldContainer.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),
            folderPathLabel.leadingAnchor.constraint(equalTo: folderFieldContainer.leadingAnchor, constant: 12),
            folderPathLabel.trailingAnchor.constraint(equalTo: folderFieldContainer.trailingAnchor, constant: -12),
            folderPathLabel.topAnchor.constraint(equalTo: folderFieldContainer.topAnchor),
            folderPathLabel.bottomAnchor.constraint(equalTo: folderFieldContainer.bottomAnchor),
        ])

        let helper = SettingsUI.bodyCopy("Screenshots and prompts are saved here.")

        let changeButton = SettingsPillButton(title: "Change", target: self, action: #selector(changeFolderClicked))
        changeButton.widthAnchor.constraint(equalToConstant: 108).isActive = true
        changeButton.setAccessibilityLabel("Change captures folder")
        changeButton.setAccessibilityRole(.button)

        let content = NSStackView(views: [folderFieldContainer, helper, changeButton])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 18
        content.translatesAutoresizingMaskIntoConstraints = false

        return SettingsUI.makeSection(title: "Captures folder", contentView: content)
    }

    private func makeOtherSettingsSection() -> NSView {
        // Login checkbox
        loginCheckbox.state = ConfigManager.shared.launchAtLogin ? .on : .off
        loginCheckbox.target = self
        loginCheckbox.action = #selector(loginToggled)
        loginCheckbox.translatesAutoresizingMaskIntoConstraints = false
        loginCheckbox.setAccessibilityLabel("Launch at login")
        loginCheckbox.setAccessibilityRole(.checkBox)
        loginLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)

        let loginRow = NSStackView(views: [loginCheckbox, loginLabel])
        loginRow.orientation = .horizontal
        loginRow.alignment = .centerY
        loginRow.spacing = 12
        loginRow.translatesAutoresizingMaskIntoConstraints = false
        loginCheckbox.widthAnchor.constraint(equalToConstant: 18).isActive = true

        // Appearance toggle — reusable SettingsSegmentedControl
        let appearanceLabel = SettingsUI.regularLabel("Appearance")

        // Set initial selection without firing the callback
        switch ConfigManager.shared.appearance {
        case "light":  appearanceControl.setSelectedIndex(0, notify: false)
        case "dark":   appearanceControl.setSelectedIndex(1, notify: false)
        default:       appearanceControl.setSelectedIndex(2, notify: false)
        }
        appearanceControl.onSelectionChanged = { [weak self] index in
            self?.appearanceChanged(index)
        }

        appearanceControl.setAccessibilityLabel("Appearance mode")
        appearanceControl.setAccessibilityRole(.radioGroup)

        let appearanceRow = NSStackView(views: [appearanceLabel, appearanceControl])
        appearanceRow.orientation = .horizontal
        appearanceRow.alignment = .centerY
        appearanceRow.spacing = 16
        appearanceRow.translatesAutoresizingMaskIntoConstraints = false

        let content = NSStackView(views: [loginRow, appearanceRow])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 18
        content.translatesAutoresizingMaskIntoConstraints = false

        return SettingsUI.makeSection(title: "Other settings", contentView: content)
    }

    // MARK: - Actions

    @objc private func changeHotkey() {
        guard let parentWindow = window else { return }
        HotkeyCapturePanel.present(from: parentWindow) { [weak self] newKeys in
            self?.hotkeyRow.setKeys(newKeys)
        }
    }

    @objc private func changeFolderClicked() {
        guard let parentWindow = window else { return }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: ConfigManager.shared.expandedCapturesFolder)
        // VIB-300: Show as sheet so it appears on top of the floating settings window
        panel.beginSheetModal(for: parentWindow) { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            ConfigManager.shared.capturesFolder = url.path
            ConfigManager.shared.save()
            self?.folderPathLabel.stringValue = url.path
        }
    }

    @objc private func loginToggled() {
        let enabled = loginCheckbox.state == .on
        ConfigManager.shared.launchAtLogin = enabled
        ConfigManager.shared.save()
        if #available(macOS 13.0, *) {
            do {
                if enabled { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch {
                #if DEBUG
                print("Vibeliner: Login item registration failed: \(error)")
                #endif
            }
        }
    }

    private func appearanceChanged(_ index: Int) {
        let mode: String
        switch index {
        case 0:  mode = "light"
        case 1:  mode = "dark"
        default: mode = "system"
        }

        ConfigManager.shared.appearance = mode
        ConfigManager.shared.save()

        let appearance: NSAppearance?
        switch mode {
        case "light": appearance = NSAppearance(named: .aqua)
        case "dark":  appearance = NSAppearance(named: .darkAqua)
        default:      appearance = nil
        }
        NSApp.appearance = appearance
    }

}
