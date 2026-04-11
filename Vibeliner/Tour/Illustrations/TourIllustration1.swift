import AppKit

/// Tour step 1 (step 2 in UI): "Start by taking a screenshot"
/// Shows a wireframe app with dark dim overlay, bright selection cutout,
/// purple crosshair tick marks, and a dimension label pill.
final class TourIllustration1: NSView {

    private let wireframe: WireframeAppMock
    private let padding = DesignTokens.tourIllustrationPadding

    override init(frame frameRect: NSRect) {
        wireframe = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))
        super.init(frame: frameRect)
        wantsLayer = true
        addSubview(wireframe)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let w = bounds.width
        let h = bounds.height
        let contentW = w - padding * 2
        let contentH = h - padding * 2

        // Wireframe occupies the full content area
        let mockRect = CGRect(x: padding, y: padding, width: contentW, height: contentH)

        // -- Selection cutout: centered, ~65% width, ~45% height --
        let selW = floor(contentW * 0.65)
        let selH = floor(contentH * 0.45)
        let selX = mockRect.minX + floor((contentW - selW) / 2)
        let selY = mockRect.minY + floor((contentH - selH) / 2) + 8  // nudge up slightly

        let selRect = CGRect(x: selX, y: selY, width: selW, height: selH)

        // -- Dim overlay: 4 rectangles around the cutout --
        ctx.setFillColor(DesignTokens.dimOverlay.cgColor)

        // Bottom strip (below selection)
        ctx.fill(CGRect(x: mockRect.minX, y: mockRect.minY, width: contentW, height: selRect.minY - mockRect.minY))
        // Top strip (above selection)
        ctx.fill(CGRect(x: mockRect.minX, y: selRect.maxY, width: contentW, height: mockRect.maxY - selRect.maxY))
        // Left strip (between selection top/bottom)
        ctx.fill(CGRect(x: mockRect.minX, y: selRect.minY, width: selRect.minX - mockRect.minX, height: selH))
        // Right strip
        ctx.fill(CGRect(x: selRect.maxX, y: selRect.minY, width: mockRect.maxX - selRect.maxX, height: selH))

        // -- Selection border: 1.5px purple --
        let borderColor = DesignTokens.purpleLight.withAlphaComponent(DesignTokens.crosshairOpacity)
        ctx.setStrokeColor(borderColor.cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(selRect.insetBy(dx: 0.75, dy: 0.75))

        // -- Crosshair tick marks at bottom-right corner --
        let tickLen = DesignTokens.crosshairTickLength
        let tickW = DesignTokens.crosshairThickness
        let cornerX = selRect.maxX
        let cornerY = selRect.minY

        ctx.setFillColor(borderColor.cgColor)

        // Horizontal tick (extending right from corner)
        ctx.fill(CGRect(x: cornerX, y: cornerY - tickW / 2, width: tickLen, height: tickW))
        // Vertical tick (extending down from corner)
        ctx.fill(CGRect(x: cornerX - tickW / 2, y: cornerY - tickLen, width: tickW, height: tickLen))

        // -- Dimension label pill below selection --
        let dimGap = DesignTokens.dimensionLabelGap
        let dimH = DesignTokens.dimensionLabelHeight
        let dimRadius = DesignTokens.dimensionLabelCornerRadius
        let dimPadH = DesignTokens.dimensionLabelPaddingH

        let dimText = "420 × 270"
        let dimAttrs: [NSAttributedString.Key: Any] = [
            .font: DesignTokens.dimensionLabelFont,
            .foregroundColor: NSColor.white,
        ]
        let dimStr = NSAttributedString(string: dimText, attributes: dimAttrs)
        let dimTextSize = dimStr.size()
        let dimW = ceil(dimTextSize.width) + dimPadH * 2

        let dimX = selRect.midX - dimW / 2
        let dimY = selRect.minY - dimGap - dimH

        let dimRect = CGRect(x: dimX, y: dimY, width: dimW, height: dimH)
        let dimPath = CGPath(roundedRect: dimRect, cornerWidth: dimRadius, cornerHeight: dimRadius, transform: nil)

        ctx.setFillColor(DesignTokens.purpleDark.cgColor)
        ctx.addPath(dimPath)
        ctx.fillPath()

        // Dimension text centered in pill
        dimStr.draw(at: NSPoint(
            x: dimRect.midX - dimTextSize.width / 2,
            y: dimRect.midY - dimTextSize.height / 2
        ))
    }

    override func layout() {
        super.layout()
        let contentW = bounds.width - padding * 2
        let contentH = bounds.height - padding * 2
        wireframe.frame = CGRect(x: padding, y: padding, width: contentW, height: contentH)
    }
}
