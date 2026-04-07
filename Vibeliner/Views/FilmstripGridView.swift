import AppKit

/// VIB-306: NSScrollView subclass that translates vertical mouse wheel to horizontal scroll.
/// Trackpad horizontal scroll still works natively. Clamps scroll to content bounds.
private final class HorizontalScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        if hasHorizontalScroller && !hasVerticalScroller {
            // Translate vertical scroll to horizontal when only horizontal scrolling is enabled
            if event.scrollingDeltaX == 0 && event.scrollingDeltaY != 0 {
                guard let docView = documentView else { return }
                let newX = contentView.bounds.origin.x - event.scrollingDeltaY
                let maxX = max(0, docView.frame.width - contentView.bounds.width)
                let clampedX = min(max(0, newX), maxX)
                contentView.scroll(to: NSPoint(x: clampedX, y: 0))
                reflectScrolledClipView(contentView)
                return
            }
        }
        super.scrollWheel(with: event)
    }
}

/// VIB-297: Horizontal scroll filmstrip — single row of images with proportional widths.
/// Wraps content in an NSScrollView for horizontal scrolling when images exceed visible width.
final class FilmstripGridView: NSView {

    // MARK: - State

    private var captureImages: [CaptureImage] = []
    private(set) var cellViews: [FilmCellView] = []
    var isComposite: Bool { captureImages.count >= 2 }

    /// The fixed row height for image content (excluding title pill area).
    var rowHeight: CGFloat = 300

    // MARK: - Callbacks

    var onTitleChanged: ((Int, String) -> Void)?
    var onRoleChanged: ((Int, ImageRole) -> Void)?

    // MARK: - Scroll infrastructure

    private let scrollView: NSScrollView = {
        let sv = HorizontalScrollView()
        sv.hasHorizontalScroller = true
        sv.hasVerticalScroller = false
        sv.scrollerStyle = .overlay
        sv.horizontalScrollElasticity = .allowed
        sv.verticalScrollElasticity = .none
        sv.drawsBackground = false
        sv.autohidesScrollers = true
        return sv
    }()

    /// The document view inside the scroll view — holds all FilmCellViews.
    private let contentView: NSView = {
        let v = NSView()
        v.wantsLayer = true
        return v
    }()

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Flipped so Y=0 is at top — title pills at top, images below.
    override var isFlipped: Bool { true }

    private func commonInit() {
        wantsLayer = true

        // Wire scroll view hierarchy
        scrollView.documentView = contentView
        addSubview(scrollView)
    }

    // MARK: - Public API

    /// Configure with capture images and rebuild cells.
    func configure(with images: [CaptureImage]) {
        captureImages = images

        // Remove old cells from content view
        for cell in cellViews {
            cell.removeFromSuperview()
        }
        cellViews.removeAll()

        let showPills = images.count >= 2

        // Create FilmCellViews inside the scrollable content view
        for image in images {
            let cell = FilmCellView()
            cell.configure(image: image, showPill: showPills)
            cell.onTitleChanged = { [weak self] idx, title in
                self?.onTitleChanged?(idx, title)
            }
            cell.onRoleChanged = { [weak self] idx, role in
                self?.onRoleChanged?(idx, role)
            }
            contentView.addSubview(cell)
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
        let pillH: CGFloat = isComposite ? FilmCellView.pillAreaHeight : 0

        guard !captureImages.isEmpty else { return }

        // Scroll view fills the entire grid view
        scrollView.frame = bounds

        let sizes = captureImages.map { $0.originalSize }
        let (frames, totalWidth) = LayoutCalculator.computeFrames(
            imageSizes: sizes,
            rowHeight: rowHeight,
            gap: gap,
            titlePillTotalHeight: pillH
        )

        // Content view size = total filmstrip content + padding on all sides
        let contentW = totalWidth + padding * 2
        let contentH = bounds.height
        contentView.frame = NSRect(x: 0, y: 0, width: max(contentW, bounds.width), height: contentH)

        // Position cells inside the content view
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
        let pillH: CGFloat = isComposite ? FilmCellView.pillAreaHeight : 0

        let sizes = captureImages.map { $0.originalSize }
        let (_, _) = LayoutCalculator.computeFrames(
            imageSizes: sizes,
            rowHeight: rowHeight,
            gap: gap,
            titlePillTotalHeight: pillH
        )

        let totalH = rowHeight + pillH + padding * 2
        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: totalH
        )
    }

    // MARK: - Border

    private func updateBorder() {
        if isComposite {
            // VIB-293: Darker background (~65% opacity) + stronger border for visual grouping
            layer?.backgroundColor = DesignTokens.filmstripBg.cgColor
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
