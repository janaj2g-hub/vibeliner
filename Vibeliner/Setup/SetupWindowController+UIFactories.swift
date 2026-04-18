import AppKit

extension SetupWindowController {

    // MARK: - Step badge

    enum BadgeState { case active, locked, done }

    func makeStepBadge(num: Int, state: BadgeState) -> NSView {
        let size = DesignTokens.setupBadgeSize
        let view = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        view.wantsLayer = true

        let badgeRect = NSRect(x: 0, y: 0, width: size, height: size)
        switch state {
        case .done:
            SettingsUI.styleSurface(view, background: DesignTokens.setupGreenBadgeBg, border: DesignTokens.setupGreen, cornerRadius: size / 2)
            let check = DesignTokens.makeCenteredTextField("✓", font: DesignTokens.fontTitle, color: DesignTokens.setupGreen, in: badgeRect)
            view.addSubview(check)
        case .locked:
            SettingsUI.styleSurface(view, background: DesignTokens.setupGrayBg, border: DesignTokens.setupGrayText, cornerRadius: size / 2)
            let numLabel = DesignTokens.makeCenteredTextField("\(num)", font: DesignTokens.fontNumberLg, color: DesignTokens.setupGrayText, in: badgeRect)
            view.addSubview(numLabel)
        case .active:
            SettingsUI.styleSurface(
                view,
                background: DesignTokens.pillButtonBg,
                border: DesignTokens.pillButtonBorder,
                cornerRadius: size / 2
            )
            let numLabel = DesignTokens.makeCenteredTextField("\(num)", font: DesignTokens.fontNumberLg, color: DesignTokens.pillButtonText, in: badgeRect)
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
        labelBtn.font = DesignTokens.fontLabel
        labelBtn.contentTintColor = DesignTokens.pillButtonText
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
        label.font = DesignTokens.fontLabel
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
            font: DesignTokens.fontLabelSm,
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
        } else {
            let msg = makeLabel("Complete all steps to continue", font: DesignTokens.fontBody, color: DesignTokens.setupGrayText)
            msg.frame.origin = NSPoint(x: winW - 24 - msg.frame.width, y: (DesignTokens.setupFooterHeight - msg.frame.height) / 2)
            footerContent.addSubview(msg)
        }
    }

    func buildShortcutGroup() -> NSView {
        // Build all children first to measure total width
        let hint = makeLabel("Shortcut:", font: DesignTokens.fontBody, color: DesignTokens.setupTextSecondary)
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
        SettingsUI.styleSurface(group, background: .clear, cornerRadius: groupH / 2)

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
        let label = makeLabel(text, font: DesignTokens.fontLabelSm, color: DesignTokens.setupKbdText)
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
