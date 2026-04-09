import AppKit

/// Pill-shaped header for a filmstrip image cell: editable title + role dropdown.
/// Background and border colors change based on the selected `ImageRole`.
/// VIB-295: Role-tinted backgrounds, single chevron, backdrop blur, tight alignment.
/// VIB-322: Dynamic role dropdown from ConfigManager.shared.roles.
final class TitlePillView: NSView, NSTextFieldDelegate {

    // MARK: - Callbacks

    var onTitleChanged: ((String) -> Void)?
    var onRoleChanged: ((ImageRole) -> Void)?

    // MARK: - State

    private(set) var role: ImageRole = .observed {
        didSet { updateColors() }
    }

    private var previousTitle: String = ""

    // MARK: - Subviews

    private let titleField: NSTextField = {
        let field = NSTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        field.textColor = NSColor(white: 1.0, alpha: 0.92)
        field.alignment = .left
        field.lineBreakMode = .byTruncatingTail
        field.cell?.truncatesLastVisibleLine = true
        field.cell?.isScrollable = false
        return field
    }()

    /// VIB-295/322: Popup with hidden arrows — items populated dynamically.
    private let rolePopUp: NSPopUpButton = {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.isBordered = false
        popup.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        (popup.cell as? NSPopUpButtonCell)?.arrowPosition = .noArrow
        popup.alignment = .right
        // VIB-335: White text for readability against opaque pill background
        popup.contentTintColor = NSColor(white: 1.0, alpha: 0.92)
        return popup
    }()

    /// VIB-295/330: Single down chevron label.
    private let chevronLabel: NSTextField = {
        let label = NSTextField(labelWithString: "▾")
        label.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        // VIB-335: White chevron for readability
        label.textColor = NSColor(white: 1.0, alpha: 0.92)
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        return label
    }()

    // MARK: - Init

    init(title: String = "Image 1", role: ImageRole = .observed) {
        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: DesignTokens.titlePillHeight))
        self.role = role
        self.previousTitle = title

        wantsLayer = true
        layer?.masksToBounds = false

        // Shadow
        shadow = NSShadow()
        layer?.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.12).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowOffset = CGSize(width: 0, height: -3)
        layer?.shadowRadius = 10

        titleField.stringValue = title
        titleField.delegate = self
        addSubview(titleField)

        rolePopUp.target = self
        rolePopUp.action = #selector(roleChanged(_:))
        addSubview(rolePopUp)

        addSubview(chevronLabel)

        reloadRoleItems()
        rolePopUp.selectItem(at: roleIndex(for: role))
        updateColors()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        let h = bounds.height
        let cornerRadius = h / 2
        layer?.cornerRadius = cornerRadius
        layer?.borderWidth = 2
        layer?.masksToBounds = true

        let roles = ConfigManager.shared.roles

        if roles.count <= 1 {
            // 0 or 1 role: no dropdown, title fills width
            let titleX: CGFloat = 10
            let titleW = bounds.width - titleX - 10
            titleField.sizeToFit()
            let titleH = titleField.frame.height
            let titleY = (h - titleH) / 2
            titleField.frame = NSRect(x: titleX, y: titleY, width: max(titleW, 30), height: titleH)
        } else {
            // 2+ roles: chevron on far right, popup left of chevron, title fills remainder
            chevronLabel.sizeToFit()
            let chevronW = chevronLabel.frame.width
            let chevronX = bounds.width - chevronW - 8
            let chevronH = chevronLabel.frame.height
            let chevronY = (h - chevronH) / 2
            chevronLabel.frame = NSRect(x: chevronX, y: chevronY, width: chevronW, height: chevronH)

            rolePopUp.sizeToFit()
            let popupW = rolePopUp.frame.width
            let popupH = rolePopUp.frame.height
            let popupX = chevronX - popupW - 4
            let popupY = (h - popupH) / 2
            rolePopUp.frame = NSRect(x: popupX, y: popupY, width: popupW, height: popupH)

            let titleX: CGFloat = 10
            let titleW = popupX - titleX - 2
            titleField.sizeToFit()
            let titleH = titleField.frame.height
            let titleY = (h - titleH) / 2
            titleField.frame = NSRect(x: titleX, y: titleY, width: max(titleW, 30), height: titleH)
        }
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: max(100, frame.width), height: DesignTokens.titlePillHeight)
    }

    // MARK: - Public API

    func configure(title: String, role: ImageRole) {
        previousTitle = title
        titleField.stringValue = title
        self.role = role
        reloadRoleItems()
        rolePopUp.selectItem(at: roleIndex(for: role))
    }

    // MARK: - Dynamic role items

    private func reloadRoleItems() {
        rolePopUp.removeAllItems()
        let roles = ConfigManager.shared.roles

        if roles.isEmpty {
            // No roles configured — hide role UI entirely
            rolePopUp.isHidden = true
            chevronLabel.isHidden = true
        } else if roles.count == 1 {
            // Single role — show as static text, no dropdown
            rolePopUp.addItem(withTitle: roles[0].name)
            rolePopUp.isEnabled = false
            rolePopUp.isHidden = false
            chevronLabel.isHidden = true
        } else {
            // 2+ roles — full dropdown
            rolePopUp.isHidden = false
            rolePopUp.isEnabled = true
            chevronLabel.isHidden = false
            for r in roles {
                rolePopUp.addItem(withTitle: r.name)
            }
        }
        needsLayout = true
    }

    // MARK: - Role change

    @objc private func roleChanged(_ sender: NSPopUpButton) {
        let roles = ConfigManager.shared.roles
        let idx = sender.indexOfSelectedItem
        guard idx >= 0, idx < roles.count else { return }
        let newRole = ImageRole(name: roles[idx].name)
        role = newRole
        onRoleChanged?(newRole)
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidEndEditing(_ obj: Notification) {
        let text = titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            titleField.stringValue = previousTitle
        } else {
            previousTitle = text
            onTitleChanged?(text)
        }
    }

    // MARK: - Colors

    private func updateColors() {
        let hex = role.colorHex
        let bgColor = DesignTokens.roleBgColor(forHex: hex)
        let borderColor = DesignTokens.roleColor(forHex: hex)

        layer?.backgroundColor = bgColor.cgColor
        layer?.borderColor = borderColor.cgColor
        needsLayout = true
        needsDisplay = true
    }

    // MARK: - Helpers

    private func roleIndex(for role: ImageRole) -> Int {
        let roles = ConfigManager.shared.roles
        return roles.firstIndex(where: { $0.name.lowercased() == role.name.lowercased() }) ?? 0
    }
}
