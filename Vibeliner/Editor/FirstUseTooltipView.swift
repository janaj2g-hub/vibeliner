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
        layer?.backgroundColor = DesignTokens.tooltipBg.cgColor
        layer?.borderColor = DesignTokens.tooltipBorder.cgColor
        layer?.borderWidth = 1
        layer?.cornerRadius = 12
        layer?.shadowColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.1).cgColor
        layer?.shadowOffset = NSSize(width: 0, height: -4)
        layer?.shadowRadius = 16
        layer?.shadowOpacity = 1.0

        let width: CGFloat = 380
        var y: CGFloat = 8

        // Got it button
        let gotIt = NSButton(title: "Got it", target: self, action: #selector(gotItClicked))
        gotIt.isBordered = false
        gotIt.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        gotIt.contentTintColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)
        gotIt.frame = NSRect(x: (width - 40) / 2, y: y, width: 40, height: 20)
        addSubview(gotIt)
        y += 28

        // Divider
        let divider = NSView(frame: NSRect(x: 16, y: y, width: width - 32, height: 1))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = DesignTokens.tooltipBorder.cgColor
        addSubview(divider)
        y += 13

        // App block
        let appTitle = makeTitle("App")
        appTitle.frame = NSRect(x: 16, y: y + 16, width: width - 32, height: 16)
        addSubview(appTitle)
        let appDesc = makeDesc("Choose when pasting into Claude.ai, ChatGPT, or Gemini. You'll copy the prompt and the image in two steps.")
        appDesc.frame = NSRect(x: 16, y: y, width: width - 32, height: 16)
        addSubview(appDesc)
        y += 42

        // IDE block
        let ideTitle = makeTitle("IDE")
        ideTitle.frame = NSRect(x: 16, y: y + 16, width: width - 32, height: 16)
        addSubview(ideTitle)
        let ideDesc = makeDesc("Choose when pasting into Claude Code, Codex, or any terminal. You only need the prompt.")
        ideDesc.frame = NSRect(x: 16, y: y, width: width - 32, height: 16)
        addSubview(ideDesc)
        y += 50

        // Intro text
        let intro = makeDesc("Terminal tools can read files on your computer. Web chat apps cannot. Select a mode based on your workflow.")
        intro.frame = NSRect(x: 16, y: y, width: width - 32, height: 16)
        addSubview(intro)
        y += 28

        setFrameSize(NSSize(width: width, height: y))
    }

    private func makeTitle(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        field.textColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)
        return field
    }

    private func makeDesc(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: 12)
        field.textColor = NSColor(white: 0.33, alpha: 1)
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
