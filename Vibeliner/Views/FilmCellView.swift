import AppKit

/// A single filmstrip cell: title pill (optional) + screenshot image.
/// Title pill is horizontally centered above the image with `titlePillGap` spacing.
final class FilmCellView: NSView {

    // MARK: - Callbacks

    var onTitleChanged: ((Int, String) -> Void)?
    var onRoleChanged: ((Int, ImageRole) -> Void)?

    // MARK: - State

    private(set) var imageIndex: Int = 0
    var showTitlePill: Bool = false

    /// VIB-271: Whether this cell's image is selected for deletion.
    var isImageSelected: Bool = false {
        didSet { updateSelectionAppearance() }
    }

    // MARK: - Subviews

    private let imageView: NSImageView = {
        let iv = NSImageView()
        iv.imageScaling = .scaleProportionallyUpOrDown
        iv.imageAlignment = .alignCenter
        iv.wantsLayer = true
        iv.layer?.cornerRadius = 4
        iv.layer?.masksToBounds = true
        return iv
    }()

    let titlePill: TitlePillView

    /// Flipped so pill at top (Y=0), image below.
    override var isFlipped: Bool { true }

    // MARK: - Init

    init() {
        self.titlePill = TitlePillView()
        super.init(frame: .zero)
        wantsLayer = true

        addSubview(imageView)
        addSubview(titlePill)
        titlePill.isHidden = true
        // Ensure pill renders in front of the image
        titlePill.layer?.zPosition = 10

        titlePill.onTitleChanged = { [weak self] newTitle in
            guard let self else { return }
            self.onTitleChanged?(self.imageIndex, newTitle)
        }
        titlePill.onRoleChanged = { [weak self] newRole in
            guard let self else { return }
            self.onRoleChanged?(self.imageIndex, newRole)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(image: CaptureImage, showPill: Bool) {
        imageIndex = image.index
        imageView.image = image.sourceImage
        showTitlePill = showPill
        titlePill.configure(title: image.title, role: image.role)
        titlePill.isHidden = !showPill
        needsLayout = true
    }

    // MARK: - Layout

    /// Total height of the title pill area (pill + gap) when visible.
    static var pillAreaHeight: CGFloat {
        return DesignTokens.titlePillHeight + DesignTokens.titlePillGap
    }

    override func layout() {
        super.layout()

        if showTitlePill {
            // Pill at top, image below (flipped coordinates: Y=0 is top)
            let pillW = min(max(100, bounds.width - 4), 220)
            let pillX = (bounds.width - pillW) / 2
            let pillY: CGFloat = 0
            titlePill.frame = NSRect(x: pillX, y: pillY, width: pillW, height: DesignTokens.titlePillHeight)

            let imageY = DesignTokens.titlePillHeight + DesignTokens.titlePillGap
            let imageH = bounds.height - imageY
            imageView.frame = NSRect(x: 0, y: imageY, width: bounds.width, height: max(imageH, 0))
        } else {
            // No pill — image fills entire cell
            imageView.frame = bounds
        }
    }

    // MARK: - VIB-271: Selection indicator

    private func updateSelectionAppearance() {
        if isImageSelected {
            imageView.layer?.borderWidth = 2
            imageView.layer?.borderColor = DesignTokens.imageSelectionBorder.cgColor
        } else {
            imageView.layer?.borderWidth = 0
            imageView.layer?.borderColor = nil
        }
    }
}
