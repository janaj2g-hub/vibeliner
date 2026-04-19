import AppKit

enum TourToolType { case pin, arrow, rect, circle, freehand }
enum TourModeType { case ide, app }

struct TourMiniToolbarConfig {
    var activeTool: TourToolType = .pin
    var mode: TourModeType = .app
    var showToolSection: Bool = true
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
        if config.showToolSection {
            let toolsSectionWidth = CGFloat(5) * toolSize + CGFloat(4) * toolSpacing
            totalWidth += toolsSectionWidth + sectionPadding
            totalWidth += dividerWidth + sectionPadding
        }
        totalWidth += toggleWidth + sectionPadding
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
        layer?.borderColor = DesignTokens.neutralBorder.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { bounds.size }

    override func updateLayer() {
        layer?.backgroundColor = DesignTokens.toolbarBg.cgColor
        layer?.borderColor = DesignTokens.neutralBorder.cgColor
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
            ctx.setStrokeColor(DesignTokens.neutralDim.cgColor)
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
            ctx.setFillColor(DesignTokens.dynamicColor(dark: DesignTokens.neutralHairline, light: DesignTokens.neutralBorder).cgColor)
            ctx.fill(CGRect(x: x, y: h * 0.2, width: dividerWidth, height: h * 0.6))
            x += dividerWidth + sectionPadding
        }

        // -- Tool buttons --
        if config.showToolSection {
            let tools: [TourToolType] = [.pin, .arrow, .rect, .circle, .freehand]
            for tool in tools {
                let toolY = (h - toolSize) / 2
                let toolRect = CGRect(x: x, y: toolY, width: toolSize, height: toolSize)

                if tool == config.activeTool {
                    ctx.setFillColor(DesignTokens.purpleSubtle.cgColor)
                    ctx.fillEllipse(in: toolRect)
                }

                let iconColor = tool == config.activeTool
                    ? DesignTokens.purpleBrand
                    : DesignTokens.neutralDim

                switch tool {
                case .pin:
                    ToolbarView.drawPinIcon(toolRect, iconColor)
                case .arrow:
                    ToolbarView.drawArrowIcon(toolRect, iconColor)
                case .rect:
                    ToolbarView.drawRectIcon(toolRect, iconColor)
                case .circle:
                    ToolbarView.drawCircleIcon(toolRect, iconColor)
                case .freehand:
                    ToolbarView.drawFreehandIcon(toolRect, iconColor)
                }

                x += toolSize + toolSpacing
            }
            x += sectionPadding - toolSpacing

            // -- Divider --
            ctx.setFillColor(DesignTokens.dynamicColor(dark: DesignTokens.neutralHairline, light: DesignTokens.neutralBorder).cgColor)
            ctx.fill(CGRect(x: x, y: h * 0.2, width: dividerWidth, height: h * 0.6))
            x += dividerWidth + sectionPadding
        }

        // -- IDE / App toggle --
        drawModeToggle(ctx: ctx, x: x, h: h)
        x += toggleWidth + sectionPadding

        // -- Copy / Add Image buttons --
        if config.showCopyPrompt || config.showCopyImage || config.showAddImage {
            ctx.setFillColor(DesignTokens.dynamicColor(dark: DesignTokens.neutralHairline, light: DesignTokens.neutralBorder).cgColor)
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

    // MARK: - Mode Toggle

    private func drawModeToggle(ctx: CGContext, x: CGFloat, h: CGFloat) {
        let toggleY = (h - toggleHeight) / 2
        let toggleRect = CGRect(x: x, y: toggleY, width: toggleWidth, height: toggleHeight)

        // Track background
        ctx.setFillColor(DesignTokens.neutralHairline.withAlphaComponent(0.03).cgColor)
        let togglePath = CGPath(roundedRect: toggleRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(togglePath)
        ctx.fillPath()

        // Active segment pill
        let ideActive = config.mode == .ide
        let activeX = ideActive ? x : x + toggleSegmentWidth
        let segRect = CGRect(x: activeX + 2, y: toggleY + 2, width: toggleSegmentWidth - 4, height: toggleHeight - 4)
        ctx.setFillColor(DesignTokens.purpleSubtle.cgColor)
        let segPath = CGPath(roundedRect: segRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(segPath)
        ctx.fillPath()

        // Labels
        let ideAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: ideActive ? DesignTokens.purpleBrand : DesignTokens.neutralStrong,
        ]
        let appAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: ideActive ? DesignTokens.neutralStrong : DesignTokens.purpleBrand,
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

        ctx.setFillColor(DesignTokens.purpleStrong.cgColor)
        let path = CGPath(roundedRect: pillRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()

        ctx.setStrokeColor(DesignTokens.purpleBrand.cgColor)
        ctx.setLineWidth(1)
        ctx.addPath(path)
        ctx.strokePath()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8, weight: .bold),
            .foregroundColor: DesignTokens.purpleBrand,
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
            .foregroundColor: DesignTokens.purpleBrand,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let size = str.size()
        str.draw(at: NSPoint(x: pillRect.midX - size.width / 2, y: pillRect.midY - size.height / 2))
        return x + width
    }
}
