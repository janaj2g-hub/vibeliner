import AppKit

extension SetupWindowController {

    // MARK: - Panel 1: Captures folder (VIB-303)

    func buildPanel1(in c: NSView) {
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

    func buildPanel2(in c: NSView) {
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

    func buildPanel3(in c: NSView) {
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
        step3RestartNote = makeWrappingLabel(
            "You may need to restart the app after granting.",
            font: DesignTokens.setupHelperFont,
            color: DesignTokens.setupTextDim,
            width: contentW
        )
        step3RestartNote.alignment = .center
        step3RestartNote.frame.origin = NSPoint(x: pad, y: desc.frame.origin.y - 14 - step3RestartNote.frame.height)
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

    enum BadgeState { case active, locked, done }

    func makeStepBadge(num: Int, state: BadgeState) -> NSView {
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

    func replaceBadge(_ badgeRef: inout NSView!, num: Int, state: BadgeState) {
        let newBadge = makeStepBadge(num: num, state: state)
        newBadge.frame = badgeRef.frame
        badgeRef.superview?.addSubview(newBadge)
        badgeRef.removeFromSuperview()
        badgeRef = newBadge
    }

    // MARK: - Action row (label + arrow)

    func makeActionRow(label: String, action: Selector, width: CGFloat) -> NSView {
        let rowH: CGFloat = 72
        let row = NSView(frame: NSRect(x: 0, y: 0, width: width, height: rowH))

        let labelBtn = NSButton(title: label, target: self, action: action)
        labelBtn.isBordered = false
        labelBtn.wantsLayer = true
        labelBtn.font = DesignTokens.setupActionLabelFont
        labelBtn.contentTintColor = DesignTokens.setupButtonText
        labelBtn.sizeToFit()
        let labelW = labelBtn.frame.width
        labelBtn.frame = NSRect(x: (width - labelW) / 2, y: rowH - 18, width: labelW, height: 18)
        row.addSubview(labelBtn)

        let arrow = SetupCircleButton(title: "→", target: self, action: action)
        let arrowSize = DesignTokens.setupArrowSize
        arrow.frame = NSRect(
            x: (width - arrowSize) / 2,
            y: rowH - 18 - 8 - arrowSize,
            width: arrowSize,
            height: arrowSize
        )
        row.addSubview(arrow)
        return row
    }

    // MARK: - Status label

    enum StatusStyle { case amber, green, gray }

    func makeStatusLabel(_ text: String, style: StatusStyle) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = DesignTokens.setupStatusFont
        label.alignment = .center
        applyStatusStyle(label, style: style)
        return label
    }

    func applyStatusStyle(_ label: NSTextField, style: StatusStyle) {
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

    func makeSmallPillButton(_ title: String, green: Bool) -> NSButton {
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

    func updateFooter() {
        for sv in footerContent.subviews { sv.removeFromSuperview() }
        let winW = DesignTokens.setupWindowWidth

        if step1Done && step2Done && step3Done {
            // Left: Shortcut group in pill container
            let shortcutGroup = buildShortcutGroup()
            shortcutGroup.frame.origin = NSPoint(x: 24, y: (DesignTokens.setupFooterHeight - shortcutGroup.frame.height) / 2)
            footerContent.addSubview(shortcutGroup)

            // Right: Green "Start using Vibeliner →" button
            let startBtn = SetupFooterButton(
                title: "Start using Vibeliner \u{2192}",
                role: .success,
                target: self,
                action: #selector(startClicked)
            )
            let btnW = startBtn.frame.width
            startBtn.frame.origin = NSPoint(
                x: winW - 24 - btnW,
                y: (DesignTokens.setupFooterHeight - DesignTokens.setupFooterButtonHeight) / 2
            )
            footerContent.addSubview(startBtn)

            // VIB-360: "Take a tour" ghost button, to the left of Start button
            let tourBtn = SetupFooterButton(
                title: "Take a tour",
                role: .ghost,
                target: self,
                action: #selector(tourClicked)
            )
            let tourBtnW = tourBtn.frame.width
            tourBtn.frame.origin = NSPoint(
                x: winW - 24 - btnW - 10 - tourBtnW,
                y: (DesignTokens.setupFooterHeight - DesignTokens.setupFooterButtonHeight) / 2
            )
            footerContent.addSubview(tourBtn)
        } else {
            let msg = makeLabel("Complete all steps to continue", font: DesignTokens.setupDescFont, color: DesignTokens.setupGrayText)
            msg.frame.origin = NSPoint(x: winW - 24 - msg.frame.width, y: (DesignTokens.setupFooterHeight - msg.frame.height) / 2)
            footerContent.addSubview(msg)
        }
    }

    func buildShortcutGroup() -> NSView {
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

    func makeKbdPill(_ text: String) -> NSView {
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

}
