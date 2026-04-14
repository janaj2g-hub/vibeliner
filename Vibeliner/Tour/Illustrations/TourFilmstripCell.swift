import AppKit

/// Reusable filmstrip thumbnail for tour steps 6 and 7.
/// Badge coordinates use the view's top-left origin.
final class TourFilmstripCell: NSView {

    var badges: [TourBadgePlacement] {
        didSet {
            rebuildBadges()
        }
    }

    var bodyHeight: CGFloat {
        didSet {
            canvasView.bodyHeight = bodyHeight
            invalidateIntrinsicContentSize()
            needsLayout = true
        }
    }

    private let canvasView: TourFilmstripCellCanvasView
    private var badgeViews: [TourMiniBadge] = []

    override var isFlipped: Bool { true }

    init(
        bodyHeight: CGFloat = DesignTokens.tourFilmstripCellBodyHeight,
        badges: [TourBadgePlacement] = []
    ) {
        self.bodyHeight = bodyHeight
        self.badges = badges
        self.canvasView = TourFilmstripCellCanvasView(bodyHeight: bodyHeight)
        super.init(frame: .zero)

        wantsLayer = true
        layer?.masksToBounds = false

        canvasView.wantsLayer = true
        canvasView.layer?.cornerRadius = DesignTokens.tourFilmstripCellRadius
        canvasView.layer?.masksToBounds = true
        addSubview(canvasView)

        updateAppearance()
        rebuildBadges()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: NSView.noIntrinsicMetric,
            height: DesignTokens.tourFilmstripCellBarHeight + bodyHeight
        )
    }

    override func layout() {
        super.layout()
        canvasView.frame = bounds
        canvasView.layer?.cornerRadius = DesignTokens.tourFilmstripCellRadius

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
                textColor: DesignTokens.tourFilmstripCellBadgeText
            )
            canvasView.addSubview(badge)
            return badge
        }
        needsLayout = true
    }

    private func updateAppearance() {
        layer?.shadowColor = DesignTokens.tourFilmstripCellShadowColor.cgColor
        layer?.shadowOffset = CGSize(width: 0, height: DesignTokens.tourFilmstripCellShadowYOffset)
        layer?.shadowRadius = DesignTokens.tourFilmstripCellShadowBlur
        layer?.shadowOpacity = 1
    }
}

private final class TourFilmstripCellCanvasView: NSView {

    var bodyHeight: CGFloat {
        didSet {
            needsDisplay = true
        }
    }

    override var isFlipped: Bool { true }

    init(bodyHeight: CGFloat) {
        self.bodyHeight = bodyHeight
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let bounds = self.bounds
        drawBackground(in: bounds, context: context)

        let barHeight = min(DesignTokens.tourFilmstripCellBarHeight, bounds.height)
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
                DesignTokens.tourFilmstripCellBgTop.cgColor,
                DesignTokens.tourFilmstripCellBgBottom.cgColor,
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
        context.setFillColor(DesignTokens.tourFilmstripCellBarBg.cgColor)
        context.fill(rect)

        let dotSize = DesignTokens.tourFilmstripCellDotSize
        let dotY = rect.midY - dotSize / 2
        var dotX = DesignTokens.tourFilmstripCellBarPaddingH

        for _ in 0..<3 {
            let dotRect = CGRect(x: dotX, y: dotY, width: dotSize, height: dotSize)
            context.setFillColor(DesignTokens.tourFilmstripCellDotColor.cgColor)
            context.fillEllipse(in: dotRect)
            dotX += dotSize + DesignTokens.tourFilmstripCellDotGap
        }
    }

    private func drawBody(in rect: CGRect, context: CGContext) {
        let lineHeight = DesignTokens.tourFilmstripCellLineHeight
        let maxWidth = rect.width - DesignTokens.tourFilmstripCellBodyPadding * 2
        let lineCount = bodyHeight >= 70 ? 5 : 4
        var widths: [CGFloat] = [maxWidth * DesignTokens.tourFilmstripCellAccentWidthRatio]

        if lineCount == 5 {
            widths.append(contentsOf: [maxWidth * 0.9, maxWidth * 0.78, maxWidth * 0.64, maxWidth * 0.52])
        } else {
            widths.append(contentsOf: [maxWidth * 0.86, maxWidth * 0.74, maxWidth * 0.58])
        }

        var currentY = rect.minY + DesignTokens.tourFilmstripCellBodyPadding
        for (index, width) in widths.enumerated() {
            let lineRect = CGRect(
                x: rect.minX + DesignTokens.tourFilmstripCellBodyPadding,
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
                ? DesignTokens.tourFilmstripCellAccent
                : DesignTokens.tourFilmstripCellLineColor
            context.setFillColor(lineColor.cgColor)
            context.addPath(linePath)
            context.fillPath()
            currentY += lineHeight + DesignTokens.tourFilmstripCellBodyGap
        }
    }
}
