import AppKit

/// Tour step 2: "Point at what you see"
/// Full-height mini editor frame with title bar, toolbar, and canvas with 4 annotation groups.
final class TourIllustration2: NSView {

    private let editorFrame: NSView
    private let titleLabel: NSTextField
    private let titleDivider: NSView
    private let toolbar: TourMiniToolbar
    private let canvasMock: WireframeAppMock

    // Annotation group 1: badge + stake + note (pin tool)
    private let badge1: TourAnnotationBadge
    private let stake1: TourAnnotationStake
    private let note1: TourAnnotationNote

    // Annotation group 2: badge + arrow + note (arrow tool)
    private let badge2: TourAnnotationBadge
    private let arrow2: TourAnnotationArrow
    private let note2: TourAnnotationNote

    // Annotation group 3: badge + rect + note (rect tool)
    private let badge3: TourAnnotationBadge
    private let rect3: TourAnnotationRect
    private let note3: TourAnnotationNote

    // Annotation group 4: badge + circle + note (circle tool)
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

        badge1 = TourAnnotationBadge(number: 1)
        stake1 = TourAnnotationStake()
        note1 = TourAnnotationNote(text: "Padding too tight")

        badge2 = TourAnnotationBadge(number: 2)
        arrow2 = TourAnnotationArrow(length: 70, angle: 12 * .pi / 180)
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

        // Annotations on top of canvas
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

        // Annotation positions: convert HTML CSS (top/left in .app-mock-main) to AppKit
        let sideW = DesignTokens.tourWireframeSidebarWidth + 1
        let mainX = canvasPadH + sideW
        let mainTopY = canvasPadBottom + canvasH - DesignTokens.tourWireframeTopbarHeight - 1
        let badgeD = DesignTokens.badgeDiameter

        // Group 1: pin + stake + note
        badge1.frame.origin = NSPoint(x: mainX + 4, y: mainTopY - 10 - badgeD)
        stake1.frame.origin = NSPoint(x: mainX + 12, y: mainTopY - 28 - stake1.frame.height)
        note1.frame.origin = NSPoint(x: mainX + 28, y: mainTopY - 4 - note1.frame.height)

        // Group 2: arrow + badge + note
        arrow2.frame.origin = NSPoint(x: mainX + 100, y: mainTopY - 46 - arrow2.frame.height)
        badge2.frame.origin = NSPoint(x: mainX + 96, y: mainTopY - 38 - badgeD)
        note2.frame.origin = NSPoint(x: mainX + 120, y: mainTopY - 32 - note2.frame.height)

        // Group 3: rect + badge + note
        rect3.frame.origin = NSPoint(x: mainX, y: mainTopY - 58)
        badge3.frame.origin = NSPoint(x: mainX + 88, y: mainTopY - 56 - badgeD)
        note3.frame.origin = NSPoint(x: mainX + 108, y: mainTopY - 56 - note3.frame.height)

        // Group 4: circle + badge + note
        circle4.frame.origin = NSPoint(x: mainX + 8, y: mainTopY - 72 - 36)
        badge4.frame.origin = NSPoint(x: mainX + 42, y: mainTopY - 78 - badgeD)
        note4.frame.origin = NSPoint(x: mainX + 62, y: mainTopY - 78 - note4.frame.height)
    }
}
