import AppKit

enum TourToolType { case pin, arrow, rect, circle, freehand }
enum TourModeType { case ide, app }

struct TourMiniToolbarConfig {
    var activeTool: TourToolType = .pin
    var mode: TourModeType = .app
    var showCopyPrompt: Bool = true
    var showCopyImage: Bool = true
    var showAddImage: Bool = false
    var showCloseButton: Bool = false
}

/// Miniature toolbar pill used in tour illustrations.
/// Uses appearance-aware `toolbar*` tokens so it responds to light/dark mode.
/// Lays out: [close] | tool buttons | divider | IDE/App toggle | divider | copy buttons
final class TourMiniToolbar: NSView {

    private let config: TourMiniToolbarConfig

    // Layout constants
    private let barHeight: CGFloat = 36
    private let toolSize: CGFloat = 24
    private let toolSpacing: CGFloat = 4
    private let sectionPadding: CGFloat = 8
    private let dividerWidth: CGFloat = 1
    private let copyPillHeight: CGFloat = 20
    private let toggleWidth: CGFloat = 72
    private let toggleHeight: CGFloat = 20
    private let toggleSegmentWidth: CGFloat = 36

    init(config: TourMiniToolbarConfig = TourMiniToolbarConfig()) {
        self.config = config
        // Calculate total width
        var totalWidth: CGFloat = sectionPadding
        if config.showCloseButton {
            totalWidth += toolSize + toolSpacing + dividerWidth + sectionPadding
        }
        let toolsSectionWidth = CGFloat(5) * toolSize + CGFloat(4) * toolSpacing
        totalWidth += toolsSectionWidth + sectionPadding
        totalWidth += dividerWidth + sectionPadding + toggleWidth + sectionPadding
        if config.showCopyPrompt || config.showCopyImage || config.showAddImage {
            totalWidth += dividerWidth + sectionPadding
            if config.showCopyPrompt { totalWidth += 70 + toolSpacing }
            if config.showCopyImage { totalWidth += 66 + toolSpacing }
            if config.showAddImage { totalWidth += 64 + toolSpacing }
            totalWidth += sectionPadding - toolSpacing
        }
        super.init(frame: NSRect(x: 0, y: 0, width: totalWidth, height: barHeight))
        wantsLayer = true
        layer?.cornerRadius = 999
        layer?.masksToBounds = true
        layer?.backgroundColor = DesignTokens.toolbarBg.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = DesignTokens.toolbarBorder.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { bounds.size }

    override func updateLayer() {
        layer?.backgroundColor = DesignTokens.toolbarBg.cgColor
        layer?.borderColor = DesignTokens.toolbarBorder.cgColor
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let h = bounds.height
        var x: CGFloat = sectionPadding

        // -- Close button (if shown) --
        if config.showCloseButton {
            let toolY = (h - toolSize) / 2
            let cx = x + toolSize / 2
            let cy = toolY + toolSize / 2
            ctx.setStrokeColor(DesignTokens.toolbarIconDefault.cgColor)
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)
            let s: CGFloat = 3.5
            ctx.move(to: CGPoint(x: cx - s, y: cy - s))
            ctx.addLine(to: CGPoint(x: cx + s, y: cy + s))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: cx + s, y: cy - s))
            ctx.addLine(to: CGPoint(x: cx - s, y: cy + s))
            ctx.strokePath()
            x += toolSize + toolSpacing

            // Divider after close
            ctx.setFillColor(DesignTokens.toolbarDivider.cgColor)
            ctx.fill(CGRect(x: x, y: h * 0.2, width: dividerWidth, height: h * 0.6))
            x += dividerWidth + sectionPadding
        }

        // -- Tool buttons --
        let tools: [TourToolType] = [.pin, .arrow, .rect, .circle, .freehand]
        for tool in tools {
            let toolY = (h - toolSize) / 2
            let toolRect = CGRect(x: x, y: toolY, width: toolSize, height: toolSize)

            if tool == config.activeTool {
                ctx.setFillColor(DesignTokens.toolbarToolActiveBg.cgColor)
                ctx.fillEllipse(in: toolRect)
            }

            let iconColor = tool == config.activeTool
                ? DesignTokens.toolbarPurpleActive.cgColor
                : DesignTokens.toolbarIconDefault.cgColor
            ctx.setStrokeColor(iconColor)
            ctx.setFillColor(iconColor)
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)

            let cx = toolRect.midX
            let cy = toolRect.midY

            switch tool {
            case .pin:    drawPinIcon(ctx: ctx, cx: cx, cy: cy)
            case .arrow:  drawArrowIcon(ctx: ctx, cx: cx, cy: cy)
            case .rect:   drawRectIcon(ctx: ctx, cx: cx, cy: cy)
            case .circle: drawCircleIcon(ctx: ctx, cx: cx, cy: cy)
            case .freehand: drawFreehandIcon(ctx: ctx, cx: cx, cy: cy)
            }

            x += toolSize + toolSpacing
        }
        x += sectionPadding - toolSpacing

        // -- Divider --
        ctx.setFillColor(DesignTokens.toolbarDivider.cgColor)
        ctx.fill(CGRect(x: x, y: h * 0.2, width: dividerWidth, height: h * 0.6))
        x += dividerWidth + sectionPadding

        // -- IDE / App toggle --
        drawModeToggle(ctx: ctx, x: x, h: h)
        x += toggleWidth + sectionPadding

        // -- Copy / Add Image buttons --
        if config.showCopyPrompt || config.showCopyImage || config.showAddImage {
            ctx.setFillColor(DesignTokens.toolbarDivider.cgColor)
            ctx.fill(CGRect(x: x, y: h * 0.2, width: dividerWidth, height: h * 0.6))
            x += dividerWidth + sectionPadding

            if config.showCopyPrompt {
                x = drawCopyPill(ctx: ctx, text: "Copy Prompt", x: x, h: h, width: 70)
                x += toolSpacing
            }
            if config.showCopyImage {
                x = drawCopyPill(ctx: ctx, text: "Copy Image", x: x, h: h, width: 66)
                x += toolSpacing
            }
            if config.showAddImage {
                x = drawAddImagePill(ctx: ctx, text: "+ Add image", x: x, h: h, width: 64)
            }
        }
    }

    // MARK: - Tool Icons

    private func drawPinIcon(ctx: CGContext, cx: CGFloat, cy: CGFloat) {
        let circleR: CGFloat = 3
        ctx.strokeEllipse(in: CGRect(x: cx - circleR, y: cy, width: circleR * 2, height: circleR * 2))
        ctx.move(to: CGPoint(x: cx, y: cy))
        ctx.addLine(to: CGPoint(x: cx, y: cy - 4))
        ctx.strokePath()
    }

    private func drawArrowIcon(ctx: CGContext, cx: CGFloat, cy: CGFloat) {
        let len: CGFloat = 5
        ctx.move(to: CGPoint(x: cx - len, y: cy - len))
        ctx.addLine(to: CGPoint(x: cx + len, y: cy + len))
        ctx.strokePath()
        let chev: CGFloat = 3
        ctx.move(to: CGPoint(x: cx + len - chev, y: cy + len))
        ctx.addLine(to: CGPoint(x: cx + len, y: cy + len))
        ctx.addLine(to: CGPoint(x: cx + len, y: cy + len - chev))
        ctx.strokePath()
    }

    private func drawRectIcon(ctx: CGContext, cx: CGFloat, cy: CGFloat) {
        let s: CGFloat = 5
        let rect = CGRect(x: cx - s, y: cy - s + 1, width: s * 2, height: s * 2 - 2)
        let path = CGPath(roundedRect: rect, cornerWidth: 2, cornerHeight: 2, transform: nil)
        ctx.addPath(path)
        ctx.strokePath()
    }

    private func drawCircleIcon(ctx: CGContext, cx: CGFloat, cy: CGFloat) {
        let r: CGFloat = 5
        ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
    }

    private func drawFreehandIcon(ctx: CGContext, cx: CGFloat, cy: CGFloat) {
        ctx.move(to: CGPoint(x: cx - 6, y: cy))
        ctx.addCurve(to: CGPoint(x: cx, y: cy),
                     control1: CGPoint(x: cx - 4, y: cy + 4),
                     control2: CGPoint(x: cx - 2, y: cy - 4))
        ctx.addCurve(to: CGPoint(x: cx + 6, y: cy),
                     control1: CGPoint(x: cx + 2, y: cy + 4),
                     control2: CGPoint(x: cx + 4, y: cy - 4))
        ctx.strokePath()
    }

    // MARK: - Mode Toggle

    private func drawModeToggle(ctx: CGContext, x: CGFloat, h: CGFloat) {
        let toggleY = (h - toggleHeight) / 2
        let toggleRect = CGRect(x: x, y: toggleY, width: toggleWidth, height: toggleHeight)

        // Track background
        ctx.setFillColor(DesignTokens.toolbarToggleBg.cgColor)
        let togglePath = CGPath(roundedRect: toggleRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(togglePath)
        ctx.fillPath()

        // Active segment pill
        let ideActive = config.mode == .ide
        let activeX = ideActive ? x : x + toggleSegmentWidth
        let segRect = CGRect(x: activeX + 2, y: toggleY + 2, width: toggleSegmentWidth - 4, height: toggleHeight - 4)
        ctx.setFillColor(DesignTokens.toolbarToggleActiveBg.cgColor)
        let segPath = CGPath(roundedRect: segRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(segPath)
        ctx.fillPath()

        // Labels
        let ideAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: ideActive ? DesignTokens.toolbarPurpleActive : DesignTokens.toolbarToggleInactiveText,
        ]
        let appAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: ideActive ? DesignTokens.toolbarToggleInactiveText : DesignTokens.toolbarPurpleActive,
        ]
        let ideStr = NSAttributedString(string: "IDE", attributes: ideAttrs)
        let appStr = NSAttributedString(string: "App", attributes: appAttrs)
        let ideSize = ideStr.size()
        let appSize = appStr.size()
        ideStr.draw(at: NSPoint(
            x: x + (toggleSegmentWidth - ideSize.width) / 2,
            y: toggleY + (toggleHeight - ideSize.height) / 2
        ))
        appStr.draw(at: NSPoint(
            x: x + toggleSegmentWidth + (toggleSegmentWidth - appSize.width) / 2,
            y: toggleY + (toggleHeight - appSize.height) / 2
        ))
    }

    // MARK: - Copy Pills

    private func drawCopyPill(ctx: CGContext, text: String, x: CGFloat, h: CGFloat, width: CGFloat) -> CGFloat {
        let pillY = (h - 20) / 2
        let pillRect = CGRect(x: x, y: pillY, width: width, height: 20)

        ctx.setFillColor(DesignTokens.toolbarPurpleButtonBg.cgColor)
        let path = CGPath(roundedRect: pillRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()

        ctx.setStrokeColor(DesignTokens.toolbarPurpleButtonBorder.cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(path)
        ctx.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: DesignTokens.toolbarPurpleButtonText,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let size = str.size()
        str.draw(at: NSPoint(x: pillRect.midX - size.width / 2, y: pillRect.midY - size.height / 2))
        return x + width
    }

    // MARK: - Add Image Pill

    private func drawAddImagePill(ctx: CGContext, text: String, x: CGFloat, h: CGFloat, width: CGFloat) -> CGFloat {
        let pillY = (h - 20) / 2
        let pillRect = CGRect(x: x, y: pillY, width: width, height: 20)

        ctx.setFillColor(DesignTokens.addImageBg.cgColor)
        let path = CGPath(roundedRect: pillRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()

        ctx.setStrokeColor(DesignTokens.addImageBorder.cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(path)
        ctx.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: DesignTokens.toolbarPurpleButtonText,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let size = str.size()
        str.draw(at: NSPoint(x: pillRect.midX - size.width / 2, y: pillRect.midY - size.height / 2))
        return x + width
    }
}
