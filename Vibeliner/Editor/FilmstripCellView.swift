import AppKit

final class FilmstripCellView: NSView {

    var onClick: ((Int) -> Void)?
    var onRoleChanged: ((Int, ImageRole) -> Void)?
    var onTitleChanged: ((Int, String) -> Void)?
    var onDelete: ((Int) -> Void)?
    var isSelected: Bool = false {
        didSet { updateSelectionAppearance() }
    }

    private let imageID: UUID
    private let index: Int
    private var role: ImageRole
    private let imageView = NSImageView()
    private let clipView = NSView()
    private let titlePill: TitlePillView
    /// VIB-271: Delete indicator — trash icon, hidden by default, shown when selected
    private let deleteIndicator = NSView(frame: NSRect(x: 0, y: 0, width: 22, height: 22))
    private let trashImageView = NSImageView()
    private var isHovered = false
    private var isTrashHovered = false

    init(image: CaptureImage, isSelected: Bool) {
        self.imageID = image.id
        self.index = image.index
        self.role = image.role
        self.titlePill = TitlePillView(title: image.title, role: image.role)
        self.isSelected = isSelected
        super.init(frame: .zero)
        setupView(image: image.sourceImage)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView(image: NSImage) {
        wantsLayer = true

        // TitlePillView at top — editable with role dropdown
        titlePill.onRoleChanged = { [weak self] newRole in
            guard let self else { return }
            self.role = newRole
            self.updateSelectionAppearance()
            self.onRoleChanged?(self.index, newRole)
        }
        titlePill.onTitleChanged = { [weak self] newTitle in
            guard let self else { return }
            self.onTitleChanged?(self.index, newTitle)
        }
        addSubview(titlePill)

        // VIB-271: Delete indicator — trash icon, hidden by default, shown when selected
        deleteIndicator.wantsLayer = true
        deleteIndicator.layer?.cornerRadius = 11
        deleteIndicator.layer?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor

        let trashSize: CGFloat = 12
        if let trashSymbol = NSImage(systemSymbolName: "trash.fill", accessibilityDescription: "Delete image") {
            let config = NSImage.SymbolConfiguration(pointSize: trashSize, weight: .medium)
            trashImageView.image = trashSymbol.withSymbolConfiguration(config)
        }
        trashImageView.contentTintColor = NSColor(white: 1.0, alpha: 0.85)
        trashImageView.imageScaling = .scaleProportionallyUpOrDown
        trashImageView.frame = NSRect(x: 3, y: 3, width: 16, height: 16)
        deleteIndicator.addSubview(trashImageView)
        deleteIndicator.toolTip = "Remove image"
        addSubview(deleteIndicator)
        deleteIndicator.isHidden = true

        // Image in clip view with rounded corners and border
        clipView.wantsLayer = true
        clipView.layer?.cornerRadius = 6
        clipView.layer?.masksToBounds = true
        clipView.layer?.borderWidth = 2
        addSubview(clipView)

        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        clipView.addSubview(imageView)

        updateSelectionAppearance()
    }

    override func layout() {
        super.layout()

        let pillH = DesignTokens.titlePillHeight
        let pillGap = DesignTokens.titlePillGap
        let pillW = min(bounds.width - 24, max(120, bounds.width * 0.75))
        titlePill.frame = NSRect(
            x: (bounds.width - pillW) / 2,
            y: bounds.height - pillH,
            width: pillW,
            height: pillH
        )

        // VIB-271: Trash icon centered at right edge of title pill zone
        let deleteSize: CGFloat = 22
        deleteIndicator.frame = NSRect(
            x: bounds.width - deleteSize - 2,
            y: bounds.height - pillH + (pillH - deleteSize) / 2,
            width: deleteSize,
            height: deleteSize
        )

        let imageY: CGFloat = 0
        let imageH = bounds.height - pillH - pillGap
        clipView.frame = NSRect(x: 0, y: imageY, width: bounds.width, height: max(0, imageH))
        imageView.frame = clipView.bounds
    }

    private func updateSelectionAppearance() {
        let borderColor = DesignTokens.roleColor(forHex: role.colorHex)

        if isSelected {
            clipView.layer?.borderColor = borderColor.cgColor
            clipView.layer?.borderWidth = 2
            titlePill.alphaValue = 1.0
        } else {
            clipView.layer?.borderColor = borderColor.withAlphaComponent(0.4).cgColor
            clipView.layer?.borderWidth = 1.5
            titlePill.alphaValue = 0.7
        }
        // VIB-385: Screenshot content always fully opaque — never set layer.opacity
        // VIB-271: Show trash when selected, red tint only when hovering the trash circle
        deleteIndicator.isHidden = !isSelected
        updateTrashAppearance()
    }

    private func updateTrashAppearance() {
        if isSelected && isTrashHovered {
            trashImageView.contentTintColor = NSColor.systemRed
            deleteIndicator.layer?.borderWidth = 1.5
            deleteIndicator.layer?.borderColor = NSColor.systemRed.cgColor
        } else {
            trashImageView.contentTintColor = NSColor(white: 1.0, alpha: 0.85)
            deleteIndicator.layer?.borderWidth = 0
            deleteIndicator.layer?.borderColor = nil
        }
    }

    // VIB-385: Separate tracking areas — cell-wide for general hover, trash-only for red state
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }

        // Cell-wide tracking for general hover (show/hide trash)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        deleteIndicator.isHidden = !isSelected
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        isTrashHovered = false
        updateTrashAppearance()
    }

    override func mouseMoved(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        let overTrash = isSelected && deleteIndicator.frame.contains(localPoint)
        if overTrash != isTrashHovered {
            isTrashHovered = overTrash
            updateTrashAppearance()
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        // Intercept clicks on delete indicator so cell's mouseDown handles them
        if isSelected && !deleteIndicator.isHidden && deleteIndicator.frame.contains(localPoint) {
            return self
        }
        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        if isSelected && !deleteIndicator.isHidden && deleteIndicator.frame.contains(localPoint) {
            onDelete?(index)
        } else {
            onClick?(index)
        }
    }
}
