import AppKit

/// Tour step 7: "Label what each image shows"
/// Top ~50%: 3-column filmstrip grid with TourTitlePills above each cell.
/// Bottom ~50%: TourPromptSheet with preamble listing images, annotations, and footer.
final class TourIllustration7: NSView {

    // Top: filmstrip grid
    private let pill1: TourTitlePill
    private let cell1: NSView
    private let cell1Line1: NSView
    private let cell1Line2: NSView
    private let badge1: TourAnnotationBadge
    private let badge2: TourAnnotationBadge

    private let pill2: TourTitlePill
    private let cell2: NSView
    private let cell2Line1: NSView
    private let cell2Line2: NSView

    private let pill3: TourTitlePill
    private let cell3: NSView
    private let cell3Line1: NSView
    private let cell3Line2: NSView

    // Bottom: prompt sheet
    private let promptSheet: TourPromptSheet

    private let padding = DesignTokens.tourIllustrationPadding
    private let sectionGap: CGFloat = 16
    private let filmstripGap: CGFloat = 10

    override init(frame frameRect: NSRect) {
        // Cell 1: observed
        pill1 = TourTitlePill(name: "Image 1", role: .observed)
        cell1 = NSView()
        cell1Line1 = NSView()
        cell1Line2 = NSView()
        badge1 = TourAnnotationBadge(number: 1)
        badge2 = TourAnnotationBadge(number: 2)

        // Cell 2: expected
        pill2 = TourTitlePill(name: "Image 2", role: .expected)
        cell2 = NSView()
        cell2Line1 = NSView()
        cell2Line2 = NSView()

        // Cell 3: reference
        pill3 = TourTitlePill(name: "Mockup", role: .reference)
        cell3 = NSView()
        cell3Line1 = NSView()
        cell3Line2 = NSView()

        // Prompt sheet
        promptSheet = TourPromptSheet(
            preamble: "Images:\n  Image 1 (Observed) \u{2014} ./image_1.png\n  Image 2 (Expected) \u{2014} ./image_2.png\n  Mockup (Reference) \u{2014} ./image_3.png",
            annotations: [
                TourPromptLine(index: 1, tool: "pin", note: "padding too tight"),
                TourPromptLine(index: 2, tool: "rect", note: "row spacing cramped"),
            ],
            footer: "Fix each issue to match the expected."
        )

        super.init(frame: frameRect)
        wantsLayer = true

        // Cell styling
        for cell in [cell1, cell2, cell3] {
            cell.wantsLayer = true
            cell.layer?.cornerRadius = DesignTokens.tourFilmstripCellRadius
            cell.layer?.backgroundColor = DesignTokens.tourOutputCardBorder.cgColor
        }

        // Lines
        for line in [cell1Line1, cell1Line2, cell2Line1, cell2Line2, cell3Line1, cell3Line2] {
            line.wantsLayer = true
            line.layer?.cornerRadius = 2
            line.layer?.backgroundColor = DesignTokens.tooltipDarkBorder.cgColor
        }

        // Build hierarchy
        cell1.addSubview(cell1Line1)
        cell1.addSubview(cell1Line2)
        cell1.addSubview(badge1)
        cell1.addSubview(badge2)

        cell2.addSubview(cell2Line1)
        cell2.addSubview(cell2Line2)

        cell3.addSubview(cell3Line1)
        cell3.addSubview(cell3Line2)

        addSubview(pill1)
        addSubview(cell1)
        addSubview(pill2)
        addSubview(cell2)
        addSubview(pill3)
        addSubview(cell3)
        addSubview(promptSheet)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2
        let contentH = h - padding * 2

        // Two vertical sections
        let topH = floor(contentH * 0.50) - sectionGap / 2
        let bottomH = contentH - topH - sectionGap

        // AppKit: origin bottom-left
        let bottomY = padding
        let topY = bottomY + bottomH + sectionGap

        // -- Bottom: prompt sheet --
        promptSheet.frame = CGRect(x: padding, y: bottomY, width: contentW, height: bottomH)

        // -- Top: 3-column filmstrip --
        let cellW = (contentW - filmstripGap * 2) / 3
        let pillH: CGFloat = 22
        let pillGap: CGFloat = 6
        let cellBodyH: CGFloat = 60
        let cellsH = pillH + pillGap + cellBodyH

        // Vertically center the cells+pills in the top section
        let offsetY = topY + (topH - cellsH) / 2
        let cellY = offsetY
        let pillY = cellY + cellBodyH + pillGap

        // Cell 1
        let c1x = padding
        pill1.frame.origin = NSPoint(x: c1x + (cellW - pill1.frame.width) / 2, y: pillY)
        cell1.frame = CGRect(x: c1x, y: cellY, width: cellW, height: cellBodyH)
        layoutLines(cell1, cell1Line1, cell1Line2)
        badge1.frame = CGRect(x: cellW * 0.25 - 9, y: cellBodyH * 0.55, width: 18, height: 18)
        badge2.frame = CGRect(x: cellW * 0.65 - 9, y: cellBodyH * 0.25, width: 18, height: 18)

        // Cell 2
        let c2x = padding + cellW + filmstripGap
        pill2.frame.origin = NSPoint(x: c2x + (cellW - pill2.frame.width) / 2, y: pillY)
        cell2.frame = CGRect(x: c2x, y: cellY, width: cellW, height: cellBodyH)
        layoutLines(cell2, cell2Line1, cell2Line2)

        // Cell 3
        let c3x = padding + (cellW + filmstripGap) * 2
        pill3.frame.origin = NSPoint(x: c3x + (cellW - pill3.frame.width) / 2, y: pillY)
        cell3.frame = CGRect(x: c3x, y: cellY, width: cellW, height: cellBodyH)
        layoutLines(cell3, cell3Line1, cell3Line2)
    }

    private func layoutLines(_ cell: NSView, _ line1: NSView, _ line2: NSView) {
        let cw = cell.bounds.width
        let ch = cell.bounds.height
        let linePad: CGFloat = 10
        line1.frame = CGRect(x: linePad, y: ch * 0.55, width: cw * 0.6, height: 4)
        line2.frame = CGRect(x: linePad, y: ch * 0.55 - 10, width: cw * 0.4, height: 4)
    }
}
