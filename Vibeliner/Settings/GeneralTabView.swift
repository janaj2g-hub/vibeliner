import AppKit
import ServiceManagement

final class GeneralTabView: NSView {

    private let hotkeyDisplay = NSTextField(labelWithString: "⌘ ⇧ 6")
    private let folderPathLabel = NSTextField(labelWithString: "")
    private let loginCheckbox = NSButton(checkboxWithTitle: "Start Vibeliner when you log in", target: nil, action: nil)
    private var isRecordingHotkey = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        let pad: CGFloat = 24
        var y = frame.height - 50

        // Hotkey row
        let hotkeyLabel = makeLabel("Capture hotkey", y: y)
        addSubview(hotkeyLabel)

        hotkeyDisplay.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        hotkeyDisplay.textColor = NSColor(white: 0.3, alpha: 1)
        hotkeyDisplay.wantsLayer = true
        hotkeyDisplay.layer?.backgroundColor = NSColor(white: 0.96, alpha: 1).cgColor
        hotkeyDisplay.layer?.cornerRadius = 8
        hotkeyDisplay.layer?.borderWidth = 1
        hotkeyDisplay.layer?.borderColor = NSColor(white: 0.88, alpha: 1).cgColor
        hotkeyDisplay.alignment = .center
        hotkeyDisplay.frame = NSRect(x: pad + 130, y: y - 2, width: 100, height: 24)
        addSubview(hotkeyDisplay)

        let changeHotkey = makeLink("Change", action: #selector(changeHotkey))
        changeHotkey.frame = NSRect(x: pad + 240, y: y, width: 50, height: 20)
        addSubview(changeHotkey)

        y -= 50
        addDivider(at: y + 16)

        // Folder row
        let folderLabel = makeLabel("Captures folder", y: y)
        addSubview(folderLabel)

        folderPathLabel.stringValue = ConfigManager.shared.capturesFolder
        folderPathLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        folderPathLabel.textColor = NSColor(white: 0.3, alpha: 1)
        folderPathLabel.wantsLayer = true
        folderPathLabel.layer?.backgroundColor = NSColor(white: 0.96, alpha: 1).cgColor
        folderPathLabel.layer?.cornerRadius = 4
        folderPathLabel.layer?.borderWidth = 1
        folderPathLabel.layer?.borderColor = NSColor(white: 0.88, alpha: 1).cgColor
        folderPathLabel.frame = NSRect(x: pad + 130, y: y - 2, width: 240, height: 22)
        addSubview(folderPathLabel)

        let changeFolder = makeLink("Change", action: #selector(changeFolderClicked))
        changeFolder.frame = NSRect(x: pad + 380, y: y, width: 50, height: 20)
        addSubview(changeFolder)

        let folderHelper = NSTextField(labelWithString: "Screenshots and prompts are saved here.")
        folderHelper.font = NSFont.systemFont(ofSize: 11)
        folderHelper.textColor = NSColor(white: 0.53, alpha: 1)
        folderHelper.frame = NSRect(x: pad + 130, y: y - 22, width: 300, height: 16)
        addSubview(folderHelper)

        y -= 60
        addDivider(at: y + 16)

        // Login row
        let loginLabel = makeLabel("Launch at login", y: y)
        addSubview(loginLabel)

        loginCheckbox.state = ConfigManager.shared.launchAtLogin ? .on : .off
        loginCheckbox.target = self
        loginCheckbox.action = #selector(loginToggled)
        loginCheckbox.frame = NSRect(x: pad + 130, y: y - 2, width: 250, height: 20)
        addSubview(loginCheckbox)
    }

    private func makeLabel(_ text: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = NSColor(white: 0.2, alpha: 1)
        label.frame = NSRect(x: 24, y: y, width: 120, height: 20)
        return label
    }

    private func makeLink(_ text: String, action: Selector) -> NSButton {
        let btn = NSButton(title: text, target: self, action: action)
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        btn.contentTintColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)
        return btn
    }

    private func addDivider(at y: CGFloat) {
        let div = NSView(frame: NSRect(x: 24, y: y, width: frame.width - 48, height: 0.5))
        div.wantsLayer = true
        div.layer?.backgroundColor = NSColor(white: 0.94, alpha: 1).cgColor
        addSubview(div)
    }

    @objc private func changeHotkey() {
        hotkeyDisplay.stringValue = "Press new shortcut…"
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
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Vibeliner: Login item registration failed: \(error)")
            }
        }
    }
}
