import AppKit

typealias TourBadgePlacement = (number: Int, x: CGFloat, y: CGFloat)

final class TourMiniBadge: NSView {

    private let fillColor: NSColor
    private let textColor: NSColor
    private let label: NSTextField

    override var isFlipped: Bool { true }

    init(number: Int, fillColor: NSColor, textColor: NSColor) {
        self.fillColor = fillColor
        self.textColor = textColor
        self.label = NSTextField(labelWithString: "\(number)")
        let size = DesignTokens.tourMiniBadgeSize

        super.init(frame: NSRect(x: 0, y: 0, width: size, height: size))
        wantsLayer = true
        layer?.cornerRadius = size / 2
        label.font = DesignTokens.tourMiniBadgeFont
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        addSubview(label)
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        NSSize(width: DesignTokens.tourMiniBadgeSize, height: DesignTokens.tourMiniBadgeSize)
    }

    override func layout() {
        super.layout()
        label.sizeToFit()
        label.frame = CGRect(
            x: (bounds.width - label.frame.width) / 2,
            y: (bounds.height - label.frame.height) / 2,
            width: label.frame.width,
            height: label.frame.height
        )
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    private func updateAppearance() {
        layer?.backgroundColor = fillColor.cgColor
        label.textColor = textColor
    }
}

/// Compact app thumbnail used in the exported screenshot cards for tour steps 3 and 4.
/// Badge coordinates use the view's top-left origin.
/// Rect coordinates are relative to the content area inside the sidebar rail.
final class TourMiniScreenshot: NSView {

    var badges: [TourBadgePlacement] {
        didSet {
            rebuildBadges()
        }
    }

    var showRect: Bool {
        didSet {
            rectOverlay.isHidden = !showRect
        }
    }

    var rectFrame: NSRect {
        didSet {
            needsLayout = true
        }
    }

    private let canvasView = TourMiniScreenshotCanvasView()
    private let rectOverlay = NSView()
    private var badgeViews: [TourMiniBadge] = []

    override var isFlipped: Bool { true }

    init(
        badges: [TourBadgePlacement] = [],
        showRect: Bool = false,
        rectFrame: NSRect = .zero
    ) {
        self.badges = badges
        self.showRect = showRect
        self.rectFrame = rectFrame
        super.init(frame: .zero)

        wantsLayer = true
        layer?.masksToBounds = false

        canvasView.wantsLayer = true
        canvasView.layer?.cornerRadius = DesignTokens.tourMiniScreenshotRadius
        canvasView.layer?.masksToBounds = true
        addSubview(canvasView)

        rectOverlay.wantsLayer = true
        rectOverlay.layer?.cornerRadius = DesignTokens.tourMiniScreenshotRectRadius
        canvasView.addSubview(rectOverlay)

        updateAppearance()
        rebuildBadges()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: NSView.noIntrinsicMetric,
            height: DesignTokens.tourMiniScreenshotBarHeight + DesignTokens.tourMiniScreenshotBodyHeight
        )
    }

    override func layout() {
        super.layout()
        canvasView.frame = bounds
        canvasView.layer?.cornerRadius = DesignTokens.tourMiniScreenshotRadius
        layoutRectOverlay()

        for (badgeView, badge) in zip(badgeViews, badges) {
            let size = DesignTokens.tourMiniBadgeSize
            badgeView.frame = CGRect(x: badge.x, y: badge.y, width: size, height: size)
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    private func rebuildBadges() {
        badgeViews.forEach { $0.removeFromSuperview() }
        badgeViews = badges.map {
            let badge = TourMiniBadge(
                number: $0.number,
                fillColor: DesignTokens.red,
                textColor: DesignTokens.tourMiniScreenshotBadgeText
            )
            canvasView.addSubview(badge)
            return badge
        }
        needsLayout = true
    }

    private func layoutRectOverlay() {
        rectOverlay.isHidden = !showRect
        guard showRect else { return }

        rectOverlay.frame = CGRect(
            x: DesignTokens.tourMiniScreenshotRailWidth + DesignTokens.tourMiniScreenshotContentPadding + rectFrame.origin.x,
            y: DesignTokens.tourMiniScreenshotBarHeight + DesignTokens.tourMiniScreenshotContentPadding + rectFrame.origin.y,
            width: rectFrame.width,
            height: rectFrame.height
        )
    }

    private func updateAppearance() {
        layer?.shadowColor = DesignTokens.tourMiniScreenshotShadowColor.cgColor
        layer?.shadowOffset = CGSize(width: 0, height: DesignTokens.tourMiniScreenshotShadowYOffset)
        layer?.shadowRadius = DesignTokens.tourMiniScreenshotShadowBlur
        layer?.shadowOpacity = 1

        rectOverlay.layer?.borderWidth = DesignTokens.tourMiniRectStroke
        rectOverlay.layer?.borderColor = DesignTokens.red.cgColor
        rectOverlay.layer?.backgroundColor = DesignTokens.tourMiniScreenshotRectFill.cgColor
    }
}

private final class TourMiniScreenshotCanvasView: NSView {

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let bounds = self.bounds
        drawBackground(in: bounds, context: context)

        let barHeight = min(DesignTokens.tourMiniScreenshotBarHeight, bounds.height)
        let barRect = CGRect(x: 0, y: 0, width: bounds.width, height: barHeight)
        drawBar(in: barRect, context: context)

        let bodyRect = CGRect(
            x: 0,
            y: barRect.maxY,
            width: bounds.width,
            height: max(0, bounds.height - barRect.height)
        )
        drawBody(in: bodyRect, context: context)
    }

    private func drawBackground(in rect: CGRect, context: CGContext) {
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                DesignTokens.tourMiniScreenshotBgTop.cgColor,
                DesignTokens.tourMiniScreenshotBgBottom.cgColor,
            ] as CFArray,
            locations: [0, 1]
        ) else {
            return
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
    }

    private func drawBar(in rect: CGRect, context: CGContext) {
        context.setFillColor(DesignTokens.tourMiniScreenshotBarBg.cgColor)
        context.fill(rect)

        let dotSize = DesignTokens.tourMiniScreenshotDotSize
        let dotY = rect.midY - dotSize / 2
        var dotX = DesignTokens.tourMiniScreenshotBarPaddingH

        for _ in 0..<3 {
            let dotRect = CGRect(x: dotX, y: dotY, width: dotSize, height: dotSize)
            context.setFillColor(DesignTokens.tourMiniScreenshotDotColor.cgColor)
            context.fillEllipse(in: dotRect)
            dotX += dotSize + DesignTokens.tourMiniScreenshotDotGap
        }
    }

    private func drawBody(in rect: CGRect, context: CGContext) {
        let railWidth = min(DesignTokens.tourMiniScreenshotRailWidth, rect.width)
        let railRect = CGRect(x: rect.minX, y: rect.minY, width: railWidth, height: rect.height)
        context.setFillColor(DesignTokens.tourMiniScreenshotRailBg.cgColor)
        context.fill(railRect)
        drawRailPills(in: railRect, context: context)

        let contentRect = CGRect(
            x: railRect.maxX,
            y: rect.minY,
            width: max(0, rect.width - railWidth),
            height: rect.height
        )
        drawContentLines(in: contentRect, context: context)
    }

    private func drawRailPills(in rect: CGRect, context: CGContext) {
        let maxWidth = rect.width - DesignTokens.tourMiniScreenshotRailPaddingH * 2
        let widths: [CGFloat] = [maxWidth * 0.72, maxWidth * 0.58, maxWidth * 0.66]
        var currentY = rect.minY + DesignTokens.tourMiniScreenshotRailPaddingV

        for width in widths {
            let pillRect = CGRect(
                x: rect.minX + DesignTokens.tourMiniScreenshotRailPaddingH,
                y: currentY,
                width: width,
                height: DesignTokens.tourMiniScreenshotRailPillHeight
            )
            let pillPath = CGPath(
                roundedRect: pillRect,
                cornerWidth: DesignTokens.tourMiniScreenshotRailPillHeight / 2,
                cornerHeight: DesignTokens.tourMiniScreenshotRailPillHeight / 2,
                transform: nil
            )
            context.setFillColor(DesignTokens.tourMiniScreenshotRailPillColor.cgColor)
            context.addPath(pillPath)
            context.fillPath()
            currentY += DesignTokens.tourMiniScreenshotRailPillHeight + DesignTokens.tourMiniScreenshotRailGap
        }
    }

    private func drawContentLines(in rect: CGRect, context: CGContext) {
        let lineHeight = DesignTokens.tourMiniScreenshotLineHeight
        let maxWidth = rect.width - DesignTokens.tourMiniScreenshotContentPadding * 2
        let widths: [CGFloat] = [
            maxWidth * DesignTokens.tourMiniScreenshotAccentWidthRatio,
            maxWidth * 0.88,
            maxWidth * 0.76,
            maxWidth * 0.62,
        ]
        var currentY = rect.minY + DesignTokens.tourMiniScreenshotContentPadding

        for (index, width) in widths.enumerated() {
            let lineRect = CGRect(
                x: rect.minX + DesignTokens.tourMiniScreenshotContentPadding,
                y: currentY,
                width: width,
                height: lineHeight
            )
            let linePath = CGPath(
                roundedRect: lineRect,
                cornerWidth: lineHeight / 2,
                cornerHeight: lineHeight / 2,
                transform: nil
            )
            let lineColor = index == 0
                ? DesignTokens.tourMiniScreenshotAccent
                : DesignTokens.tourMiniScreenshotLineColor
            context.setFillColor(lineColor.cgColor)
            context.addPath(linePath)
            context.fillPath()
            currentY += lineHeight + DesignTokens.tourMiniScreenshotContentGap
        }
    }
}
