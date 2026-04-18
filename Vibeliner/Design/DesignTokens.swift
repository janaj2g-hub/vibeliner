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

    // MARK: - Universal pill button (VIB-440)

    /// Pill button border — dark: #A796EB, light: #534AB7
    static let pillButtonBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 167/255, green: 150/255, blue: 235/255, alpha: 1.0)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)
    }

    /// Pill button text — alias of `purpleBrand`.
    static let pillButtonText = purpleBrand

    /// Pill button bg — dark: rgba(116,97,194,0.25), light: rgba(83,74,183,0.08)
    static let pillButtonBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 0.25)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.08)
    }

    /// Pill button hover border — dark: #C4B8F5, light: #7461C2
    static let pillButtonHoverBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 196/255, green: 184/255, blue: 245/255, alpha: 1.0)
            : NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 1.0)
    }

    /// Pill button hover text — dark: #C4B8F5, light: #7461C2
    static let pillButtonHoverText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 196/255, green: 184/255, blue: 245/255, alpha: 1.0)
            : NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 1.0)
    }

    /// Pill button hover bg — dark: rgba(116,97,194,0.35), light: rgba(83,74,183,0.12)
    static let pillButtonHoverBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 0.35)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.12)
    }

    /// Primary pill button text — dark: #AFA9EC, light: white (solid CTA)
    static let pillButtonPrimaryText = dynamicColor(
        dark: purpleLight,
        light: NSColor.white
    )

    /// Primary pill button bg — dark: rgba(175,169,236,0.16), light: #534AB7 (solid CTA)
    static let pillButtonPrimaryBg = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16),
        light: purpleDark
    )

    /// Primary pill button border — dark: rgba(175,169,236,0.36), light: #534AB7
    static let pillButtonPrimaryBorder = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.36),
        light: purpleDark
    )

    /// Primary pill button hover bg — dark: rgba(175,169,236,0.22), light: #6055C4
    static let pillButtonPrimaryHoverBg = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.22),
        light: NSColor(red: 96/255, green: 85/255, blue: 196/255, alpha: 1.0)
    )

    /// Primary pill button hover border — dark: rgba(175,169,236,0.48), light: #6055C4
    static let pillButtonPrimaryHoverBorder = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.48),
        light: NSColor(red: 96/255, green: 85/255, blue: 196/255, alpha: 1.0)
    )

    // MARK: - Appearance-aware toolbar tokens (VIB-235)

    /// Toolbar background — dark: rgba(30,30,30,0.92), light: rgba(255,255,255,0.88)
    static let toolbarBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.92)
            : NSColor(white: 1.0, alpha: 0.88)
    }

    /// Toolbar border — dark: rgba(255,255,255,0.12), light: rgba(0,0,0,0.10)
    static let toolbarBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.12)
            : NSColor(white: 0.0, alpha: 0.10)
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

    /// Toolbar icon default — dark: rgba(255,255,255,0.40), light: rgba(0,0,0,0.45)
    static let toolbarIconDefault = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1.0, alpha: 0.40) : NSColor(white: 0.0, alpha: 0.45)
    }

    /// Toolbar icon hover — dark: rgba(255,255,255,0.70), light: rgba(0,0,0,0.70)
    static let toolbarIconHover = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1.0, alpha: 0.70) : NSColor(white: 0.0, alpha: 0.70)
    }

    /// Toolbar divider — dark: rgba(255,255,255,0.08), light: rgba(0,0,0,0.12)
    static let toolbarDivider = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1.0, alpha: 0.08) : NSColor(white: 0.0, alpha: 0.12)
    }

    /// Toolbar purple active — alias of `purpleBrand`.
    static let toolbarPurpleActive = purpleBrand

    // MARK: - Secondary Toolbar Buttons (VIB-330)
    // Used by + Add image and New capture — subtle outlined style, secondary to Copy Prompt/Image

    /// Secondary button border — dark: rgba(255,255,255,0.20), light: rgba(0,0,0,0.15)
    static let toolbarSecondaryBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.20)
            : NSColor(white: 0.0, alpha: 0.15)
    }

    /// Secondary button text — dark: rgba(255,255,255,0.60), light: rgba(0,0,0,0.55)
    static let toolbarSecondaryText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.60)
            : NSColor(white: 0.0, alpha: 0.65)
    }

    /// Secondary button bg — transparent
    static let toolbarSecondaryBg = NSColor.clear

    /// Secondary button hover border — dark: rgba(255,255,255,0.35), light: rgba(0,0,0,0.25)
    static let toolbarSecondaryHoverBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.35)
            : NSColor(white: 0.0, alpha: 0.25)
    }

    /// Secondary button hover text — dark: rgba(255,255,255,0.80), light: rgba(0,0,0,0.75)
    static let toolbarSecondaryHoverText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.80)
            : NSColor(white: 0.0, alpha: 0.75)
    }

    /// Secondary button hover bg — dark: rgba(255,255,255,0.05), light: rgba(0,0,0,0.04)
    static let toolbarSecondaryHoverBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.05)
            : NSColor(white: 0.0, alpha: 0.04)
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

    /// Toolbar button hover bg — dark: rgba(255,255,255,0.08), light: rgba(0,0,0,0.06)
    static let toolbarButtonHoverBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1.0, alpha: 0.08) : NSColor(white: 0.0, alpha: 0.06)
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

    /// Toolbar tool active bg — dark: rgba(175,169,236,0.2), light: rgba(83,74,183,0.12)
    static let toolbarToolActiveBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.2)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.12)
    }

    // MARK: - Universal segmented control (VIB-441)

    /// Segmented track bg — dark: rgba(255,255,255,0.03), light: rgba(15,23,42,0.04)
    static let segmentedTrack = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.03)
            : NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.04)
    }

    /// Segmented track border — dark: rgba(255,255,255,0.08), light: rgba(15,23,42,0.08)
    static let segmentedTrackBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.08)
            : NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.08)
    }

    /// Segmented active fill — dark: rgba(175,169,236,0.16), light: rgba(175,169,236,0.14)
    static let segmentedActiveFill = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16)
            : NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.14)
    }

    /// Segmented active border — dark: rgba(175,169,236,0.20), light: rgba(114,103,221,0.18)
    static let segmentedActiveBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.20)
            : NSColor(red: 114/255, green: 103/255, blue: 221/255, alpha: 0.18)
    }

    /// Segmented active text — dark: #AFA9EC, light: #7267DD
    static let segmentedActiveText = pillButtonText

    /// Segmented inactive text — dark: rgba(255,255,255,0.58), light: rgba(15,23,42,0.58)
    static let segmentedInactiveText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(white: 1.0, alpha: 0.58)
            : NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.58)
    }

}
