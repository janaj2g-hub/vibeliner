import AppKit
import ServiceManagement

final class GeneralTabView: NSView {

    private let contentStack = NSStackView()
    private let hotkeyRow = SettingsKeyPillRow()
    private let folderPathLabel = SettingsUI.fieldLabel("", monospaced: true)
    private let loginCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let loginLabel = SettingsUI.regularLabel("Start Vibeliner when you log in")
    private var hotkeyCaptureMonitor: Any?
    private var hotkeyCaptureSheet: NSWindow?

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
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
        let loginSection = makeLoginSection()

        [hotkeySection, firstDivider, folderSection, secondDivider, loginSection].forEach { view in
            contentStack.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }
    }

    private func makeHotkeySection() -> NSView {
        hotkeyRow.setKeys(HotkeyManager.shared.displayParts(for: ConfigManager.shared.hotkey))

        let changeButton = SettingsPillButton(title: "Change", target: self, action: #selector(changeHotkey))
        NSLayoutConstraint.activate([
            changeButton.widthAnchor.constraint(equalToConstant: 108)
        ])

        let content = NSStackView(views: [hotkeyRow, changeButton])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 18
        content.translatesAutoresizingMaskIntoConstraints = false

        return SettingsUI.makeSection(title: "Capture hotkey", contentView: content)
    }

    private func makeFolderSection() -> NSView {
        folderPathLabel.stringValue = ConfigManager.shared.capturesFolder

        let fieldContainer = NSView()
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        SettingsUI.styleFieldSurface(fieldContainer)
        fieldContainer.addSubview(folderPathLabel)

        folderPathLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fieldContainer.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),
            folderPathLabel.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 16),
            folderPathLabel.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -16),
            folderPathLabel.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor)
        ])

        let helper = SettingsUI.bodyCopy("Screenshots and prompts are saved here.")

        let changeButton = SettingsPillButton(title: "Change", target: self, action: #selector(changeFolderClicked))
        NSLayoutConstraint.activate([
            changeButton.widthAnchor.constraint(equalToConstant: 108)
        ])

        let content = NSStackView(views: [fieldContainer, helper, changeButton])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 18
        content.translatesAutoresizingMaskIntoConstraints = false

        return SettingsUI.makeSection(title: "Captures folder", contentView: content)
    }

    private func makeLoginSection() -> NSView {
        loginCheckbox.state = ConfigManager.shared.launchAtLogin ? .on : .off
        loginCheckbox.target = self
        loginCheckbox.action = #selector(loginToggled)
        loginCheckbox.translatesAutoresizingMaskIntoConstraints = false

        loginLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)

        let row = NSStackView(views: [loginCheckbox, loginLabel])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loginCheckbox.widthAnchor.constraint(equalToConstant: 18)
        ])

        return SettingsUI.makeSection(title: "Launch at login", contentView: row)
    }

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
