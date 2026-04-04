import AppKit

/// Matches vibeliner_walkthrough.jsx SetupScreen() exactly.
/// Two side-by-side panels (Screen recording + Captures folder), tip card after completion, footer.
final class SetupWindowController: NSWindowController {

    // State
    private var step1Done = false
    private var step2Done = false
    private var showTip = false
    private var folderPath = ""

    // UI refs
    private var panel1Container: NSView!
    private var panel2Container: NSView!
    private var tipCard: NSView?
    private var footerContent: NSView!
    private var badge1View: NSView!
    private var badge2View: NSView!
    private var step1Button: NSButton?
    private var step1SuccessLabel: NSTextField?
    private var step2Button: NSButton?
    private var pathDisplay: NSTextField!
    private var status1: NSView!
    private var status2: NSView!
    private var permissionTimer: Timer?

    // Colors (dark mode — the setup window is always dark)
    private static let bg = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)        // #1e1e1e
    private static let titleBarBg = NSColor(red: 42/255, green: 42/255, blue: 42/255, alpha: 1)  // #2a2a2a
    private static let bdr = NSColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)          // #333
    private static let tx = NSColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1)        // #e0e0e0
    private static let txS = NSColor(red: 136/255, green: 136/255, blue: 136/255, alpha: 1)       // #888
    private static let footerBg = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)     // #222
    // Instance accessors
    private var bg: NSColor { Self.bg }
    private var bdr: NSColor { Self.bdr }
    private var tx: NSColor { Self.tx }
    private var txS: NSColor { Self.txS }
    private var footerBg: NSColor { Self.footerBg }

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Vibeliner"
        window.center()
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = Self.bg
        self.init(window: window)
        buildUI()
        startPermissionPolling()
    }

    deinit { permissionTimer?.invalidate() }

    // MARK: - Build UI

    private func buildUI() {
        guard let cv = window?.contentView else { return }
        cv.wantsLayer = true
        cv.layer?.backgroundColor = bg.cgColor

        let winW: CGFloat = 700
        let footerH: CGFloat = 56
        let panelMinH: CGFloat = 310

        // --- Two panels side by side ---
        let panelsY = footerH
        let panelW = (winW - 1) / 2  // -1 for divider

        // Panel 1: Screen recording
        panel1Container = NSView(frame: NSRect(x: 0, y: panelsY, width: panelW, height: panelMinH))
        buildPanel1(in: panel1Container)
        cv.addSubview(panel1Container)

        // Divider
        let divider = NSView(frame: NSRect(x: panelW, y: panelsY, width: 1, height: panelMinH))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = bdr.cgColor
        cv.addSubview(divider)

        // Panel 2: Captures folder
        panel2Container = NSView(frame: NSRect(x: panelW + 1, y: panelsY, width: panelW, height: panelMinH))
        buildPanel2(in: panel2Container)
        cv.addSubview(panel2Container)

        // Set panel 2 locked initially
        panel2Container.alphaValue = 0.35

        // --- Footer ---
        footerContent = NSView(frame: NSRect(x: 0, y: 0, width: winW, height: footerH))
        footerContent.wantsLayer = true
        footerContent.layer?.backgroundColor = footerBg.cgColor
        cv.addSubview(footerContent)

        let footerBorder = NSView(frame: NSRect(x: 0, y: footerH - 1, width: winW, height: 1))
        footerBorder.wantsLayer = true
        footerBorder.layer?.backgroundColor = bdr.cgColor
        cv.addSubview(footerBorder)

        updateFooter()

        // Resize window to fit: panels + footer
        let totalH = panelMinH + footerH
        window?.setContentSize(NSSize(width: winW, height: totalH))
    }

    // MARK: - Panel 1: Screen recording

    private func buildPanel1(in container: NSView) {
        let pad: CGFloat = 28
        let h = container.frame.height

        // Badge + title row
        badge1View = makeStepBadge(num: 1, done: false, locked: false)
        badge1View.frame.origin = NSPoint(x: pad, y: h - pad - 32)
        container.addSubview(badge1View)

        let title = makeLabel("Screen recording", size: 16, weight: .semibold, color: tx)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: 200, height: 22)
        container.addSubview(title)

        // Description
        let desc = makeLabel("Vibeliner needs screen recording permission to capture screenshots of your running app.", size: 13, weight: .regular, color: txS)
        desc.maximumNumberOfLines = 0
        desc.preferredMaxLayoutWidth = container.frame.width - pad * 2
        desc.lineBreakMode = .byWordWrapping
        desc.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 50, width: container.frame.width - pad * 2, height: 50)
        container.addSubview(desc)

        // Button
        let btn = makePillButton("Open System Settings →")
        btn.target = self
        btn.action = #selector(openSystemSettings)
        btn.frame.origin = NSPoint(x: pad, y: h - pad - 32 - 18 - 50 - 14 - 36)
        container.addSubview(btn)
        step1Button = btn

        // Success text (hidden initially)
        let success = makeLabel("Vibeliner can now capture your screen.", size: 13, weight: .regular, color: NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1))
        success.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 50 - 14 - 20, width: 300, height: 20)
        success.isHidden = true
        container.addSubview(success)
        step1SuccessLabel = success

        // Status pill at bottom
        status1 = makeStatusPill(text: "Not yet granted", style: .amber)
        status1.frame.origin = NSPoint(x: pad, y: 10)
        status1.frame.size.width = container.frame.width - pad * 2
        container.addSubview(status1)
    }

    // MARK: - Panel 2: Captures folder

    private func buildPanel2(in container: NSView) {
        let pad: CGFloat = 28
        let h = container.frame.height

        badge2View = makeStepBadge(num: 2, done: false, locked: true)
        badge2View.frame.origin = NSPoint(x: pad, y: h - pad - 32)
        container.addSubview(badge2View)

        let title = makeLabel("Captures folder", size: 16, weight: .semibold, color: tx)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: 200, height: 22)
        container.addSubview(title)

        let desc = makeLabel("Choose where Vibeliner saves screenshots and prompts.", size: 13, weight: .regular, color: txS)
        desc.maximumNumberOfLines = 0
        desc.preferredMaxLayoutWidth = container.frame.width - pad * 2
        desc.lineBreakMode = .byWordWrapping
        desc.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 36, width: container.frame.width - pad * 2, height: 36)
        container.addSubview(desc)

        // Path display
        pathDisplay = NSTextField(labelWithString: "No folder selected")
        pathDisplay.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        pathDisplay.textColor = txS
        pathDisplay.wantsLayer = true
        pathDisplay.layer?.backgroundColor = NSColor(white: 1, alpha: 0.05).cgColor
        pathDisplay.layer?.borderColor = NSColor(white: 1, alpha: 0.08).cgColor
        pathDisplay.layer?.borderWidth = 1
        pathDisplay.layer?.cornerRadius = 8
        pathDisplay.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 36 - 14 - 36, width: container.frame.width - pad * 2, height: 36)
        // Inset text by adding padding via edge insets on the cell
        container.addSubview(pathDisplay)

        // Create folder button
        let btn = makePillButton("Create folder…")
        btn.target = self
        btn.action = #selector(createFolder)
        btn.frame.origin = NSPoint(x: pad, y: h - pad - 32 - 18 - 36 - 14 - 36 - 14 - 36)
        btn.isHidden = true  // Hidden until step 1 is done
        container.addSubview(btn)
        step2Button = btn

        // Status pill
        status2 = makeStatusPill(text: "Complete step 1 first", style: .gray)
        status2.frame.origin = NSPoint(x: pad, y: 10)
        status2.frame.size.width = container.frame.width - pad * 2
        container.addSubview(status2)

        // Pre-fill if default folder already exists
        let defaultPath = NSString("~/Documents/vibeliner").expandingTildeInPath
        if FileManager.default.fileExists(atPath: defaultPath) {
            folderPath = "~/Documents/vibeliner"
            pathDisplay.stringValue = folderPath
            pathDisplay.textColor = tx
        }
    }

    // MARK: - Step badge (prototype StepBadge component)

    private func makeStepBadge(num: Int, done: Bool, locked: Bool) -> NSView {
        let size: CGFloat = 32
        let view = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        view.wantsLayer = true
        view.layer?.cornerRadius = size / 2

        if done {
            view.layer?.borderColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1).cgColor
            view.layer?.borderWidth = 2
            view.layer?.backgroundColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.1).cgColor
            // Checkmark
            let check = makeLabel("✓", size: 16, weight: .bold, color: NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1))
            check.alignment = .center
            check.frame = NSRect(x: 0, y: 4, width: size, height: size - 8)
            view.addSubview(check)
        } else if locked {
            view.layer?.borderColor = NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1).cgColor  // #555
            view.layer?.borderWidth = 2
            view.layer?.backgroundColor = NSColor(white: 1, alpha: 0.03).cgColor
            let numLabel = makeLabel("\(num)", size: 14, weight: .semibold, color: NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1))
            numLabel.alignment = .center
            numLabel.frame = NSRect(x: 0, y: 4, width: size, height: size - 8)
            view.addSubview(numLabel)
        } else {
            // Active: purple (#534AB7)
            view.layer?.borderColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1).cgColor
            view.layer?.borderWidth = 2
            view.layer?.backgroundColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.08).cgColor
            let numLabel = makeLabel("\(num)", size: 14, weight: .semibold, color: NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1))
            numLabel.alignment = .center
            numLabel.frame = NSRect(x: 0, y: 4, width: size, height: size - 8)
            view.addSubview(numLabel)
        }

        return view
    }

    // MARK: - Status pill

    private enum StatusStyle { case amber, green, gray }

    private func makeStatusPill(text: String, style: StatusStyle) -> NSView {
        let pill = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 36))
        pill.wantsLayer = true
        pill.layer?.cornerRadius = 20

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.alignment = .center

        switch style {
        case .amber:
            pill.layer?.backgroundColor = NSColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 0.08).cgColor
            label.textColor = NSColor(red: 180/255, green: 83/255, blue: 9/255, alpha: 1)  // #b45309
        case .green:
            pill.layer?.backgroundColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.08).cgColor
            label.textColor = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1)  // #16a34a
        case .gray:
            pill.layer?.backgroundColor = NSColor(white: 1, alpha: 0.03).cgColor
            label.textColor = NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)  // #555
        }

        label.frame = NSRect(x: 0, y: 8, width: pill.frame.width, height: 20)
        pill.addSubview(label)
        return pill
    }

    private func updateStatusPill(_ pill: NSView, text: String, style: StatusStyle) {
        if let label = pill.subviews.first as? NSTextField {
            label.stringValue = text
            switch style {
            case .amber:
                pill.layer?.backgroundColor = NSColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 0.08).cgColor
                label.textColor = NSColor(red: 180/255, green: 83/255, blue: 9/255, alpha: 1)
            case .green:
                pill.layer?.backgroundColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.08).cgColor
                label.textColor = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1)
            case .gray:
                pill.layer?.backgroundColor = NSColor(white: 1, alpha: 0.03).cgColor
                label.textColor = NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
            }
        }
    }

    // MARK: - Pill button (white bg, dark text, 20px radius)

    private func makePillButton(_ title: String) -> NSButton {
        let btn = NSButton(title: title, target: nil, action: nil)
        btn.isBordered = false
        btn.wantsLayer = true
        btn.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        btn.contentTintColor = NSColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)  // #1a1a1a
        btn.layer?.backgroundColor = NSColor.white.cgColor
        btn.layer?.cornerRadius = 20
        btn.sizeToFit()
        let w = max(btn.frame.width + 48, 160)
        btn.setFrameSize(NSSize(width: w, height: 36))
        return btn
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.sizeToFit()
        return label
    }

    // MARK: - Footer

    private func updateFooter() {
        // Remove old footer content
        for sv in footerContent.subviews { sv.removeFromSuperview() }

        let winW: CGFloat = 700

        if step1Done && step2Done {
            // Left: "Capture shortcut:" + kbd pills
            let hint = makeLabel("Capture shortcut:", size: 12, weight: .regular, color: txS)
            hint.frame.origin = NSPoint(x: 24, y: 18)
            footerContent.addSubview(hint)

            var kx: CGFloat = 24 + hint.frame.width + 8
            for key in ["⌘", "⇧", "6"] {
                let pill = makeKbdPill(key)
                pill.frame.origin = NSPoint(x: kx, y: 17)
                footerContent.addSubview(pill)
                kx += pill.frame.width + 3
            }

            // Right: green "Start using Vibeliner →" button
            let startBtn = NSButton(title: "Start using Vibeliner →", target: self, action: #selector(startClicked))
            startBtn.isBordered = false
            startBtn.wantsLayer = true
            startBtn.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
            startBtn.contentTintColor = .white
            startBtn.layer?.backgroundColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1).cgColor  // #22c55e
            startBtn.layer?.cornerRadius = 20
            startBtn.sizeToFit()
            let btnW = startBtn.frame.width + 48
            startBtn.setFrameSize(NSSize(width: btnW, height: 36))
            startBtn.frame.origin = NSPoint(x: winW - 24 - btnW, y: 10)
            footerContent.addSubview(startBtn)
        } else {
            // Right-aligned gray text
            let msg = makeLabel("Complete both steps to continue", size: 13, weight: .regular, color: NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1))
            msg.frame.origin = NSPoint(x: winW - 24 - msg.frame.width, y: 18)
            footerContent.addSubview(msg)
        }
    }

    private func makeKbdPill(_ text: String) -> NSView {
        let label = makeLabel(text, size: 12, weight: .semibold, color: NSColor(white: 1, alpha: 0.55))
        label.alignment = .center
        let w = max(22, label.frame.width + 10)
        let h: CGFloat = 22
        let pill = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor(white: 1, alpha: 0.08).cgColor
        pill.layer?.borderColor = NSColor(white: 1, alpha: 0.12).cgColor
        pill.layer?.borderWidth = 1
        pill.layer?.cornerRadius = 5
        label.frame = NSRect(x: 0, y: (h - label.frame.height) / 2, width: w, height: label.frame.height)
        pill.addSubview(label)
        return pill
    }

    // MARK: - Tip card (appears after both steps complete)

    private func showTipCard() {
        guard let cv = window?.contentView else { return }
        let winW: CGFloat = 700
        let footerH: CGFloat = 56

        let card = NSView(frame: NSRect(x: 24, y: footerH + 4, width: winW - 48, height: 100))
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.08).cgColor
        card.layer?.borderColor = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.2).cgColor
        card.layer?.borderWidth = 1
        card.layer?.cornerRadius = 12
        card.alphaValue = 0

        let titleLabel = makeLabel("How to share with AI tools", size: 14, weight: .semibold, color: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1))
        titleLabel.frame.origin = NSPoint(x: 18, y: 62)
        card.addSubview(titleLabel)

        let line1 = makeLabel("Copy Prompt: for terminal tools (Claude Code, Codex). Paste text, AI reads screenshot from disk.", size: 13, weight: .regular, color: NSColor(white: 1, alpha: 0.7))
        line1.maximumNumberOfLines = 0
        line1.preferredMaxLayoutWidth = winW - 48 - 36
        line1.lineBreakMode = .byWordWrapping
        line1.frame = NSRect(x: 18, y: 32, width: winW - 48 - 36, height: 26)
        card.addSubview(line1)

        let line2 = makeLabel("Copy Image: for web/app tools (Claude.ai, ChatGPT). Paste image alongside the prompt.", size: 13, weight: .regular, color: NSColor(white: 1, alpha: 0.7))
        line2.maximumNumberOfLines = 0
        line2.preferredMaxLayoutWidth = winW - 48 - 36
        line2.lineBreakMode = .byWordWrapping
        line2.frame = NSRect(x: 18, y: 6, width: winW - 48 - 36, height: 26)
        card.addSubview(line2)

        cv.addSubview(card)
        self.tipCard = card

        // Shift panels up to make room
        let newPanelsY = footerH + 108
        panel1Container.frame.origin.y = newPanelsY
        panel2Container.frame.origin.y = newPanelsY
        // Divider
        for sv in cv.subviews where sv.frame.width == 1 && sv.frame.height > 200 {
            sv.frame.origin.y = newPanelsY
        }
        window?.setContentSize(NSSize(width: 700, height: panel1Container.frame.maxY))

        // Fade in
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            card.animator().alphaValue = 1
        }
    }

    // MARK: - Step completion

    func completeStep1() {
        step1Done = true

        // Update panel 1: opacity 0.45, badge → done
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            panel1Container.animator().alphaValue = 0.45
        }

        // Replace badge1
        let newBadge = makeStepBadge(num: 1, done: true, locked: false)
        newBadge.frame = badge1View.frame
        badge1View.superview?.addSubview(newBadge)
        badge1View.removeFromSuperview()
        badge1View = newBadge

        step1Button?.isHidden = true
        step1SuccessLabel?.isHidden = false
        updateStatusPill(status1, text: "Permission granted", style: .green)

        // Unlock panel 2
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            panel2Container.animator().alphaValue = 1.0
        }

        // Update badge2 from locked to active
        let newBadge2 = makeStepBadge(num: 2, done: false, locked: false)
        newBadge2.frame = badge2View.frame
        badge2View.superview?.addSubview(newBadge2)
        badge2View.removeFromSuperview()
        badge2View = newBadge2

        step2Button?.isHidden = false
        updateStatusPill(status2, text: "Folder not yet created", style: .amber)

        checkCompletion()
    }

    func completeStep2() {
        step2Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            panel2Container.animator().alphaValue = 0.45
        }

        let newBadge = makeStepBadge(num: 2, done: true, locked: false)
        newBadge.frame = badge2View.frame
        badge2View.superview?.addSubview(newBadge)
        badge2View.removeFromSuperview()
        badge2View = newBadge

        step2Button?.isHidden = true
        pathDisplay.stringValue = folderPath.isEmpty ? "~/Documents/vibeliner" : folderPath
        pathDisplay.textColor = tx
        updateStatusPill(status2, text: "Folder created and ready", style: .green)

        checkCompletion()
    }

    private func checkCompletion() {
        if step1Done && step2Done {
            updateFooter()
            // Show tip card after 400ms
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.showTipCard()
            }
        }
    }

    // MARK: - Permission polling

    private func startPermissionPolling() {
        // Check immediately on open
        if CGPreflightScreenCaptureAccess() {
            completeStep1()
        }
        // Then poll every 2 seconds
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self, !self.step1Done else { return }
            if CGPreflightScreenCaptureAccess() {
                self.completeStep1()
            }
        }
    }

    // MARK: - Actions

    @objc private func openSystemSettings() {
        CGRequestScreenCaptureAccess()
    }

    @objc private func createFolder() {
        let defaultPath = NSString("~/Documents/vibeliner").expandingTildeInPath
        do {
            try FileManager.default.createDirectory(atPath: defaultPath, withIntermediateDirectories: true)
            folderPath = "~/Documents/vibeliner"
            ConfigManager.shared.capturesFolder = folderPath
            ConfigManager.shared.save()
            completeStep2()
        } catch {
            NSLog("Failed to create folder: \(error)")
        }
    }

    @objc private func startClicked() {
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        window?.close()
    }
}
