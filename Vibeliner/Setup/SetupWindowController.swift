import AppKit
import ApplicationServices

/// 3-panel setup: Screen Recording → Accessibility → Captures Folder
final class SetupWindowController: NSWindowController {

    // State
    private var step1Done = false
    private var step2AccessibilityDone = false
    private var step3Done = false
    private var folderPath = ""

    // UI refs
    private var panel1Container: NSView!
    private var panel2Container: NSView!
    private var panel3Container: NSView!
    private var footerContent: NSView!
    private var badge1View: NSView!
    private var badge2View: NSView!
    private var badge3View: NSView!
    private var step1Button: NSButton?
    private var step1SuccessLabel: NSTextField?
    private var step2Button: NSButton?
    private var step3Button: NSButton?
    private var pathDisplay: NSTextField!
    private var status1: NSView!
    private var status2: NSView!
    private var status3: NSView!
    private var permissionTimer: Timer?

    // Colors (dark mode — the setup window is always dark)
    private static let bg = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
    private static let titleBarBg = NSColor(red: 42/255, green: 42/255, blue: 42/255, alpha: 1)
    private static let bdr = NSColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
    private static let tx = NSColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1)
    private static let txS = NSColor(red: 136/255, green: 136/255, blue: 136/255, alpha: 1)
    private static let footerBg = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1)
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
        let panelW = (winW - 2) / 3  // -2 for two dividers

        let panelsY = footerH

        // Panel 1: Screen recording
        panel1Container = NSView(frame: NSRect(x: 0, y: panelsY, width: panelW, height: panelMinH))
        buildPanel1(in: panel1Container)
        cv.addSubview(panel1Container)

        // Divider 1
        let divider1 = NSView(frame: NSRect(x: panelW, y: panelsY, width: 1, height: panelMinH))
        divider1.wantsLayer = true
        divider1.layer?.backgroundColor = bdr.cgColor
        cv.addSubview(divider1)

        // Panel 2: Accessibility
        panel2Container = NSView(frame: NSRect(x: panelW + 1, y: panelsY, width: panelW, height: panelMinH))
        buildPanel2Accessibility(in: panel2Container)
        cv.addSubview(panel2Container)
        panel2Container.alphaValue = 0.35

        // Divider 2
        let divider2 = NSView(frame: NSRect(x: panelW * 2 + 1, y: panelsY, width: 1, height: panelMinH))
        divider2.wantsLayer = true
        divider2.layer?.backgroundColor = bdr.cgColor
        cv.addSubview(divider2)

        // Panel 3: Captures folder
        panel3Container = NSView(frame: NSRect(x: panelW * 2 + 2, y: panelsY, width: panelW, height: panelMinH))
        buildPanel3(in: panel3Container)
        cv.addSubview(panel3Container)
        panel3Container.alphaValue = 0.35

        // Footer
        footerContent = NSView(frame: NSRect(x: 0, y: 0, width: winW, height: footerH))
        footerContent.wantsLayer = true
        footerContent.layer?.backgroundColor = footerBg.cgColor
        cv.addSubview(footerContent)

        let footerBorder = NSView(frame: NSRect(x: 0, y: footerH - 1, width: winW, height: 1))
        footerBorder.wantsLayer = true
        footerBorder.layer?.backgroundColor = bdr.cgColor
        cv.addSubview(footerBorder)

        updateFooter()

        let totalH = panelMinH + footerH
        window?.setContentSize(NSSize(width: winW, height: totalH))
    }

    // MARK: - Panel 1: Screen recording

    private func buildPanel1(in container: NSView) {
        let pad: CGFloat = 28
        let h = container.frame.height

        badge1View = makeStepBadge(num: 1, done: false, locked: false)
        badge1View.frame.origin = NSPoint(x: pad, y: h - pad - 32)
        container.addSubview(badge1View)

        let title = makeLabel("Screen recording", size: 16, weight: .semibold, color: tx)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: 200, height: 22)
        container.addSubview(title)

        let desc = makeLabel("Vibeliner needs screen recording permission to capture screenshots of your running app.", size: 13, weight: .regular, color: txS)
        desc.maximumNumberOfLines = 0
        desc.preferredMaxLayoutWidth = container.frame.width - pad * 2
        desc.lineBreakMode = .byWordWrapping
        desc.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 50, width: container.frame.width - pad * 2, height: 50)
        container.addSubview(desc)

        let btn = makePillButton("Open Screen Recording Settings →")
        btn.target = self
        btn.action = #selector(openSystemSettings)
        btn.frame.origin = NSPoint(x: pad, y: h - pad - 32 - 18 - 50 - 14 - 36)
        container.addSubview(btn)
        step1Button = btn

        let success = makeLabel("Vibeliner can now capture your screen.", size: 13, weight: .regular, color: NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1))
        success.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 50 - 14 - 20, width: 300, height: 20)
        success.isHidden = true
        container.addSubview(success)
        step1SuccessLabel = success

        status1 = makeStatusPill(text: "Not yet granted", style: .amber)
        status1.frame.origin = NSPoint(x: pad, y: 10)
        status1.frame.size.width = container.frame.width - pad * 2
        container.addSubview(status1)
    }

    // MARK: - Panel 2: Accessibility

    private func buildPanel2Accessibility(in container: NSView) {
        let pad: CGFloat = 28
        let h = container.frame.height

        badge2View = makeStepBadge(num: 2, done: false, locked: true)
        badge2View.frame.origin = NSPoint(x: pad, y: h - pad - 32)
        container.addSubview(badge2View)

        let title = makeLabel("Accessibility", size: 16, weight: .semibold, color: tx)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: 180, height: 22)
        container.addSubview(title)

        let desc = makeLabel("Vibeliner needs accessibility permission so the capture hotkey (⌘⇧6) works from any app.", size: 13, weight: .regular, color: txS)
        desc.maximumNumberOfLines = 0
        desc.preferredMaxLayoutWidth = container.frame.width - pad * 2
        desc.lineBreakMode = .byWordWrapping
        desc.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 50, width: container.frame.width - pad * 2, height: 50)
        container.addSubview(desc)

        let btn = makePillButton("Open Accessibility Settings →")
        btn.target = self
        btn.action = #selector(openAccessibilitySettings)
        btn.frame.origin = NSPoint(x: pad, y: h - pad - 32 - 18 - 50 - 14 - 36)
        container.addSubview(btn)
        step2Button = btn

        let note = makeLabel("You may need to relaunch after granting.", size: 11, weight: .regular, color: NSColor(white: 0.4, alpha: 1))
        note.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 50 - 14 - 36 - 18, width: container.frame.width - pad * 2, height: 14)
        container.addSubview(note)

        status2 = makeStatusPill(text: "Complete step 1 first", style: .gray)
        status2.frame.origin = NSPoint(x: pad, y: 10)
        status2.frame.size.width = container.frame.width - pad * 2
        container.addSubview(status2)
    }

    // MARK: - Panel 3: Captures folder

    private func buildPanel3(in container: NSView) {
        let pad: CGFloat = 28
        let h = container.frame.height

        badge3View = makeStepBadge(num: 3, done: false, locked: true)
        badge3View.frame.origin = NSPoint(x: pad, y: h - pad - 32)
        container.addSubview(badge3View)

        let title = makeLabel("Captures folder", size: 16, weight: .semibold, color: tx)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: 200, height: 22)
        container.addSubview(title)

        let desc = makeLabel("Choose where Vibeliner saves screenshots and prompts.", size: 13, weight: .regular, color: txS)
        desc.maximumNumberOfLines = 0
        desc.preferredMaxLayoutWidth = container.frame.width - pad * 2
        desc.lineBreakMode = .byWordWrapping
        desc.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 36, width: container.frame.width - pad * 2, height: 36)
        container.addSubview(desc)

        pathDisplay = NSTextField(labelWithString: "No folder selected")
        pathDisplay.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        pathDisplay.textColor = txS
        pathDisplay.wantsLayer = true
        pathDisplay.layer?.backgroundColor = NSColor(white: 1, alpha: 0.05).cgColor
        pathDisplay.layer?.borderColor = NSColor(white: 1, alpha: 0.08).cgColor
        pathDisplay.layer?.borderWidth = 1
        pathDisplay.layer?.cornerRadius = 8
        pathDisplay.frame = NSRect(x: pad, y: h - pad - 32 - 18 - 36 - 14 - 36, width: container.frame.width - pad * 2, height: 36)
        pathDisplay.usesSingleLineMode = true
        pathDisplay.cell?.truncatesLastVisibleLine = true
        container.addSubview(pathDisplay)

        let btn = makePillButton("Choose folder…")
        btn.target = self
        btn.action = #selector(createFolder)
        btn.frame.origin = NSPoint(x: pad, y: h - pad - 32 - 18 - 36 - 14 - 36 - 14 - 36)
        btn.isHidden = true
        container.addSubview(btn)
        step3Button = btn

        status3 = makeStatusPill(text: "Complete step 2 first", style: .gray)
        status3.frame.origin = NSPoint(x: pad, y: 10)
        status3.frame.size.width = container.frame.width - pad * 2
        container.addSubview(status3)

        // Pre-fill if default folder already exists
        let defaultPath = NSString("~/Documents/vibeliner").expandingTildeInPath
        if FileManager.default.fileExists(atPath: defaultPath) {
            folderPath = "~/Documents/vibeliner"
            pathDisplay.stringValue = folderPath
            pathDisplay.textColor = tx
        }
    }

    // MARK: - Step badge

    private func makeStepBadge(num: Int, done: Bool, locked: Bool) -> NSView {
        let size: CGFloat = 32
        let view = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        view.wantsLayer = true
        view.layer?.cornerRadius = size / 2

        if done {
            view.layer?.borderColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1).cgColor
            view.layer?.borderWidth = 2
            view.layer?.backgroundColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.1).cgColor
            let check = makeLabel("✓", size: 16, weight: .bold, color: NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1))
            check.alignment = .center
            check.frame = NSRect(x: 0, y: 0, width: size, height: size)
            view.addSubview(check)
        } else if locked {
            view.layer?.borderColor = NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1).cgColor
            view.layer?.borderWidth = 2
            view.layer?.backgroundColor = NSColor(white: 1, alpha: 0.03).cgColor
            let numLabel = makeLabel("\(num)", size: 14, weight: .semibold, color: NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1))
            numLabel.alignment = .center
            numLabel.frame = NSRect(x: 0, y: 0, width: size, height: size)
            view.addSubview(numLabel)
        } else {
            view.layer?.borderColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1).cgColor
            view.layer?.borderWidth = 2
            view.layer?.backgroundColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.08).cgColor
            let numLabel = makeLabel("\(num)", size: 14, weight: .semibold, color: NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1))
            numLabel.alignment = .center
            numLabel.frame = NSRect(x: 0, y: 0, width: size, height: size)
            view.addSubview(numLabel)
        }

        return view
    }

    // MARK: - Status pill

    private enum StatusStyle { case amber, green, gray, locked }

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
            label.textColor = NSColor(red: 180/255, green: 83/255, blue: 9/255, alpha: 1)
        case .green:
            pill.layer?.backgroundColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.08).cgColor
            label.textColor = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1)
        case .gray, .locked:
            pill.layer?.backgroundColor = NSColor(white: 1, alpha: 0.03).cgColor
            label.textColor = NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
        }

        label.frame = NSRect(x: 0, y: 0, width: pill.frame.width, height: pill.frame.height)
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
            case .gray, .locked:
                pill.layer?.backgroundColor = NSColor(white: 1, alpha: 0.03).cgColor
                label.textColor = NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1)
            }
        }
    }

    // MARK: - Pill button

    private func makePillButton(_ title: String) -> NSButton {
        let btn = NSButton(title: title, target: nil, action: nil)
        btn.isBordered = false
        btn.wantsLayer = true
        btn.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        btn.contentTintColor = NSColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)
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
        for sv in footerContent.subviews { sv.removeFromSuperview() }
        let winW: CGFloat = 700

        if step1Done && step2AccessibilityDone && step3Done {
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

            let startBtn = NSButton(title: "Start using Vibeliner →", target: self, action: #selector(startClicked))
            startBtn.isBordered = false
            startBtn.wantsLayer = true
            startBtn.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
            startBtn.contentTintColor = .white
            startBtn.layer?.backgroundColor = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1).cgColor
            startBtn.layer?.cornerRadius = 20
            startBtn.sizeToFit()
            let btnW = startBtn.frame.width + 48
            startBtn.setFrameSize(NSSize(width: btnW, height: 36))
            startBtn.frame.origin = NSPoint(x: winW - 24 - btnW, y: 10)
            footerContent.addSubview(startBtn)
        } else {
            let msg = makeLabel("Complete all steps to continue", size: 13, weight: .regular, color: NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1))
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

    // MARK: - Step completion

    func completeStep1() {
        step1Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            panel1Container.animator().alphaValue = 0.45
        }

        let newBadge = makeStepBadge(num: 1, done: true, locked: false)
        newBadge.frame = badge1View.frame
        badge1View.superview?.addSubview(newBadge)
        badge1View.removeFromSuperview()
        badge1View = newBadge

        step1Button?.isHidden = true
        step1SuccessLabel?.isHidden = false
        updateStatusPill(status1, text: "Permission granted", style: .green)

        // Unlock panel 2 (Accessibility)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            panel2Container.animator().alphaValue = 1.0
        }

        let newBadge2 = makeStepBadge(num: 2, done: false, locked: false)
        newBadge2.frame = badge2View.frame
        badge2View.superview?.addSubview(newBadge2)
        badge2View.removeFromSuperview()
        badge2View = newBadge2

        step2Button?.isHidden = false
        updateStatusPill(status2, text: "Not yet granted", style: .amber)

        checkCompletion()
    }

    func completeStep2Accessibility() {
        step2AccessibilityDone = true

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
        updateStatusPill(status2, text: "Permission granted", style: .green)

        // Unlock panel 3 (Captures folder)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.5
            panel3Container.animator().alphaValue = 1.0
        }

        let newBadge3 = makeStepBadge(num: 3, done: false, locked: false)
        newBadge3.frame = badge3View.frame
        badge3View.superview?.addSubview(newBadge3)
        badge3View.removeFromSuperview()
        badge3View = newBadge3

        step3Button?.isHidden = false
        updateStatusPill(status3, text: "Folder not yet chosen", style: .amber)

        checkCompletion()
    }

    func completeStep3() {
        step3Done = true

        // Panel 3 does NOT dim — stays fully interactive
        let newBadge = makeStepBadge(num: 3, done: true, locked: false)
        newBadge.frame = badge3View.frame
        badge3View.superview?.addSubview(newBadge)
        badge3View.removeFromSuperview()
        badge3View = newBadge

        pathDisplay.stringValue = folderPath.isEmpty ? "~/Documents/vibeliner" : folderPath
        pathDisplay.textColor = tx
        updateStatusPill(status3, text: "Folder ready", style: .green)

        checkCompletion()
    }

    private func checkCompletion() {
        if step1Done && step2AccessibilityDone && step3Done {
            updateFooter()
        }
    }

    // MARK: - Permission polling

    private func startPermissionPolling() {
        // Immediate checks on open
        if CGPreflightScreenCaptureAccess() {
            completeStep1()
        }
        if step1Done && AXIsProcessTrusted() {
            completeStep2Accessibility()
        }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if !self.step1Done && CGPreflightScreenCaptureAccess() {
                self.completeStep1()
            }
            if self.step1Done && !self.step2AccessibilityDone && AXIsProcessTrusted() {
                self.completeStep2Accessibility()
            }
        }
    }

    // MARK: - Actions

    @objc private func openSystemSettings() {
        CGRequestScreenCaptureAccess()
    }

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc private func createFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: NSString("~/Documents").expandingTildeInPath)
        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            self.folderPath = url.path
            ConfigManager.shared.capturesFolder = url.path
            ConfigManager.shared.save()
            self.completeStep3()
        }
    }

    @objc private func startClicked() {
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        window?.close()
    }
}
