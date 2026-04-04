import AppKit
import ServiceManagement

final class GeneralTabView: NSView {

    private let folderPathLabel = NSTextField(labelWithString: "")
    private let loginCheckbox = NSButton(checkboxWithTitle: "Start Vibeliner when you log in", target: nil, action: nil)

    private let purpleAccent = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1)
    private let labelWidth: CGFloat = 120
    private let pad: CGFloat = 28

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        var y = frame.height - 36

        // Hotkey row
        addSubview(makeRowLabel("Capture hotkey", y: y + 3))

        let hotkeyContainer = NSView(frame: NSRect(x: pad + labelWidth + 12, y: y - 2, width: 120, height: 28))
        let keys = ["⌘", "⇧", "6"]
        var kx: CGFloat = 0
        for key in keys {
            let pill = NSTextField(labelWithString: key)
            pill.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
            pill.textColor = .labelColor
            pill.alignment = .center
            pill.wantsLayer = true
            pill.layer?.backgroundColor = NSColor(white: 1, alpha: 0.08).cgColor
            pill.layer?.cornerRadius = 5
            pill.layer?.borderWidth = 1
            pill.layer?.borderColor = NSColor(white: 1, alpha: 0.12).cgColor
            pill.frame = NSRect(x: kx, y: 2, width: 28, height: 24)
            hotkeyContainer.addSubview(pill)
            kx += 32
        }
        addSubview(hotkeyContainer)

        let changeHotkey = makePurpleLink("Change", action: #selector(changeHotkey))
        changeHotkey.frame = NSRect(x: pad + labelWidth + 122, y: y + 1, width: 50, height: 20)
        addSubview(changeHotkey)

        y -= 52
        addDivider(at: y + 20)

        // Folder row
        addSubview(makeRowLabel("Captures folder", y: y + 3))

        let folderFieldX = pad + labelWidth + 12
        let folderW = frame.width - folderFieldX - 80  // reserve 80px for Change button
        folderPathLabel.stringValue = ConfigManager.shared.capturesFolder
        folderPathLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        folderPathLabel.textColor = .secondaryLabelColor
        folderPathLabel.wantsLayer = true
        folderPathLabel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        folderPathLabel.layer?.cornerRadius = 6
        folderPathLabel.layer?.borderWidth = 1
        folderPathLabel.layer?.borderColor = NSColor.separatorColor.cgColor
        folderPathLabel.frame = NSRect(x: folderFieldX, y: y - 2, width: folderW, height: 26)
        addSubview(folderPathLabel)

        let changeFolder = makePurpleLink("Change", action: #selector(changeFolderClicked))
        changeFolder.frame = NSRect(x: folderFieldX + folderW + 8, y: y + 1, width: 50, height: 20)
        addSubview(changeFolder)

        let folderHelper = NSTextField(labelWithString: "Screenshots and prompts are saved here.")
        folderHelper.font = NSFont.systemFont(ofSize: 12)
        folderHelper.textColor = .tertiaryLabelColor
        folderHelper.frame = NSRect(x: folderFieldX, y: y - 22, width: 300, height: 16)
        addSubview(folderHelper)

        y -= 72
        addDivider(at: y + 20)

        // Login row
        addSubview(makeRowLabel("Launch at login", y: y + 3))

        loginCheckbox.state = ConfigManager.shared.launchAtLogin ? .on : .off
        loginCheckbox.target = self
        loginCheckbox.action = #selector(loginToggled)
        loginCheckbox.font = NSFont.systemFont(ofSize: 13)
        loginCheckbox.frame = NSRect(x: pad + labelWidth + 12, y: y - 2, width: 260, height: 20)
        addSubview(loginCheckbox)
    }

    private func makeRowLabel(_ text: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.frame = NSRect(x: pad, y: y, width: labelWidth, height: 20)
        return label
    }

    private func makePurpleLink(_ text: String, action: Selector) -> NSButton {
        let btn = NSButton(title: text, target: self, action: action)
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        btn.contentTintColor = purpleAccent
        return btn
    }

    private func addDivider(at y: CGFloat) {
        let div = NSView(frame: NSRect(x: pad, y: y, width: frame.width - pad * 2, height: 0.5))
        div.wantsLayer = true
        div.layer?.backgroundColor = NSColor.separatorColor.cgColor
        addSubview(div)
    }

    @objc private func changeHotkey() {
        // Hotkey change not yet implemented
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
}
