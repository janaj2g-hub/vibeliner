import AppKit

/// Pill-shaped header for a filmstrip image cell: editable title + role dropdown.
/// Background and border colors change based on the selected `ImageRole`.
/// VIB-295: Role-tinted backgrounds, single ▾ chevron, backdrop blur, tight alignment.
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

    /// VIB-295: Backdrop blur behind the pill for readability against varying screenshot backgrounds.
    private let blurView: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        return view
    }()

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

    /// VIB-295: Standard popup with hidden arrows — single ▾ chevron added separately.
    private let rolePopUp: NSPopUpButton = {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.isBordered = false
        popup.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        (popup.cell as? NSPopUpButtonCell)?.arrowPosition = .noArrow
        popup.addItems(withTitles: [
            ImageRole.observed.displayName,
            ImageRole.expected.displayName,
            ImageRole.reference.displayName,
        ])
        return popup
    }()

    /// VIB-295: Single down chevron label positioned tight to the right of role text.
    private let chevronLabel: NSTextField = {
        let label = NSTextField(labelWithString: "▾")
        label.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        label.textColor = NSColor(white: 1.0, alpha: 0.6)
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

        // VIB-295: Backdrop blur for readability
        addSubview(blurView)

        titleField.stringValue = title
        titleField.delegate = self
        addSubview(titleField)

        rolePopUp.selectItem(at: roleIndex(for: role))
        rolePopUp.target = self
        rolePopUp.action = #selector(roleChanged(_:))
        addSubview(rolePopUp)

        addSubview(chevronLabel)

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
        layer?.borderWidth = 1

        // Backdrop blur fills the pill shape
        blurView.frame = bounds
        blurView.layer?.cornerRadius = cornerRadius
        blurView.layer?.masksToBounds = true

        // VIB-295: Chevron on the far right
        chevronLabel.sizeToFit()
        let chevronW = chevronLabel.frame.width
        let chevronX = bounds.width - chevronW - 8
        let chevronH = chevronLabel.frame.height
        let chevronY = (h - chevronH) / 2
        chevronLabel.frame = NSRect(x: chevronX, y: chevronY, width: chevronW, height: chevronH)

        // VIB-295: Role popup right-aligned, tight to the chevron
        rolePopUp.sizeToFit()
        let popupW = rolePopUp.frame.width
        let popupH = rolePopUp.frame.height
        let popupX = chevronX - popupW + 2  // overlap slightly for tight spacing
        let popupY = (h - popupH) / 2
        rolePopUp.frame = NSRect(x: popupX, y: popupY, width: popupW, height: popupH)

        // VIB-295: Title text left-padded 10px, fills remaining space up to the role popup
        let titleX: CGFloat = 10
        let titleW = popupX - titleX - 2
        let titleH: CGFloat = 16
        let titleY = (h - titleH) / 2
        titleField.frame = NSRect(x: titleX, y: titleY, width: max(titleW, 30), height: titleH)
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: max(100, frame.width), height: DesignTokens.titlePillHeight)
    }

    // MARK: - Public API

    func configure(title: String, role: ImageRole) {
        previousTitle = title
        titleField.stringValue = title
        self.role = role
        rolePopUp.selectItem(at: roleIndex(for: role))
    }

    // MARK: - Role change

    @objc private func roleChanged(_ sender: NSPopUpButton) {
        let newRole: ImageRole
        switch sender.indexOfSelectedItem {
        case 0: newRole = .observed
        case 1: newRole = .expected
        case 2: newRole = .reference
        default: newRole = .observed
        }
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
        let bgColor: NSColor
        let borderColor: NSColor

        switch role {
        case .observed:
            bgColor = DesignTokens.roleObservedBg
            borderColor = DesignTokens.roleObservedBorder
        case .expected:
            bgColor = DesignTokens.roleExpectedBg
            borderColor = DesignTokens.roleExpectedBorder
        case .reference:
            bgColor = DesignTokens.roleReferenceBg
            borderColor = DesignTokens.roleReferenceBorder
        }

        layer?.backgroundColor = bgColor.cgColor
        layer?.borderColor = borderColor.cgColor
        needsLayout = true
        needsDisplay = true
    }

    // MARK: - Helpers

    private func roleIndex(for role: ImageRole) -> Int {
        switch role {
        case .observed: return 0
        case .expected: return 1
        case .reference: return 2
        }
    }
}
