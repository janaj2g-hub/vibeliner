import AppKit
import ApplicationServices

/// VIB-332: Content view that notifies the controller on appearance changes
/// so layer-backed CGColors can be re-applied with the new appearance.
private class SetupContentView: NSView {
    var onAppearanceChange: (() -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onAppearanceChange?()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}

private final class SetupDividerView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleDividerSurface(self, color: DesignTokens.setupBorder)
    }
}

private final class SetupFooterSurfaceView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(self, background: DesignTokens.setupFooterBg, borderWidth: 0)
    }
}

private enum SetupPillRole {
    case accent
    case success
    case ghost
}

private final class SetupPillButton: AppearanceAwareSurfaceButton {
    private let role: SetupPillRole
    private let heightValue: CGFloat

    init(
        title: String,
        role: SetupPillRole,
        height: CGFloat,
        font: NSFont,
        horizontalPadding: CGFloat,
        target: AnyObject?,
        action: Selector?
    ) {
        self.role = role
        self.heightValue = height
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        setButtonType(.momentaryPushIn)
        self.font = font
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        sizeToFit()
        let width = frame.width + horizontalPadding
        setFrameSize(NSSize(width: width, height: heightValue))
        refreshSurfaceAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func refreshSurfaceAppearance() {
        switch role {
        case .accent:
            contentTintColor = DesignTokens.setupButtonText
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.setupButtonFill,
                border: DesignTokens.setupButtonBorder,
                cornerRadius: heightValue / 2
            )
        case .success:
            contentTintColor = DesignTokens.setupGreenText
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.setupGreenBg,
                border: DesignTokens.setupGreenBorder,
                cornerRadius: heightValue / 2
            )
        case .ghost:
            contentTintColor = DesignTokens.setupTextSecondary
            SettingsUI.styleSurface(
                self,
                background: .clear,
                border: DesignTokens.setupBorder,
                cornerRadius: heightValue / 2
            )
        }
    }
}

private final class SetupCircleButton: AppearanceAwareSurfaceButton {
    init(title: String, target: AnyObject?, action: Selector?) {
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        setButtonType(.momentaryPushIn)
        font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        let size = DesignTokens.setupArrowSize
        setFrameSize(NSSize(width: size, height: size))
        refreshSurfaceAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func refreshSurfaceAppearance() {
        contentTintColor = DesignTokens.setupButtonText
        SettingsUI.styleSurface(
            self,
            background: DesignTokens.setupButtonFill,
            border: DesignTokens.setupButtonBorder,
            cornerRadius: bounds.height / 2
        )
    }
}

/// 3-panel setup: Captures Folder → Accessibility → Screen Recording (VIB-303)
final class SetupWindowController: NSWindowController {

    // MARK: - State

    private var step1Done = false
    private var step2Done = false
    private var step3Done = false
    private var folderPath = ""
    private var isRerun: Bool

    // MARK: - UI refs

    private var panel1Container: NSView!
    private var panel2Container: NSView!
    private var panel3Container: NSView!
    private var footerContent: SetupFooterSurfaceView!
    private var badge1View: NSView!
    private var badge2View: NSView!
    private var badge3View: NSView!
    private var step1ActionRow: NSView!
    private var step1DoneArea: NSView!
    private var pathDisplay: NSTextField!
    private var step2ActionRow: NSView!
    private var step2Helper: NSTextField!
    private var step3ActionRow: NSView!
    private var step3RestartNote: NSTextField!
    private var status1: NSTextField!
    private var status2: NSTextField!
    private var status3: NSTextField!
    private var permissionTimer: Timer?
    private var divider1: NSView!
    private var divider2: NSView!
    private var footerBorderView: NSView!

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
        // VIB-332: Follow system appearance — no forced dark mode
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
        // VIB-332: Use SetupContentView to track appearance changes for layer color re-application
        let contentView = SetupContentView(frame: window?.contentView?.frame ?? .zero)
        contentView.wantsLayer = true
        window?.contentView = contentView
        contentView.onAppearanceChange = { [weak self] in self?.reapplyLayerColors() }
        guard let cv = window?.contentView else { return }
        cv.wantsLayer = true

        let winW = DesignTokens.setupWindowWidth
        let footerH = DesignTokens.setupFooterHeight
        let panelH = DesignTokens.setupPanelHeight
        let panelW = (winW - 2) / 3

        let panelsY = footerH

        // VIB-303: Panel 1: Captures folder (immediately active)
        panel1Container = NSView(frame: NSRect(x: 0, y: panelsY, width: panelW, height: panelH))
        buildPanel1(in: panel1Container)
        cv.addSubview(panel1Container)

        // Divider 1
        divider1 = makeDivider(x: panelW, y: panelsY, height: panelH)
        cv.addSubview(divider1)

        // VIB-303: Panel 2: Accessibility (locked until folder chosen)
        panel2Container = NSView(frame: NSRect(x: panelW + 1, y: panelsY, width: panelW, height: panelH))
        buildPanel2(in: panel2Container)
        cv.addSubview(panel2Container)
        panel2Container.alphaValue = 0.35

        // Divider 2
        divider2 = makeDivider(x: panelW * 2 + 1, y: panelsY, height: panelH)
        cv.addSubview(divider2)

        // VIB-303: Panel 3: Screen recording (locked until accessibility granted)
        panel3Container = NSView(frame: NSRect(x: panelW * 2 + 2, y: panelsY, width: panelW, height: panelH))
        buildPanel3(in: panel3Container)
        cv.addSubview(panel3Container)
        panel3Container.alphaValue = 0.35

        // Footer
        footerContent = SetupFooterSurfaceView(frame: NSRect(x: 0, y: 0, width: winW, height: footerH))
        cv.addSubview(footerContent)

        footerBorderView = makeDivider(x: 0, y: footerH - 1, height: 1)
        footerBorderView.frame.size.width = winW
        cv.addSubview(footerBorderView)

        updateFooter()
    }

    // MARK: - Panel 1: Captures folder (VIB-303)

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
        SettingsUI.styleSurface(
            pathDisplay,
            background: DesignTokens.setupFieldBg,
            border: DesignTokens.setupFieldBorder,
            cornerRadius: DesignTokens.setupPathBoxRadius
        )
        pathDisplay.frame = NSRect(x: pad, y: pathBoxY, width: contentW, height: 36)
        c.addSubview(pathDisplay)

        // Action row (choose folder)
        step1ActionRow = makeActionRow(label: "Choose folder…", action: #selector(chooseFolder), width: contentW)
        step1ActionRow.frame.origin = NSPoint(x: pad, y: 10)
        c.addSubview(step1ActionRow)

        // Step 1 done area: "Folder ready" + "Change folder" button
        // Aligned to match action row: label at y=54, button at y=10 within 72px container at y=10
        step1DoneArea = NSView(frame: NSRect(x: pad, y: 10, width: contentW, height: 72))
        step1DoneArea.isHidden = true

        let readyLabel = makeLabel("Folder ready", font: DesignTokens.setupStatusFont, color: DesignTokens.setupGreenText)
        readyLabel.alignment = .center
        readyLabel.frame = NSRect(x: 0, y: 54, width: contentW, height: 18)
        step1DoneArea.addSubview(readyLabel)

        let changeBtn = makeSmallPillButton("Change folder", green: true)
        changeBtn.target = self
        changeBtn.action = #selector(chooseFolder)
        let cbW = changeBtn.frame.width
        changeBtn.frame.origin = NSPoint(x: (contentW - cbW) / 2, y: 10)
        step1DoneArea.addSubview(changeBtn)

        c.addSubview(step1DoneArea)

        // Status label (hidden — action row starts visible) — aligned with action row label
        status1 = makeStatusLabel("", style: .gray)
        status1.frame = NSRect(x: pad, y: 64, width: contentW, height: 20)
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

        // Helper text — always positioned for stable layout, visibility toggled
        step2Helper = makeLabel("You may need to relaunch after granting.", font: DesignTokens.setupHelperFont, color: DesignTokens.setupTextDim)
        step2Helper.frame = NSRect(x: pad, y: desc.frame.origin.y - 14 - 14, width: contentW, height: 14)
        step2Helper.isHidden = true  // visible only when step 2 is active
        c.addSubview(step2Helper)

        // Action row
        step2ActionRow = makeActionRow(label: "Open Accessibility Settings", action: #selector(openAccessibilitySettings), width: contentW)
        step2ActionRow.frame.origin = NSPoint(x: pad, y: 10)
        step2ActionRow.isHidden = true
        c.addSubview(step2ActionRow)

        // Status label — aligned with action row label (y=64 from panel bottom)
        status2 = makeStatusLabel("Complete step 1 first", style: .gray)
        status2.frame = NSRect(x: pad, y: 64, width: contentW, height: 20)
        c.addSubview(status2)
    }

    // MARK: - Panel 3: Screen recording (VIB-303)

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

        // VIB-303: "Restart" note only on Screen recording panel
        step3RestartNote = makeLabel("You may need to restart the app after granting.", font: DesignTokens.setupHelperFont, color: DesignTokens.setupTextDim)
        step3RestartNote.frame = NSRect(x: pad, y: desc.frame.origin.y - 14 - 14, width: contentW, height: 14)
        step3RestartNote.isHidden = true  // visible only when step 3 is active
        c.addSubview(step3RestartNote)

        // Action row (label + arrow button)
        step3ActionRow = makeActionRow(label: "Open Screen Recording Settings", action: #selector(openSystemSettings), width: contentW)
        step3ActionRow.frame.origin = NSPoint(x: pad, y: 10)
        step3ActionRow.isHidden = true
        c.addSubview(step3ActionRow)

        // Status label — aligned with action row label (y=64 from panel bottom)
        status3 = makeStatusLabel("Complete step 2 first", style: .gray)
        status3.frame = NSRect(x: pad, y: 64, width: contentW, height: 20)
        c.addSubview(status3)
    }

    // MARK: - Step badge

    private enum BadgeState { case active, locked, done }

    private func makeStepBadge(num: Int, state: BadgeState) -> NSView {
        let size = DesignTokens.setupBadgeSize
        let view = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        view.wantsLayer = true

        let badgeRect = NSRect(x: 0, y: 0, width: size, height: size)
        switch state {
        case .done:
            SettingsUI.styleSurface(view, background: DesignTokens.setupGreenBadgeBg, border: DesignTokens.setupGreen, cornerRadius: size / 2, borderWidth: 2)
            let check = DesignTokens.makeCenteredTextField("✓", font: DesignTokens.setupBadgeCheckFont, color: DesignTokens.setupGreen, in: badgeRect)
            view.addSubview(check)
        case .locked:
            SettingsUI.styleSurface(view, background: DesignTokens.setupGrayBg, border: DesignTokens.setupGrayText, cornerRadius: size / 2, borderWidth: 2)
            let numLabel = DesignTokens.makeCenteredTextField("\(num)", font: DesignTokens.setupBadgeFont, color: DesignTokens.setupGrayText, in: badgeRect)
            view.addSubview(numLabel)
        case .active:
            SettingsUI.styleSurface(
                view,
                background: DesignTokens.setupButtonFill,
                border: DesignTokens.setupButtonBorder,
                cornerRadius: size / 2,
                borderWidth: 2
            )
            let numLabel = DesignTokens.makeCenteredTextField("\(num)", font: DesignTokens.setupBadgeFont, color: DesignTokens.setupButtonText, in: badgeRect)
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

        let labelBtn = NSButton(title: label, target: self, action: action)
        labelBtn.isBordered = false
        labelBtn.font = DesignTokens.setupActionLabelFont
        labelBtn.contentTintColor = DesignTokens.setupButtonText
        labelBtn.sizeToFit()

        let arrow = SetupCircleButton(title: "→", target: self, action: action)

        let stack = NSStackView(views: [labelBtn, arrow])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: row.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
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
        let role: SetupPillRole = green ? .success : .accent
        return SetupPillButton(
            title: title,
            role: role,
            height: DesignTokens.setupSmallPillHeight,
            font: DesignTokens.setupSmallPillFont,
            horizontalPadding: 20,
            target: nil,
            action: nil
        )
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
            let startBtn = SetupPillButton(
                title: "Start using Vibeliner \u{2192}",
                role: .success,
                height: 36,
                font: DesignTokens.setupActionLabelFont,
                horizontalPadding: 32,
                target: self,
                action: #selector(startClicked)
            )
            let btnW = startBtn.frame.width
            startBtn.frame.origin = NSPoint(x: winW - 24 - btnW, y: (DesignTokens.setupFooterHeight - 36) / 2)
            footerContent.addSubview(startBtn)

            // VIB-360: "Take a tour" ghost button, to the left of Start button
            let tourBtn = SetupPillButton(
                title: "Take a tour",
                role: .ghost,
                height: 36,
                font: DesignTokens.setupActionLabelFont,
                horizontalPadding: 24,
                target: self,
                action: #selector(tourClicked)
            )
            let tourBtnW = tourBtn.frame.width
            tourBtn.frame.origin = NSPoint(x: winW - 24 - btnW - 10 - tourBtnW, y: (DesignTokens.setupFooterHeight - 36) / 2)
            footerContent.addSubview(tourBtn)
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
        SettingsUI.styleSurface(group, background: DesignTokens.setupFieldBg, border: DesignTokens.setupFieldBorder, cornerRadius: groupH / 2)

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
        SettingsUI.styleSurface(pill, background: DesignTokens.setupKbdBg, border: DesignTokens.setupKbdBorder, cornerRadius: 5)
        label.frame = NSRect(x: 0, y: (h - label.frame.height) / 2, width: w, height: label.frame.height)
        pill.addSubview(label)
        return pill
    }

    // MARK: - Step completion

    // VIB-303: Step 1 = Captures folder chosen
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

        // Unlock panel 2
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel2Container.animator().alphaValue = 1.0
        }

        replaceBadge(&badge2View, num: 2, state: .active)
        step2ActionRow.isHidden = false
        step2Helper.isHidden = false
        status2.isHidden = true

        // If accessibility already granted, auto-complete step 2
        if AXIsProcessTrusted() {
            completeStep2()
        }

        checkCompletion()
    }

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
        step3RestartNote.isHidden = false
        status3.isHidden = true

        // If screen recording already granted, auto-complete step 3
        if CGPreflightScreenCaptureAccess() {
            completeStep3()
        }

        checkCompletion()
    }

    // VIB-303: Step 3 = Screen recording granted
    func completeStep3() {
        guard !step3Done else { return }
        step3Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel3Container.animator().alphaValue = 0.45
        }

        replaceBadge(&badge3View, num: 3, state: .done)
        step3ActionRow.isHidden = true
        step3RestartNote.isHidden = true
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

    /// VIB-332: Re-apply all layer-backed CGColors after an appearance change.
    /// Dynamic NSColor resolves correctly when .cgColor is called again.
    private func reapplyLayerColors() {
        window?.backgroundColor = DesignTokens.setupWindowBg
        SettingsUI.styleSurface(footerContent, background: DesignTokens.setupFooterBg, borderWidth: 0)
        if let divider1 { SettingsUI.styleDividerSurface(divider1, color: DesignTokens.setupBorder) }
        if let divider2 { SettingsUI.styleDividerSurface(divider2, color: DesignTokens.setupBorder) }
        if let footerBorderView { SettingsUI.styleDividerSurface(footerBorderView, color: DesignTokens.setupBorder) }
        SettingsUI.styleSurface(
            pathDisplay,
            background: DesignTokens.setupFieldBg,
            border: DesignTokens.setupFieldBorder,
            cornerRadius: DesignTokens.setupPathBoxRadius
        )
        // Rebuild footer (shortcut group, start button) with fresh colors
        updateFooter()
        // Rebuild badges with fresh colors for current state
        replaceBadge(&badge1View, num: 1, state: step1Done ? .done : .active)
        replaceBadge(&badge2View, num: 2, state: step2Done ? .done : (step1Done ? .active : .locked))
        replaceBadge(&badge3View, num: 3, state: step3Done ? .done : (step2Done ? .active : .locked))
    }

    // MARK: - Permission polling

    // VIB-303: Reordered — step 1 is folder (no polling), step 2 is accessibility, step 3 is screen recording
    private func startPermissionPolling() {
        // Immediate check: if re-running with valid folder, auto-complete step 1
        if isRerun && !folderPath.isEmpty && ConfigManager.shared.capturesFolderExists {
            completeStep1()
        }

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
            // VIB-303: Folder is now step 1
            self.completeStep1()
        }
    }

    @objc private func startClicked() {
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        permissionTimer?.invalidate()
        permissionTimer = nil
        window?.close()
    }

    /// VIB-360: Close setup (marking complete) and open the tour window
    @objc private func tourClicked() {
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        permissionTimer?.invalidate()
        permissionTimer = nil
        window?.close()
        DispatchQueue.main.async {
            TourWindowController.shared.showTour()
        }
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
        let d = SetupDividerView(frame: NSRect(x: x, y: y, width: 1, height: height))
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
