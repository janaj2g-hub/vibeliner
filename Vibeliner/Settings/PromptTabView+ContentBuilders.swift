import AppKit

extension PromptTabView {

    // MARK: - Sub-tab switching

    func selectSubTab(_ tab: PromptSubTab, syncDrafts: Bool = true) {
        if syncDrafts { captureActiveDrafts() }

        activeSubTab = tab
        if segmentedControl.selectedIndex != tab.rawValue {
            segmentedControl.setSelectedIndex(tab.rawValue)
        }

        activeContentStack.arrangedSubviews.forEach { view in
            activeContentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        toolFields.removeAll()
        roleFields.removeAll()
        preambleEditor = nil
        footerEditor = nil

        switch tab {
        case .preamble:   buildPreambleContent()
        case .tools:      buildToolsContent()
        case .footer:     buildFooterContent()
        case .multiImage: buildMultiImageContent()
        }
    }

    func buildPreambleContent() {
        let description = SettingsUI.bodyCopy(
            "Text before the annotation list. [Screenshot Path] inserts the image path. "
            + "[Tool Description] auto-generates based on tools used."
        )
        let editor = makeEditor(text: drafts.preamble)
        preambleEditor = findTextView(in: editor)
        preambleEditor?.delegate = self
        preambleEditor?.setAccessibilityLabel("Preamble text editor")
        preambleEditor?.setAccessibilityRole(.textArea)

        activeContentStack.addArrangedSubview(description)
        activeContentStack.addArrangedSubview(editor)

        NSLayoutConstraint.activate([
            editor.heightAnchor.constraint(equalToConstant: 140),
            editor.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor),
        ])
    }

    func buildToolsContent() {
        let description = SettingsUI.bodyCopy(
            "Each tool's description feeds into [Tool Description] when that tool is used. "
            + "The tool type also appears in brackets next to each annotation."
        )
        activeContentStack.addArrangedSubview(description)

        let rowsStack = NSStackView()
        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = 10
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        activeContentStack.addArrangedSubview(rowsStack)

        for definition in toolRows() {
            let row = makeToolRow(definition: definition)
            rowsStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor).isActive = true
        }
    }

    func buildFooterContent() {
        let description = SettingsUI.bodyCopy("Text after the annotation list. Leave empty for no footer.")
        let editor = makeEditor(text: drafts.footer)
        footerEditor = findTextView(in: editor)
        footerEditor?.delegate = self
        footerEditor?.setAccessibilityLabel("Footer text editor")
        footerEditor?.setAccessibilityRole(.textArea)

        activeContentStack.addArrangedSubview(description)
        activeContentStack.addArrangedSubview(editor)

        NSLayoutConstraint.activate([
            editor.heightAnchor.constraint(equalToConstant: 100),
            editor.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor),
        ])
    }

    func buildMultiImageContent() {
        let description = SettingsUI.bodyCopy(
            "Configure roles for multi-image prompts. Each role has a name, description, and color."
        )
        activeContentStack.addArrangedSubview(description)

        let rowsStack = NSStackView()
        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.spacing = 10
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        activeContentStack.addArrangedSubview(rowsStack)

        for (i, role) in drafts.roles.enumerated() {
            let row = makeDynamicRoleRow(index: i, role: role)
            rowsStack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor).isActive = true
        }

        // VIB-448: "+ Add role" button — aligned with description fields
        let addBtnRow = NSView()
        addBtnRow.translatesAutoresizingMaskIntoConstraints = false
        let addBtn = SettingsPillButton(title: drafts.roles.count >= 10 ? "Maximum 10 roles" : "+ Add role", target: self, action: #selector(addRoleClicked))
        addBtn.isEnabled = drafts.roles.count < 10
        addBtn.translatesAutoresizingMaskIntoConstraints = false
        addBtnRow.addSubview(addBtn)
        // Leading offset: swatch(8+16+12) + nameField(120+10) = 166
        NSLayoutConstraint.activate([
            addBtnRow.heightAnchor.constraint(equalToConstant: DesignTokens.settingsPillHeight),
            addBtn.leadingAnchor.constraint(equalTo: addBtnRow.leadingAnchor, constant: 166),
            addBtn.trailingAnchor.constraint(equalTo: addBtnRow.trailingAnchor, constant: -30),
            addBtn.centerYAnchor.constraint(equalTo: addBtnRow.centerYAnchor),
        ])
        activeContentStack.addArrangedSubview(addBtnRow)
        addBtnRow.widthAnchor.constraint(equalTo: activeContentStack.widthAnchor).isActive = true
    }

    func makeDynamicRoleRow(index: Int, role: RoleConfig) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let swatchColor = DesignTokens.roleColor(forHex: role.colorHex)
        let swatch = RoleSwatchView(color: swatchColor)
        swatch.onClicked = { [weak self] swatchView in
            self?.showColorPopover(for: index, swatch: swatchView)
        }

        let nameField = SettingsTextField()
        nameField.stringValue = role.name
        nameField.placeholderString = "Role name"
        nameField.delegate = self
        nameField.identifier = NSUserInterfaceItemIdentifier("rolename_\(index)")
        nameField.translatesAutoresizingMaskIntoConstraints = false

        let descField = SettingsTextField()
        descField.stringValue = role.description
        descField.placeholderString = "Description for LLM prompt"
        descField.delegate = self
        descField.identifier = NSUserInterfaceItemIdentifier("roledesc_\(index)")
        descField.translatesAutoresizingMaskIntoConstraints = false

        let deleteBtn = NSButton(title: "×", target: self, action: #selector(deleteRoleClicked(_:)))
        deleteBtn.tag = index
        deleteBtn.isBordered = false
        deleteBtn.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        deleteBtn.contentTintColor = .tertiaryLabelColor
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(swatch)
        row.addSubview(nameField)
        row.addSubview(descField)
        row.addSubview(deleteBtn)

        swatch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),

            swatch.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 8),
            swatch.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            swatch.widthAnchor.constraint(equalToConstant: 16),
            swatch.heightAnchor.constraint(equalToConstant: 16),

            // VIB-391: Increased spacing for better visual separation
            nameField.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 12),
            nameField.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            nameField.widthAnchor.constraint(equalToConstant: 120),
            nameField.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),

            descField.leadingAnchor.constraint(equalTo: nameField.trailingAnchor, constant: 10),
            descField.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            descField.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),

            deleteBtn.leadingAnchor.constraint(equalTo: descField.trailingAnchor, constant: 8),
            deleteBtn.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            deleteBtn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            deleteBtn.widthAnchor.constraint(equalToConstant: 22),
        ])

        return row
    }

    @objc func addRoleClicked() {
        guard drafts.roles.count < 10 else { return }
        // Pick next unused preset color, cycling through all 8
        let usedHexes = Set(drafts.roles.map { $0.colorHex.lowercased() })
        let nextColor = DesignTokens.rolePresetColors.first { !usedHexes.contains($0.hex.lowercased()) }?.hex
            ?? DesignTokens.rolePresetColors[drafts.roles.count % DesignTokens.rolePresetColors.count].hex
        drafts.roles.append(RoleConfig(name: "New role", description: "", colorHex: nextColor))
        selectSubTab(.multiImage)
        refreshPreview()
    }

    @objc func deleteRoleClicked(_ sender: NSButton) {
        let index = sender.tag
        guard index < drafts.roles.count else { return }
        drafts.roles.remove(at: index)
        selectSubTab(.multiImage)
        refreshPreview()
    }

    // activeColorPopover moved to main PromptTabView class

    func showColorPopover(for roleIndex: Int, swatch: RoleSwatchView) {
        // Dismiss any existing popover
        activeColorPopover?.close()
        activeColorPopover = nil

        let popover = NSPopover()
        popover.behavior = .transient
        // VIB-389: Fast popover — no animation delay
        popover.animates = false

        // Build content: color circles in a single row
        let contentView = NSView()
        contentView.wantsLayer = true
        let dotSize: CGFloat = 22
        let gap: CGFloat = 6
        let padding: CGFloat = 10
        let totalWidth = CGFloat(DesignTokens.rolePresetColors.count) * dotSize + CGFloat(DesignTokens.rolePresetColors.count - 1) * gap + padding * 2
        let totalHeight = dotSize + padding * 2
        contentView.frame = NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight)

        for (colorIdx, preset) in DesignTokens.rolePresetColors.enumerated() {
            let dot = NSButton(frame: NSRect(
                x: padding + CGFloat(colorIdx) * (dotSize + gap),
                y: padding,
                width: dotSize,
                height: dotSize
            ))
            // VIB-389: Clear title to prevent "Bu" text from NSButton default
            dot.title = ""
            dot.isBordered = false
            dot.wantsLayer = true
            dot.layer?.cornerRadius = dotSize / 2
            let isSelected = preset.hex.lowercased() == drafts.roles[roleIndex].colorHex.lowercased()
            applyColorDotStyle(dot, color: preset.color, isSelected: isSelected, in: contentView)
            dot.target = self
            dot.action = #selector(colorPopoverDotClicked(_:))
            dot.tag = roleIndex * 100 + colorIdx
            contentView.addSubview(dot)
        }

        let vc = NSViewController()
        vc.view = contentView
        vc.preferredContentSize = NSSize(width: totalWidth, height: totalHeight)
        popover.contentViewController = vc
        activeColorPopover = popover

        popover.show(relativeTo: swatch.bounds, of: swatch, preferredEdge: .minY)
    }

    @objc func colorPopoverDotClicked(_ sender: NSButton) {
        let roleIndex = sender.tag / 100
        let colorIndex = sender.tag % 100
        guard roleIndex < drafts.roles.count, colorIndex < DesignTokens.rolePresetColors.count else { return }
        drafts.roles[roleIndex].colorHex = DesignTokens.rolePresetColors[colorIndex].hex

        // VIB-391: Update selection indicators in the popover WITHOUT closing it.
        // The popover stays open so the user can try different colors.
        // It closes on outside click because behavior = .transient.
        if let contentView = activeColorPopover?.contentViewController?.view {
            for subview in contentView.subviews {
                guard let dot = subview as? NSButton else { continue }
                let ci = dot.tag % 100
                let isNowSelected = ci == colorIndex && dot.tag / 100 == roleIndex
                applyColorDotStyle(
                    dot,
                    color: DesignTokens.rolePresetColors[ci].color,
                    isSelected: isNowSelected,
                    in: contentView
                )
            }
        }

        selectSubTab(.multiImage)
        refreshPreview()
    }

}
