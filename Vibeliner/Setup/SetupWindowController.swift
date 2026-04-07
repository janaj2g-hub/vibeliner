import AppKit
import ApplicationServices

/// VIB-303: 3-panel setup: Captures Folder → Accessibility → Screen Recording
/// Screen recording is last because it requires an app restart via macOS "Quit & Reopen".
final class SetupWindowController: NSWindowController {

    // MARK: - State

    private var step1Done = false   // Captures folder
    private var step2Done = false   // Accessibility
    private var step3Done = false   // Screen recording
    private var folderPath = ""
    private var isRerun: Bool

    // MARK: - UI refs

    private var panel1Container: NSView!    // Captures folder
    private var panel2Container: NSView!    // Accessibility
    private var panel3Container: NSView!    // Screen recording
    private var footerContent: NSView!
    private var badge1View: NSView!
    private var badge2View: NSView!
    private var badge3View: NSView!
    private var step1ActionRow: NSView!     // "Choose folder…"
    private var step1DoneArea: NSView!      // "Folder ready" + "Change folder"
    private var pathDisplay: NSTextField!
    private var step2ActionRow: NSView!     // "Open Accessibility Settings"
    private var step2Helper: NSTextField!
    private var step3ActionRow: NSView!     // "Open Screen Recording Settings"
    private var step3Helper: NSTextField!
    private var status1: NSTextField!
    private var status2: NSTextField!
    private var status3: NSTextField!
    private var permissionTimer: Timer?

    // MARK: - Init

    convenience init() {
        let winW = DesignTokens.setupWindowWidth
        let totalH = DesignTokens.setupPanelHeight + DesignTokens.setupFooterHeight
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winW, height: totalH),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Vibeliner"
        window.center()
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = DesignTokens.setupWindowBg
        self.init(window: window)
        buildUI()
        startPermissionPolling()
    }

    override init(window: NSWindow?) {
        isRerun = ConfigManager.shared.capturesFolderExists
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    deinit { permissionTimer?.invalidate() }

    // MARK: - Build UI

    private func buildUI() {
        guard let cv = window?.contentView else { return }
        cv.wantsLayer = true
        cv.layer?.backgroundColor = DesignTokens.setupWindowBg.cgColor

        let winW = DesignTokens.setupWindowWidth
        let footerH = DesignTokens.setupFooterHeight
        let panelH = DesignTokens.setupPanelHeight
        let panelW = (winW - 2) / 3

        let panelsY = footerH

        // Panel 1: Captures folder (always unlocked)
        panel1Container = NSView(frame: NSRect(x: 0, y: panelsY, width: panelW, height: panelH))
        buildPanel1(in: panel1Container)
        cv.addSubview(panel1Container)

        // Divider 1
        let d1 = makeDivider(x: panelW, y: panelsY, height: panelH)
        cv.addSubview(d1)

        // Panel 2: Accessibility (locked until step 1 done)
        panel2Container = NSView(frame: NSRect(x: panelW + 1, y: panelsY, width: panelW, height: panelH))
        buildPanel2(in: panel2Container)
        cv.addSubview(panel2Container)
        panel2Container.alphaValue = 0.35

        // Divider 2
        let d2 = makeDivider(x: panelW * 2 + 1, y: panelsY, height: panelH)
        cv.addSubview(d2)

        // Panel 3: Screen recording (locked until step 2 done)
        panel3Container = NSView(frame: NSRect(x: panelW * 2 + 2, y: panelsY, width: panelW, height: panelH))
        buildPanel3(in: panel3Container)
        cv.addSubview(panel3Container)
        panel3Container.alphaValue = 0.35

        // Footer
        footerContent = NSView(frame: NSRect(x: 0, y: 0, width: winW, height: footerH))
        footerContent.wantsLayer = true
        footerContent.layer?.backgroundColor = DesignTokens.setupFooterBg.cgColor
        cv.addSubview(footerContent)

        let footerBorder = makeDivider(x: 0, y: footerH - 1, height: 1)
        footerBorder.frame.size.width = winW
        cv.addSubview(footerBorder)

        updateFooter()
    }

    // MARK: - Panel 1: Captures folder

    private func buildPanel1(in c: NSView) {
        let pad = DesignTokens.setupPanelPad
        let h = c.frame.height
        let contentW = c.frame.width - pad * 2

        badge1View = makeStepBadge(num: 1, state: .active)
        badge1View.frame.origin = NSPoint(x: pad, y: h - pad - DesignTokens.setupBadgeSize)
        c.addSubview(badge1View)

        let title = makeLabel("Captures folder", font: DesignTokens.setupPanelTitleFont, color: DesignTokens.setupTextPrimary)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: contentW - 44, height: 22)
        c.addSubview(title)

        let desc = makeWrappingLabel("Choose where Vibeliner saves screenshots and prompts.", font: DesignTokens.setupDescFont, color: DesignTokens.setupTextSecondary, width: contentW)
        desc.frame.origin = NSPoint(x: pad, y: h - pad - DesignTokens.setupBadgeSize - 18 - desc.frame.height)
        c.addSubview(desc)

        // Path box
        let pathBoxY = desc.frame.origin.y - 14 - 36
        let pathText = isRerun ? abbreviatePath(ConfigManager.shared.capturesFolder) : "No folder selected"
        pathDisplay = NSTextField()
        let centeredCell = VerticallyCenteredTextFieldCell()
        centeredCell.isEditable = false
        centeredCell.isSelectable = true
        centeredCell.isBezeled = false
        centeredCell.drawsBackground = false
        centeredCell.font = DesignTokens.setupPathFont
        centeredCell.textColor = isRerun ? DesignTokens.setupTextPrimary : DesignTokens.setupTextSecondary
        centeredCell.stringValue = pathText
        centeredCell.usesSingleLineMode = true
        centeredCell.lineBreakMode = .byTruncatingHead
        centeredCell.truncatesLastVisibleLine = false
        pathDisplay.cell = centeredCell
        pathDisplay.wantsLayer = true
        pathDisplay.layer?.backgroundColor = DesignTokens.setupFieldBg.cgColor
        pathDisplay.layer?.borderColor = DesignTokens.setupFieldBorder.cgColor
        pathDisplay.layer?.borderWidth = 1
        pathDisplay.layer?.cornerRadius = DesignTokens.setupPathBoxRadius
        pathDisplay.frame = NSRect(x: pad, y: pathBoxY, width: contentW, height: 36)
        c.addSubview(pathDisplay)

        // Action row (choose folder)
        step1ActionRow = makeActionRow(label: "Choose folder…", action: #selector(chooseFolder), width: contentW)
        step1ActionRow.frame.origin = NSPoint(x: pad, y: 10)
        c.addSubview(step1ActionRow)

        // Step 1 done area: "Folder ready" + "Change folder" button
        step1DoneArea = NSView(frame: NSRect(x: pad, y: 10, width: contentW, height: 50))
        step1DoneArea.isHidden = true

        let readyLabel = makeLabel("Folder ready", font: DesignTokens.setupStatusFont, color: DesignTokens.setupGreenText)
        readyLabel.alignment = .center
        readyLabel.frame = NSRect(x: 0, y: 30, width: contentW, height: 18)
        step1DoneArea.addSubview(readyLabel)

        let changeBtn = makeSmallPillButton("Change folder", green: true)
        changeBtn.target = self
        changeBtn.action = #selector(chooseFolder)
        let cbW = changeBtn.frame.width
        changeBtn.frame.origin = NSPoint(x: (contentW - cbW) / 2, y: 0)
        step1DoneArea.addSubview(changeBtn)

        c.addSubview(step1DoneArea)

        // Status label (hidden — panel starts active)
        status1 = makeStatusLabel("", style: .gray)
        status1.frame = NSRect(x: pad, y: 10, width: contentW, height: 20)
        status1.isHidden = true
        c.addSubview(status1)

        // Pre-fill path for re-run
        if isRerun {
            folderPath = ConfigManager.shared.capturesFolder
        }
    }

    // MARK: - Panel 2: Accessibility

    private func buildPanel2(in c: NSView) {
        let pad = DesignTokens.setupPanelPad
        let h = c.frame.height
        let contentW = c.frame.width - pad * 2

        badge2View = makeStepBadge(num: 2, state: .locked)
        badge2View.frame.origin = NSPoint(x: pad, y: h - pad - DesignTokens.setupBadgeSize)
        c.addSubview(badge2View)

        let title = makeLabel("Accessibility", font: DesignTokens.setupPanelTitleFont, color: DesignTokens.setupTextPrimary)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: contentW - 44, height: 22)
        c.addSubview(title)

        let desc = makeWrappingLabel("Vibeliner needs accessibility permission so the capture hotkey works from any app.", font: DesignTokens.setupDescFont, color: DesignTokens.setupTextSecondary, width: contentW)
        desc.frame.origin = NSPoint(x: pad, y: h - pad - DesignTokens.setupBadgeSize - 18 - desc.frame.height)
        c.addSubview(desc)

        // VIB-305: Helper text uses makeWrappingLabel for proper multi-line wrapping
        step2Helper = makeWrappingLabel("You may need to relaunch after granting.", font: DesignTokens.setupHelperFont, color: DesignTokens.setupTextDim, width: contentW)
        step2Helper.frame.origin = NSPoint(x: pad, y: desc.frame.origin.y - 14 - step2Helper.frame.height)
        step2Helper.isHidden = true  // visible only when step 2 is active
        c.addSubview(step2Helper)

        // Action row
        step2ActionRow = makeActionRow(label: "Open Accessibility Settings", action: #selector(openAccessibilitySettings), width: contentW)
        step2ActionRow.frame.origin = NSPoint(x: pad, y: 10)
        step2ActionRow.isHidden = true
        c.addSubview(step2ActionRow)

        // Status label
        status2 = makeStatusLabel("Complete step 1 first", style: .gray)
        status2.frame = NSRect(x: pad, y: 10, width: contentW, height: 20)
        c.addSubview(status2)
    }

    // MARK: - Panel 3: Screen recording

    private func buildPanel3(in c: NSView) {
        let pad = DesignTokens.setupPanelPad
        let h = c.frame.height
        let contentW = c.frame.width - pad * 2

        badge3View = makeStepBadge(num: 3, state: .locked)
        badge3View.frame.origin = NSPoint(x: pad, y: h - pad - DesignTokens.setupBadgeSize)
        c.addSubview(badge3View)

        let title = makeLabel("Screen recording", font: DesignTokens.setupPanelTitleFont, color: DesignTokens.setupTextPrimary)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: contentW - 44, height: 22)
        c.addSubview(title)

        let desc = makeWrappingLabel("Vibeliner needs screen recording permission to capture screenshots of your running app.", font: DesignTokens.setupDescFont, color: DesignTokens.setupTextSecondary, width: contentW)
        desc.frame.origin = NSPoint(x: pad, y: h - pad - DesignTokens.setupBadgeSize - 18 - desc.frame.height)
        c.addSubview(desc)

        // VIB-305: Helper text uses makeWrappingLabel for proper multi-line wrapping
        step3Helper = makeWrappingLabel("You may need to restart the app after granting.", font: DesignTokens.setupHelperFont, color: DesignTokens.setupTextDim, width: contentW)
        step3Helper.frame.origin = NSPoint(x: pad, y: desc.frame.origin.y - 14 - step3Helper.frame.height)
        step3Helper.isHidden = true  // visible only when step 3 is active
        c.addSubview(step3Helper)

        // Action row (label + arrow button)
        step3ActionRow = makeActionRow(label: "Open Screen Recording Settings", action: #selector(openSystemSettings), width: contentW)
        step3ActionRow.frame.origin = NSPoint(x: pad, y: 10)
        step3ActionRow.isHidden = true
        c.addSubview(step3ActionRow)

        // Status label
        status3 = makeStatusLabel("Complete step 2 first", style: .gray)
        status3.frame = NSRect(x: pad, y: 10, width: contentW, height: 20)
        c.addSubview(status3)
    }

    // MARK: - Step badge

    private enum BadgeState { case active, locked, done }

    private func makeStepBadge(num: Int, state: BadgeState) -> NSView {
        let size = DesignTokens.setupBadgeSize
        let view = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        view.wantsLayer = true
        view.layer?.cornerRadius = size / 2
        view.layer?.borderWidth = 2

        let badgeRect = NSRect(x: 0, y: 0, width: size, height: size)
        switch state {
        case .done:
            view.layer?.borderColor = DesignTokens.setupGreen.cgColor
            view.layer?.backgroundColor = DesignTokens.setupGreenBadgeBg.cgColor
            let check = DesignTokens.makeCenteredTextField("✓", font: DesignTokens.setupBadgeCheckFont, color: DesignTokens.setupGreen, in: badgeRect)
            view.addSubview(check)
        case .locked:
            view.layer?.borderColor = DesignTokens.setupGrayText.cgColor
            view.layer?.backgroundColor = DesignTokens.setupGrayBg.cgColor
            let numLabel = DesignTokens.makeCenteredTextField("\(num)", font: DesignTokens.setupBadgeFont, color: DesignTokens.setupGrayText, in: badgeRect)
            view.addSubview(numLabel)
        case .active:
            view.layer?.borderColor = DesignTokens.purpleDark.cgColor
            view.layer?.backgroundColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.08).cgColor
            let numLabel = DesignTokens.makeCenteredTextField("\(num)", font: DesignTokens.setupBadgeFont, color: DesignTokens.purpleDark, in: badgeRect)
            view.addSubview(numLabel)
        }

        return view
    }

    private func replaceBadge(_ badgeRef: inout NSView!, num: Int, state: BadgeState) {
        let newBadge = makeStepBadge(num: num, state: state)
        newBadge.frame = badgeRef.frame
        badgeRef.superview?.addSubview(newBadge)
        badgeRef.removeFromSuperview()
        badgeRef = newBadge
    }

    // MARK: - Action row (label + arrow)

    private func makeActionRow(label: String, action: Selector, width: CGFloat) -> NSView {
        let rowH: CGFloat = 72
        let row = NSView(frame: NSRect(x: 0, y: 0, width: width, height: rowH))

        // Label (clickable)
        let labelBtn = NSButton(title: label, target: self, action: action)
        labelBtn.isBordered = false
        labelBtn.wantsLayer = true
        labelBtn.font = DesignTokens.setupActionLabelFont
        labelBtn.contentTintColor = DesignTokens.setupButtonText
        labelBtn.sizeToFit()
        let labelW = labelBtn.frame.width
        labelBtn.frame = NSRect(x: (width - labelW) / 2, y: rowH - 18, width: labelW, height: 18)
        row.addSubview(labelBtn)

        // Arrow button
        let arrowSize = DesignTokens.setupArrowSize
        let arrow = NSButton(title: "→", target: self, action: action)
        arrow.isBordered = false
        arrow.wantsLayer = true
        arrow.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        arrow.contentTintColor = DesignTokens.setupButtonText
        arrow.layer?.backgroundColor = DesignTokens.setupButtonFill.cgColor
        arrow.layer?.borderColor = DesignTokens.setupButtonBorder.cgColor
        arrow.layer?.borderWidth = 1
        arrow.layer?.cornerRadius = arrowSize / 2
        arrow.frame = NSRect(x: (width - arrowSize) / 2, y: rowH - 18 - 8 - arrowSize, width: arrowSize, height: arrowSize)

        // Hover tracking
        let trackArea = NSTrackingArea(rect: arrow.bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: nil, userInfo: nil)
        arrow.addTrackingArea(trackArea)

        row.addSubview(arrow)
        return row
    }

    // MARK: - Status label

    private enum StatusStyle { case amber, green, gray }

    private func makeStatusLabel(_ text: String, style: StatusStyle) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = DesignTokens.setupStatusFont
        label.alignment = .center
        applyStatusStyle(label, style: style)
        return label
    }

    private func applyStatusStyle(_ label: NSTextField, style: StatusStyle) {
        switch style {
        case .amber:
            label.textColor = DesignTokens.setupAmberText
        case .green:
            label.textColor = DesignTokens.setupGreenText
        case .gray:
            label.textColor = DesignTokens.setupGrayText
        }
    }

    // MARK: - Small pill button

    private func makeSmallPillButton(_ title: String, green: Bool) -> NSButton {
        let btn = NSButton(title: title, target: nil, action: nil)
        btn.isBordered = false
        btn.wantsLayer = true
        btn.font = DesignTokens.setupSmallPillFont
        let pillH = DesignTokens.setupSmallPillHeight

        if green {
            btn.contentTintColor = DesignTokens.setupGreenText
            btn.layer?.backgroundColor = DesignTokens.setupGreenBg.cgColor
            btn.layer?.borderColor = DesignTokens.setupGreenBorder.cgColor
        } else {
            btn.contentTintColor = DesignTokens.purpleButton
            btn.layer?.backgroundColor = DesignTokens.purpleButtonBg.cgColor
            btn.layer?.borderColor = DesignTokens.purpleButton.cgColor
        }

        btn.layer?.borderWidth = 1
        btn.layer?.cornerRadius = pillH / 2
        btn.sizeToFit()
        let w = btn.frame.width + 20
        btn.setFrameSize(NSSize(width: w, height: pillH))
        return btn
    }

    // MARK: - Footer

    private func updateFooter() {
        for sv in footerContent.subviews { sv.removeFromSuperview() }
        let winW = DesignTokens.setupWindowWidth

        if step1Done && step2Done && step3Done {
            // Left: Shortcut group in pill container
            let shortcutGroup = buildShortcutGroup()
            shortcutGroup.frame.origin = NSPoint(x: 24, y: (DesignTokens.setupFooterHeight - shortcutGroup.frame.height) / 2)
            footerContent.addSubview(shortcutGroup)

            // Right: Green "Start using Vibeliner →" button
            let startBtn = NSButton(title: "Start using Vibeliner →", target: self, action: #selector(startClicked))
            startBtn.isBordered = false
            startBtn.wantsLayer = true
            startBtn.font = DesignTokens.setupActionLabelFont
            startBtn.contentTintColor = DesignTokens.setupGreenText
            startBtn.layer?.backgroundColor = DesignTokens.setupGreenBg.cgColor
            startBtn.layer?.borderColor = DesignTokens.setupGreenBorder.cgColor
            startBtn.layer?.borderWidth = 1
            startBtn.layer?.cornerRadius = 20
            startBtn.sizeToFit()
            let btnW = startBtn.frame.width + 48
            startBtn.setFrameSize(NSSize(width: btnW, height: 36))
            startBtn.frame.origin = NSPoint(x: winW - 24 - btnW, y: (DesignTokens.setupFooterHeight - 36) / 2)
            footerContent.addSubview(startBtn)
        } else {
            let msg = makeLabel("Complete all steps to continue", font: DesignTokens.setupDescFont, color: DesignTokens.setupGrayText)
            msg.frame.origin = NSPoint(x: winW - 24 - msg.frame.width, y: (DesignTokens.setupFooterHeight - msg.frame.height) / 2)
            footerContent.addSubview(msg)
        }
    }

    private func buildShortcutGroup() -> NSView {
        // Build all children first to measure total width
        let hint = makeLabel("Shortcut:", font: DesignTokens.setupShortcutHintFont, color: DesignTokens.setupTextSecondary)
        let keys = HotkeyManager.shared.displayParts(for: ConfigManager.shared.hotkey)
        var kbdPills: [NSView] = []
        for key in keys {
            kbdPills.append(makeKbdPill(key))
        }
        let editBtn = makeSmallPillButton("Edit", green: false)
        editBtn.target = self
        editBtn.action = #selector(editShortcut)

        // Calculate total width
        let innerPad: CGFloat = 12
        let gap: CGFloat = 6
        let rightPad: CGFloat = 3
        var totalW = innerPad + hint.frame.width + gap
        for pill in kbdPills {
            totalW += pill.frame.width + 3
        }
        totalW += gap + editBtn.frame.width + rightPad

        let groupH: CGFloat = 28
        let group = NSView(frame: NSRect(x: 0, y: 0, width: totalW, height: groupH))
        group.wantsLayer = true
        group.layer?.backgroundColor = DesignTokens.setupFieldBg.cgColor
        group.layer?.borderColor = DesignTokens.setupFieldBorder.cgColor
        group.layer?.borderWidth = 1
        group.layer?.cornerRadius = groupH / 2

        var x = innerPad
        hint.frame.origin = NSPoint(x: x, y: (groupH - hint.frame.height) / 2)
        group.addSubview(hint)
        x += hint.frame.width + gap

        for pill in kbdPills {
            pill.frame.origin = NSPoint(x: x, y: (groupH - pill.frame.height) / 2)
            group.addSubview(pill)
            x += pill.frame.width + 3
        }

        x += gap - 3
        editBtn.frame.origin = NSPoint(x: x, y: (groupH - editBtn.frame.height) / 2)
        group.addSubview(editBtn)

        return group
    }

    private func makeKbdPill(_ text: String) -> NSView {
        let label = makeLabel(text, font: DesignTokens.setupKbdFont, color: DesignTokens.setupKbdText)
        label.alignment = .center
        let w = max(22, label.frame.width + 10)
        let h: CGFloat = 22
        let pill = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        pill.wantsLayer = true
        pill.layer?.backgroundColor = DesignTokens.setupKbdBg.cgColor
        pill.layer?.borderColor = DesignTokens.setupKbdBorder.cgColor
        pill.layer?.borderWidth = 1
        pill.layer?.cornerRadius = 5
        label.frame = NSRect(x: 0, y: (h - label.frame.height) / 2, width: w, height: label.frame.height)
        pill.addSubview(label)
        return pill
    }

    // MARK: - Step completion

    /// Step 1: Captures folder selected
    func completeStep1() {
        guard !step1Done else { return }
        step1Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel1Container.animator().alphaValue = 0.45
        }

        replaceBadge(&badge1View, num: 1, state: .done)
        step1ActionRow.isHidden = true
        status1.isHidden = true
        step1DoneArea.isHidden = false

        pathDisplay.stringValue = abbreviatePath(folderPath)
        pathDisplay.textColor = DesignTokens.setupTextPrimary

        // Unlock panel 2 (Accessibility)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel2Container.animator().alphaValue = 1.0
        }

        replaceBadge(&badge2View, num: 2, state: .active)
        step2ActionRow.isHidden = false
        step2Helper.isHidden = false
        status2.isHidden = true

        checkCompletion()
    }

    /// Step 2: Accessibility permission granted
    func completeStep2() {
        guard !step2Done else { return }
        step2Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel2Container.animator().alphaValue = 0.45
        }

        replaceBadge(&badge2View, num: 2, state: .done)
        step2ActionRow.isHidden = true
        step2Helper.isHidden = true
        status2.isHidden = false
        status2.stringValue = "Permission granted"
        applyStatusStyle(status2, style: .green)

        // Unlock panel 3 (Screen recording)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel3Container.animator().alphaValue = 1.0
        }

        replaceBadge(&badge3View, num: 3, state: .active)
        step3ActionRow.isHidden = false
        step3Helper.isHidden = false
        status3.isHidden = true

        checkCompletion()
    }

    /// Step 3: Screen recording permission granted
    func completeStep3() {
        guard !step3Done else { return }
        step3Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel3Container.animator().alphaValue = 0.45
        }

        replaceBadge(&badge3View, num: 3, state: .done)
        step3ActionRow.isHidden = true
        step3Helper.isHidden = true
        status3.isHidden = false
        status3.stringValue = "Permission granted"
        applyStatusStyle(status3, style: .green)

        checkCompletion()
    }

    /// Called when "Change folder" is clicked after step 1 is done — allow re-selecting
    private func reopenFolderSelection() {
        step1Done = false
        step1DoneArea.isHidden = true
        step1ActionRow.isHidden = false

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel1Container.animator().alphaValue = 1.0
        }
        replaceBadge(&badge1View, num: 1, state: .active)
        updateFooter()
    }

    private func checkCompletion() {
        updateFooter()
    }

    // MARK: - Permission polling

    private func startPermissionPolling() {
        // Immediate checks

        // Step 1: Captures folder — auto-complete if folder already exists
        if isRerun && !folderPath.isEmpty && ConfigManager.shared.capturesFolderExists {
            completeStep1()
        }

        // Step 2: Accessibility — auto-complete if already granted (and step 1 done)
        if step1Done && AXIsProcessTrusted() {
            completeStep2()
        }

        // Step 3: Screen recording — auto-complete if already granted (and step 2 done)
        if step2Done && CGPreflightScreenCaptureAccess() {
            completeStep3()
        }

        // Timer polls for permission changes (steps 2 and 3)
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.step1Done && !self.step2Done && AXIsProcessTrusted() {
                self.completeStep2()
            }
            if self.step2Done && !self.step3Done && CGPreflightScreenCaptureAccess() {
                self.completeStep3()
            }
        }
    }

    // MARK: - Actions

    @objc private func openSystemSettings() {
        // VIB-304: Set pending restart flag so setup re-shows after macOS "Quit & Reopen"
        ConfigManager.shared.setupPendingRestart = true
        ConfigManager.shared.save()

        // Open System Settings directly — no macOS dialog
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"

        // Start from existing folder or default
        if !folderPath.isEmpty {
            let expanded = (folderPath as NSString).expandingTildeInPath
            panel.directoryURL = URL(fileURLWithPath: expanded)
        } else {
            panel.directoryURL = URL(fileURLWithPath: NSString("~/Documents").expandingTildeInPath)
        }

        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            self.folderPath = url.path
            ConfigManager.shared.capturesFolder = url.path
            ConfigManager.shared.save()
            self.completeStep1()
        }
    }

    @objc private func startClicked() {
        // VIB-304: Clear the pending restart flag and mark setup complete
        ConfigManager.shared.setupPendingRestart = false
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        permissionTimer?.invalidate()
        permissionTimer = nil
        window?.close()
    }

    @objc private func editShortcut() {
        guard let win = window else { return }
        HotkeyCapturePanel.present(from: win) { [weak self] _ in
            self?.updateFooter()
        }
    }

    // MARK: - Helpers

    private func makeLabel(_ text: String, font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.sizeToFit()
        return label
    }

    private func makeWrappingLabel(_ text: String, font: NSFont, color: NSColor, width: CGFloat) -> NSTextField {
        let label = makeLabel(text, font: font, color: color)
        label.maximumNumberOfLines = 0
        label.preferredMaxLayoutWidth = width
        label.lineBreakMode = .byWordWrapping
        label.setFrameSize(NSSize(width: width, height: label.fittingSize.height))
        return label
    }

    private func makeDivider(x: CGFloat, y: CGFloat, height: CGFloat) -> NSView {
        let d = NSView(frame: NSRect(x: x, y: y, width: 1, height: height))
        d.wantsLayer = true
        d.layer?.backgroundColor = DesignTokens.setupBorder.cgColor
        return d
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        if path.hasPrefix("~/") {
            return path
        }
        return path
    }
}
