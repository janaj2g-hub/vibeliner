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
    // VIB-500: `setupWindowBg`, `setupBorder`, `setupFieldBorder`, `setupTextPrimary`,
    // `setupTextSecondary`, `setupTextDim`, `setupGrayText` were system-color aliases;
    // deleted. Consumers use `NSColor.*` constants directly.

    /// Setup footer background — slightly different from window bg
    static let setupFooterBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 0.133, alpha: 1) : NSColor(white: 0.94, alpha: 1)
    }
    /// Alias — setup field background matches settings field surface (VIB-501).
    static let setupFieldBg = settingsFieldSurface

    // VIB-502: kbd* tokens (previously setupKbd*) promoted to main scale — consumed by both Setup and Tour.

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
    /// Tour progress active — alias of `purpleBrand` (tour → main direction allowed).
    static let tourProgressActive = purpleBrand
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
    /// Exit/ghost button border — alias of `tourWindowBorder` (VIB-502, identical value).
    static let tourGhostButtonBorder = tourWindowBorder
    /// Exit/ghost button hover border
    static let tourGhostButtonHoverBorder = dynamicColor(
        dark: NSColor(white: 1.0, alpha: 0.12),
        light: NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.12)
    )
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
