import AppKit

extension PromptTabView {

    // MARK: - Helpers

    /// Finds the NSTextView inside an editor container (container → scroll → textView).
    func findTextView(in container: NSView) -> NSTextView? {
        for sub in container.subviews {
            if let scroll = sub as? NSScrollView {
                return scroll.documentView as? NSTextView
            }
        }
        return nil
    }

    func applyColorDotStyle(_ dot: NSButton, color: NSColor, isSelected: Bool, in view: NSView) {
        dot.layer?.backgroundColor = color.cgColor
        dot.layer?.borderWidth = isSelected ? 2.5 : 1.0
        view.effectiveAppearance.performAsCurrentDrawingAppearance {
            dot.layer?.borderColor = (isSelected ? DesignTokens.roleSwatchSelectedRing : DesignTokens.roleSwatchOutline).cgColor
            dot.layer?.shadowColor = DesignTokens.roleSwatchSelectedRing.withAlphaComponent(0.26).cgColor
        }
        dot.layer?.shadowOpacity = isSelected ? 1.0 : 0.0
        dot.layer?.shadowRadius = isSelected ? 4 : 0
        dot.layer?.shadowOffset = .zero
    }

    /// Creates an editable text box with visible field surface styling.
    /// Returns a wrapper NSView (not the scroll view directly) so the
    /// rounded-rect background and border are visible around the editor.
    func makeEditor(text: String) -> NSView {
        // Outer container provides the visible field surface (bg + border + radius)
        let container = AppearanceAwareFieldView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Scroll view inside the container
        let scroll = NSScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.hasHorizontalScroller = false
        scroll.borderType = .noBorder
        container.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
        ])

        // Text view
        let textView = NSTextView()
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .labelColor
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.string = text
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.insertionPointColor = DesignTokens.purpleLight

        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false

        scroll.documentView = textView

        return container
    }

    static let toolRowHeight: CGFloat = 40

    func makeToolRow(definition: AnnotationToolDefinition) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let icon = ToolIconView(tool: definition.type)
        let nameLabel = SettingsUI.regularLabel(definition.displayName)
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

        let field = SettingsTextField()
        field.stringValue = drafts.toolDescriptions[definition.label] ?? ""
        field.delegate = self
        field.identifier = NSUserInterfaceItemIdentifier(definition.label)
        field.translatesAutoresizingMaskIntoConstraints = false
        toolFields[definition.label] = field

        row.addSubview(icon)
        row.addSubview(nameLabel)
        row.addSubview(field)

        icon.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),

            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),
            icon.heightAnchor.constraint(equalToConstant: DesignTokens.settingsFieldHeight),

            nameLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            nameLabel.widthAnchor.constraint(equalToConstant: 80),

            field.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 14),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.heightAnchor.constraint(equalToConstant: Self.toolRowHeight),
        ])

        return row
    }

    func toolRows() -> [AnnotationToolDefinition] {
        AnnotationToolType.promptExportDefinitions
    }

    // MARK: - Data

    func captureActiveDrafts() {
        switch activeSubTab {
        case .preamble:
            drafts.preamble = preambleEditor?.string ?? drafts.preamble
        case .tools:
            for (key, field) in toolFields {
                drafts.toolDescriptions[key] = field.stringValue
            }
        case .footer:
            drafts.footer = footerEditor?.string ?? drafts.footer
        case .multiImage:
            // Role drafts are updated in real-time via field delegates
            break
        }
    }

    func refreshPreview() {
        let isDirty = hasUnsavedChanges
        previewView.refresh(
            preamble: drafts.preamble,
            footer: drafts.footer,
            toolDescriptions: drafts.toolDescriptions,
            roles: drafts.roles,
            isDirty: isDirty
        )
        updateDraftStateUI(isDirty: isDirty)
    }

    @objc func saveAllPromptSections() {
        captureActiveDrafts()
        ConfigManager.shared.preamble = drafts.preamble
        ConfigManager.shared.footer = drafts.footer
        ConfigManager.shared.toolDescriptions = drafts.toolDescriptions
        ConfigManager.shared.roles = drafts.roles
        ConfigManager.shared.save()
        refreshPreview()
    }

    @objc func resetCurrentPromptSection() {
        switch activeSubTab {
        case .preamble:
            drafts.preamble = Self.defaultPreamble
            preambleEditor?.string = Self.defaultPreamble
        case .tools:
            drafts.toolDescriptions = Self.defaultToolDescriptions
            for (key, value) in Self.defaultToolDescriptions {
                toolFields[key]?.stringValue = value
            }
        case .footer:
            drafts.footer = Self.defaultFooter
            footerEditor?.string = Self.defaultFooter
        case .multiImage:
            drafts.roles = RoleConfig.defaultRoles
            selectSubTab(.multiImage)
        }
        refreshPreview()
    }

    // MARK: - NSTextViewDelegate / NSTextFieldDelegate

    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView {
            if textView === preambleEditor {
                drafts.preamble = textView.string
            } else if textView === footerEditor {
                drafts.footer = textView.string
            }
            textView.breakUndoCoalescing()
            refreshPreview()
        }
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSTextField,
              let key = field.identifier?.rawValue else { return }
        if key.hasPrefix("rolename_"), let idx = Int(key.dropFirst(9)) {
            guard idx < drafts.roles.count else { return }
            drafts.roles[idx].name = field.stringValue
        } else if key.hasPrefix("roledesc_"), let idx = Int(key.dropFirst(9)) {
            guard idx < drafts.roles.count else { return }
            drafts.roles[idx].description = field.stringValue
        } else {
            drafts.toolDescriptions[key] = field.stringValue
        }
        (field.currentEditor() as? NSTextView)?.breakUndoCoalescing()
        refreshPreview()
    }

    // MARK: - Defaults

    static let defaultPreamble = "This is a screenshot of my running app. View it at [Screenshot Path]\n\n[Tool Description] Each annotation has a number and a description.\n\nFix each issue:"

    static let defaultFooter = "Make the changes and verify they match the design."

    static let defaultToolDescriptions = AnnotationToolType.defaultPromptDescriptions

    var hasUnsavedChanges: Bool {
        drafts != PromptDrafts.current()
    }

    func updateDraftStateUI(isDirty: Bool? = nil) {
        let dirty = isDirty ?? hasUnsavedChanges
        draftStateView.setState(dirty ? .unsaved : .saved)
        draftHelperLabel.stringValue = dirty
            ? "Changes below stay in a draft until you click Save. The preview already reflects the draft values."
            : "These prompt settings are saved and currently used for copy, export, and prompt.txt."
        saveButton.isEnabled = dirty
        saveButton.alphaValue = dirty ? 1.0 : 0.7
    }

}

