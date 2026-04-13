import AppKit

/// Tour step 5: "One paste or two"
/// Two rows separated by a 1px divider, vertically centered.
/// Each row: section label → mini toolbar pill LEFT of mode card.
/// Row 1: TERMINAL TOOLS — IDE toggle active, 1 copy button.
/// Row 2: CHAT TOOLS — App toggle active, 2 copy buttons.
final class TourIllustration5: NSView {

    // Row 1
    private let terminalLabel: NSTextField
    private let ideToolbarPill: ModeToolbarPill
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
    private let appToolbarPill: ModeToolbarPill
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
        ideToolbarPill = ModeToolbarPill(activeMode: .ide, showCopyImage: false)

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
        appToolbarPill = ModeToolbarPill(activeMode: .app, showCopyImage: true)

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
            label.textColor = .clear // drawn manually for letter-spacing
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
        addSubview(ideToolbarPill)
        addSubview(ideCard)
        addSubview(divider)
        addSubview(chatLabel)
        addSubview(appToolbarPill)
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
        ideToolbarPill.needsDisplay = true
        appToolbarPill.needsDisplay = true
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height

        let contentW = w - padding * 2
        let contentH = h - padding * 2

        // Measure content to center vertically
        let sectionLabelH: CGFloat = 14
        let labelGap: CGFloat = 8
        let dividerH: CGFloat = 1
        let rowGap: CGFloat = 18

        // Row content height = label + gap + toolbar/card area
        let tbH: CGFloat = 36
        let cardMinH: CGFloat = 100
        let rowContentH = max(tbH, cardMinH)
        let rowH = sectionLabelH + labelGap + rowContentH

        let totalH = rowH * 2 + rowGap + dividerH
        let startY = padding + (contentH - totalH) / 2

        // AppKit: bottom-up
        // Row 2 at bottom
        let row2Y = startY
        let dividerY = row2Y + rowH + rowGap / 2
        let row1Y = dividerY + dividerH + rowGap / 2

        divider.frame = CGRect(x: padding, y: dividerY, width: contentW, height: dividerH)

        layoutRow(
            y: row1Y, rowContentH: rowContentH, contentW: contentW,
            sectionLabel: terminalLabel, sectionLabelH: sectionLabelH, labelGap: labelGap,
            toolbar: ideToolbarPill,
            card: ideCard, titleLabel: ideTitleLabel, descLabel: ideDescLabel,
            chips: [ideChip1, ideChip2, ideChip3]
        )

        layoutRow(
            y: row2Y, rowContentH: rowContentH, contentW: contentW,
            sectionLabel: chatLabel, sectionLabelH: sectionLabelH, labelGap: labelGap,
            toolbar: appToolbarPill,
            card: appCard, titleLabel: appTitleLabel, descLabel: appDescLabel,
            chips: [appChip1, appChip2, appChip3]
        )
    }

    private func layoutRow(
        y: CGFloat, rowContentH: CGFloat, contentW: CGFloat,
        sectionLabel: NSTextField, sectionLabelH: CGFloat, labelGap: CGFloat,
        toolbar: ModeToolbarPill,
        card: NSView, titleLabel: NSTextField, descLabel: NSTextField,
        chips: [NSView]
    ) {
        let rowTopY = y + rowContentH + labelGap + sectionLabelH

        // Section label at top
        sectionLabel.frame = CGRect(
            x: padding,
            y: rowTopY - sectionLabelH,
            width: contentW,
            height: sectionLabelH
        )

        // Content area below label
        let contentY = y

        // Toolbar on left, vertically centered
        let tbW = toolbar.intrinsicContentSize.width
        let tbH = toolbar.intrinsicContentSize.height
        let tbY = contentY + (rowContentH - tbH) / 2
        toolbar.frame = CGRect(x: padding, y: tbY, width: tbW, height: tbH)

        // Card on right, fills remaining width, full height
        let cardGap: CGFloat = 14
        let cardX = padding + tbW + cardGap
        let cardW = contentW - tbW - cardGap
        card.frame = CGRect(x: cardX, y: contentY, width: cardW, height: rowContentH)

        // Card internals
        let cardPad = DesignTokens.tourModeCardPadding

        // Title at top of card
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(
            x: cardPad,
            y: rowContentH - cardPad - titleLabel.frame.height
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
        let chipGap: CGFloat = 4
        for chip in chips {
            let cw = chip.frame.width
            let ch = chip.frame.height
            chip.frame = CGRect(x: chipX, y: chipY, width: cw, height: ch)
            chipX += cw + chipGap
        }
    }

    // MARK: - Chip factory

    private static func makeChip(_ text: String) -> NSView {
        let chipHeight: CGFloat = 22

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
    }
}

// MARK: - Compact mode toolbar pill (custom-drawn, no annotation tools)

/// A compact mini toolbar showing only: IDE/App toggle + copy pill(s).
/// This wraps the shared tour toolbar helper so the compact mode card follows the
/// same runtime toolbar contract as the other tour editor surfaces.
private final class ModeToolbarPill: NSView {

    enum Mode { case ide, app }

    private let toolbar: TourMiniToolbar

    init(activeMode: Mode, showCopyImage: Bool) {
        let config = TourMiniToolbarConfig(
            activeTool: .pin,
            mode: activeMode == .ide ? .ide : .app,
            showToolSection: false,
            showCopyPrompt: true,
            showCopyImage: showCopyImage,
            showAddImage: false,
            showCloseButton: false
        )
        toolbar = TourMiniToolbar(config: config)
        super.init(frame: NSRect(origin: .zero, size: toolbar.intrinsicContentSize))
        addSubview(toolbar)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { toolbar.intrinsicContentSize }

    override func layout() {
        super.layout()
        toolbar.frame = bounds
    }
}
