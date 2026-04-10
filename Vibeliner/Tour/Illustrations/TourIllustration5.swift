import AppKit

/// Tour step 5: "One paste or two"
/// Two rows separated by a 1px divider.
/// Row 1: TERMINAL TOOLS — IDE mode toolbar + mode card with chip pills.
/// Row 2: CHAT TOOLS — App mode toolbar + mode card with chip pills.
final class TourIllustration5: NSView {

    // Row 1
    private let terminalLabel: NSTextField
    private let ideToolbar: TourMiniToolbar
    private let ideCard: NSView
    private let ideTitleLabel: NSTextField
    private let ideDescLabel: NSTextField
    private let ideChip1: NSView
    private let ideChip2: NSView
    private let ideChip3: NSView

    // Divider
    private let divider: NSView

    // Row 2
    private let chatLabel: NSTextField
    private let appToolbar: TourMiniToolbar
    private let appCard: NSView
    private let appTitleLabel: NSTextField
    private let appDescLabel: NSTextField
    private let appChip1: NSView
    private let appChip2: NSView
    private let appChip3: NSView

    private let padding = DesignTokens.tourIllustrationPadding

    override init(frame frameRect: NSRect) {
        // -- Row 1: Terminal Tools --
        terminalLabel = NSTextField(labelWithString: "TERMINAL TOOLS")
        ideToolbar = TourMiniToolbar(config: TourMiniToolbarConfig(
            activeTool: .pin,
            mode: .ide,
            showCopyPrompt: true,
            showCopyImage: false,
            showAddImage: false
        ))
        ideCard = NSView()
        ideTitleLabel = NSTextField(labelWithString: "IDE mode")
        ideDescLabel = NSTextField(wrappingLabelWithString: "One paste. The prompt includes the file path so the AI reads the screenshot from your disk.")

        ideChip1 = TourIllustration5.makeChip("Claude Code")
        ideChip2 = TourIllustration5.makeChip("Codex")
        ideChip3 = TourIllustration5.makeChip("Terminal")

        // -- Divider --
        divider = NSView()

        // -- Row 2: Chat Tools --
        chatLabel = NSTextField(labelWithString: "CHAT TOOLS")
        appToolbar = TourMiniToolbar(config: TourMiniToolbarConfig(
            activeTool: .pin,
            mode: .app,
            showCopyPrompt: true,
            showCopyImage: true,
            showAddImage: false
        ))
        appCard = NSView()
        appTitleLabel = NSTextField(labelWithString: "App mode")
        appDescLabel = NSTextField(wrappingLabelWithString: "Two pastes. Copy the prompt and the image separately into the chat window.")

        appChip1 = TourIllustration5.makeChip("Claude.ai")
        appChip2 = TourIllustration5.makeChip("ChatGPT")
        appChip3 = TourIllustration5.makeChip("Gemini")

        super.init(frame: frameRect)
        wantsLayer = true

        // Section labels
        for label in [terminalLabel, chatLabel] {
            label.font = DesignTokens.tourModeSectionFont
            label.textColor = DesignTokens.tourTextDim
            label.isBezeled = false
            label.drawsBackground = false
            label.isEditable = false
            label.sizeToFit()
        }

        // Mode cards
        for card in [ideCard, appCard] {
            card.wantsLayer = true
            card.layer?.cornerRadius = DesignTokens.tourModeCardRadius
            card.layer?.backgroundColor = DesignTokens.tourModeCardBg.cgColor
            card.layer?.borderWidth = 1
            card.layer?.borderColor = DesignTokens.tourModeCardBorder.cgColor
        }

        // Title labels
        for title in [ideTitleLabel, appTitleLabel] {
            title.font = DesignTokens.tourModeLabelFont
            title.textColor = DesignTokens.purpleLight
            title.isBezeled = false
            title.drawsBackground = false
            title.isEditable = false
            title.sizeToFit()
        }

        // Description labels
        for desc in [ideDescLabel, appDescLabel] {
            desc.font = DesignTokens.tourModeDescFont
            desc.textColor = DesignTokens.tourTextDim
            desc.isBezeled = false
            desc.drawsBackground = false
            desc.isEditable = false
            desc.lineBreakMode = .byWordWrapping
            desc.maximumNumberOfLines = 0
            desc.usesSingleLineMode = false
        }

        // Divider
        divider.wantsLayer = true
        divider.layer?.backgroundColor = DesignTokens.tourModeCardBorder.cgColor

        // Build hierarchy
        ideCard.addSubview(ideTitleLabel)
        ideCard.addSubview(ideDescLabel)
        ideCard.addSubview(ideChip1)
        ideCard.addSubview(ideChip2)
        ideCard.addSubview(ideChip3)

        appCard.addSubview(appTitleLabel)
        appCard.addSubview(appDescLabel)
        appCard.addSubview(appChip1)
        appCard.addSubview(appChip2)
        appCard.addSubview(appChip3)

        addSubview(terminalLabel)
        addSubview(ideToolbar)
        addSubview(ideCard)
        addSubview(divider)
        addSubview(chatLabel)
        addSubview(appToolbar)
        addSubview(appCard)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        for card in [ideCard, appCard] {
            card.layer?.backgroundColor = DesignTokens.tourModeCardBg.cgColor
            card.layer?.borderColor = DesignTokens.tourModeCardBorder.cgColor
        }
        divider.layer?.backgroundColor = DesignTokens.tourModeCardBorder.cgColor
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2
        let contentH = h - padding * 2

        // Two equal rows with 1px divider in between
        let dividerH: CGFloat = 1
        let rowH = (contentH - dividerH) / 2

        // AppKit: origin bottom-left
        // Row 2 (bottom) = chat tools
        let row2Y = padding
        let dividerY = row2Y + rowH
        let row1Y = dividerY + dividerH

        divider.frame = CGRect(x: padding, y: dividerY, width: contentW, height: dividerH)

        // Layout a row: label on top, toolbar left, card right
        layoutRow(
            y: row1Y, rowH: rowH, contentW: contentW,
            sectionLabel: terminalLabel,
            toolbar: ideToolbar,
            card: ideCard,
            titleLabel: ideTitleLabel,
            descLabel: ideDescLabel,
            chips: [ideChip1, ideChip2, ideChip3]
        )

        layoutRow(
            y: row2Y, rowH: rowH, contentW: contentW,
            sectionLabel: chatLabel,
            toolbar: appToolbar,
            card: appCard,
            titleLabel: appTitleLabel,
            descLabel: appDescLabel,
            chips: [appChip1, appChip2, appChip3]
        )
    }

    private func layoutRow(
        y: CGFloat, rowH: CGFloat, contentW: CGFloat,
        sectionLabel: NSTextField, toolbar: TourMiniToolbar,
        card: NSView, titleLabel: NSTextField, descLabel: NSTextField,
        chips: [NSView]
    ) {
        // Section label at top of row
        let labelH = sectionLabel.frame.height
        sectionLabel.frame = CGRect(
            x: padding,
            y: y + rowH - labelH - 4,
            width: contentW,
            height: labelH
        )

        // Toolbar and card below label
        let belowLabelY = y
        let belowLabelH = rowH - labelH - 12

        // Toolbar on left, vertically centered
        let tbSize = toolbar.frame.size
        let tbY = belowLabelY + (belowLabelH - tbSize.height) / 2
        toolbar.frame = CGRect(x: padding, y: tbY, width: tbSize.width, height: tbSize.height)

        // Card on right, filling remaining space
        let cardGap: CGFloat = 14
        let cardX = padding + tbSize.width + cardGap
        let cardW = contentW - tbSize.width - cardGap
        card.frame = CGRect(x: cardX, y: belowLabelY, width: cardW, height: belowLabelH)

        // Card internals
        let cardPad = DesignTokens.tourModeCardPadding

        // Title at top of card
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(
            x: cardPad,
            y: belowLabelH - cardPad - titleLabel.frame.height
        )

        // Description below title
        let descW = cardW - cardPad * 2
        descLabel.preferredMaxLayoutWidth = descW
        descLabel.sizeToFit()
        descLabel.frame = CGRect(
            x: cardPad,
            y: titleLabel.frame.minY - 4 - descLabel.frame.height,
            width: descW,
            height: descLabel.frame.height
        )

        // Chips at bottom
        let chipY: CGFloat = cardPad
        var chipX: CGFloat = cardPad
        let chipGap: CGFloat = 6
        for chip in chips {
            let cw = chip.frame.width
            let ch = chip.frame.height
            chip.frame = CGRect(x: chipX, y: chipY, width: cw, height: ch)
            chipX += cw + chipGap
        }
    }

    // MARK: - Chip factory

    private static func makeChip(_ text: String) -> NSView {
        let chipHeight: CGFloat = 16

        let label = NSTextField(labelWithString: text)
        label.font = DesignTokens.tourChipFont
        label.textColor = DesignTokens.tourTextDim
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.sizeToFit()

        let hPad = DesignTokens.tourChipPaddingH
        let chipW = label.frame.width + hPad * 2

        let chip = NSView(frame: NSRect(x: 0, y: 0, width: chipW, height: chipHeight))
        chip.wantsLayer = true
        chip.layer?.cornerRadius = 999
        chip.layer?.backgroundColor = DesignTokens.tourChipBg.cgColor
        chip.layer?.borderWidth = 1
        chip.layer?.borderColor = DesignTokens.tourChipBorder.cgColor

        label.frame.origin = NSPoint(
            x: hPad,
            y: (chipHeight - label.frame.height) / 2
        )
        chip.addSubview(label)

        return chip
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Section labels need letter-spacing; draw manually
        drawLetterSpacedLabel(terminalLabel, text: "TERMINAL TOOLS")
        drawLetterSpacedLabel(chatLabel, text: "CHAT TOOLS")
    }

    private func drawLetterSpacedLabel(_ field: NSTextField, text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: DesignTokens.tourModeSectionFont,
            .foregroundColor: DesignTokens.tourTextDim,
            .kern: 1.0,
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let origin = field.convert(NSPoint.zero, to: self)
        str.draw(at: origin)

        // Hide the text field's own text since we draw custom
        field.textColor = .clear
    }
}
