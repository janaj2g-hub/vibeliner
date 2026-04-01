import AppKit

final class SetupWindowController: NSWindowController {

    let panel1 = SetupPanelView(stepNumber: 1, title: "Screen recording")
    let panel2 = SetupPanelView(stepNumber: 2, title: "Captures folder")
    let panel3 = SetupPanelView(stepNumber: 3, title: "How to share")
    private let startButton = NSButton(title: "Start using Vibeliner →", target: nil, action: nil)
    var allStepsComplete = false {
        didSet { startButton.alphaValue = allStepsComplete ? 1.0 : 0.35; startButton.isEnabled = allStepsComplete }
    }

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Vibeliner"
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        setupLayout()
    }

    private func setupLayout() {
        guard let contentView = window?.contentView else { return }

        let footerH: CGFloat = 46
        let bodyH: CGFloat = 400 - footerH
        let panelW: CGFloat = 620.0 / 3.0

        // Panels
        panel1.frame = NSRect(x: 0, y: footerH, width: panelW, height: bodyH)
        panel1.state = .active
        panel1.setStatus(text: "Not yet granted", style: .amber)

        let permissionPanel = PermissionPanel()
        permissionPanel.setupController = self
        panel1.contentView.addSubview(permissionPanel)
        permissionPanel.autoresizingMask = [.width, .height]

        panel2.frame = NSRect(x: panelW, y: footerH, width: panelW, height: bodyH)
        panel2.state = .locked
        panel2.setStatus(text: "Folder not yet created", style: .gray)

        let folderPanel = FolderPanel()
        folderPanel.setupController = self
        panel2.contentView.addSubview(folderPanel)
        folderPanel.autoresizingMask = [.width, .height]

        panel3.frame = NSRect(x: panelW * 2, y: footerH, width: panelW, height: bodyH)
        panel3.state = .locked
        panel3.setStatus(text: "Complete steps 1 & 2", style: .gray)

        let sharePanel = ShareExplanationPanel()
        panel3.contentView.addSubview(sharePanel)
        sharePanel.autoresizingMask = [.width, .height]

        contentView.addSubview(panel1)
        contentView.addSubview(panel2)
        contentView.addSubview(panel3)

        // Panel dividers
        for i in 1...2 {
            let divider = NSView(frame: NSRect(x: panelW * CGFloat(i), y: footerH, width: 0.5, height: bodyH))
            divider.wantsLayer = true
            divider.layer?.backgroundColor = NSColor(white: 0, alpha: 0.06).cgColor
            contentView.addSubview(divider)
        }

        // Footer
        let footer = NSView(frame: NSRect(x: 0, y: 0, width: 620, height: footerH))
        footer.wantsLayer = true
        footer.layer?.backgroundColor = NSColor(white: 0.98, alpha: 1).cgColor
        contentView.addSubview(footer)

        // Footer top border
        let footerBorder = NSView(frame: NSRect(x: 0, y: footerH - 0.5, width: 620, height: 0.5))
        footerBorder.wantsLayer = true
        footerBorder.layer?.backgroundColor = NSColor(white: 0, alpha: 0.08).cgColor
        contentView.addSubview(footerBorder)

        // Hotkey pills: "Capture shortcut:" + ⌘ ⇧ 6
        let hintLabel = NSTextField(labelWithString: "Capture shortcut:")
        hintLabel.font = NSFont.systemFont(ofSize: 11)
        hintLabel.textColor = NSColor(white: 0.53, alpha: 1)
        hintLabel.frame = NSRect(x: 16, y: 14, width: 105, height: 16)
        footer.addSubview(hintLabel)

        var pillX: CGFloat = 124
        for key in ["⌘", "⇧", "6"] {
            let pill = makeKeyPill(key)
            pill.frame.origin = NSPoint(x: pillX, y: 13)
            footer.addSubview(pill)
            pillX += pill.frame.width + 4
        }

        // Start button
        startButton.isBordered = false
        startButton.wantsLayer = true
        startButton.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        startButton.contentTintColor = .white
        startButton.layer?.backgroundColor = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1).cgColor
        startButton.layer?.cornerRadius = 6
        startButton.frame = NSRect(x: 620 - 200 - 16, y: 9, width: 200, height: 28)
        startButton.target = self
        startButton.action = #selector(startClicked)
        startButton.isEnabled = false
        startButton.alphaValue = 0.35
        footer.addSubview(startButton)
    }

    private func makeKeyPill(_ key: String) -> NSView {
        let label = NSTextField(labelWithString: key)
        label.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
        label.textColor = NSColor(white: 0.33, alpha: 1)
        label.alignment = .center
        label.sizeToFit()

        let w = max(20, label.frame.width + 10)
        let pill = NSView(frame: NSRect(x: 0, y: 0, width: w, height: 18))
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor.white.cgColor
        pill.layer?.borderWidth = 1
        pill.layer?.borderColor = NSColor(white: 0.87, alpha: 1).cgColor
        pill.layer?.cornerRadius = 4
        pill.layer?.shadowColor = NSColor(white: 0.88, alpha: 1).cgColor
        pill.layer?.shadowOffset = NSSize(width: 0, height: -1)
        pill.layer?.shadowRadius = 0
        pill.layer?.shadowOpacity = 1

        label.frame = NSRect(x: 0, y: 1, width: w, height: 16)
        pill.addSubview(label)
        return pill
    }

    @objc private func startClicked() {
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        window?.close()
    }

    func completeStep1() {
        panel1.state = .complete
        panel1.setStatus(text: "Permission granted", style: .green)
        panel2.state = .active
        panel2.setStatus(text: "Folder not yet created", style: .amber)
    }

    func completeStep2() {
        panel2.state = .complete
        panel2.setStatus(text: "Folder ready", style: .green)
        panel3.state = .active
        panel3.setStatus(text: "You can always change this in settings", style: .info)
        allStepsComplete = true
    }
}
