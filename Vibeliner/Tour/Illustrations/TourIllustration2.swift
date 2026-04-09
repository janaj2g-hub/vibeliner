import AppKit

/// Tour step 2: "Point at what you see"
/// Full-height mini editor frame with title bar, toolbar, and canvas with 4 annotation groups.
final class TourIllustration2: NSView {

    private let editorFrame: NSView
    private let titleLabel: NSTextField
    private let toolbar: TourMiniToolbar
    private let canvasMock: WireframeAppMock

    // Annotation group 1: badge + stake + note
    private let badge1: TourAnnotationBadge
    private let stake1: TourAnnotationStake
    private let note1: TourAnnotationNote

    // Annotation group 2: badge + arrow + note
    private let badge2: TourAnnotationBadge
    private let arrow2: TourAnnotationArrow
    private let note2: TourAnnotationNote

    // Annotation group 3: badge + rect + note
    private let badge3: TourAnnotationBadge
    private let rect3: TourAnnotationRect
    private let note3: TourAnnotationNote

    // Annotation group 4: badge + circle + note
    private let badge4: TourAnnotationBadge
    private let circle4: TourAnnotationCircle
    private let note4: TourAnnotationNote

    private let padding: CGFloat = 24
    private let titleBarHeight: CGFloat = 28
    private let canvasPadding: CGFloat = 8

    override init(frame frameRect: NSRect) {
        // Editor frame
        editorFrame = NSView()

        // Title bar label
        titleLabel = NSTextField(labelWithString: "Vibeliner")

        // Toolbar
        toolbar = TourMiniToolbar(config: TourMiniToolbarConfig(
            activeTool: .pin,
            mode: .app,
            showCopyPrompt: true,
            showCopyImage: true
        ))

        // Canvas wireframe
        canvasMock = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))

        // Annotation groups
        badge1 = TourAnnotationBadge(number: 1)
        stake1 = TourAnnotationStake()
        note1 = TourAnnotationNote(text: "Padding too tight")

        badge2 = TourAnnotationBadge(number: 2)
        arrow2 = TourAnnotationArrow(length: 50, angle: .pi / 4)
        note2 = TourAnnotationNote(text: "Wrong border radius")

        badge3 = TourAnnotationBadge(number: 3)
        rect3 = TourAnnotationRect(size: CGSize(width: 80, height: 50))
        note3 = TourAnnotationNote(text: "Needs more height")

        badge4 = TourAnnotationBadge(number: 4)
        circle4 = TourAnnotationCircle(diameter: 30)
        note4 = TourAnnotationNote(text: "Spacing cramped")

        super.init(frame: frameRect)
        wantsLayer = true

        // Configure editor frame
        editorFrame.wantsLayer = true
        editorFrame.layer?.cornerRadius = 8
        editorFrame.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.02).cgColor
        editorFrame.layer?.borderWidth = 1
        editorFrame.layer?.borderColor = DesignTokens.chromeBorder.cgColor

        // Configure title label
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = DesignTokens.tourTextSecondary
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.alignment = .center
        titleLabel.sizeToFit()

        // Build view hierarchy
        editorFrame.addSubview(canvasMock)
        editorFrame.addSubview(toolbar)

        // Annotations go on top of the canvas mock
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
        addSubview(titleLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        // Editor frame fills the view with padding
        let frameX = padding
        let frameY = padding
        let frameW = w - padding * 2
        let frameH = h - padding * 2
        editorFrame.frame = CGRect(x: frameX, y: frameY, width: frameW, height: frameH)

        // Title bar label centered at top of editor frame
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(
            x: (frameW - titleLabel.frame.width) / 2,
            y: frameH - titleBarHeight + (titleBarHeight - titleLabel.frame.height) / 2
        )

        // Toolbar centered horizontally below title bar
        let toolbarY = frameH - titleBarHeight - 6 - toolbar.frame.height
        toolbar.frame.origin = NSPoint(
            x: (frameW - toolbar.frame.width) / 2,
            y: toolbarY
        )

        // Canvas area below toolbar
        let canvasTop = toolbarY - 6
        let canvasX = canvasPadding
        let canvasY = canvasPadding
        let canvasW = frameW - canvasPadding * 2
        let canvasH = canvasTop - canvasPadding
        canvasMock.frame = CGRect(x: canvasX, y: canvasY, width: canvasW, height: max(0, canvasH))

        // Position annotations relative to editor frame
        // Use canvas coordinates as reference
        let cX = canvasX
        let cY = canvasY
        let cW = canvasW
        let cH = canvasH

        // Group 1: badge + stake + note near error card area (top-left of content)
        let g1X = cX + cW * 0.28
        let g1Y = cY + cH * 0.62
        badge1.frame.origin = NSPoint(x: g1X, y: g1Y + 10 + 2)
        stake1.frame.origin = NSPoint(x: g1X + 8, y: g1Y)
        note1.frame.origin = NSPoint(x: g1X + 20, y: g1Y + 14)

        // Group 2: badge + arrow + note (middle area, near cards)
        let g2X = cX + cW * 0.55
        let g2Y = cY + cH * 0.55
        badge2.frame.origin = NSPoint(x: g2X, y: g2Y + arrow2.frame.height - 4)
        arrow2.frame.origin = NSPoint(x: g2X - 4, y: g2Y - 10)
        note2.frame.origin = NSPoint(x: g2X + 20, y: g2Y + arrow2.frame.height + 2)

        // Group 3: badge + rect + note (table header area)
        let g3X = cX + cW * 0.35
        let g3Y = cY + cH * 0.22
        rect3.frame.origin = NSPoint(x: g3X, y: g3Y)
        badge3.frame.origin = NSPoint(x: g3X - 6, y: g3Y + rect3.frame.height - 6)
        note3.frame.origin = NSPoint(x: g3X + rect3.frame.width + 4, y: g3Y + (rect3.frame.height - 26) / 2)

        // Group 4: badge + circle + note near table bottom
        let g4X = cX + cW * 0.5
        let g4Y = cY + cH * 0.06
        circle4.frame.origin = NSPoint(x: g4X, y: g4Y)
        badge4.frame.origin = NSPoint(x: g4X - 6, y: g4Y + circle4.frame.height - 6)
        note4.frame.origin = NSPoint(x: g4X + circle4.frame.width + 4, y: g4Y + (circle4.frame.height - 26) / 2)
    }
}
