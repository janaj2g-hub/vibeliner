import AppKit

/// Horizontal scrolling filmstrip that displays multiple captured images as cells
/// with title pills and role-colored borders. Used when the editor has 2+ images.
final class FilmstripGridView: NSView {

    /// Called when user clicks a cell. Parameter is the image index.
    var onCellSelected: ((Int) -> Void)?

    private let scrollView = NSScrollView()
    private let documentContainer = NSView()
    private var cellViews: [FilmstripCellView] = []
    private(set) var selectedIndex: Int = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        wantsLayer = true

        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.horizontalScrollElasticity = .allowed
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        documentContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentContainer

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    /// Rebuild the filmstrip with the given images. Each image gets a title pill
    /// showing its 1-based index and a role-colored border.
    func setImages(_ images: [NSImage], roles: [String], selectedIndex: Int) {
        self.selectedIndex = selectedIndex

        // Remove old cells
        for cell in cellViews { cell.removeFromSuperview() }
        cellViews.removeAll()

        let cellHeight = bounds.height
        guard cellHeight > 0 else { return }

        let titleH = DesignTokens.filmstripTitlePillHeight + DesignTokens.filmstripTitlePillGap
        let imageAreaHeight = cellHeight - titleH
        let spacing = DesignTokens.filmstripCellSpacing
        var x: CGFloat = 0

        for (i, image) in images.enumerated() {
            // Scale image to fit height while preserving aspect ratio
            let aspect = image.size.width / max(image.size.height, 1)
            let cellW = imageAreaHeight * aspect

            let role = i < roles.count ? roles[i] : "observed"
            let cell = FilmstripCellView(
                image: image,
                index: i,
                role: role,
                isSelected: i == selectedIndex
            )
            cell.frame = NSRect(x: x, y: 0, width: cellW, height: cellHeight)
            cell.onClick = { [weak self] idx in
                self?.selectCell(idx)
            }
            documentContainer.addSubview(cell)
            cellViews.append(cell)

            x += cellW + spacing
        }

        // Remove trailing spacing
        if !images.isEmpty { x -= spacing }

        // Size the document view
        documentContainer.frame = NSRect(x: 0, y: 0, width: max(x, bounds.width), height: cellHeight)

        // Scroll selected cell into view
        if selectedIndex < cellViews.count {
            scrollView.contentView.scrollToVisible(cellViews[selectedIndex].frame)
        }
    }

    private func selectCell(_ index: Int) {
        guard index != selectedIndex, index < cellViews.count else { return }
        selectedIndex = index
        for (i, cell) in cellViews.enumerated() {
            cell.isSelected = (i == index)
        }
        onCellSelected?(index)
    }
}

// MARK: - Cell View

private final class FilmstripCellView: NSView {

    var onClick: ((Int) -> Void)?
    var isSelected: Bool = false {
        didSet { updateSelectionAppearance() }
    }

    private let index: Int
    private let role: String
    private let imageView = NSImageView()
    private let titlePill = NSView()
    private let titleLabel: NSTextField
    private let clipView = NSView()

    init(image: NSImage, index: Int, role: String, isSelected: Bool) {
        self.index = index
        self.role = role
        self.titleLabel = NSTextField(labelWithString: "Image \(index + 1)")
        self.isSelected = isSelected
        super.init(frame: .zero)
        setupView(image: image)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView(image: NSImage) {
        wantsLayer = true

        // Title pill at top
        titlePill.wantsLayer = true
        titlePill.layer?.cornerRadius = DesignTokens.filmstripTitlePillRadius
        titlePill.layer?.backgroundColor = DesignTokens.filmstripTitlePillBg.cgColor
        addSubview(titlePill)

        titleLabel.font = DesignTokens.filmstripTitlePillFont
        titleLabel.textColor = DesignTokens.filmstripTitlePillText
        titleLabel.alignment = .center
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.sizeToFit()
        titlePill.addSubview(titleLabel)

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

        let pillH = DesignTokens.filmstripTitlePillHeight
        let pillGap = DesignTokens.filmstripTitlePillGap
        let pillW = titleLabel.frame.width + 16
        titlePill.frame = NSRect(
            x: (bounds.width - pillW) / 2,
            y: bounds.height - pillH,
            width: pillW,
            height: pillH
        )
        titleLabel.frame = NSRect(
            x: 8,
            y: (pillH - titleLabel.frame.height) / 2,
            width: titleLabel.frame.width,
            height: titleLabel.frame.height
        )

        let imageY: CGFloat = 0
        let imageH = bounds.height - pillH - pillGap
        clipView.frame = NSRect(x: 0, y: imageY, width: bounds.width, height: imageH)
        imageView.frame = clipView.bounds
    }

    private func updateSelectionAppearance() {
        let borderColor: NSColor
        switch role {
        case "expected":  borderColor = DesignTokens.roleExpectedBorder
        case "reference": borderColor = DesignTokens.roleReferenceBorder
        default:          borderColor = DesignTokens.roleObservedBorder
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
    }

    override func mouseDown(with event: NSEvent) {
        onClick?(index)
    }
}
