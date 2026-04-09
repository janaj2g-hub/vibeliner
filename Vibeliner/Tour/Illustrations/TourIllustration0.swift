import AppKit

/// Tour step 0: "Visual bugs are hard to describe"
/// Top ~65%: WireframeAppMock with both errors and shadow.
/// Bottom ~35%: LLM strip with purple dot, label, and monospace text.
final class TourIllustration0: NSView {

    private let appMock: WireframeAppMock
    private let llmStrip: NSView

    // LLM strip children
    private let purpleDot: NSView
    private let llmLabel: NSTextField
    private let promptText: NSTextField

    private let padding: CGFloat = 24
    private let gap: CGFloat = 16

    override init(frame frameRect: NSRect) {
        // App mock with both errors visible
        appMock = WireframeAppMock(config: WireframeConfig(showErrorCard: true, showErrorRow: true))

        // LLM strip container
        llmStrip = NSView()

        // Purple dot
        purpleDot = NSView(frame: NSRect(x: 0, y: 0, width: 7, height: 7))

        // "LLM" label
        llmLabel = NSTextField(labelWithString: "LLM")

        // Monospace prompt text
        promptText = NSTextField(wrappingLabelWithString:
            "Can you fix this layout? The padding feels off on the first card and the table row below feels cramped. It's hard to point to the exact spots that need work..."
        )

        super.init(frame: frameRect)
        wantsLayer = true

        // Configure app mock shadow
        appMock.wantsLayer = true
        appMock.layer?.masksToBounds = false
        appMock.layer?.shadowColor = NSColor.black.cgColor
        appMock.layer?.shadowOpacity = 0.3
        appMock.layer?.shadowOffset = CGSize(width: 0, height: -4)
        appMock.layer?.shadowRadius = 16

        // Configure LLM strip
        llmStrip.wantsLayer = true
        llmStrip.layer?.cornerRadius = 8
        llmStrip.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.03).cgColor
        llmStrip.layer?.borderWidth = 1
        llmStrip.layer?.borderColor = DesignTokens.chromeBorder.cgColor

        // Purple dot
        purpleDot.wantsLayer = true
        purpleDot.layer?.cornerRadius = 3.5
        purpleDot.layer?.backgroundColor = DesignTokens.purpleLight.cgColor

        // LLM label
        llmLabel.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        llmLabel.textColor = DesignTokens.tourTextSecondary
        llmLabel.isBezeled = false
        llmLabel.drawsBackground = false
        llmLabel.isEditable = false
        llmLabel.sizeToFit()

        // Prompt text
        promptText.font = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)
        promptText.textColor = DesignTokens.tourTextDim
        promptText.isBezeled = false
        promptText.drawsBackground = false
        promptText.isEditable = false
        promptText.lineBreakMode = .byWordWrapping
        promptText.maximumNumberOfLines = 0
        promptText.usesSingleLineMode = false

        addSubview(appMock)
        llmStrip.addSubview(purpleDot)
        llmStrip.addSubview(llmLabel)
        llmStrip.addSubview(promptText)
        addSubview(llmStrip)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2
        let contentH = h - padding * 2

        // Top ~65% for app mock
        let mockH = floor(contentH * 0.65) - gap / 2
        let mockY = padding + (contentH - mockH) + gap / 2  // top-aligned in flipped coords... AppKit is bottom-up

        // Bottom ~35% for LLM strip
        let stripH = floor(contentH * 0.35) - gap / 2
        let stripY = padding

        // In AppKit coordinate system (origin at bottom-left):
        // LLM strip at bottom, app mock at top
        llmStrip.frame = CGRect(x: padding, y: stripY, width: contentW, height: stripH)
        appMock.frame = CGRect(x: padding, y: stripY + stripH + gap, width: contentW, height: mockH)

        // Position LLM strip children
        let stripPad: CGFloat = 12

        // Purple dot + LLM label on top-left of strip
        let dotY = stripH - stripPad - 7
        purpleDot.frame = CGRect(x: stripPad, y: dotY, width: 7, height: 7)

        llmLabel.sizeToFit()
        llmLabel.frame.origin = NSPoint(
            x: stripPad + 7 + 6,
            y: dotY + (7 - llmLabel.frame.height) / 2
        )

        // Prompt text below dot/label
        let textTop = dotY - 8
        let textW = contentW - stripPad * 2
        promptText.preferredMaxLayoutWidth = textW
        promptText.frame = CGRect(
            x: stripPad,
            y: stripPad,
            width: textW,
            height: max(0, textTop - stripPad)
        )
    }
}
