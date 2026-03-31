import AppKit

final class SetupWindowController: NSWindowController {

    let panel1 = SetupPanelView(stepNumber: 1, title: "Screen recording")
    let panel2 = SetupPanelView(stepNumber: 2, title: "Captures folder")
    let panel3 = SetupPanelView(stepNumber: 3, title: "How to share")
    private let startButton = NSButton(title: "Start using Vibeliner →", target: nil, action: nil)
    var allStepsComplete = false { didSet { startButton.isEnabled = allStepsComplete } }

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 400),
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
        contentView.wantsLayer = true

        let footerH: CGFloat = 44
        let bodyH = 400 - footerH
        let panelW = 680.0 / 3.0

        // Panels
        panel1.frame = NSRect(x: 0, y: footerH, width: panelW, height: bodyH)
        panel1.state = .active
        panel1.setStatus(text: "Not yet granted", color: NSColor(red: 217/255, green: 119/255, blue: 6/255, alpha: 1))

        let permissionPanel = PermissionPanel()
        permissionPanel.setupController = self
        panel1.contentView.addSubview(permissionPanel)
        permissionPanel.autoresizingMask = [.width, .height]

        panel2.frame = NSRect(x: panelW, y: footerH, width: panelW, height: bodyH)
        panel2.state = .locked
        panel2.setStatus(text: "Waiting", color: NSColor(white: 0.6, alpha: 1))

        let folderPanel = FolderPanel()
        folderPanel.setupController = self
        panel2.contentView.addSubview(folderPanel)
        folderPanel.autoresizingMask = [.width, .height]

        panel3.frame = NSRect(x: panelW * 2, y: footerH, width: panelW, height: bodyH)
        panel3.state = .locked
        panel3.setStatus(text: "Waiting", color: NSColor(white: 0.6, alpha: 1))

        let sharePanel = ShareExplanationPanel()
        panel3.contentView.addSubview(sharePanel)
        sharePanel.autoresizingMask = [.width, .height]

        contentView.addSubview(panel1)
        contentView.addSubview(panel2)
        contentView.addSubview(panel3)

        // Dividers
        for i in 1...2 {
            let divider = NSView(frame: NSRect(x: panelW * CGFloat(i), y: footerH, width: 0.5, height: bodyH))
            divider.wantsLayer = true
            divider.layer?.backgroundColor = NSColor(white: 0.85, alpha: 1).cgColor
            contentView.addSubview(divider)
        }

        // Footer
        let footer = NSView(frame: NSRect(x: 0, y: 0, width: 680, height: footerH))
        footer.wantsLayer = true
        footer.layer?.backgroundColor = NSColor(white: 0.96, alpha: 1).cgColor
        contentView.addSubview(footer)

        // Footer divider
        let footerDiv = NSView(frame: NSRect(x: 0, y: footerH, width: 680, height: 0.5))
        footerDiv.wantsLayer = true
        footerDiv.layer?.backgroundColor = NSColor(white: 0.85, alpha: 1).cgColor
        contentView.addSubview(footerDiv)

        // Hotkey hint
        let hint = NSTextField(labelWithString: "Capture shortcut:  ⌘  ⇧  6")
        hint.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        hint.textColor = NSColor(white: 0.5, alpha: 1)
        hint.frame = NSRect(x: 16, y: 12, width: 200, height: 20)
        footer.addSubview(hint)

        // Start button
        startButton.bezelStyle = .rounded
        startButton.controlSize = .large
        startButton.contentTintColor = .white
        startButton.wantsLayer = true
        startButton.layer?.backgroundColor = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1).cgColor
        startButton.layer?.cornerRadius = 6
        startButton.isBordered = false
        startButton.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        startButton.frame = NSRect(x: 680 - 220, y: 8, width: 204, height: 28)
        startButton.target = self
        startButton.action = #selector(startClicked)
        startButton.isEnabled = false
        footer.addSubview(startButton)
    }

    @objc private func startClicked() {
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        window?.close()
    }

    func completeStep1() {
        panel1.state = .complete
        panel1.setStatus(text: "Permission granted", color: NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1))
        panel2.state = .active
        panel2.setStatus(text: "Folder not yet created", color: NSColor(red: 217/255, green: 119/255, blue: 6/255, alpha: 1))
    }

    func completeStep2() {
        panel2.state = .complete
        panel2.setStatus(text: "Folder ready", color: NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1))
        panel3.state = .active
        panel3.setStatus(text: "You can always change this in settings", color: NSColor(red: 55/255, green: 138/255, blue: 221/255, alpha: 1))
        allStepsComplete = true
    }
}
