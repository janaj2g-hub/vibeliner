import AppKit

final class FirstUseTooltipView: NSView {

    var onDismiss: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        wantsLayer = true
        // Prototype spec: rgba(28,28,32,0.96) bg, rgba(255,255,255,0.1) border
        layer?.backgroundColor = DesignTokens.tooltipDarkBg.cgColor
        layer?.borderColor = DesignTokens.tooltipDarkBorder.cgColor
        layer?.borderWidth = 1
        layer?.cornerRadius = 12
        layer?.shadowColor = NSColor.black.withAlphaComponent(0.4).cgColor
        layer?.shadowOffset = NSSize(width: 0, height: -8)
        layer?.shadowRadius = 32
        layer?.shadowOpacity = 1.0

        let width: CGFloat = 480
        var y: CGFloat = 6

        // "Got it" button at bottom
        let gotIt = NSButton(title: "Got it", target: self, action: #selector(gotItClicked))
        gotIt.isBordered = false
        gotIt.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        gotIt.contentTintColor = DesignTokens.purpleLight
        gotIt.frame = NSRect(x: (width - 40) / 2, y: y, width: 40, height: 20)
        addSubview(gotIt)
        y += 26

        // Divider: 1px solid rgba(255,255,255,0.06)
        let divider = NSView(frame: NSRect(x: 16, y: y, width: width - 32, height: 1))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.06).cgColor
        addSubview(divider)
        y += 11

        // App mode description
        let appLabel = makeBadge("App")
        appLabel.frame.origin = NSPoint(x: 16, y: y)
        addSubview(appLabel)
        let appDesc = makeDesc("Paste into Claude.ai, ChatGPT, or Gemini. Prompt + image.")
        appDesc.frame = NSRect(x: 16 + appLabel.frame.width + 6, y: y, width: width - 32 - appLabel.frame.width - 6, height: 16)
        addSubview(appDesc)
        y += 26

        // IDE mode description
        let ideLabel = makeBadge("IDE")
        ideLabel.frame.origin = NSPoint(x: 16, y: y)
        addSubview(ideLabel)
        let ideDesc = makeDesc("Paste into Claude Code, Codex, or terminal. Prompt only.")
        ideDesc.frame = NSRect(x: 16 + ideLabel.frame.width + 6, y: y, width: width - 32 - ideLabel.frame.width - 6, height: 16)
        addSubview(ideDesc)
        y += 26

        // Intro text
        let intro = makeDesc("Terminal tools can read files. Web chat apps cannot.")
        intro.textColor = NSColor(white: 1.0, alpha: 0.5)
        intro.frame = NSRect(x: 16, y: y, width: width - 32, height: 16)
        addSubview(intro)
        y += 28

        setFrameSize(NSSize(width: width, height: y))

        // Arrow pointing down (12px rotated square)
        let arrowSize: CGFloat = 12
        let arrow = NSView(frame: NSRect(x: width - 250 - arrowSize / 2, y: -arrowSize / 2, width: arrowSize, height: arrowSize))
        arrow.wantsLayer = true
        arrow.layer?.backgroundColor = DesignTokens.tooltipDarkBg.cgColor
        arrow.layer?.borderColor = DesignTokens.tooltipDarkBorder.cgColor
        arrow.layer?.borderWidth = 1
        arrow.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        arrow.layer?.transform = CATransform3DMakeRotation(.pi / 4, 0, 0, 1)
        addSubview(arrow)
    }

    private func makeBadge(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = DesignTokens.purpleLight
        label.isBezeled = false
        label.drawsBackground = false
        label.sizeToFit()

        let badge = NSView(frame: NSRect(x: 0, y: 0, width: label.frame.width + 20, height: 20))
        badge.wantsLayer = true
        badge.layer?.backgroundColor = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.2).cgColor
        badge.layer?.cornerRadius = 10

        label.frame.origin = NSPoint(x: 10, y: (20 - label.frame.height) / 2)
        badge.addSubview(label)

        return badge
    }

    private func makeDesc(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: 12)
        field.textColor = NSColor(white: 1.0, alpha: 0.45)
        field.isBezeled = false
        field.drawsBackground = false
        field.lineBreakMode = .byWordWrapping
        return field
    }

    @objc private func gotItClicked() {
        ConfigManager.shared.tooltipDismissed = true
        ConfigManager.shared.save()

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            self.animator().alphaValue = 0
        }) { [weak self] in
            self?.removeFromSuperview()
            self?.onDismiss?()
        }
    }
}
