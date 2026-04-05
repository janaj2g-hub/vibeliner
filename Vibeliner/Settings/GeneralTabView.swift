import AppKit
import ServiceManagement

final class GeneralTabView: NSView {

    private let contentStack = NSStackView()
    private let hotkeyRow = SettingsKeyPillRow()
    private let folderPathLabel = SettingsUI.fieldLabel("", monospaced: true)
    private let loginCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let loginLabel = SettingsUI.regularLabel("Start Vibeliner when you log in")
    private let appearanceControl = SettingsSegmentedControl(items: ["Light", "Dark", "System"])
    private var hotkeyCaptureMonitor: Any?
    private var hotkeyCaptureSheet: NSWindow?

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

        let fieldContainer = NSView()
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        SettingsUI.styleFieldSurface(fieldContainer)
        fieldContainer.addSubview(folderPathLabel)

        folderPathLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fieldContainer.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),
            folderPathLabel.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 12),
            folderPathLabel.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -12),
            folderPathLabel.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            folderPathLabel.bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),
        ])

        let helper = SettingsUI.bodyCopy("Screenshots and prompts are saved here.")

        let changeButton = SettingsPillButton(title: "Change", target: self, action: #selector(changeFolderClicked))
        changeButton.widthAnchor.constraint(equalToConstant: 108).isActive = true

        let content = NSStackView(views: [fieldContainer, helper, changeButton])
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

        NSLayoutConstraint.activate([
            appearanceControl.widthAnchor.constraint(equalToConstant: 240),
        ])

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
        guard hotkeyCaptureSheet == nil, let parentWindow = window else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 150),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        panel.title = "Record Hotkey"
        panel.isReleasedWhenClosed = false

        let content = NSView(frame: panel.contentRect(forFrameRect: panel.frame))

        let title = NSTextField(labelWithString: "Press your new capture shortcut")
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 20, y: 86, width: 320, height: 22)
        content.addSubview(title)

        let helper = NSTextField(labelWithString: "Use at least one modifier key. Press Escape to cancel.")
        helper.font = NSFont.systemFont(ofSize: 12)
        helper.textColor = .secondaryLabelColor
        helper.alignment = .center
        helper.frame = NSRect(x: 20, y: 58, width: 320, height: 18)
        content.addSubview(helper)

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelHotkeyCapture))
        cancelButton.frame = NSRect(x: 140, y: 16, width: 80, height: 28)
        content.addSubview(cancelButton)

        panel.contentView = content
        hotkeyCaptureSheet = panel
        parentWindow.beginSheet(panel)

        hotkeyCaptureMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.hotkeyCaptureSheet != nil else { return event }

            if event.keyCode == 53 {
                self.cancelHotkeyCapture()
                return nil
            }

            guard let spec = HotkeyManager.shared.hotkeySpec(for: event) else {
                NSSound.beep()
                return nil
            }

            HotkeyManager.shared.updateHotkey(to: spec.configValue)
            self.hotkeyRow.setKeys(spec.displayParts)
            self.closeHotkeyCaptureSheet()
            return nil
        }
    }

    @objc private func changeFolderClicked() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: ConfigManager.shared.expandedCapturesFolder)
        panel.begin { [weak self] response in
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
                print("Vibeliner: Login item registration failed: \(error)")
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

    @objc private func cancelHotkeyCapture() {
        closeHotkeyCaptureSheet()
    }

    private func closeHotkeyCaptureSheet() {
        if let monitor = hotkeyCaptureMonitor {
            NSEvent.removeMonitor(monitor)
            hotkeyCaptureMonitor = nil
        }
        if let sheet = hotkeyCaptureSheet, let parentWindow = window {
            parentWindow.endSheet(sheet)
            sheet.orderOut(nil)
        }
        hotkeyCaptureSheet = nil
    }
}
