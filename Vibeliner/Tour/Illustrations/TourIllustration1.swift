import AppKit

/// Tour step 1: "Screenshots become LLM ready prompts"
/// Two-column layout (align-items: start): left = screenshot card, right = prompt card.
/// Cards are sized to their content, NOT stretched to fill the pane.
final class TourIllustration1: NSView {

    private let leftCard: TourOutputCard
    private let rightCard: TourOutputCard
    private let leftMock: WireframeAppMock
    private let badge1: TourAnnotationBadge
    private let badge2: TourAnnotationBadge
    private let promptSheet: TourPromptSheet

    private let padding = DesignTokens.tourIllustrationPadding
    private let columnGap: CGFloat = 14

    override init(frame frameRect: NSRect) {
        leftCard = TourOutputCard(label: "screenshot.png")
        rightCard = TourOutputCard(label: "prompt.txt")

        leftMock = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))
        badge1 = TourAnnotationBadge(number: 1)
        badge2 = TourAnnotationBadge(number: 2)

        promptSheet = TourPromptSheet(
            preamble: "This is a screenshot of my app.\nView it at ./screenshot.png\n\nNumbered pins point to issues.\nFix each issue:",
            annotations: [
                TourPromptLine(index: 1, tool: "pin", note: "padding too tight"),
                TourPromptLine(index: 2, tool: "arrow", note: "row spacing cramped"),
            ],
            footer: "Make the changes and verify."
        )

        super.init(frame: frameRect)
        wantsLayer = true

        // Add mock to left card's content area with subtle shadow
        leftMock.wantsLayer = true
        leftMock.layer?.shadowColor = NSColor.black.cgColor
        leftMock.layer?.shadowOpacity = 0.08
        leftMock.layer?.shadowOffset = CGSize(width: 0, height: -4)
        leftMock.layer?.shadowRadius = 8

        leftCard.contentArea.addSubview(leftMock)
        leftCard.contentArea.addSubview(badge1)
        leftCard.contentArea.addSubview(badge2)

        // Add prompt sheet to right card's content area
        rightCard.contentArea.addSubview(promptSheet)

        addSubview(leftCard)
        addSubview(rightCard)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2

        // Two equal-width columns
        let colW = (contentW - columnGap) / 2

        // Card internal metrics (must match TourOutputCard layout)
        let cardPad = DesignTokens.tourOutputCardPadding  // 10
        let labelH: CGFloat = 20
        let labelGap: CGFloat = 8
        let cardOverhead = cardPad + labelH + labelGap + cardPad  // 48

        // Left card: wireframe with min body height 140px (HTML: .s1-screenshot-card .app-mock-body { min-height: 140px })
        let mockContentW = colW - cardPad * 2
        let mockBodyH = max(CGFloat(140), mockContentW * 0.55)
        let mockH = DesignTokens.tourWireframeTopbarHeight + 1 + mockBodyH
        let leftCardH = cardOverhead + mockH

        // Right card: match left card height so layout is balanced
        let rightCardH = leftCardH

        // Top-align (align-items: start) — position from top of content area
        let topEdge = h - padding
        leftCard.frame = CGRect(x: padding, y: topEdge - leftCardH, width: colW, height: leftCardH)
        rightCard.frame = CGRect(x: padding + colW + columnGap, y: topEdge - rightCardH, width: colW, height: rightCardH)

        // Force child layout so contentArea bounds are updated for new frame size
        leftCard.layoutSubtreeIfNeeded()
        rightCard.layoutSubtreeIfNeeded()

        // Left card content: wireframe fills the content area
        let lca = leftCard.contentArea
        leftMock.frame = lca.bounds

        // Badge positions (relative to contentArea = wireframe coordinate space)
        // HTML positions are relative to .app-mock-main (after sidebar + topbar)
        let mockViewH = lca.bounds.height
        let sideW = DesignTokens.tourWireframeSidebarWidth + 1
        let mainTopY = mockViewH - DesignTokens.tourWireframeTopbarHeight - 1
        let badgeD = DesignTokens.badgeDiameter

        // Badge #1: near error card (HTML: top:18px, left:8px in .app-mock-main)
        badge1.frame.origin = NSPoint(
            x: sideW + 8,
            y: mainTopY - 18 - badgeD
        )

        // Badge #2: near table area (HTML: top:82px, left:30px in .app-mock-main)
        badge2.frame.origin = NSPoint(
            x: sideW + 30,
            y: mainTopY - 82 - badgeD
        )

        // Right card content: prompt sheet fills the content area
        promptSheet.frame = rightCard.contentArea.bounds
    }
}
