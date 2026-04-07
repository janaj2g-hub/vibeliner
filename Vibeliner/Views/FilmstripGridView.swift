import AppKit

/// Grid container that arranges image cells using proportional-width layout.
/// Each row has uniform height with cell widths proportional to aspect ratios.
/// For now, renders placeholder colored rectangles — real images come in VIB-261.
final class FilmstripGridView: NSView {

    // MARK: - State

    private var imageSizes: [CGSize] = []
    private var cellViews: [NSView] = []
    private var isComposite: Bool { imageSizes.count >= 2 }

    // Placeholder colors for testing
    private static let placeholderColors: [NSColor] = [
        NSColor(red: 100/255, green: 100/255, blue: 160/255, alpha: 0.3),
        NSColor(red: 100/255, green: 160/255, blue: 100/255, alpha: 0.3),
        NSColor(red: 160/255, green: 100/255, blue: 100/255, alpha: 0.3),
        NSColor(red: 160/255, green: 160/255, blue: 100/255, alpha: 0.3),
        NSColor(red: 100/255, green: 160/255, blue: 160/255, alpha: 0.3),
        NSColor(red: 160/255, green: 100/255, blue: 160/255, alpha: 0.3),
    ]

    // MARK: - Init

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        wantsLayer = true
    }

    // MARK: - Public API

    /// Configure with image sizes and rebuild cells.
    func configure(with sizes: [CGSize]) {
        imageSizes = sizes

        // Remove old cells
        for cell in cellViews {
            cell.removeFromSuperview()
        }
        cellViews.removeAll()

        // Create placeholder cells
        for (i, _) in sizes.enumerated() {
            let cell = NSView()
            cell.wantsLayer = true
            let color = Self.placeholderColors[i % Self.placeholderColors.count]
            cell.layer?.backgroundColor = color.cgColor
            cell.layer?.cornerRadius = 4
            addSubview(cell)
            cellViews.append(cell)
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

        guard contentWidth > 0, !imageSizes.isEmpty else { return }

        let frames = LayoutCalculator.computeFrames(
            imageSizes: imageSizes,
            availableWidth: contentWidth,
            gap: gap
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

        let frames = LayoutCalculator.computeFrames(
            imageSizes: imageSizes,
            availableWidth: contentWidth,
            gap: gap
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
            layer?.borderWidth = 1
            layer?.borderColor = DesignTokens.filmstripBorder.cgColor
            layer?.cornerRadius = 8
        } else {
            layer?.borderWidth = 0
            layer?.borderColor = nil
            layer?.cornerRadius = 0
        }
    }
}
