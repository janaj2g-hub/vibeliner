import AppKit

/// Tour step 3: "Marks become instructions"
/// Three vertical sections: top mock with overlays, flow arrows, bottom two-column output cards.
final class TourIllustration3: NSView {

    // Top section: wireframe with annotations
    private let topMock: WireframeAppMock
    private let topBadge1: TourAnnotationBadge
    private let topNote1: TourAnnotationNote
    private let topRect: TourAnnotationRect
    private let topBadge2: TourAnnotationBadge
    private let topNote2: TourAnnotationNote

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

    private let padding = DesignTokens.tourIllustrationPadding
    private let sectionGap: CGFloat = 12
    private let columnGap: CGFloat = 12
    private let arrowGap: CGFloat = 100

    override init(frame frameRect: NSRect) {
        // Top mock with annotations
        topMock = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))
        topBadge1 = TourAnnotationBadge(number: 1)
        topNote1 = TourAnnotationNote(text: "Padding too tight")
        topRect = TourAnnotationRect(size: CGSize(width: 92, height: 58))
        topBadge2 = TourAnnotationBadge(number: 2)
        topNote2 = TourAnnotationNote(text: "Row spacing cramped")

        // Flow arrows (28px tall)
        flowArrow1 = TourFlowArrow(height: 28)
        flowArrow2 = TourFlowArrow(height: 28)

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
            ],
            footer: "Fix each issue."
        )

        // Hint labels (multiline)
        leftHint = NSTextField(wrappingLabelWithString: "Badges and marks baked in.\nNotes are not in the image.")
        rightHint = NSTextField(wrappingLabelWithString: "Notes become numbered\nprompt lines automatically.")

        super.init(frame: frameRect)
        wantsLayer = true

        // Configure hint labels
        for hint in [leftHint, rightHint] {
            hint.font = DesignTokens.tourHintFont
            hint.textColor = DesignTokens.tourTextDim
            hint.isBezeled = false
            hint.drawsBackground = false
            hint.isEditable = false
            hint.alignment = .center
            hint.maximumNumberOfLines = 0
        }

        // Build view hierarchy
        addSubview(topMock)
        addSubview(topRect)
        addSubview(topBadge1)
        addSubview(topNote1)
        addSubview(topBadge2)
        addSubview(topNote2)

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
        let colW = (contentW - columnGap) / 2
        leftHint.preferredMaxLayoutWidth = colW
        rightHint.preferredMaxLayoutWidth = colW
        let lhSize = leftHint.sizeThatFits(NSSize(width: colW, height: .greatestFiniteMagnitude))
        let rhSize = rightHint.sizeThatFits(NSSize(width: colW, height: .greatestFiniteMagnitude))
        let hintH = max(lhSize.height, rhSize.height)

        // Vertical distribution
        let arrowH: CGFloat = 28
        let totalGaps = sectionGap * 3
        let availableH = contentH - arrowH - totalGaps - hintH
        let topH = floor(availableH * 0.53)
        let bottomH = floor(availableH * 0.47)

        // Layout from bottom
        var y = padding

        // Hint labels
        leftHint.frame = CGRect(x: padding, y: y, width: colW, height: hintH)
        rightHint.frame = CGRect(x: padding + colW + columnGap, y: y, width: colW, height: hintH)
        y += hintH + sectionGap

        // Bottom cards
        leftCard.frame = CGRect(x: padding, y: y, width: colW, height: bottomH)
        rightCard.frame = CGRect(x: padding + colW + columnGap, y: y, width: colW, height: bottomH)

        // Left card: mock + badges
        leftMock.frame = leftCard.contentArea.bounds
        let lMockH = leftCard.contentArea.bounds.height
        let mainXL = DesignTokens.tourWireframeSidebarWidth + 1
        let mainTopYL = lMockH - DesignTokens.tourWireframeTopbarHeight - 1
        let badgeD = DesignTokens.badgeDiameter

        leftBadge1.frame.origin = NSPoint(x: mainXL + 4, y: mainTopYL - 14 - badgeD)
        leftBadge2.frame.origin = NSPoint(x: mainXL + 4, y: mainTopYL - 64 - badgeD)

        // Right card: prompt sheet
        promptSheet.frame = rightCard.contentArea.bounds

        y += bottomH + sectionGap

        // Flow arrows centered with 100px gap
        let arrowsTotalW = flowArrow1.frame.width + arrowGap + flowArrow2.frame.width
        let arrowsStartX = padding + (contentW - arrowsTotalW) / 2
        flowArrow1.frame.origin = NSPoint(x: arrowsStartX, y: y)
        flowArrow2.frame.origin = NSPoint(x: arrowsStartX + flowArrow1.frame.width + arrowGap, y: y)

        y += arrowH + sectionGap

        // Top mock
        topMock.frame = CGRect(x: padding, y: y, width: contentW, height: topH)

        // Top annotations (positions relative to wireframe main area)
        let mainX = padding + DesignTokens.tourWireframeSidebarWidth + 1
        let mainTopY = y + topH - DesignTokens.tourWireframeTopbarHeight - 1

        // Badge 1: top:14, left:4
        topBadge1.frame.origin = NSPoint(x: mainX + 4, y: mainTopY - 14 - badgeD)
        // Note 1: top:8, left:28
        topNote1.frame.origin = NSPoint(x: mainX + 28, y: mainTopY - 8 - topNote1.frame.height)
        // Rect: top:2, left:0, 92x58
        topRect.frame.origin = NSPoint(x: mainX, y: mainTopY - 2 - 58)
        // Badge 2: top:64, left:4
        topBadge2.frame.origin = NSPoint(x: mainX + 4, y: mainTopY - 64 - badgeD)
        // Note 2: top:58, left:28
        topNote2.frame.origin = NSPoint(x: mainX + 28, y: mainTopY - 58 - topNote2.frame.height)
    }
}
