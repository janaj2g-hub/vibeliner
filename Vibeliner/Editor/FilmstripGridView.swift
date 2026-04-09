import AppKit

/// Horizontal filmstrip that displays multiple captured images as cells with
/// editable title pills and role-colored borders. Used when the editor has 2+ images.
/// Images scale to fit the available width — no scrolling.
final class FilmstripGridView: NSView {

    /// Called when user clicks a cell. Parameter is the image index.
    var onCellSelected: ((Int) -> Void)?
    /// Called when user changes a cell's role via the dropdown.
    var onRoleChanged: ((Int, ImageRole) -> Void)?
    /// Called when user edits a cell's title.
    var onTitleChanged: ((Int, String) -> Void)?

    private var cellViews: [FilmstripCellView] = []
    private(set) var selectedIndex: Int = 0
    /// The image-area rect in filmstrip-local coordinates (below title pills).
    private(set) var imageAreaRect: NSRect = .zero
    /// Called when user requests to delete an image at the given index.
    var onDeleteImage: ((Int) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Rebuild the filmstrip with the given images. Each image gets a TitlePillView
    /// with editable title and role dropdown.
    func setImages(_ images: [NSImage], roles: [String], selectedIndex: Int) {
        self.selectedIndex = selectedIndex

        // Remove old cells
        for cell in cellViews { cell.removeFromSuperview() }
        cellViews.removeAll()

        guard !images.isEmpty else { imageAreaRect = .zero; return }

        let availableWidth = bounds.width
        let availableHeight = bounds.height
        guard availableWidth > 0, availableHeight > 0 else { imageAreaRect = .zero; return }

        let gap = DesignTokens.filmstripGap
        let pillTotalH = DesignTokens.titlePillHeight + DesignTokens.titlePillGap

        // Compute row height that fits all images in the available width
        let imageSizes = images.map { $0.size }
        let rowHeight = Self.computeFittingRowHeight(
            imageSizes: imageSizes,
            availableWidth: availableWidth,
            availableHeight: availableHeight - pillTotalH,
            gap: gap
        )

        let (frames, totalWidth) = LayoutCalculator.computeFrames(
            imageSizes: imageSizes,
            rowHeight: rowHeight,
            gap: gap,
            titlePillTotalHeight: pillTotalH
        )

        // Position content: top-aligned (high Y in AppKit) and horizontally centered
        let contentHeight = frames.first?.size.height ?? 0
        let yOffset = max(0, bounds.height - contentHeight)
        let xOffset = max(0, (bounds.width - totalWidth) / 2)

        for (i, image) in images.enumerated() {
            guard i < frames.count else { break }
            let frame = frames[i]

            let roleStr = i < roles.count ? roles[i] : "observed"
            let imageRole = ImageRole.from(string: roleStr)

            let cell = FilmstripCellView(
                image: image,
                index: i,
                role: imageRole,
                isSelected: i == selectedIndex
            )
            cell.frame = NSRect(
                x: xOffset + frame.origin.x,
                y: yOffset,
                width: frame.size.width,
                height: frame.size.height
            )
            cell.onClick = { [weak self] idx in
                self?.selectCell(idx)
            }
            cell.onRoleChanged = { [weak self] idx, newRole in
                self?.onRoleChanged?(idx, newRole)
            }
            cell.onTitleChanged = { [weak self] idx, newTitle in
                self?.onTitleChanged?(idx, newTitle)
            }
            cell.onDelete = { [weak self] idx in
                self?.onDeleteImage?(idx)
            }
            addSubview(cell)
            cellViews.append(cell)
        }

        // Track image area (below title pills) for canvas overlay positioning
        imageAreaRect = NSRect(
            x: 0,
            y: yOffset,
            width: bounds.width,
            height: rowHeight
        )
    }

    private func selectCell(_ index: Int) {
        guard index != selectedIndex, index < cellViews.count else { return }
        selectedIndex = index
        for (i, cell) in cellViews.enumerated() {
            cell.isSelected = (i == index)
        }
        onCellSelected?(index)
    }

    /// Select the cell containing the given point (in filmstrip coordinates).
    func selectCellAtPoint(_ point: CGPoint) {
        for (i, cell) in cellViews.enumerated() {
            if cell.frame.contains(point) {
                if i != selectedIndex { selectCell(i) }
                return
            }
        }
    }

    // MARK: - Fitting

    /// Compute a row height so all images fit within availableWidth.
    private static func computeFittingRowHeight(
        imageSizes: [CGSize],
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        gap: CGFloat
    ) -> CGFloat {
        guard !imageSizes.isEmpty else { return 200 }

        // Sum of aspect ratios — each image width = rowHeight * ar
        let totalAR = imageSizes.reduce(CGFloat(0)) { sum, size in
            sum + (size.height > 0 ? size.width / size.height : 1)
        }
        let totalGap = CGFloat(max(0, imageSizes.count - 1)) * gap
        let idealRowHeight = (availableWidth - totalGap) / totalAR

        // Clamp: at least minRowHeight for readable thumbnails, at most maxRowHeight/availableHeight
        let upper = min(LayoutCalculator.maxRowHeight, availableHeight)
        return max(LayoutCalculator.minRowHeight, min(idealRowHeight, upper))
    }
}

// MARK: - Cell View

private final class FilmstripCellView: NSView {

    var onClick: ((Int) -> Void)?
    var onRoleChanged: ((Int, ImageRole) -> Void)?
    var onTitleChanged: ((Int, String) -> Void)?
    var onDelete: ((Int) -> Void)?
    var isSelected: Bool = false {
        didSet { updateSelectionAppearance() }
    }

    private let index: Int
    private var role: ImageRole
    private let imageView = NSImageView()
    private let clipView = NSView()
    private let titlePill: TitlePillView
    private let deleteIndicator = NSView(frame: NSRect(x: 0, y: 0, width: 18, height: 18))

    init(image: NSImage, index: Int, role: ImageRole, isSelected: Bool) {
        self.index = index
        self.role = role
        self.titlePill = TitlePillView(title: "Image \(index + 1)", role: role)
        self.isSelected = isSelected
        super.init(frame: .zero)
        setupView(image: image)
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

        // Delete indicator — small × in top-right, visible only when selected
        deleteIndicator.wantsLayer = true
        deleteIndicator.layer?.cornerRadius = 9
        deleteIndicator.layer?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.55).cgColor
        let xLbl = NSTextField(labelWithString: "×")
        xLbl.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        xLbl.textColor = NSColor(white: 1.0, alpha: 0.9)
        xLbl.isBezeled = false
        xLbl.drawsBackground = false
        xLbl.isEditable = false
        xLbl.isSelectable = false
        xLbl.sizeToFit()
        xLbl.frame.origin = NSPoint(
            x: (18 - xLbl.frame.width) / 2,
            y: (18 - xLbl.frame.height) / 2
        )
        deleteIndicator.addSubview(xLbl)
        addSubview(deleteIndicator)
        deleteIndicator.isHidden = !isSelected

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

        // Delete button in top-right corner of title pill zone
        let deleteSize: CGFloat = 18
        deleteIndicator.frame = NSRect(
            x: bounds.width - deleteSize - 2,
            y: bounds.height - pillH + (pillH - deleteSize) / 2,
            width: deleteSize,
            height: deleteSize
        )
        deleteIndicator.isHidden = !isSelected

        let imageY: CGFloat = 0
        let imageH = bounds.height - pillH - pillGap
        clipView.frame = NSRect(x: 0, y: imageY, width: bounds.width, height: max(0, imageH))
        imageView.frame = clipView.bounds
    }

    private func updateSelectionAppearance() {
        let borderColor: NSColor
        switch role {
        case .observed:  borderColor = DesignTokens.roleObservedBorder
        case .expected:  borderColor = DesignTokens.roleExpectedBorder
        case .reference: borderColor = DesignTokens.roleReferenceBorder
        }

        if isSelected {
            clipView.layer?.borderColor = borderColor.cgColor
            clipView.layer?.borderWidth = 2
            layer?.opacity = 1.0
        } else {
            clipView.layer?.borderColor = borderColor.withAlphaComponent(0.4).cgColor
            clipView.layer?.borderWidth = 1.5
            layer?.opacity = 0.7
        }
        deleteIndicator.isHidden = !isSelected
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
