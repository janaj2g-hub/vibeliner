import AppKit

/// Tour step 2: "Point at what you see"
/// Editor frame (dark rounded rect) containing:
///   - "Vibeliner" title bar
///   - Mini toolbar (pill shape, clearly visible with shadow)
///   - Canvas with WireframeAppMock + 4 annotation groups spread across quadrants
final class TourIllustration2: NSView {

    private let editorFrame: NSView
    private let titleLabel: NSTextField
    private let titleDivider: NSView
    private let toolbarShadow: NSView   // container that casts a shadow
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

        // Toolbar shadow container — casts shadow so toolbar pops off the dark bg
        toolbarShadow = NSView()
        toolbar = TourMiniToolbar(config: TourMiniToolbarConfig(
            activeTool: .pin,
            mode: .app,
            showCopyPrompt: true,
            showCopyImage: true,
            showCloseButton: true
        ))

        canvasMock = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))

        badge1 = TourAnnotationBadge(number: 1)
        stake1 = TourAnnotationStake()
        note1 = TourAnnotationNote(text: "Padding too tight")

        badge2 = TourAnnotationBadge(number: 2)
        arrow2 = TourAnnotationArrow(length: 70, angle: 15 * .pi / 180)
        note2 = TourAnnotationNote(text: "Wrong border radius")

        badge3 = TourAnnotationBadge(number: 3)
        rect3 = TourAnnotationRect(size: CGSize(width: 92, height: 58))
        note3 = TourAnnotationNote(text: "Needs more height")

        badge4 = TourAnnotationBadge(number: 4)
        circle4 = TourAnnotationCircle(diameter: 36)
        note4 = TourAnnotationNote(text: "Spacing cramped")

        super.init(frame: frameRect)
        wantsLayer = true

        // Editor frame: dark bg, subtle border, 8px radius
        // NO masksToBounds — allows toolbar shadow to render inside the frame.
        // The wireframe clips its own corners via its own masksToBounds.
        editorFrame.wantsLayer = true
        editorFrame.layer?.cornerRadius = 8
        editorFrame.layer?.backgroundColor = DesignTokens.tourEditorFrameBg.cgColor
        editorFrame.layer?.borderWidth = 1
        editorFrame.layer?.borderColor = DesignTokens.tourOutputCardBorder.cgColor

        // Title label
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

        // Toolbar shadow container — gives the toolbar a visible drop shadow
        toolbarShadow.wantsLayer = true
        toolbarShadow.layer?.shadowColor = NSColor.black.cgColor
        toolbarShadow.layer?.shadowOpacity = 0.3
        toolbarShadow.layer?.shadowOffset = CGSize(width: 0, height: -8)
        toolbarShadow.layer?.shadowRadius = 15

        // Build view hierarchy — all inside editor frame
        editorFrame.addSubview(titleLabel)
        editorFrame.addSubview(titleDivider)
        editorFrame.addSubview(canvasMock)
        toolbarShadow.addSubview(toolbar)
        editorFrame.addSubview(toolbarShadow)

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

        // Toolbar: 14px below title divider, centered, with shadow container
        let tbSize = toolbar.frame.size
        let toolbarY = frameH - titleBarH - 14 - tbSize.height
        toolbarShadow.frame = CGRect(
            x: (frameW - tbSize.width) / 2,
            y: toolbarY,
            width: tbSize.width,
            height: tbSize.height
        )
        toolbar.frame = toolbarShadow.bounds
        toolbarShadow.layer?.shadowPath = CGPath(
            roundedRect: toolbarShadow.bounds,
            cornerWidth: tbSize.height / 2,
            cornerHeight: tbSize.height / 2,
            transform: nil
        )

        // Canvas area: padding 8px top, 16px sides, 16px bottom
        let canvasPadH: CGFloat = 16
        let canvasPadBottom: CGFloat = 16
        let canvasTopEdge = toolbarY - 4 - 8
        let canvasH = canvasTopEdge - canvasPadBottom
        let canvasW = frameW - canvasPadH * 2
        canvasMock.frame = CGRect(x: canvasPadH, y: canvasPadBottom, width: canvasW, height: max(0, canvasH))

        // -- Annotation positions --
        let sideW = DesignTokens.tourWireframeSidebarWidth + 1  // 101
        let topBarH = DesignTokens.tourWireframeTopbarHeight + 1  // 37
        let badgeD = DesignTokens.badgeDiameter  // 18

        // Main area origin in editor-frame coords
        let mainX = canvasPadH + sideW
        let mainTopY = canvasPadBottom + canvasH - topBarH

        // Wireframe layout offsets (from top of main area)
        let headingTop: CGFloat = 16
        let cardsTop: CGFloat = 42
        let cardsHeight: CGFloat = 64
        let tableTop: CGFloat = 118

        let mainContentW = canvasW - sideW - 32
        let cardW = (mainContentW - 16) / 3
        let mainPad: CGFloat = 16

        // ================================================================
        // GROUP 1: PIN — top-left, near heading
        // ================================================================
        let pin1X = mainX + mainPad + 12
        let pin1TargetY = mainTopY - headingTop - 7

        let stakeH = stake1.frame.height
        let stakeW = stake1.frame.width

        stake1.frame.origin = NSPoint(
            x: pin1X + (badgeD - stakeW) / 2,
            y: pin1TargetY
        )
        badge1.frame.origin = NSPoint(x: pin1X, y: pin1TargetY + stakeH)
        note1.frame.origin = NSPoint(
            x: pin1X + badgeD + 6,
            y: pin1TargetY + stakeH + (badgeD - note1.frame.height) / 2
        )

        // ================================================================
        // GROUP 2: ARROW — cards area, badge at start, arrow attached to badge
        // Arrow exits from the RIGHT edge of the badge circle, pointing toward
        // the bottom-right corner of card 3.
        // ================================================================
        let arrow2BadgeX = mainX + mainPad + cardW + 8 + cardW * 0.5
        let arrow2BadgeY = mainTopY - cardsTop - cardsHeight * 0.35

        badge2.frame.origin = NSPoint(x: arrow2BadgeX, y: arrow2BadgeY)

        // Arrow origin: at the right edge of the badge, vertically centered
        // The TourAnnotationArrow draws from its top-left area toward bottom-right
        arrow2.frame.origin = NSPoint(
            x: arrow2BadgeX + badgeD - 2,
            y: arrow2BadgeY - arrow2.frame.height + badgeD
        )

        // Note above the badge
        note2.frame.origin = NSPoint(
            x: arrow2BadgeX - 4,
            y: arrow2BadgeY + badgeD + 4
        )

        // ================================================================
        // GROUP 3: RECTANGLE — around error card, badge at top-left corner
        // Note is entirely to the LEFT of the rectangle.
        // Shift rect right enough so the note fits to its left.
        // ================================================================
        let note3W = note3.frame.width
        let rect3X = mainX + mainPad + note3W + 8  // note space + gap on the left
        let rect3TopOffset = cardsTop - 4
        let rect3Y = mainTopY - rect3TopOffset - rect3.frame.height

        rect3.frame.origin = NSPoint(x: rect3X, y: rect3Y)

        // Badge at the top-left corner of the rectangle
        badge3.frame.origin = NSPoint(
            x: rect3X - badgeD / 2 + 2,
            y: rect3Y + rect3.frame.height - badgeD / 2 - 2
        )

        // Note entirely to the LEFT of the rectangle, vertically centered
        note3.frame.origin = NSPoint(
            x: rect3X - note3W - 4,
            y: rect3Y + (rect3.frame.height - note3.frame.height) / 2
        )

        // ================================================================
        // GROUP 4: CIRCLE — table area, badge on perimeter
        // ================================================================
        let circle4X = mainX + mainPad + 30
        let circle4TopOffset = tableTop + 8
        let circle4Y = mainTopY - circle4TopOffset - circle4.frame.height

        circle4.frame.origin = NSPoint(x: circle4X, y: circle4Y)

        badge4.frame.origin = NSPoint(
            x: circle4X + circle4.frame.width - badgeD / 2,
            y: circle4Y + circle4.frame.height / 2 - badgeD / 2
        )

        note4.frame.origin = NSPoint(
            x: badge4.frame.maxX + 4,
            y: circle4Y + circle4.frame.height / 2 - note4.frame.height / 2
        )
    }
}
