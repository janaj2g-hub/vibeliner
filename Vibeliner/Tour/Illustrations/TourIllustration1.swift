import AppKit

/// Tour step 1: "Screenshots become LLM ready prompts"
/// Two-column layout: left = screenshot output card with badges, right = prompt output card.
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

        // Add mock to left card's content area
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
        let contentH = h - padding * 2

        // Two equal columns, vertically centered
        let colW = (contentW - columnGap) / 2
        let cardH = contentH

        let leftX = padding
        let rightX = padding + colW + columnGap
        let cardY = padding

        leftCard.frame = CGRect(x: leftX, y: cardY, width: colW, height: cardH)
        rightCard.frame = CGRect(x: rightX, y: cardY, width: colW, height: cardH)

        // Left card content: mock fills the content area
        let contentArea = leftCard.contentArea
        leftMock.frame = contentArea.bounds

        // Position badges relative to wireframe layout (sidebar + topbar offsets)
        let mockH = contentArea.bounds.height
        let mainX = DesignTokens.tourWireframeSidebarWidth + 1
        let mainTopY = mockH - DesignTokens.tourWireframeTopbarHeight - 1
        let badgeD = DesignTokens.badgeDiameter

        // Badge #1: near error card (HTML top:18px, left:8px in main area)
        badge1.frame.origin = NSPoint(
            x: mainX + 8,
            y: mainTopY - 18 - badgeD
        )

        // Badge #2: near table area (HTML top:82px, left:30px in main area)
        badge2.frame.origin = NSPoint(
            x: mainX + 30,
            y: mainTopY - 82 - badgeD
        )

        // Right card content: prompt sheet fills the content area
        promptSheet.frame = rightCard.contentArea.bounds
    }
}
