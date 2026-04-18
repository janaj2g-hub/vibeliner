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

        let title = makeLabel("Captures folder", font: DesignTokens.fontTitle, color: DesignTokens.setupTextPrimary)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: contentW - 44, height: 22)
        c.addSubview(title)

        let desc = makeWrappingLabel("Choose where Vibeliner saves screenshots and prompts.", font: DesignTokens.fontBody, color: DesignTokens.setupTextSecondary, width: contentW)
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
        centeredCell.font = DesignTokens.fontMonoBody
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

        let readyLabel = makeLabel("Folder ready", font: DesignTokens.fontLabel, color: DesignTokens.setupGreenText)
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

        let title = makeLabel("Accessibility", font: DesignTokens.fontTitle, color: DesignTokens.setupTextPrimary)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: contentW - 44, height: 22)
        c.addSubview(title)

        let desc = makeWrappingLabel("Vibeliner needs accessibility permission so the capture hotkey works from any app.", font: DesignTokens.fontBody, color: DesignTokens.setupTextSecondary, width: contentW)
        desc.frame.origin = NSPoint(x: pad, y: h - pad - DesignTokens.setupBadgeSize - 18 - desc.frame.height)
        c.addSubview(desc)

        // Helper text — always positioned for stable layout, visibility toggled
        step2Helper = makeLabel("You may need to relaunch after granting.", font: DesignTokens.fontCaption, color: DesignTokens.setupTextDim)
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

        let title = makeLabel("Screen recording", font: DesignTokens.fontTitle, color: DesignTokens.setupTextPrimary)
        title.frame = NSRect(x: pad + 44, y: h - pad - 28, width: contentW - 44, height: 22)
        c.addSubview(title)

        let desc = makeWrappingLabel("Vibeliner needs screen recording permission to capture screenshots of your running app.", font: DesignTokens.fontBody, color: DesignTokens.setupTextSecondary, width: contentW)
        desc.frame.origin = NSPoint(x: pad, y: h - pad - DesignTokens.setupBadgeSize - 18 - desc.frame.height)
        c.addSubview(desc)

        // VIB-303: "Restart" note only on Screen recording panel
        step3RestartNote = makeWrappingLabel(
            "You may need to restart the app after granting.",
            font: DesignTokens.fontCaption,
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

}
