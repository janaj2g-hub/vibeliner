import AppKit

/// Horizontal filmstrip that displays multiple captured images as cells with
/// editable title pills and role-colored borders. Used when the editor has 2+ images.
/// VIB-330: Images maintain a minimum width (200px); scrolls horizontally when needed.
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

    /// VIB-330: Minimum cell width — images won't shrink below this
    static let minCellWidth: CGFloat = 200

    /// VIB-330: Scroll view used only when content exceeds available width
    private var scrollView: NSScrollView?
    /// The document view that holds cells (either self or scroll view's documentView)
    private var contentHost: NSView { scrollView?.documentView ?? self }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Rebuild the filmstrip with the given images. Each image gets a TitlePillView
    /// with editable title and role dropdown.
    func setImages(_ images: [NSImage], roles: [String], selectedIndex: Int) {
        self.selectedIndex = selectedIndex

        // Remove old cells and scroll view
        for cell in cellViews { cell.removeFromSuperview() }
        cellViews.removeAll()
        scrollView?.removeFromSuperview()
        scrollView = nil

        guard !images.isEmpty else { imageAreaRect = .zero; return }

        let availableWidth = bounds.width
        let availableHeight = bounds.height
        guard availableWidth > 0, availableHeight > 0 else { imageAreaRect = .zero; return }

        let gap = DesignTokens.filmstripGap
        let pillTotalH = DesignTokens.titlePillHeight + DesignTokens.titlePillGap
        let imageSizes = images.map { $0.size }

        // VIB-330: Check if images need minimum width enforcement.
        // Compute what row height would give each image at least minCellWidth.
        let minRowHeight = Self.minRowHeightForMinCellWidth(
            imageSizes: imageSizes, minCellWidth: Self.minCellWidth
        )

        // Compute the ideal row height that fits everything in available width
        let idealRowHeight = Self.computeFittingRowHeight(
            imageSizes: imageSizes,
            availableWidth: availableWidth,
            availableHeight: availableHeight - pillTotalH,
            gap: gap
        )

        // Use the ideal height if it gives wide enough cells, otherwise enforce min
        let rowHeight: CGFloat
        let needsScroll: Bool
        if idealRowHeight >= minRowHeight {
            // Images fit at a comfortable size — no scrolling needed
            rowHeight = idealRowHeight
            needsScroll = false
        } else {
            // Images would be too small — use min row height and scroll
            rowHeight = min(minRowHeight, availableHeight - pillTotalH)
            needsScroll = true
        }

        let (frames, totalWidth) = LayoutCalculator.computeFrames(
            imageSizes: imageSizes,
            rowHeight: rowHeight,
            gap: gap,
            titlePillTotalHeight: pillTotalH
        )

        let contentHeight = frames.first?.size.height ?? 0
        let yOffset = max(0, bounds.height - contentHeight)

        // VIB-330: If content overflows, wrap in horizontal scroll view
        let hostView: NSView
        if needsScroll && totalWidth > availableWidth {
            let sv = NSScrollView(frame: NSRect(x: 0, y: yOffset, width: availableWidth, height: contentHeight))
            sv.hasHorizontalScroller = true
            sv.hasVerticalScroller = false
            sv.autohidesScrollers = true
            sv.borderType = .noBorder
            sv.drawsBackground = false
            sv.horizontalScrollElasticity = .allowed
            sv.scrollerStyle = .overlay

            let docView = NSView(frame: NSRect(x: 0, y: 0, width: totalWidth, height: contentHeight))
            docView.wantsLayer = true
            sv.documentView = docView
            addSubview(sv)
            self.scrollView = sv
            hostView = docView
        } else {
            hostView = self
        }

        // Center content horizontally when not scrolling
        let xOffset: CGFloat = needsScroll ? 0 : max(0, (bounds.width - totalWidth) / 2)

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

            let cellY: CGFloat = needsScroll ? 0 : yOffset
            cell.frame = NSRect(
                x: xOffset + frame.origin.x,
                y: cellY,
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
            hostView.addSubview(cell)
            cellViews.append(cell)
        }

        // Track image area (below title pills) for canvas overlay positioning
        let imageAreaWidth = needsScroll ? totalWidth : bounds.width
        imageAreaRect = NSRect(
            x: 0,
            y: yOffset,
            width: imageAreaWidth,
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
            // Convert point to cell's parent coordinate system
            let cellFrame = cell.frame
            let testPoint: CGPoint
            if let sv = scrollView {
                // Convert filmstrip point to scroll content point
                let scrollContentPoint = sv.contentView.convert(point, from: self)
                testPoint = scrollContentPoint
            } else {
                testPoint = point
            }
            if cellFrame.contains(testPoint) {
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

        let totalAR = imageSizes.reduce(CGFloat(0)) { sum, size in
            sum + (size.height > 0 ? size.width / size.height : 1)
        }
        let totalGap = CGFloat(max(0, imageSizes.count - 1)) * gap
        let idealRowHeight = (availableWidth - totalGap) / totalAR

        // Clamp to LayoutCalculator limits and available height
        let upper = min(LayoutCalculator.maxRowHeight, availableHeight)
        return min(idealRowHeight, upper)
    }

    /// VIB-330: Compute the minimum row height that ensures all cells are at least minCellWidth wide.
    private static func minRowHeightForMinCellWidth(imageSizes: [CGSize], minCellWidth: CGFloat) -> CGFloat {
        var maxNeeded: CGFloat = 0
        for size in imageSizes {
            let ar = size.height > 0 ? size.width / size.height : 1
            // cellWidth = rowHeight * ar → rowHeight = cellWidth / ar
            let needed = minCellWidth / ar
            maxNeeded = max(maxNeeded, needed)
        }
        return maxNeeded
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
    /// VIB-330: Delete indicator — hidden by default, shown on hover only
    private let deleteIndicator = NSView(frame: NSRect(x: 0, y: 0, width: 18, height: 18))
    private var isHovered = false

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

        // VIB-330: Delete indicator — subtle ×, hidden by default, shown on hover only
        deleteIndicator.wantsLayer = true
        deleteIndicator.layer?.cornerRadius = 9
        deleteIndicator.layer?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.45).cgColor
        let xLbl = NSTextField(labelWithString: "×")
        xLbl.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        xLbl.textColor = NSColor(white: 1.0, alpha: 0.7)
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
        deleteIndicator.toolTip = "Remove image"
        addSubview(deleteIndicator)
        deleteIndicator.isHidden = true  // VIB-330: hidden by default, shown on hover

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
        // VIB-330: Only show delete when hovered AND selected
        deleteIndicator.isHidden = !(isSelected && isHovered)
    }

    // VIB-330: Hover tracking for delete indicator
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        deleteIndicator.isHidden = !(isSelected && isHovered)
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        deleteIndicator.isHidden = true
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
