import AppKit

/// Grid container that arranges FilmCellViews using proportional-width layout.
/// Each row has uniform height with cell widths proportional to aspect ratios.
final class FilmstripGridView: NSView {

    // MARK: - State

    private var captureImages: [CaptureImage] = []
    private var cellViews: [FilmCellView] = []
    var isComposite: Bool { captureImages.count >= 2 }

    // MARK: - Callbacks

    var onTitleChanged: ((Int, String) -> Void)?
    var onRoleChanged: ((Int, ImageRole) -> Void)?

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Flipped so Y=0 is at top — content flows top-to-bottom, matching LayoutCalculator's
    /// row ordering and placing title pills close to the toolbar above.
    override var isFlipped: Bool { true }

    private func commonInit() {
        wantsLayer = true
    }

    // MARK: - Public API

    /// Configure with capture images and rebuild cells.
    func configure(with images: [CaptureImage]) {
        captureImages = images

        // Remove old cells
        for cell in cellViews {
            cell.removeFromSuperview()
        }
        cellViews.removeAll()

        let showPills = images.count >= 2

        // Create FilmCellViews
        for image in images {
            let cell = FilmCellView()
            cell.configure(image: image, showPill: showPills)
            cell.onTitleChanged = { [weak self] idx, title in
                self?.onTitleChanged?(idx, title)
            }
            cell.onRoleChanged = { [weak self] idx, role in
                self?.onRoleChanged?(idx, role)
            }
            addSubview(cell)
            cellViews.append(cell)
        }

        updateBorder()
        needsLayout = true
        invalidateIntrinsicContentSize()
    }

    /// Update title pill visibility on all cells (used during 1↔2 transitions).
    func updatePillVisibility(show: Bool, animated: Bool = false) {
        for cell in cellViews {
            if animated {
                if show && cell.titlePill.isHidden {
                    cell.titlePill.isHidden = false
                    cell.titlePill.alphaValue = 0
                    cell.showTitlePill = true
                    NSAnimationContext.runAnimationGroup { ctx in
                        ctx.duration = 0.3
                        ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                        cell.titlePill.animator().alphaValue = 1
                    }
                } else if !show && !cell.titlePill.isHidden {
                    cell.showTitlePill = false
                    NSAnimationContext.runAnimationGroup({ ctx in
                        ctx.duration = 0.2
                        ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
                        cell.titlePill.animator().alphaValue = 0
                    }, completionHandler: {
                        cell.titlePill.isHidden = true
                    })
                }
            } else {
                cell.showTitlePill = show
                cell.titlePill.isHidden = !show
                cell.titlePill.alphaValue = show ? 1 : 0
            }
        }
        updateBorder()
        needsLayout = true
        invalidateIntrinsicContentSize()
    }

    // MARK: - Layout

    override func layout() {
        super.layout()

        let padding = DesignTokens.filmstripPadding
        let gap = DesignTokens.filmstripGap
        let contentWidth = bounds.width - padding * 2
        let pillH: CGFloat = isComposite ? FilmCellView.pillAreaHeight : 0

        guard contentWidth > 0, !captureImages.isEmpty else { return }

        let sizes = captureImages.map { $0.originalSize }
        let frames = LayoutCalculator.computeFrames(
            imageSizes: sizes,
            availableWidth: contentWidth,
            gap: gap,
            titlePillTotalHeight: pillH
        )

        for (i, layoutFrame) in frames.enumerated() where i < cellViews.count {
            cellViews[i].frame = NSRect(
                x: padding + layoutFrame.origin.x,
                y: padding + layoutFrame.origin.y,
                width: layoutFrame.size.width,
                height: layoutFrame.size.height
            )
        }
    }

    override var intrinsicContentSize: NSSize {
        let padding = DesignTokens.filmstripPadding
        let gap = DesignTokens.filmstripGap
        let contentWidth = bounds.width > 0 ? bounds.width - padding * 2 : 600
        let pillH: CGFloat = isComposite ? FilmCellView.pillAreaHeight : 0

        let sizes = captureImages.map { $0.originalSize }
        let frames = LayoutCalculator.computeFrames(
            imageSizes: sizes,
            availableWidth: contentWidth,
            gap: gap,
            titlePillTotalHeight: pillH
        )

        let totalH = LayoutCalculator.totalHeight(frames: frames)
        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: totalH + padding * 2
        )
    }

    // MARK: - Border

    private func updateBorder() {
        if isComposite {
            // VIB-290: Darkened background + border for visual grouping
            layer?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.12).cgColor
            layer?.borderWidth = 1
            layer?.borderColor = DesignTokens.filmstripBorder.cgColor
            layer?.cornerRadius = 6
        } else {
            layer?.backgroundColor = nil
            layer?.borderWidth = 0
            layer?.borderColor = nil
            layer?.cornerRadius = 0
        }
    }
}
