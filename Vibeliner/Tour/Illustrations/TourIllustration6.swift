import AppKit

/// Tour step 6: "Add more screenshots"
/// Mini editor frame with title bar, TourMiniToolbar, and 3-column filmstrip grid.
/// Columns 1–2 use real TourFilmstripCell; column 3 is a dashed add-image placeholder.
final class TourIllustration6: NSView {

    // Editor frame
    private let editorFrame: NSView
    private let titleBar: NSView
    private let titleLabel: NSTextField
    private let toolbar: TourMiniToolbar

    // Filmstrip cells (real helpers)
    private let pill1: TourTitlePill
    private let cell1: TourFilmstripCell

    private let pill2: TourTitlePill
    private let cell2: TourFilmstripCell

    // Cell 3: dashed placeholder (drawn in draw(_:))
    private let plusCircle: NSView
    private let plusLabel: NSTextField
    private let addLabel: NSTextField

    private let padding = DesignTokens.tourIllustrationPadding
    private let titleBarH: CGFloat = 36
    private let filmstripGap: CGFloat = 10
    private let toolbarGap: CGFloat = 16

    override init(frame frameRect: NSRect) {
        // Editor frame
        editorFrame = NSView()
        titleBar = NSView()
        titleLabel = NSTextField(labelWithString: "Vibeliner")

        toolbar = TourMiniToolbar(config: TourMiniToolbarConfig(
            activeTool: .pin,
            mode: .app,
            showCopyPrompt: true,
            showCopyImage: true,
            showAddImage: true
        ))

        // Cell 1: observed with one badge
        pill1 = TourTitlePill(name: "Image 1", role: .observed)
        cell1 = TourFilmstripCell(bodyHeight: 50, badges: [(1, 12, 28)])

        // Cell 2: expected, no badges
        pill2 = TourTitlePill(name: "Image 2", role: .expected)
        cell2 = TourFilmstripCell(bodyHeight: 50)

        // Cell 3: dashed add-image placeholder
        plusCircle = NSView()
        plusLabel = NSTextField(labelWithString: "+")
        addLabel = NSTextField(labelWithString: "Add image")

        super.init(frame: frameRect)
        wantsLayer = true

        // Editor frame styling
        editorFrame.wantsLayer = true
        editorFrame.layer?.cornerRadius = 8
        editorFrame.layer?.masksToBounds = true
        editorFrame.layer?.backgroundColor = DesignTokens.tourEditorFrameBg.cgColor
        editorFrame.layer?.borderWidth = 1
        editorFrame.layer?.borderColor = DesignTokens.tourOutputCardBorder.cgColor

        // Title bar
        titleBar.wantsLayer = true
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = DesignTokens.tourTextSecondary
        titleLabel.alignment = .center
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.sizeToFit()

        // Plus circle
        plusCircle.wantsLayer = true
        plusCircle.layer?.cornerRadius = DesignTokens.tourAddCellPlusSize / 2
        plusCircle.layer?.backgroundColor = DesignTokens.tourAddCellPlusBg.cgColor

        plusLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        plusLabel.textColor = DesignTokens.purpleLight
        plusLabel.alignment = .center
        plusLabel.isBezeled = false
        plusLabel.drawsBackground = false
        plusLabel.isEditable = false
        plusLabel.sizeToFit()

        addLabel.font = DesignTokens.tourOutputLabelFont
        addLabel.textColor = DesignTokens.purpleLight
        addLabel.isBezeled = false
        addLabel.drawsBackground = false
        addLabel.isEditable = false
        addLabel.sizeToFit()

        // Build hierarchy
        titleBar.addSubview(titleLabel)
        editorFrame.addSubview(titleBar)
        editorFrame.addSubview(toolbar)

        editorFrame.addSubview(pill1)
        editorFrame.addSubview(cell1)
        editorFrame.addSubview(pill2)
        editorFrame.addSubview(cell2)
        editorFrame.addSubview(plusCircle)
        editorFrame.addSubview(plusLabel)
        editorFrame.addSubview(addLabel)

        addSubview(editorFrame)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2
        let contentH = h - padding * 2

        editorFrame.frame = CGRect(x: padding, y: padding, width: contentW, height: contentH)

        let frameW = contentW
        let frameH = contentH

        // Title bar at top
        titleBar.frame = CGRect(x: 0, y: frameH - titleBarH, width: frameW, height: titleBarH)
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(
            x: (frameW - titleLabel.frame.width) / 2,
            y: (titleBarH - titleLabel.frame.height) / 2,
            width: titleLabel.frame.width,
            height: titleLabel.frame.height
        )

        // Toolbar below title bar, centered
        let tbSize = toolbar.frame.size
        let toolbarY = frameH - titleBarH - toolbarGap - tbSize.height
        toolbar.frame = CGRect(
            x: (frameW - tbSize.width) / 2,
            y: toolbarY,
            width: tbSize.width,
            height: tbSize.height
        )

        // Filmstrip grid below toolbar
        let gridTop = toolbarY - toolbarGap
        let gridPad: CGFloat = 16
        let gridW = frameW - gridPad * 2
        let cellW = (gridW - filmstripGap * 2) / 3

        let pillH: CGFloat = 22
        let pillGap: CGFloat = 6
        let cellBodyH = cell1.intrinsicContentSize.height
        let cellH = min(cellBodyH, gridTop - gridPad - pillH - pillGap)

        let cellY = gridPad
        let pillY = cellY + cellH + pillGap

        // Cell 1
        let c1x = gridPad
        pill1.frame.origin = NSPoint(x: c1x + (cellW - pill1.frame.width) / 2, y: pillY)
        cell1.frame = CGRect(x: c1x, y: cellY, width: cellW, height: cellH)

        // Cell 2
        let c2x = gridPad + cellW + filmstripGap
        pill2.frame.origin = NSPoint(x: c2x + (cellW - pill2.frame.width) / 2, y: pillY)
        cell2.frame = CGRect(x: c2x, y: cellY, width: cellW, height: cellH)

        // Cell 3: dashed placeholder (drawn in draw())
        let c3x = gridPad + (cellW + filmstripGap) * 2
        cell3Rect = CGRect(x: c3x, y: cellY, width: cellW, height: cellH)

        // Plus circle centered in cell3
        let plusSize = DesignTokens.tourAddCellPlusSize
        plusCircle.frame = CGRect(
            x: c3x + (cellW - plusSize) / 2,
            y: cellY + cellH / 2 + 2,
            width: plusSize,
            height: plusSize
        )

        plusLabel.sizeToFit()
        plusLabel.frame = CGRect(
            x: plusCircle.frame.midX - plusLabel.frame.width / 2,
            y: plusCircle.frame.midY - plusLabel.frame.height / 2,
            width: plusLabel.frame.width,
            height: plusLabel.frame.height
        )

        addLabel.sizeToFit()
        addLabel.frame.origin = NSPoint(
            x: c3x + (cellW - addLabel.frame.width) / 2,
            y: cellY + cellH / 2 - addLabel.frame.height - 4
        )
    }

    private var cell3Rect: CGRect = .zero

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Draw cell3 dashed border inside editorFrame coordinates
        let selfRect = CGRect(
            x: editorFrame.frame.origin.x + cell3Rect.origin.x,
            y: editorFrame.frame.origin.y + cell3Rect.origin.y,
            width: cell3Rect.width,
            height: cell3Rect.height
        )

        let cellRadius = DesignTokens.tourFilmstripCellRadius
        let dashPath = CGPath(roundedRect: selfRect, cornerWidth: cellRadius, cornerHeight: cellRadius, transform: nil)

        // Fill first so border draws on top
        ctx.addPath(dashPath)
        ctx.setFillColor(DesignTokens.tourAddCellBg.cgColor)
        ctx.fillPath()

        // Dashed border
        ctx.addPath(dashPath)
        ctx.setStrokeColor(DesignTokens.tourAddCellBorder.cgColor)
        ctx.setLineWidth(DesignTokens.tourAddCellDashWidth)
        ctx.setLineDash(phase: 0, lengths: [6, 4])
        ctx.strokePath()

        // Reset dash
        ctx.setLineDash(phase: 0, lengths: [])

        // Title bar bottom border
        let tbBorderY = editorFrame.frame.origin.y + editorFrame.frame.height - titleBarH
        ctx.setFillColor(DesignTokens.tourLLMComposerBg.cgColor)
        ctx.fill(CGRect(x: editorFrame.frame.origin.x, y: tbBorderY, width: editorFrame.frame.width, height: 1))
    }
}
