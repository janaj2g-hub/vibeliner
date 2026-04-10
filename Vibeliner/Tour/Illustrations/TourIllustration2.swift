import AppKit

/// Tour step 2: "Point at what you see"
/// Full-height mini editor frame with title bar, toolbar, and canvas with 4 annotation groups.
/// Annotations are spread across 4 quadrants: pin (top-left), arrow (top-right),
/// rect (middle-left), circle (bottom).
final class TourIllustration2: NSView {

    private let editorFrame: NSView
    private let titleLabel: NSTextField
    private let titleDivider: NSView
    private let toolbar: TourMiniToolbar
    private let canvasMock: WireframeAppMock

    // Annotation group 1: pin (badge + stake + note) — heading area, top-left
    private let badge1: TourAnnotationBadge
    private let stake1: TourAnnotationStake
    private let note1: TourAnnotationNote

    // Annotation group 2: arrow (badge + arrow + note) — cards area, top-right
    private let badge2: TourAnnotationBadge
    private let arrow2: TourAnnotationArrow
    private let note2: TourAnnotationNote

    // Annotation group 3: rect (badge + rect + note) — error card, middle-left
    private let badge3: TourAnnotationBadge
    private let rect3: TourAnnotationRect
    private let note3: TourAnnotationNote

    // Annotation group 4: circle (badge + circle + note) — table area, bottom
    private let badge4: TourAnnotationBadge
    private let circle4: TourAnnotationCircle
    private let note4: TourAnnotationNote

    private let padding = DesignTokens.tourIllustrationPadding
    private let titleBarH: CGFloat = 36

    override init(frame frameRect: NSRect) {
        editorFrame = NSView()
        titleLabel = NSTextField(labelWithString: "Vibeliner")
        titleDivider = NSView()

        toolbar = TourMiniToolbar(config: TourMiniToolbarConfig(
            activeTool: .pin,
            mode: .app,
            showCopyPrompt: true,
            showCopyImage: true,
            showCloseButton: true
        ))

        canvasMock = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))

        // Group 1: pin — badge above stake, stake tip points at heading
        badge1 = TourAnnotationBadge(number: 1)
        stake1 = TourAnnotationStake()
        note1 = TourAnnotationNote(text: "Padding too tight")

        // Group 2: arrow — badge at start, arrow toward card 3, 70px at 15deg
        badge2 = TourAnnotationBadge(number: 2)
        arrow2 = TourAnnotationArrow(length: 70, angle: 15 * .pi / 180)
        note2 = TourAnnotationNote(text: "Wrong border radius")

        // Group 3: rect — surrounds error card, badge at top-left corner
        badge3 = TourAnnotationBadge(number: 3)
        rect3 = TourAnnotationRect(size: CGSize(width: 92, height: 58))
        note3 = TourAnnotationNote(text: "Needs more height")

        // Group 4: circle — highlights table cell, badge on perimeter
        badge4 = TourAnnotationBadge(number: 4)
        circle4 = TourAnnotationCircle(diameter: 36)
        note4 = TourAnnotationNote(text: "Spacing cramped")

        super.init(frame: frameRect)
        wantsLayer = true

        // Editor frame: dark bg, subtle border, 8px radius
        editorFrame.wantsLayer = true
        editorFrame.layer?.cornerRadius = 8
        editorFrame.layer?.backgroundColor = DesignTokens.tourEditorFrameBg.cgColor
        editorFrame.layer?.borderWidth = 1
        editorFrame.layer?.borderColor = DesignTokens.tourOutputCardBorder.cgColor

        // Title label: centered, 12px semibold
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = DesignTokens.tourTextSecondary
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.alignment = .center
        titleLabel.sizeToFit()

        // Title bar bottom divider
        titleDivider.wantsLayer = true
        titleDivider.layer?.backgroundColor = DesignTokens.tourLLMComposerBg.cgColor

        // Build view hierarchy — all inside editor frame
        editorFrame.addSubview(titleLabel)
        editorFrame.addSubview(titleDivider)
        editorFrame.addSubview(canvasMock)
        editorFrame.addSubview(toolbar)

        // Annotations: shapes first (lowest z), then badges, then notes on top
        editorFrame.addSubview(rect3)
        editorFrame.addSubview(circle4)
        editorFrame.addSubview(arrow2)
        editorFrame.addSubview(stake1)
        editorFrame.addSubview(badge1)
        editorFrame.addSubview(badge2)
        editorFrame.addSubview(badge3)
        editorFrame.addSubview(badge4)
        editorFrame.addSubview(note1)
        editorFrame.addSubview(note2)
        editorFrame.addSubview(note3)
        editorFrame.addSubview(note4)

        addSubview(editorFrame)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let frameW = w - padding * 2
        let frameH = h - padding * 2
        editorFrame.frame = CGRect(x: padding, y: padding, width: frameW, height: frameH)

        // Title bar: centered label, bottom divider
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(
            x: (frameW - titleLabel.frame.width) / 2,
            y: frameH - titleBarH + (titleBarH - titleLabel.frame.height) / 2
        )
        titleDivider.frame = CGRect(x: 0, y: frameH - titleBarH, width: frameW, height: 1)

        // Toolbar: 14px below title divider, centered
        let toolbarY = frameH - titleBarH - 14 - toolbar.frame.height
        toolbar.frame.origin = NSPoint(
            x: (frameW - toolbar.frame.width) / 2,
            y: toolbarY
        )

        // Canvas area: padding 8px top, 16px sides, 16px bottom
        let canvasPadH: CGFloat = 16
        let canvasPadBottom: CGFloat = 16
        let canvasTopEdge = toolbarY - 4 - 8
        let canvasH = canvasTopEdge - canvasPadBottom
        let canvasW = frameW - canvasPadH * 2
        canvasMock.frame = CGRect(x: canvasPadH, y: canvasPadBottom, width: canvasW, height: max(0, canvasH))

        // -- Annotation positions --
        // All positions are in editor-frame coords, computed from the wireframe layout.
        // The wireframe has: sidebar (100+1 = 101px from left), topbar (36+1 = 37px from top).
        // Main content area starts at x=101, occupies the rest.
        // Inside main area: 16px padding, heading 14px, 12px gap, cards 64px, 12px gap, table.

        let sideW = DesignTokens.tourWireframeSidebarWidth + 1  // 101
        let topBarH = DesignTokens.tourWireframeTopbarHeight + 1  // 37
        let badgeD = DesignTokens.badgeDiameter  // 18

        // Main area origin in editor-frame coords
        let mainX = canvasPadH + sideW
        let mainTopY = canvasPadBottom + canvasH - topBarH  // top of main content in AppKit y

        // Wireframe main area layout offsets (from top of main area):
        // 16px padding → heading at y_offset=16 (14px tall)
        // 42px → card row starts (3 cards, 64px tall, ~100px each wide, 8px gap)
        // 118px → table starts
        let headingTop: CGFloat = 16
        let cardsTop: CGFloat = 42
        let cardsHeight: CGFloat = 64
        let tableTop: CGFloat = 118

        // Card widths in main content (approx)
        let mainContentW = canvasW - sideW - 32  // 32 = mainPad * 2
        let cardW = (mainContentW - 16) / 3  // 16 = 2 gaps of 8px
        let mainPad: CGFloat = 16  // main area internal padding

        // ================================================================
        // GROUP 1: PIN — top-left, near heading placeholder
        // Pin: badge above stake, stake tip points at the heading
        // ================================================================
        let pin1X = mainX + mainPad + 12  // slightly right of heading start
        let pin1TargetY = mainTopY - headingTop - 7  // stake tip points at middle of heading

        // Stake tip at target, extends upward
        let stakeH = stake1.frame.height  // 10
        stake1.frame.origin = NSPoint(x: pin1X + badgeD / 2 - 1, y: pin1TargetY)

        // Badge sits above the stake
        badge1.frame.origin = NSPoint(x: pin1X, y: pin1TargetY + stakeH + 2)

        // Note to the right of the badge
        note1.frame.origin = NSPoint(
            x: pin1X + badgeD + 6,
            y: pin1TargetY + stakeH + 2 + (badgeD - note1.frame.height) / 2
        )

        // ================================================================
        // GROUP 2: ARROW — top-right, between card 2 and card 3
        // Arrow: badge at start point, line exits from badge, chevron at end
        // ================================================================
        let arrow2StartX = mainX + mainPad + cardW + 8 + cardW * 0.6  // mid-card2 area
        let arrow2StartY = mainTopY - cardsTop - cardsHeight * 0.4  // middle of cards

        // Badge at the start point
        badge2.frame.origin = NSPoint(x: arrow2StartX, y: arrow2StartY)

        // Arrow starts to the right of the badge, pointing rightward/downward
        arrow2.frame.origin = NSPoint(
            x: arrow2StartX + badgeD + 2,
            y: arrow2StartY - arrow2.frame.height + badgeD / 2
        )

        // Note offset from the badge (above-right)
        note2.frame.origin = NSPoint(
            x: arrow2StartX + badgeD + 6,
            y: arrow2StartY + badgeD + 4
        )

        // ================================================================
        // GROUP 3: RECTANGLE — middle-left, surrounding the error card (card 1)
        // Rect: 2.5px stroke around the error card. Badge at top-left corner.
        // ================================================================
        let rect3X = mainX + mainPad - 4  // slightly wider than card 1
        let rect3TopOffset = cardsTop - 4  // slightly above cards
        let rect3Y = mainTopY - rect3TopOffset - rect3.frame.height

        rect3.frame.origin = NSPoint(x: rect3X, y: rect3Y)

        // Badge at the top-left corner of the rectangle (where drag started)
        badge3.frame.origin = NSPoint(
            x: rect3X - badgeD / 2 + 2,
            y: rect3Y + rect3.frame.height - badgeD / 2 - 2
        )

        // Note to the right of the rectangle
        note3.frame.origin = NSPoint(
            x: rect3X + rect3.frame.width + 6,
            y: rect3Y + rect3.frame.height / 2 - note3.frame.height / 2
        )

        // ================================================================
        // GROUP 4: CIRCLE — bottom, in the table's error row area
        // Circle: highlights a table cell. Badge on the perimeter (right side).
        // ================================================================
        let circle4X = mainX + mainPad + 30  // within the table content
        let circle4TopOffset = tableTop + 8  // in the error row area
        let circle4Y = mainTopY - circle4TopOffset - circle4.frame.height

        circle4.frame.origin = NSPoint(x: circle4X, y: circle4Y)

        // Badge on the right perimeter of the circle
        badge4.frame.origin = NSPoint(
            x: circle4X + circle4.frame.width - badgeD / 2,
            y: circle4Y + circle4.frame.height / 2 - badgeD / 2
        )

        // Note to the right of the badge
        note4.frame.origin = NSPoint(
            x: badge4.frame.maxX + 4,
            y: circle4Y + circle4.frame.height / 2 - note4.frame.height / 2
        )
    }
}
