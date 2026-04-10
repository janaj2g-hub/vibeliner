import AppKit

/// Tour step 4: "Give your AI the full picture"
/// Top ~30%: Two compact TourOutputCards (TourMiniScreenshot + TourPromptSheet).
/// Middle: Single TourFlowArrow pointing down.
/// Bottom ~50%: LLM panel with gradient dot + glow, bubble with tail, composer bar.
final class TourIllustration4: NSView {

    // Top section
    private let screenshotCard: TourOutputCard
    private let promptCard: TourOutputCard
    private let miniScreenshot: TourMiniScreenshot
    private let promptSheet: TourPromptSheet

    // Middle
    private let flowArrow: TourFlowArrow

    // Bottom: LLM panel
    private let llmPanel: NSView
    private let llmDot: NSView
    private let llmLabel: NSTextField
    private let chatBubble: NSView
    private let chatText: NSTextField
    private let composerBar: NSView
    private let thumbnailPlaceholder: NSView
    private let thumbnailBadge: TourAnnotationBadge
    private let composerLine1: NSView
    private let composerLine2: NSView
    private let composerLine3: NSView
    private let sendCircle: NSView

    private let padding = DesignTokens.tourIllustrationPadding
    private let sectionGap: CGFloat = 12

    override init(frame frameRect: NSRect) {
        // -- Top: output cards --
        screenshotCard = TourOutputCard(label: "screenshot.png")
        promptCard = TourOutputCard(label: "prompt.txt")

        // Mini screenshot with 2 badges (compact, no full wireframe)
        miniScreenshot = TourMiniScreenshot(
            badges: [(1, 8, 26), (2, 8, 52)]
        )

        promptSheet = TourPromptSheet(annotations: [
            TourPromptLine(index: 1, tool: "pin", note: "padding too tight"),
            TourPromptLine(index: 2, tool: "rect", note: "row spacing cramped"),
        ])

        // -- Middle: arrow --
        flowArrow = TourFlowArrow(height: 28)

        // -- Bottom: LLM panel --
        llmPanel = NSView()
        llmDot = NSView(frame: NSRect(x: 0, y: 0, width: DesignTokens.tourLLMDotSize, height: DesignTokens.tourLLMDotSize))
        llmLabel = NSTextField(labelWithString: "Your AI tool")

        chatBubble = NSView()
        chatText = NSTextField(wrappingLabelWithString:
            "The model sees each numbered badge on the image and reads the matching note in the prompt. No guessing required."
        )

        composerBar = NSView()
        thumbnailPlaceholder = NSView()
        thumbnailBadge = TourAnnotationBadge(number: 1)
        composerLine1 = NSView()
        composerLine2 = NSView()
        composerLine3 = NSView()
        sendCircle = NSView()

        super.init(frame: frameRect)
        wantsLayer = true

        // Configure screenshot card content
        screenshotCard.contentArea.addSubview(miniScreenshot)

        // Configure prompt card content
        promptCard.contentArea.addSubview(promptSheet)

        // Configure LLM panel
        llmPanel.wantsLayer = true
        llmPanel.layer?.cornerRadius = DesignTokens.tourLLMPanelRadius
        llmPanel.layer?.backgroundColor = DesignTokens.tourLLMPanelBg.cgColor
        llmPanel.layer?.borderWidth = 1
        llmPanel.layer?.borderColor = DesignTokens.tourLLMPanelBorder.cgColor

        llmDot.wantsLayer = true
        llmDot.layer?.cornerRadius = DesignTokens.tourLLMDotSize / 2

        llmLabel.font = DesignTokens.tourLLMHeaderFont
        llmLabel.textColor = DesignTokens.tourTextPrimary
        llmLabel.isBezeled = false
        llmLabel.drawsBackground = false
        llmLabel.isEditable = false
        llmLabel.sizeToFit()

        chatBubble.wantsLayer = true
        chatBubble.layer?.cornerRadius = 12
        chatBubble.layer?.backgroundColor = DesignTokens.tourLLMBubbleBg.cgColor

        chatText.font = DesignTokens.tourLLMBubbleFont
        chatText.textColor = DesignTokens.tourTextSecondary
        chatText.isBezeled = false
        chatText.drawsBackground = false
        chatText.isEditable = false
        chatText.lineBreakMode = .byWordWrapping
        chatText.maximumNumberOfLines = 0
        chatText.usesSingleLineMode = false

        composerBar.wantsLayer = true
        composerBar.layer?.cornerRadius = DesignTokens.tourLLMComposerRadius
        composerBar.layer?.backgroundColor = DesignTokens.tourLLMComposerBg.cgColor
        composerBar.layer?.borderWidth = 1
        composerBar.layer?.borderColor = DesignTokens.tourLLMComposerBorder.cgColor

        thumbnailPlaceholder.wantsLayer = true
        thumbnailPlaceholder.layer?.cornerRadius = DesignTokens.tourMiniScreenshotRadius
        thumbnailPlaceholder.layer?.backgroundColor = DesignTokens.tourWireframeBgBottom.cgColor

        for line in [composerLine1, composerLine2, composerLine3] {
            line.wantsLayer = true
            line.layer?.cornerRadius = 2
            line.layer?.backgroundColor = DesignTokens.dividerColor.cgColor
        }

        sendCircle.wantsLayer = true
        sendCircle.layer?.cornerRadius = DesignTokens.tourLLMSendSize / 2
        sendCircle.layer?.backgroundColor = DesignTokens.tourLLMSendBg.cgColor

        // Build hierarchy
        chatBubble.addSubview(chatText)

        composerBar.addSubview(thumbnailPlaceholder)
        composerBar.addSubview(thumbnailBadge)
        composerBar.addSubview(composerLine1)
        composerBar.addSubview(composerLine2)
        composerBar.addSubview(composerLine3)
        composerBar.addSubview(sendCircle)

        llmPanel.addSubview(llmDot)
        llmPanel.addSubview(llmLabel)
        llmPanel.addSubview(chatBubble)
        llmPanel.addSubview(composerBar)

        addSubview(screenshotCard)
        addSubview(promptCard)
        addSubview(flowArrow)
        addSubview(llmPanel)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2
        let contentH = h - padding * 2

        // Section heights
        let topH = floor(contentH * 0.30) - sectionGap / 2
        let arrowH: CGFloat = 28
        let bottomH = contentH - topH - arrowH - sectionGap * 2

        // AppKit: origin bottom-left
        let bottomY = padding
        let arrowY = bottomY + bottomH + sectionGap
        let topY = arrowY + arrowH + sectionGap

        // -- Top: two cards side by side --
        let cardGap: CGFloat = 10
        let cardW = (contentW - cardGap) / 2
        screenshotCard.frame = CGRect(x: padding, y: topY, width: cardW, height: topH)
        promptCard.frame = CGRect(x: padding + cardW + cardGap, y: topY, width: cardW, height: topH)

        // Force child layout so contentArea bounds are correct
        screenshotCard.layoutSubtreeIfNeeded()
        promptCard.layoutSubtreeIfNeeded()

        // Screenshot card: mini screenshot fills content area
        miniScreenshot.frame = screenshotCard.contentArea.bounds

        // Prompt card: prompt sheet fills content area
        promptSheet.frame = promptCard.contentArea.bounds

        // -- Middle: flow arrow --
        flowArrow.frame = CGRect(
            x: padding + (contentW - 14) / 2,
            y: arrowY,
            width: 14,
            height: arrowH
        )

        // -- Bottom: LLM panel --
        llmPanel.frame = CGRect(x: padding, y: bottomY, width: contentW, height: bottomH)

        let panelPad: CGFloat = 14
        let panelW = contentW

        // Purple dot + label at top-left
        let dotSize = DesignTokens.tourLLMDotSize
        let dotY = bottomH - panelPad - dotSize
        llmDot.frame = CGRect(x: panelPad, y: dotY, width: dotSize, height: dotSize)
        llmLabel.sizeToFit()
        llmLabel.frame.origin = NSPoint(
            x: panelPad + dotSize + 6,
            y: dotY + (dotSize - llmLabel.frame.height) / 2
        )

        // Composer bar at bottom
        let composerH: CGFloat = 44
        let composerY = panelPad
        composerBar.frame = CGRect(x: panelPad, y: composerY, width: panelW - panelPad * 2, height: composerH)
        let cBarW = composerBar.frame.width

        // Thumbnail in composer
        let thumbW = DesignTokens.tourLLMThumbWidth
        let thumbH = DesignTokens.tourLLMThumbHeight
        thumbnailPlaceholder.frame = CGRect(x: 8, y: (composerH - thumbH) / 2, width: thumbW, height: thumbH)
        thumbnailBadge.frame = CGRect(x: thumbW - 2, y: thumbH - 8, width: 14, height: 14)
        thumbnailBadge.layer?.cornerRadius = 7

        // Gray lines in composer
        let lineX = 8 + thumbW + 10
        let lineW = cBarW - lineX - 24 - 14
        composerLine1.frame = CGRect(x: lineX, y: composerH - 12, width: min(lineW, 100), height: 4)
        composerLine2.frame = CGRect(x: lineX, y: composerH - 20, width: min(lineW * 0.75, 75), height: 4)
        composerLine3.frame = CGRect(x: lineX, y: composerH - 28, width: min(lineW * 0.5, 50), height: 4)

        // Send circle
        let sendSize = DesignTokens.tourLLMSendSize
        sendCircle.frame = CGRect(x: cBarW - sendSize - 8, y: (composerH - sendSize) / 2, width: sendSize, height: sendSize)

        // Chat bubble between label and composer
        let bubbleTop = dotY - 10
        let bubbleBottom = composerY + composerH + 10
        let bubbleH = max(30, bubbleTop - bubbleBottom)
        chatBubble.frame = CGRect(x: panelPad, y: bubbleBottom, width: panelW - panelPad * 2, height: bubbleH)

        // Chat text inside bubble
        let bubblePad: CGFloat = 10
        let textW = chatBubble.frame.width - bubblePad * 2
        chatText.preferredMaxLayoutWidth = textW
        chatText.frame = CGRect(
            x: bubblePad,
            y: bubblePad,
            width: textW,
            height: max(0, bubbleH - bubblePad * 2)
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        // Draw purple gradient dot glow ring
        let dotFrame = llmDot.convert(llmDot.bounds, to: self)
        let dotCenter = CGPoint(x: dotFrame.midX, y: dotFrame.midY)
        let glowInset = DesignTokens.tourLLMDotGlowSize
        let glowRect = dotFrame.insetBy(dx: -glowInset, dy: -glowInset)
        ctx.setStrokeColor(DesignTokens.purpleLight.withAlphaComponent(0.25).cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: glowRect)

        // Draw purple gradient fill on the dot
        ctx.saveGState()
        ctx.addEllipse(in: dotFrame)
        ctx.clip()
        if let grad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                DesignTokens.purpleLight.cgColor,
                DesignTokens.purpleLight.blended(withFraction: 0.3, of: .white)?.cgColor ?? DesignTokens.purpleLight.cgColor,
            ] as CFArray,
            locations: [0, 1]
        ) {
            ctx.drawLinearGradient(
                grad,
                start: CGPoint(x: dotCenter.x, y: dotFrame.maxY),
                end: CGPoint(x: dotCenter.x, y: dotFrame.minY),
                options: []
            )
        }
        ctx.restoreGState()

        // Draw bubble tail at bottom-left of chat bubble
        let bubbleFrame = chatBubble.convert(chatBubble.bounds, to: self)
        let tailSize = DesignTokens.tourLLMBubbleTailSize
        let tailX = bubbleFrame.minX + 16
        let tailY = bubbleFrame.minY

        ctx.setFillColor(DesignTokens.tourLLMBubbleBg.cgColor)
        ctx.move(to: CGPoint(x: tailX, y: tailY))
        ctx.addLine(to: CGPoint(x: tailX + tailSize, y: tailY))
        ctx.addLine(to: CGPoint(x: tailX, y: tailY - tailSize))
        ctx.closePath()
        ctx.fillPath()

        // Draw send arrow icon in the send circle
        let sendFrame = sendCircle.convert(sendCircle.bounds, to: self)
        let cx = sendFrame.midX
        let cy = sendFrame.midY

        ctx.setFillColor(NSColor.white.cgColor)
        ctx.move(to: CGPoint(x: cx, y: cy + 5))
        ctx.addLine(to: CGPoint(x: cx + 4, y: cy - 3))
        ctx.addLine(to: CGPoint(x: cx - 4, y: cy - 3))
        ctx.closePath()
        ctx.fillPath()
    }
}
