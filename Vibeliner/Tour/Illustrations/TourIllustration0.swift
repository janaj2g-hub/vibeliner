import AppKit

/// Tour step 0: "Visual bugs are hard to describe"
/// Clean wireframe (no error highlights) with shadow, plus LLM strip below.
/// Content block is vertically centered in the pane.
final class TourIllustration0: NSView {

    private let shadowContainer: NSView
    private let appMock: WireframeAppMock
    private let llmStrip: NSView

    // LLM strip children
    private let dotView: LLMDotView
    private let llmLabel: NSTextField
    private let promptText: NSTextField

    private let padding = DesignTokens.tourIllustrationPadding
    private let gap: CGFloat = 16

    override init(frame frameRect: NSRect) {
        // Shadow container wraps the mock so shadow + corner clipping both work
        shadowContainer = NSView()
        appMock = WireframeAppMock(config: WireframeConfig(showErrorCard: false, showErrorRow: false))

        llmStrip = NSView()
        dotView = LLMDotView()
        llmLabel = NSTextField(labelWithString: "LLM")
        promptText = NSTextField(wrappingLabelWithString:
            "Can you fix this layout? The padding feels off on the first card and the table row below feels cramped. It\u{2019}s hard to point to the exact spots that need work\u{2026}"
        )

        super.init(frame: frameRect)
        wantsLayer = true

        // Shadow on container; mock keeps masksToBounds for corner clipping
        shadowContainer.wantsLayer = true
        shadowContainer.layer?.shadowColor = NSColor.black.cgColor
        shadowContainer.layer?.shadowOpacity = Float(effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? 0.25 : 0.15)
        shadowContainer.layer?.shadowOffset = CGSize(width: 0, height: -20)
        shadowContainer.layer?.shadowRadius = 30

        // LLM strip
        llmStrip.wantsLayer = true
        llmStrip.layer?.cornerRadius = DesignTokens.tourLLMPanelRadius
        llmStrip.layer?.backgroundColor = DesignTokens.tourLLMPanelBg.cgColor
        llmStrip.layer?.borderWidth = 1
        llmStrip.layer?.borderColor = DesignTokens.tourLLMPanelBorder.cgColor

        // LLM label
        llmLabel.font = DesignTokens.tourLLMHeaderFont
        llmLabel.textColor = DesignTokens.tourTextPrimary
        llmLabel.isBezeled = false
        llmLabel.drawsBackground = false
        llmLabel.isEditable = false
        llmLabel.sizeToFit()

        // Prompt text (monospace, dim)
        promptText.font = DesignTokens.tourLLMChatFont
        promptText.textColor = DesignTokens.tourLLMChatColor
        promptText.isBezeled = false
        promptText.drawsBackground = false
        promptText.isEditable = false
        promptText.lineBreakMode = .byWordWrapping
        promptText.maximumNumberOfLines = 0
        promptText.usesSingleLineMode = false

        shadowContainer.addSubview(appMock)
        addSubview(shadowContainer)
        llmStrip.addSubview(dotView)
        llmStrip.addSubview(llmLabel)
        llmStrip.addSubview(promptText)
        addSubview(llmStrip)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        shadowContainer.layer?.shadowOpacity = Float(isDark ? 0.25 : 0.15)
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2

        // Compute mock height (~63% of available content)
        let contentH = h - padding * 2
        let mockH = floor(contentH * 0.63)

        // Compute LLM strip height from content
        let stripPad: CGFloat = 14
        let dotSize = DesignTokens.tourLLMDotSize
        let glowPad: CGFloat = 4
        let dotViewSize = dotSize + glowPad * 2

        llmLabel.sizeToFit()
        let headerH = max(dotViewSize, llmLabel.frame.height)

        let textW = contentW - stripPad * 2
        promptText.preferredMaxLayoutWidth = textW
        let textSize = promptText.sizeThatFits(NSSize(width: textW, height: .greatestFiniteMagnitude))

        let stripH = stripPad + headerH + 6 + 8 + textSize.height + stripPad

        // Total content block height and vertical centering
        let totalBlockH = mockH + gap + stripH
        let blockOriginY = padding + (contentH - totalBlockH) / 2

        // Position strip at bottom of centered block, mock above
        let stripY = blockOriginY
        let mockY = stripY + stripH + gap

        shadowContainer.frame = CGRect(x: padding, y: mockY, width: contentW, height: mockH)
        appMock.frame = shadowContainer.bounds
        shadowContainer.layer?.shadowPath = CGPath(
            roundedRect: shadowContainer.bounds,
            cornerWidth: DesignTokens.tourWireframeRadius,
            cornerHeight: DesignTokens.tourWireframeRadius,
            transform: nil
        )

        llmStrip.frame = CGRect(x: padding, y: max(padding, stripY), width: contentW, height: stripH)

        // Text at bottom of strip
        promptText.frame = CGRect(x: stripPad, y: stripPad, width: textW, height: textSize.height)

        // Header at top of strip
        let headerBaseY = stripH - stripPad - headerH

        // Dot view (glow extends 4px beyond the 7px dot)
        dotView.frame = CGRect(
            x: stripPad - glowPad,
            y: headerBaseY + (headerH - dotViewSize) / 2,
            width: dotViewSize,
            height: dotViewSize
        )

        // LLM label (7px gap from dot visual edge)
        llmLabel.frame.origin = NSPoint(
            x: stripPad + dotSize + 7,
            y: headerBaseY + (headerH - llmLabel.frame.height) / 2
        )
    }
}

// MARK: - Purple gradient dot with glow ring

private final class LLMDotView: NSView {

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let dotSize = DesignTokens.tourLLMDotSize
        let cx = bounds.midX
        let cy = bounds.midY

        // Glow ring: 4px spread, purpleLight at 12%
        let glowR = (dotSize + 8) / 2
        ctx.setFillColor(DesignTokens.purpleLight.withAlphaComponent(0.12).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - glowR, y: cy - glowR, width: glowR * 2, height: glowR * 2))

        // Gradient dot (135deg: purpleLight -> purpleDark)
        let dotR = dotSize / 2
        let dotRect = CGRect(x: cx - dotR, y: cy - dotR, width: dotSize, height: dotSize)
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: [DesignTokens.purpleLight.cgColor, DesignTokens.purpleDark.cgColor] as CFArray,
                                     locations: [0, 1]) {
            ctx.saveGState()
            ctx.addEllipse(in: dotRect)
            ctx.clip()
            ctx.drawLinearGradient(gradient, start: dotRect.origin,
                                   end: CGPoint(x: dotRect.maxX, y: dotRect.maxY), options: [])
            ctx.restoreGState()
        }
    }
}
