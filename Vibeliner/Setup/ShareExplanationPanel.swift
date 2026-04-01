import AppKit

final class ShareExplanationPanel: NSView {

    private let cardBg = NSColor(red: 238/255, green: 237/255, blue: 254/255, alpha: 1)        // #EEEDFE
    private let cardBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1)    // #AFA9EC
    private let cardTextColor = NSColor(red: 60/255, green: 52/255, blue: 137/255, alpha: 1)   // #3C3489

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        let card1 = makeCard(
            title: "Copy Prompt",
            description: "For tools that read files, like Claude Code, Codex, or any terminal tool. Paste the text directly — the AI reads the screenshot from your disk."
        )
        addSubview(card1)

        let card2 = makeCard(
            title: "Copy Image",
            description: "For chat apps like Claude.ai, ChatGPT, and Gemini. Paste the image alongside the prompt."
        )
        addSubview(card2)
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        let cardH: CGFloat = 72
        let gap: CGFloat = 8
        let totalH = cardH * 2 + gap
        let startY = (bounds.height - totalH) / 2

        if subviews.count >= 2 {
            subviews[0].frame = NSRect(x: 0, y: startY + cardH + gap, width: w, height: cardH)
            subviews[1].frame = NSRect(x: 0, y: startY, width: w, height: cardH)
        }
    }

    private func makeCard(title: String, description: String) -> NSView {
        let card = NSView()
        card.wantsLayer = true
        card.layer?.backgroundColor = cardBg.cgColor
        card.layer?.borderColor = cardBorder.cgColor
        card.layer?.borderWidth = 1
        card.layer?.cornerRadius = 8

        let titleField = NSTextField(labelWithString: title)
        titleField.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleField.textColor = cardTextColor
        titleField.frame = NSRect(x: 12, y: 46, width: 160, height: 16)
        card.addSubview(titleField)

        let descField = NSTextField(wrappingLabelWithString: description)
        descField.font = NSFont.systemFont(ofSize: 12)
        descField.textColor = cardTextColor.withAlphaComponent(0.8)
        descField.isEditable = false
        descField.isBordered = false
        descField.drawsBackground = false
        descField.frame = NSRect(x: 12, y: 4, width: 160, height: 40)
        card.addSubview(descField)

        return card
    }
}
