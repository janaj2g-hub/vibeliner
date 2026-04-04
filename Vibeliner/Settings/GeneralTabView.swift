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
        let rightX = pad + labelWidth + 16
        let rightW = frame.width - rightX - pad
        let sectionGap: CGFloat = 24
        let rowH: CGFloat = 28

        var y = frame.height - sectionGap

        // Section 1: Capture hotkey
        y -= 20
        addSubview(makeRowLabel("Capture hotkey", y: y))

        let hotkeyContainer = NSView(frame: NSRect(x: rightX, y: y - 4, width: 120, height: rowH))
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

        let changeHotkey = makePillButton("Change", action: #selector(changeHotkey))
        changeHotkey.frame = NSRect(x: rightX, y: y - 4 - rowH - 8, width: 70, height: 26)
        addSubview(changeHotkey)

        y -= rowH + 8 + 26 + sectionGap
        addDivider(at: y)
        y -= sectionGap

        // Section 2: Captures folder
        y -= 20
        addSubview(makeRowLabel("Captures folder", y: y))

        folderPathLabel.stringValue = ConfigManager.shared.capturesFolder
        folderPathLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        folderPathLabel.textColor = .secondaryLabelColor
        folderPathLabel.alignment = .left
        folderPathLabel.wantsLayer = true
        folderPathLabel.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        folderPathLabel.layer?.cornerRadius = 6
        folderPathLabel.layer?.borderWidth = 1
        folderPathLabel.layer?.borderColor = NSColor.separatorColor.cgColor
        folderPathLabel.frame = NSRect(x: rightX, y: y - 6, width: rightW, height: 28)
        addSubview(folderPathLabel)

        let folderHelper = NSTextField(labelWithString: "Screenshots and prompts are saved here.")
        folderHelper.font = NSFont.systemFont(ofSize: 11)
        folderHelper.textColor = .tertiaryLabelColor
        folderHelper.frame = NSRect(x: rightX, y: y - 6 - 28 - 4, width: rightW, height: 14)
        addSubview(folderHelper)

        let changeFolder = makePillButton("Change", action: #selector(changeFolderClicked))
        changeFolder.frame = NSRect(x: rightX, y: y - 6 - 28 - 4 - 14 - 8, width: 70, height: 26)
        addSubview(changeFolder)

        y -= 28 + 4 + 14 + 8 + 26 + sectionGap
        addDivider(at: y)
        y -= sectionGap

        // Section 3: Launch at login
        y -= 20
        addSubview(makeRowLabel("Launch at login", y: y))

        loginCheckbox.state = ConfigManager.shared.launchAtLogin ? .on : .off
        loginCheckbox.target = self
        loginCheckbox.action = #selector(loginToggled)
        loginCheckbox.font = NSFont.systemFont(ofSize: 13)
        loginCheckbox.frame = NSRect(x: rightX, y: y - 2, width: 260, height: 20)
        addSubview(loginCheckbox)
    }

    private func makeRowLabel(_ text: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.frame = NSRect(x: pad, y: y, width: labelWidth, height: 20)
        return label
    }

    private func makePillButton(_ text: String, action: Selector) -> NSButton {
        let btn = NSButton(title: text, target: self, action: action)
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        btn.contentTintColor = purpleAccent
        btn.wantsLayer = true
        btn.layer?.borderColor = purpleAccent.cgColor
        btn.layer?.borderWidth = 1
        btn.layer?.cornerRadius = 13
        btn.layer?.backgroundColor = purpleAccent.withAlphaComponent(0.08).cgColor
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
