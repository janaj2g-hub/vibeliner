import AppKit

enum DesignTokens {

    static func isDarkAppearance(_ appearance: NSAppearance) -> Bool {
        let best = appearance.bestMatch(from: [.darkAqua, .aqua])
        return best == .darkAqua
    }

    static func dynamicColor(dark: NSColor, light: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            isDarkAppearance(appearance) ? dark : light
        }
    }

    // MARK: - Colors

    /// #AFA9EC — crosshair, selection border, active tool highlight
    static let purpleLight = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1.0)

    /// #534AB7 — dimension label bg, settings accents
    static let purpleDark = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)

    /// Brand purple text/accent — light mode #534AB7, dark mode #AFA9EC.
    /// Canonical "purple label on dark/light surface" color.
    static let purpleBrand = dynamicColor(dark: purpleLight, light: purpleDark)

    // MARK: - Purple opacity ladder
    //
    // Derived alpha variants of the two brand purples. Any surface that needs
    // "a tinted purple fill" or "a purple border" should reference one of these
    // primitives instead of defining its own alpha. Added in VIB-505.

    /// Purple at 6% alpha — barely-there tinted surface. Reserved for future use
    /// by the faintest purple-on-background fills.
    static let purpleFaint = dynamicColor(
        dark:  purpleLight.withAlphaComponent(0.06),
        light: purpleDark.withAlphaComponent(0.06)
    )

    /// Purple at 14% alpha — subtle tinted fill. Used for tool-active backgrounds,
    /// add-image button backgrounds, segmented-control active fills.
    static let purpleSubtle = dynamicColor(
        dark:  purpleLight.withAlphaComponent(0.14),
        light: purpleDark.withAlphaComponent(0.14)
    )

    /// Purple at 22% alpha — emphasized tinted fill. Used for pill button
    /// backgrounds in dark mode, primary button hover fills, segmented-control
    /// active borders.
    static let purpleStrong = dynamicColor(
        dark:  purpleLight.withAlphaComponent(0.22),
        light: purpleDark.withAlphaComponent(0.22)
    )

    /// Purple at 36% alpha — tinted border. Used for pill button primary borders
    /// in dark mode.
    static let purpleBorder = dynamicColor(
        dark:  purpleLight.withAlphaComponent(0.36),
        light: purpleDark.withAlphaComponent(0.36)
    )

    /// Purple hover accent — one step brighter than `purpleBrand`. Used for
    /// pill button hover borders and text. The two raw hex values are
    /// intentional: they represent a deliberately-lightened hover shift that
    /// `purpleLight.withAlphaComponent(...)` cannot produce.
    static let purpleHover = dynamicColor(
        dark:  NSColor(red: 196/255, green: 184/255, blue: 245/255, alpha: 1),  // #C4B8F5
        light: NSColor(red: 96/255,  green: 85/255,  blue: 196/255, alpha: 1)   // #6055C4
    )

    // MARK: - Neutral opacity ladder
    //
    // White-on-dark and black-on-light at canonical alpha levels. Any surface
    // needing "a gray border" or "a dimmed icon" should reference these
    // primitives instead of defining its own alpha. Added in VIB-505.

    /// Hairline at ~8% alpha — subtle dividers, faint borders, button hover
    /// backgrounds.
    static let neutralHairline = dynamicColor(
        dark:  NSColor(white: 1, alpha: 0.08),
        light: NSColor(white: 0, alpha: 0.08)
    )

    /// Standard border at ~12% alpha — 1px borders on chrome surfaces
    /// (toolbars, input fields, kbd pills).
    static let neutralBorder = dynamicColor(
        dark:  NSColor(white: 1, alpha: 0.12),
        light: NSColor(white: 0, alpha: 0.12)
    )

    /// Dimmed at ~45% alpha — secondary text, inactive icons.
    static let neutralDim = dynamicColor(
        dark:  NSColor(white: 1, alpha: 0.45),
        light: NSColor(white: 0, alpha: 0.45)
    )

    /// Strong at ~70% alpha — primary icons, emphasized labels.
    static let neutralStrong = dynamicColor(
        dark:  NSColor(white: 1, alpha: 0.70),
        light: NSColor(white: 0, alpha: 0.70)
    )

    /// Primary at ~100% alpha — primary text labels.
    static let neutralPrimary = dynamicColor(
        dark:  NSColor(white: 1, alpha: 1.0),
        light: NSColor(white: 0, alpha: 1.0)
    )

    /// Brand green — #22C55E. Canonical success / positive-state color.
    static let green = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1.0)

    /// #EF4444 — all annotation marks
    static let red = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)

    /// rgba(239, 68, 68, 0.06) — shape fills
    static let redFill = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.06)

    /// Note pill default: rgba(255, 248, 248, 0.82)
    static let redNoteBg = NSColor(red: 255/255, green: 248/255, blue: 248/255, alpha: 0.82)

    /// Note pill default border: rgba(239, 68, 68, 0.18)
    static let redNoteBorder = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.18)

    /// Note text color: #7f1d1d
    static let noteTextColor = NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 1.0)

    /// Copy success green — alias of green @ 0.5 alpha (VIB-503).
    static let copiedGreenBorder = green.withAlphaComponent(0.5)

    /// Copy success text — alias of green @ 0.8 alpha (VIB-503).
    static let copiedGreenText = green.withAlphaComponent(0.8)

    /// Copy success bg — alias of green @ 0.12 alpha (VIB-503).
    static let copiedGreenBg = green.withAlphaComponent(0.12)

    /// Copied state green — alias of green @ 0.9 alpha (VIB-503).
    static let copiedGreen = green.withAlphaComponent(0.9)

    /// rgba(0, 0, 0, 0.5) — capture overlay dim
    static let dimOverlay = NSColor.black.withAlphaComponent(0.5)

    /// Divider — dark: rgba(255,255,255,0.08), light: rgba(0,0,0,0.08)
    static let dividerColor = dynamicColor(
        dark: NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.08),
        light: NSColor(red: 0, green: 0, blue: 0, alpha: 0.08)
    )

    /// rgba(175, 169, 236, 0.12) — toolbar/canvas border
    static let chromeBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.12)

    // MARK: - Kbd pill (VIB-502: promoted from setupKbd* since consumed by Setup + Tour)

    /// Kbd pill border — dark: rgba(255,255,255,0.12), light: rgba(0,0,0,0.10)
    static let kbdBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1, alpha: 0.12) : NSColor(white: 0, alpha: 0.10)
    }
    /// Kbd pill bg — dark: rgba(255,255,255,0.08), light: rgba(0,0,0,0.05)
    static let kbdBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1, alpha: 0.08) : NSColor(white: 0, alpha: 0.05)
    }
    /// Kbd pill text — dark: rgba(255,255,255,0.55), light: rgba(0,0,0,0.60)
    static let kbdText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1, alpha: 0.55) : NSColor(white: 0, alpha: 0.6)
    }

    // MARK: - Appearance-aware toolbar tokens (VIB-235)

    /// Toolbar background — dark: rgba(30,30,30,0.92), light: rgba(255,255,255,0.88)
    static let toolbarBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.92)
            : NSColor(white: 1.0, alpha: 0.88)
    }

    /// Status pill bg — dark: rgba(30,30,30,0.88), light: rgba(255,255,255,0.85)
    static let statusPillBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.88)
            : NSColor(white: 1.0, alpha: 0.85)
    }

    /// Status pill text — dark: white, light: rgba(0,0,0,0.70)
    static let statusPillTextColor = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor.white
            : NSColor(white: 0.0, alpha: 0.70)
    }

    /// Status pill border — dark: clear, light: rgba(0,0,0,0.06)
    static let statusPillBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor.clear : NSColor(white: 0.0, alpha: 0.06)
    }

    /// Add image button bg — dark: rgba(175,169,236,0.14), light: rgba(83,74,183,0.08)
    static let addImageBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.14)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.08)
    }

    /// Add image button border — dark: rgba(175,169,236,0.22), light: rgba(83,74,183,0.15)
    static let addImageBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.22)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.15)
    }

    /// Toolbar close hover bg — dark: rgba(255,87,87,0.2), light: rgba(255,87,87,0.15)
    static let toolbarCloseHoverBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 255/255, green: 87/255, blue: 87/255, alpha: 0.2)
            : NSColor(red: 255/255, green: 87/255, blue: 87/255, alpha: 0.15)
    }

    /// Toolbar close icon hover — dark: #FF5F57, light: #FF5F57 (same)
    static let toolbarCloseIconHover = NSColor(red: 255/255, green: 95/255, blue: 87/255, alpha: 1.0)

    /// Toolbar trash hover bg — dark: rgba(255,87,87,0.15), light: rgba(255,87,87,0.12)
    static let toolbarTrashHoverBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 255/255, green: 87/255, blue: 87/255, alpha: 0.15)
            : NSColor(red: 255/255, green: 87/255, blue: 87/255, alpha: 0.12)
    }

}
