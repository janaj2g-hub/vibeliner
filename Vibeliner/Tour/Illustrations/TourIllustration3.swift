import AppKit

/// Tour step 3: "Marks become instructions"
/// Three vertical sections: top mock with overlays, flow arrows, bottom two-column output cards.
final class TourIllustration3: NSView {

    // Top section
    private let topMock: WireframeAppMock
    private let topBadge1: TourAnnotationBadge
    private let topNote1: TourAnnotationNote
    private let topBadge2: TourAnnotationBadge
    private let topRect2: TourAnnotationRect

    // Middle section: flow arrows
    private let flowArrow1: TourFlowArrow
    private let flowArrow2: TourFlowArrow

    // Bottom section
    private let leftCard: TourOutputCard
    private let rightCard: TourOutputCard
    private let leftMock: WireframeAppMock
    private let leftBadge1: TourAnnotationBadge
    private let leftBadge2: TourAnnotationBadge
    private let promptSheet: TourPromptSheet

    // Hint labels
    private let leftHint: NSTextField
    private let rightHint: NSTextField

    private let padding: CGFloat = 24
    private let sectionGap: CGFloat = 10
    private let columnGap: CGFloat = 14
    private let arrowGap: CGFloat = 80

    override init(frame frameRect: NSRect) {
        // Top mock
        topMock = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))
        topBadge1 = TourAnnotationBadge(number: 1)
        topNote1 = TourAnnotationNote(text: "Padding too tight")
        topBadge2 = TourAnnotationBadge(number: 2)
        topRect2 = TourAnnotationRect(size: CGSize(width: 70, height: 30))

        // Flow arrows
        flowArrow1 = TourFlowArrow(height: 24)
        flowArrow2 = TourFlowArrow(height: 24)

        // Bottom cards
        leftCard = TourOutputCard(label: "screenshot.png")
        rightCard = TourOutputCard(label: "prompt.txt")

        leftMock = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))
        leftBadge1 = TourAnnotationBadge(number: 1)
        leftBadge2 = TourAnnotationBadge(number: 2)

        promptSheet = TourPromptSheet(
            annotations: [
                TourPromptLine(index: 1, tool: "pin", note: "padding too tight"),
                TourPromptLine(index: 2, tool: "rect", note: "row spacing cramped"),
            ]
        )

        // Hint labels
        leftHint = NSTextField(labelWithString: "Badges baked in. Notes removed.")
        rightHint = NSTextField(labelWithString: "Notes become prompt lines.")

        super.init(frame: frameRect)
        wantsLayer = true

        // Configure hint labels
        for hint in [leftHint, rightHint] {
            hint.font = NSFont.systemFont(ofSize: 10, weight: .regular)
            hint.textColor = DesignTokens.tourTextDim
            hint.isBezeled = false
            hint.drawsBackground = false
            hint.isEditable = false
            hint.alignment = .center
            hint.sizeToFit()
        }

        // Build view hierarchy
        addSubview(topMock)
        addSubview(topRect2)
        addSubview(topBadge1)
        addSubview(topNote1)
        addSubview(topBadge2)

        addSubview(flowArrow1)
        addSubview(flowArrow2)

        leftCard.contentArea.addSubview(leftMock)
        leftCard.contentArea.addSubview(leftBadge1)
        leftCard.contentArea.addSubview(leftBadge2)
        rightCard.contentArea.addSubview(promptSheet)
        addSubview(leftCard)
        addSubview(rightCard)

        addSubview(leftHint)
        addSubview(rightHint)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2
        let contentH = h - padding * 2

        // Hint labels height
        leftHint.sizeToFit()
        rightHint.sizeToFit()
        let hintH = max(leftHint.frame.height, rightHint.frame.height)

        // Vertical distribution:
        // bottom: hints, then cards (~40%), then gap, then arrows, then gap, then top mock (~45%)
        let arrowH: CGFloat = 24
        let totalGaps = sectionGap * 2 + sectionGap  // gap between mock-arrows, arrows-cards, cards-hints
        let availableH = contentH - arrowH - totalGaps - hintH

        let topH = floor(availableH * 0.53)
        let bottomH = floor(availableH * 0.47)

        // Layout from bottom (AppKit y-axis origin is bottom-left)
        var y = padding

        // Hint labels at very bottom
        let colW = (contentW - columnGap) / 2
        leftHint.frame = CGRect(
            x: padding + (colW - leftHint.frame.width) / 2,
            y: y,
            width: leftHint.frame.width,
            height: hintH
        )
        rightHint.frame = CGRect(
            x: padding + colW + columnGap + (colW - rightHint.frame.width) / 2,
            y: y,
            width: rightHint.frame.width,
            height: hintH
        )
        y += hintH + sectionGap

        // Bottom cards
        leftCard.frame = CGRect(x: padding, y: y, width: colW, height: bottomH)
        rightCard.frame = CGRect(x: padding + colW + columnGap, y: y, width: colW, height: bottomH)

        // Left card: mini mock + badges
        leftMock.frame = leftCard.contentArea.bounds
        let lContentW = leftCard.contentArea.bounds.width
        let lContentH = leftCard.contentArea.bounds.height

        leftBadge1.frame.origin = NSPoint(
            x: lContentW * 0.30,
            y: lContentH * 0.58
        )
        leftBadge2.frame.origin = NSPoint(
            x: lContentW * 0.45,
            y: lContentH * 0.20
        )

        // Right card: prompt sheet
        promptSheet.frame = rightCard.contentArea.bounds

        y += bottomH + sectionGap

        // Flow arrows centered horizontally with gap between them
        let arrowsTotalW = flowArrow1.frame.width + arrowGap + flowArrow2.frame.width
        let arrowsStartX = padding + (contentW - arrowsTotalW) / 2
        flowArrow1.frame.origin = NSPoint(x: arrowsStartX, y: y)
        flowArrow2.frame.origin = NSPoint(x: arrowsStartX + flowArrow1.frame.width + arrowGap, y: y)

        y += arrowH + sectionGap

        // Top mock
        topMock.frame = CGRect(x: padding, y: y, width: contentW, height: topH)

        // Position annotations on the top mock
        // Badge #1 + note near error card (upper-left area of content)
        let tMockW = contentW
        let tMockH = topH

        let b1X = padding + tMockW * 0.28
        let b1Y = y + tMockH * 0.60
        topBadge1.frame.origin = NSPoint(x: b1X, y: b1Y)
        topNote1.frame.origin = NSPoint(x: b1X + 20, y: b1Y + 2)

        // Badge #2 + rect near table area
        let b2X = padding + tMockW * 0.35
        let b2Y = y + tMockH * 0.18
        topRect2.frame.origin = NSPoint(x: b2X, y: b2Y)
        topBadge2.frame.origin = NSPoint(x: b2X - 6, y: b2Y + topRect2.frame.height - 6)
    }
}
