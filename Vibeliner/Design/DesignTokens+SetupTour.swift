import AppKit

extension DesignTokens {

    // MARK: - Setup Window Colors (appearance-aware)

    // Green/amber status — fixed brand colors (must be visible in both modes)
    /// #22c55e — badge done border/text
    static let setupGreen = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1.0)
    /// rgba(34, 197, 94, 0.1) — badge done fill
    static let setupGreenBadgeBg = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.1)
    /// #16a34a — status text, green button text
    static let setupGreenText = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1.0)
    /// rgba(34, 197, 94, 0.08) — green button fill
    static let setupGreenBg = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.08)
    /// rgba(34, 197, 94, 0.5) — green button border
    static let setupGreenBorder = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.5)
    /// #b45309 — amber status text
    static let setupAmberText = NSColor(red: 180/255, green: 83/255, blue: 9/255, alpha: 1.0)

    // Window/container backgrounds — appearance-aware
    /// Setup window background — follows system
    static let setupWindowBg = NSColor.windowBackgroundColor
    /// Setup footer background — slightly different from window bg
    static let setupFooterBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 0.133, alpha: 1) : NSColor(white: 0.94, alpha: 1)
    }
    /// Setup dividers and borders
    static let setupBorder = NSColor.separatorColor
    /// Setup field background (path box, shortcut group)
    static let setupFieldBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1, alpha: 0.05) : NSColor(white: 0, alpha: 0.03)
    }
    /// Setup field border
    static let setupFieldBorder = NSColor.separatorColor

    // Text — appearance-aware (system colors)
    /// Setup primary text
    static let setupTextPrimary = NSColor.labelColor
    /// Setup secondary text
    static let setupTextSecondary = NSColor.secondaryLabelColor
    /// Setup dim/helper text
    static let setupTextDim = NSColor.tertiaryLabelColor
    /// Setup locked badge/gray status text
    static let setupGrayText = NSColor.tertiaryLabelColor
    /// Setup locked badge bg
    static let setupGrayBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1, alpha: 0.03) : NSColor(white: 0, alpha: 0.03)
    }

    // Kbd pills — appearance-aware
    /// Setup kbd pill border
    static let setupKbdBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1, alpha: 0.12) : NSColor(white: 0, alpha: 0.10)
    }
    /// Setup kbd pill bg
    static let setupKbdBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1, alpha: 0.08) : NSColor(white: 0, alpha: 0.05)
    }
    /// Setup kbd pill text
    static let setupKbdText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1, alpha: 0.55) : NSColor(white: 0, alpha: 0.6)
    }

    // MARK: - Setup Window Dimensions

    static let setupWindowWidth: CGFloat = 700
    static let setupPanelHeight: CGFloat = 310
    static let setupFooterHeight: CGFloat = 56
    static let setupPanelPad: CGFloat = 28
    static let setupBadgeSize: CGFloat = 32
    static let setupArrowSize: CGFloat = 36
    static let setupSmallPillHeight: CGFloat = 22
    static let setupFooterButtonHeight: CGFloat = 36
    static let setupFooterPrimaryPadding: CGFloat = 48
    static let setupFooterSecondaryPadding: CGFloat = 36
    static let setupPathBoxRadius: CGFloat = 8

    // MARK: - Setup Window Fonts

    static let setupPanelTitleFont = NSFont.systemFont(ofSize: 16, weight: .semibold)
    static let setupDescFont = NSFont.systemFont(ofSize: 13, weight: .regular)
    static let setupActionLabelFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
    static let setupHelperFont = NSFont.systemFont(ofSize: 11, weight: .regular)
    static let setupPathFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    static let setupStatusFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
    static let setupSmallPillFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    static let setupBadgeFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
    static let setupBadgeCheckFont = NSFont.systemFont(ofSize: 16, weight: .bold)
    static let setupKbdFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
    static let setupShortcutHintFont = NSFont.systemFont(ofSize: 12, weight: .regular)

    // MARK: - Tour Window Colors (appearance-aware)

    /// Tour window surface — dark: rgba(24,24,30,0.97), light: rgba(248,248,254,0.98)
    static let tourWindowBg = dynamicColor(
        dark: NSColor(red: 24/255, green: 24/255, blue: 30/255, alpha: 0.97),
        light: NSColor(red: 248/255, green: 248/255, blue: 254/255, alpha: 0.98)
    )
    /// Tour header/footer overlay
    static let tourBarOverlay = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.015),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.015)
    )
    /// Tour window border
    static let tourWindowBorder = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.07),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.08)
    )
    /// Tour chrome divider/border-faint
    static let tourBarDivider = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.04),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.05)
    )
    /// Tour progress active
    static let tourProgressActive = dynamicColor(
        dark: purpleLight,
        light: purpleDark
    )
    /// Tour progress inactive
    static let tourProgressInactive = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.06),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.07)
    )
    /// Tour text primary
    static let tourTextPrimary = dynamicColor(
        dark: NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.92),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.92)
    )
    /// Tour text secondary
    static let tourTextSecondary = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.58),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.58)
    )
    /// Tour text dim
    static let tourTextDim = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.34),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.36)
    )
    /// Tour illustration pane background fill
    static let tourIllustrationPaneBg = dynamicColor(
        dark: NSColor(white: 0.0, alpha: 0.08),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.02)
    )
    /// Exit/ghost button border
    static let tourGhostButtonBorder = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.07),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.08)
    )
    /// Exit/ghost button text
    static let tourGhostButtonText = tourTextDim
    /// Exit/ghost button hover border
    static let tourGhostButtonHoverBorder = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.12),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.12)
    )
    /// Exit/ghost button hover text
    static let tourGhostButtonHoverText = tourTextSecondary
    /// Done action background
    static let tourDoneButtonBg = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.14)
    /// Done action hover background
    static let tourDoneButtonHoverBg = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 0.20)
    /// Done action border
    static let tourDoneButtonBorder = NSColor(red: 74/255, green: 222/255, blue: 128/255, alpha: 0.34)
    /// Done action text
    static let tourDoneButtonText = NSColor.white

    // MARK: - Tour Window Dimensions

    static let tourWindowWidth: CGFloat = 880
    static let tourWindowHeight: CGFloat = 700
    static let tourWindowRadius: CGFloat = 10
    static let tourHeaderHeight: CGFloat = 44
    static let tourFooterHeight: CGFloat = 48
    static let tourIllustrationRatio: CGFloat = 0.6
    static let tourTextMaxWidth: CGFloat = 300
    static let tourProgressBarWidth: CGFloat = 16
    static let tourProgressBarHeight: CGFloat = 3
    static let tourNextButtonHeight: CGFloat = 34

    // MARK: - Tour Window Fonts

    static let tourHeaderFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
    static let tourStepBadgeFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    static let tourTitleFont = NSFont.systemFont(ofSize: 22, weight: .bold)
    static let tourBodyFont = NSFont.systemFont(ofSize: 14, weight: .regular)
    static let tourProgressFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    static let tourButtonFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
    static let tourExitFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
    static let tourDoneTitleFont = NSFont.systemFont(ofSize: 26, weight: .bold)

}
