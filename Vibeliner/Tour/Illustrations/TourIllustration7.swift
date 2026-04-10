import AppKit

/// Tour step 7: "Label what each image shows"
/// Top ~55%: 3-column filmstrip grid with TourTitlePills above each TourFilmstripCell.
/// Bottom ~45%: TourPromptSheet with preamble listing images, annotations, and footer.
final class TourIllustration7: NSView {

    // Top: filmstrip grid (real helpers)
    private let pill1: TourTitlePill
    private let cell1: TourFilmstripCell

    private let pill2: TourTitlePill
    private let cell2: TourFilmstripCell

    private let pill3: TourTitlePill
    private let cell3: TourFilmstripCell

    // Bottom: prompt sheet
    private let promptSheet: TourPromptSheet

    private let padding = DesignTokens.tourIllustrationPadding
    private let sectionGap: CGFloat = 14
    private let filmstripGap: CGFloat = 12

    override init(frame frameRect: NSRect) {
        // Cell 1: observed, 2 badges
        pill1 = TourTitlePill(name: "Image 1", role: .observed)
        cell1 = TourFilmstripCell(bodyHeight: 70, badges: [(1, 10, 24), (2, 40, 42)])

        // Cell 2: expected, no badges
        pill2 = TourTitlePill(name: "Image 2", role: .expected)
        cell2 = TourFilmstripCell(bodyHeight: 70)

        // Cell 3: reference, no badges
        pill3 = TourTitlePill(name: "Mockup", role: .reference)
        cell3 = TourFilmstripCell(bodyHeight: 70)

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

        // Build hierarchy
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
        let topH = floor(contentH * 0.55) - sectionGap / 2
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
        let cellBodyH = cell1.intrinsicContentSize.height
        let cellsH = pillH + pillGap + cellBodyH

        // Vertically center the cells+pills in the top section
        let offsetY = topY + (topH - cellsH) / 2
        let cellY = offsetY
        let pillY = cellY + cellBodyH + pillGap

        // Cell 1
        let c1x = padding
        pill1.frame.origin = NSPoint(x: c1x + (cellW - pill1.frame.width) / 2, y: pillY)
        cell1.frame = CGRect(x: c1x, y: cellY, width: cellW, height: cellBodyH)

        // Cell 2
        let c2x = padding + cellW + filmstripGap
        pill2.frame.origin = NSPoint(x: c2x + (cellW - pill2.frame.width) / 2, y: pillY)
        cell2.frame = CGRect(x: c2x, y: cellY, width: cellW, height: cellBodyH)

        // Cell 3
        let c3x = padding + (cellW + filmstripGap) * 2
        pill3.frame.origin = NSPoint(x: c3x + (cellW - pill3.frame.width) / 2, y: pillY)
        cell3.frame = CGRect(x: c3x, y: cellY, width: cellW, height: cellBodyH)
    }
}
