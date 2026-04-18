import AppKit

// Tour Illustration Tokens
// These tokens are for FAKE UI wireframes in the product tour only.
// They are NOT used by real app UI components.
//
// For real buttons, use: pillButton* or pillButtonPrimary*
// For real segmented controls, use: segmented*
// For real colors, use core tokens: red, purpleLight, purpleDark, etc.
//
// If you need a new token for a tour illustration, add it here.
// If you need a new token for real app UI, add it to DesignTokens.swift.

extension DesignTokens {

    // MARK: - Tour Illustration

    // -- Tour quarantine font copies (VIB-489) --
    // Tour-prefixed copies of legacy fonts so the tour can migrate off the main
    // scale independently. Do not use outside Vibeliner/Tour/.

    /// Tour-specific copy of badge font — quarantined from main scale. System 9pt semibold.
    static let tourMockBadgeFont = NSFont.systemFont(ofSize: 9, weight: .semibold)

    /// Tour-specific copy of dimension label font — quarantined from main scale. Monospace 11pt medium.
    static let tourMockDimensionFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)

    /// Tour-specific copy of keyboard shortcut font — quarantined from main scale. System 12pt semibold.
    static let tourKbdFont = NSFont.systemFont(ofSize: 12, weight: .semibold)

    // -- Illustration pane --
    static let tourIllustrationPadding: CGFloat = 24

    // -- Wireframe app mock --
    static let tourWireframeBgTop = NSColor(red: 246/255, green: 248/255, blue: 252/255, alpha: 1)
    static let tourWireframeBgBottom = NSColor(red: 238/255, green: 241/255, blue: 247/255, alpha: 1)
    static let tourWireframeTopbarBg = NSColor(white: 1, alpha: 0.8)
    static let tourWireframeTopbarBorder = NSColor(white: 0, alpha: 0.05)
    static let tourWireframeSidebarBg = NSColor(red: 245/255, green: 247/255, blue: 252/255, alpha: 0.9)
    static let tourWireframeSidebarBorder = NSColor(white: 0, alpha: 0.04)
    static let tourWireframeSidebarItem = NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.07)
    static let tourWireframeSidebarActive = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.16)
    static let tourWireframeHeading = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.14)
    static let tourWireframeCardBg = NSColor(white: 1, alpha: 0.85)
    static let tourWireframeCardBorder = NSColor(white: 0, alpha: 0.04)
    static let tourWireframeCardErrorBorder = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.2)
    static let tourWireframeCardErrorBg = NSColor(red: 255/255, green: 245/255, blue: 245/255, alpha: 0.9)
    static let tourWireframeLine = NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.08)
    static let tourWireframeTableBg = NSColor(white: 1, alpha: 0.8)
    static let tourWireframeTableBorder = NSColor(white: 0, alpha: 0.04)
    static let tourWireframeTableHeadBg = NSColor(red: 240/255, green: 242/255, blue: 248/255, alpha: 0.9)
    static let tourWireframeTableRowBorder = NSColor(white: 0, alpha: 0.04)
    static let tourWireframeTableErrorBg = NSColor(red: 255/255, green: 235/255, blue: 235/255, alpha: 0.6)
    static let tourWireframeTableCell = NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.07)
    static let tourWireframeRadius: CGFloat = 8
    static let tourWireframeTopbarHeight: CGFloat = 36
    static let tourWireframeSidebarWidth: CGFloat = 100
    static let tourWireframeCardHeight: CGFloat = 64
    static let tourWireframeCardRadius: CGFloat = 6
    static let tourWireframeTableRadius: CGFloat = 6
    static let tourWireframeBrandIconSize: CGFloat = 16
    static let tourWireframeBrandFont = NSFont.systemFont(ofSize: 11, weight: .bold)
    static let tourWireframeBrandColor = NSColor(red: 38/255, green: 48/255, blue: 65/255, alpha: 1)
    static let tourWireframeNavPillHeight: CGFloat = 8

    // -- Output card --
    static let tourOutputCardBg = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.03),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.025)
    )
    static let tourOutputCardBorder = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.06),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    )
    static let tourOutputCardRadius: CGFloat = 6
    static let tourOutputCardPadding: CGFloat = 10
    static let tourOutputLabelBg = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.05),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.05)
    )
    static let tourOutputLabelBorder = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.06),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    )
    static let tourOutputLabelFont = NSFont.systemFont(ofSize: 10, weight: .bold)
    static let tourOutputLabelPaddingH: CGFloat = 8
    static let tourOutputLabelPaddingV: CGFloat = 3
    static let tourOutputLabelGap: CGFloat = 8

    // -- Prompt sheet --
    static let tourPromptSheetBg = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.04),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.04)
    )
    static let tourPromptSheetBorder = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.06),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    )
    static let tourPromptSheetRadius: CGFloat = 6
    static let tourPromptSheetPaddingH: CGFloat = 14
    static let tourPromptSheetPaddingV: CGFloat = 16
    static let tourPromptSheetFont = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)
    static let tourPromptSheetLineHeight: CGFloat = 17.85
    static let tourPromptSheetColor = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.68),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.64)
    )
    static let tourPromptSheetDim = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.3),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.3)
    )

    // -- Tour title pill --
    static let tourTitlePillHeight: CGFloat = 22
    static let tourTitlePillPaddingLeading: CGFloat = 8
    static let tourTitlePillPaddingTrailing: CGFloat = 4
    static let tourTitlePillGap: CGFloat = 5
    static let tourTitlePillFont = NSFont.systemFont(ofSize: 9, weight: .semibold)
    static let tourTitlePillText = NSColor.white
    static let tourTitlePillTagFont = NSFont.systemFont(ofSize: 8, weight: .bold)
    static let tourTitlePillTagPaddingH: CGFloat = 6
    static let tourTitlePillTagPaddingV: CGFloat = 2
    static let tourTitlePillShadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.15)
    static let tourTitlePillShadowBlur: CGFloat = 8
    static let tourTitlePillShadowYOffset: CGFloat = -2

    // -- LLM chat panel --
    static let tourLLMPanelBg = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.025),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.025)
    )
    static let tourLLMPanelBorder = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.06),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    )
    static let tourLLMPanelRadius: CGFloat = 8
    static let tourLLMDotSize: CGFloat = 7
    static let tourLLMDotGlowSize: CGFloat = 4
    static let tourLLMBubbleTailSize: CGFloat = 6
    static let tourLLMHeaderFont = NSFont.systemFont(ofSize: 11, weight: .bold)
    static let tourLLMBubbleBg = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.05),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.04)
    )
    static let tourLLMBubbleFont = NSFont.systemFont(ofSize: 11, weight: .regular)
    static let tourLLMChatFont = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)
    static let tourLLMChatColor = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.55),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.5)
    )
    static let tourLLMComposerBg = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.04),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.03)
    )
    static let tourLLMComposerBorder = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.06),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    )
    static let tourLLMComposerRadius: CGFloat = 8
    static let tourLLMThumbWidth: CGFloat = 36
    static let tourLLMThumbHeight: CGFloat = 28
    static let tourLLMSendSize: CGFloat = 24
    static let tourLLMSendBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.2)

    // -- Flow arrow --
    static let tourFlowArrowWidth: CGFloat = 2
    static let tourFlowArrowHeight: CGFloat = 28
    static let tourFlowArrowColor = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.5)
    static let tourFlowArrowChevronSize: CGFloat = 10

    // -- Mini screenshot (inside output cards) --
    static let tourMiniScreenshotRadius: CGFloat = 4
    static let tourMiniScreenshotBgTop = NSColor(red: 246/255, green: 248/255, blue: 252/255, alpha: 1)
    static let tourMiniScreenshotBgBottom = NSColor(red: 238/255, green: 241/255, blue: 247/255, alpha: 1)
    static let tourMiniScreenshotShadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.12)
    static let tourMiniScreenshotShadowBlur: CGFloat = 16
    static let tourMiniScreenshotShadowYOffset: CGFloat = -4
    static let tourMiniScreenshotBarHeight: CGFloat = 18
    static let tourMiniScreenshotBarBg = NSColor(white: 1, alpha: 0.7)
    static let tourMiniScreenshotBarPaddingH: CGFloat = 6
    static let tourMiniScreenshotDotSize: CGFloat = 5
    static let tourMiniScreenshotDotGap: CGFloat = 4
    static let tourMiniScreenshotDotColor = NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.15)
    static let tourMiniScreenshotBodyHeight: CGFloat = 80
    static let tourMiniScreenshotRailWidth: CGFloat = 30
    static let tourMiniScreenshotRailBg = NSColor(red: 245/255, green: 247/255, blue: 252/255, alpha: 0.9)
    static let tourMiniScreenshotRailPaddingV: CGFloat = 6
    static let tourMiniScreenshotRailPaddingH: CGFloat = 4
    static let tourMiniScreenshotRailGap: CGFloat = 4
    static let tourMiniScreenshotRailPillHeight: CGFloat = 6
    static let tourMiniScreenshotRailPillColor = NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.07)
    static let tourMiniScreenshotContentPadding: CGFloat = 8
    static let tourMiniScreenshotContentGap: CGFloat = 4
    static let tourMiniScreenshotLineHeight: CGFloat = 6
    static let tourMiniScreenshotLineColor = NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    static let tourMiniScreenshotAccent = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.12)
    static let tourMiniScreenshotAccentWidthRatio: CGFloat = 0.5
    static let tourMiniScreenshotBadgeText = NSColor.white
    static let tourMiniScreenshotRectFill = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.06)
    static let tourMiniScreenshotRectRadius: CGFloat = 2
    static let tourMiniBadgeSize: CGFloat = 14
    static let tourMiniBadgeFont = NSFont.systemFont(ofSize: 7, weight: .bold)
    static let tourMiniRectStroke: CGFloat = 1.5

    // -- Mode card (step 5) --
    static let tourModeCardBg = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.025),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.025)
    )
    static let tourModeCardBorder = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.06),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    )
    static let tourModeCardRadius: CGFloat = 8
    static let tourModeCardPadding: CGFloat = 14
    static let tourModeLabelFont = NSFont.systemFont(ofSize: 12, weight: .bold)
    static let tourModeDescFont = NSFont.systemFont(ofSize: 11, weight: .regular)
    static let tourModeSectionFont = NSFont.systemFont(ofSize: 10, weight: .bold)

    // -- Example chip --
    static let tourChipBg = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.04),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.04)
    )
    static let tourChipBorder = dynamicColor(
        dark: NSColor(white: 1, alpha: 0.06),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    )
    static let tourChipFont = NSFont.systemFont(ofSize: 10, weight: .semibold)
    static let tourChipPaddingH: CGFloat = 8

    // -- Filmstrip cell (steps 6, 7) --
    static let tourFilmstripCellRadius: CGFloat = 6
    static let tourFilmstripCellBgTop = NSColor(red: 246/255, green: 248/255, blue: 252/255, alpha: 1)
    static let tourFilmstripCellBgBottom = NSColor(red: 238/255, green: 241/255, blue: 247/255, alpha: 1)
    static let tourFilmstripCellShadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.12)
    static let tourFilmstripCellShadowBlur: CGFloat = 16
    static let tourFilmstripCellShadowYOffset: CGFloat = -4
    static let tourFilmstripCellBarHeight: CGFloat = 16
    static let tourFilmstripCellBarBg = NSColor(white: 1, alpha: 0.7)
    static let tourFilmstripCellBarPaddingH: CGFloat = 5
    static let tourFilmstripCellDotSize: CGFloat = 4
    static let tourFilmstripCellDotGap: CGFloat = 3
    static let tourFilmstripCellDotColor = NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.12)
    static let tourFilmstripCellBodyHeight: CGFloat = 50
    static let tourFilmstripCellBodyPadding: CGFloat = 6
    static let tourFilmstripCellBodyGap: CGFloat = 3
    static let tourFilmstripCellLineHeight: CGFloat = 4
    static let tourFilmstripCellLineColor = NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.06)
    static let tourFilmstripCellAccent = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.12)
    static let tourFilmstripCellAccentWidthRatio: CGFloat = 0.45
    static let tourFilmstripCellBadgeText = NSColor.white

    // -- Dashed add-image cell --
    static let tourAddCellBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.3)
    static let tourAddCellBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.04)
    static let tourAddCellDashWidth: CGFloat = 2
    static let tourAddCellPlusSize: CGFloat = 22
    static let tourAddCellPlusBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16)

    // -- Editor frame (steps 3, 7, 8) --
    static let tourEditorFrameBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 20/255, green: 20/255, blue: 24/255, alpha: 0.95)
            : NSColor(red: 248/255, green: 248/255, blue: 254/255, alpha: 0.98)
    }
    static let tourEditorFrameBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1, alpha: 0.08)
            : NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.10)
    }
    static let tourEditorFrameShadowColor = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 0, alpha: 0.3)
            : NSColor(white: 0, alpha: 0.08)
    }

    // -- Role tag inside title pills --
    static let tourRoleTagBg = NSColor(white: 1, alpha: 0.2)

    // -- Hint text --
    static let tourHintFont = NSFont.systemFont(ofSize: 10, weight: .regular)

}
