import AppKit

/// Pill-shaped header for a filmstrip image cell: editable title + role dropdown.
/// Background and border colors change based on the selected `ImageRole`.
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
        field.textColor = .white
        field.alignment = .left
        field.lineBreakMode = .byTruncatingTail
        field.cell?.truncatesLastVisibleLine = true
        field.cell?.isScrollable = false
        return field
    }()

    private let rolePopUp: NSPopUpButton = {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.isBordered = false
        popup.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        (popup.cell as? NSPopUpButtonCell)?.arrowPosition = .arrowAtBottom
        popup.addItems(withTitles: [
            ImageRole.observed.displayName,
            ImageRole.expected.displayName,
            ImageRole.reference.displayName,
        ])
        return popup
    }()

    // MARK: - Init

    init(title: String = "Image 1", role: ImageRole = .observed) {
        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: DesignTokens.titlePillHeight))
        self.role = role
        self.previousTitle = title

        wantsLayer = true
        layer?.masksToBounds = true

        // Shadow
        shadow = NSShadow()
        layer?.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.12).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowOffset = CGSize(width: 0, height: -3)
        layer?.shadowRadius = 10
        layer?.masksToBounds = false

        titleField.stringValue = title
        titleField.delegate = self
        addSubview(titleField)

        rolePopUp.selectItem(at: roleIndex(for: role))
        rolePopUp.target = self
        rolePopUp.action = #selector(roleChanged(_:))
        addSubview(rolePopUp)

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

        // Role popup on the right
        rolePopUp.sizeToFit()
        let popupW = max(rolePopUp.frame.width, 68)
        let popupH = rolePopUp.frame.height
        let popupX = bounds.width - popupW - 8
        let popupY = (h - popupH) / 2
        rolePopUp.frame = NSRect(x: popupX, y: popupY, width: popupW, height: popupH)

        // Title field fills remaining space
        let titleX: CGFloat = 12
        let titleW = popupX - titleX - 4
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
