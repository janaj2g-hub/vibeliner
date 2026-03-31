import AppKit

final class ShareExplanationPanel: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        let cardBg = NSColor(red: 250/255, green: 249/255, blue: 254/255, alpha: 1)
        let cardBorder = NSColor(red: 232/255, green: 229/255, blue: 245/255, alpha: 1)
        let titleColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)

        // Card 1: Copy Prompt
        let card1 = makeCard(
            title: "Copy Prompt",
            description: "For tools that read files, like Claude Code, Codex, or any terminal tool. Paste the text directly — the AI reads the screenshot from your disk.",
            titleColor: titleColor, bg: cardBg, border: cardBorder
        )
        addSubview(card1)

        // Card 2: Copy Image
        let card2 = makeCard(
            title: "Copy Image",
            description: "For chat apps like Claude.ai, ChatGPT, and Gemini. Paste the image alongside the prompt.",
            titleColor: titleColor, bg: cardBg, border: cardBorder
        )
        addSubview(card2)

        card1.frame = NSRect(x: 0, y: 60, width: 0, height: 0)
        card2.frame = NSRect(x: 0, y: 0, width: 0, height: 0)
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        let cardH: CGFloat = 70
        let gap: CGFloat = 8
        let totalH = cardH * 2 + gap
        let startY = (bounds.height - totalH) / 2

        if subviews.count >= 2 {
            subviews[0].frame = NSRect(x: 0, y: startY + cardH + gap, width: w, height: cardH)
            subviews[1].frame = NSRect(x: 0, y: startY, width: w, height: cardH)
        }
    }

    private func makeCard(title: String, description: String, titleColor: NSColor, bg: NSColor, border: NSColor) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.backgroundColor = bg.cgColor
        card.layer?.borderColor = border.cgColor
        card.layer?.borderWidth = 1
        card.layer?.cornerRadius = 10

        let titleField = NSTextField(labelWithString: title)
        titleField.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleField.textColor = titleColor
        titleField.frame = NSRect(x: 10, y: 44, width: 180, height: 16)
        card.addSubview(titleField)

        let descField = NSTextField(wrappingLabelWithString: description)
        descField.font = NSFont.systemFont(ofSize: 11)
        descField.textColor = NSColor(white: 0.35, alpha: 1)
        descField.isEditable = false
        descField.isBordered = false
        descField.drawsBackground = false
        descField.frame = NSRect(x: 10, y: 4, width: 170, height: 40)
        card.addSubview(descField)

        return card
    }
}
