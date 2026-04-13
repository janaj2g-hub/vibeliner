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

    /// #a796eb — copy button outline and text
    static let purpleButton = NSColor(red: 167/255, green: 150/255, blue: 235/255, alpha: 1.0)

    /// rgba(116, 97, 194, 0.25) — copy button fill
    static let purpleButtonBg = NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 0.25)

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

    /// Tooltip dark bg: rgba(28, 28, 32, 0.96) — from toolbar prototype
    static let tooltipDarkBg = NSColor(red: 28/255, green: 28/255, blue: 32/255, alpha: 0.96)

    /// Tooltip dark border: rgba(255, 255, 255, 0.1)
    static let tooltipDarkBorder = NSColor(white: 1.0, alpha: 0.1)

    /// Copy success green: rgba(22, 163, 74, 0.5) — border
    static let copiedGreenBorder = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 0.5)

    /// Copy success text: rgba(22, 163, 74, 0.8)
    static let copiedGreenText = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 0.8)

    /// Copy success bg: rgba(22, 163, 74, 0.12)
    static let copiedGreenBg = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 0.12)

    /// rgba(22, 163, 74, 0.9) — copied state green
    static let copiedGreen = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 0.9)

    /// rgba(0, 0, 0, 0.5) — capture overlay dim
    static let dimOverlay = NSColor.black.withAlphaComponent(0.5)

    /// Divider — dark: rgba(255,255,255,0.08), light: rgba(0,0,0,0.08)
    static let dividerColor = dynamicColor(
        dark: NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.08),
        light: NSColor(red: 0, green: 0, blue: 0, alpha: 0.08)
    )

    /// rgba(175, 169, 236, 0.12) — toolbar/canvas border
    static let chromeBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.12)

    // MARK: - Popover copy-button tokens (VIB-394)

    /// Copy-button text — dark: #AFA9EC, light: #6B5CC5
    static let popoverCopyButtonText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1.0)
            : NSColor(red: 107/255, green: 92/255, blue: 197/255, alpha: 1.0)
    }

    /// Copy-button background — dark: rgba(175,169,236,0.10), light: rgba(107,92,197,0.10)
    static let popoverCopyButtonBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.10)
            : NSColor(red: 107/255, green: 92/255, blue: 197/255, alpha: 0.10)
    }

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

    /// Toolbar purple active — dark: #AFA9EC, light: #534AB7
    static let toolbarPurpleActive = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1.0)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)
    }

    /// Toolbar purple button border — dark: #A796EB, light: #534AB7
    static let toolbarPurpleButtonBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 167/255, green: 150/255, blue: 235/255, alpha: 1.0)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)
    }

    /// Toolbar purple button text — dark: #A796EB, light: #534AB7
    static let toolbarPurpleButtonText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 167/255, green: 150/255, blue: 235/255, alpha: 1.0)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)
    }

    /// Toolbar purple button bg — dark: rgba(116,97,194,0.25), light: rgba(83,74,183,0.08)
    static let toolbarPurpleButtonBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 0.25)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.08)
    }

    /// Toolbar purple button hover border — dark: #C4B8F5, light: #7461C2
    static let toolbarPurpleButtonHoverBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 196/255, green: 184/255, blue: 245/255, alpha: 1.0)
            : NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 1.0)
    }

    /// Toolbar purple button hover text — dark: #C4B8F5, light: #7461C2
    static let toolbarPurpleButtonHoverText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 196/255, green: 184/255, blue: 245/255, alpha: 1.0)
            : NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 1.0)
    }

    /// Toolbar purple button hover bg — dark: rgba(116,97,194,0.35), light: rgba(83,74,183,0.12)
    static let toolbarPurpleButtonHoverBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 0.35)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.12)
    }

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

    /// Toolbar toggle bg — dark: rgba(255,255,255,0.06), light: rgba(0,0,0,0.04)
    /// Toolbar toggle bg — dark: rgba(255,255,255,0.06), light: rgba(0,0,0,0.08)
    static let toolbarToggleBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1.0, alpha: 0.06) : NSColor(white: 0.0, alpha: 0.08)
    }

    /// Toolbar toggle active bg — dark: rgba(175,169,236,0.25), light: rgba(83,74,183,0.22)
    static let toolbarToggleActiveBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.25)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.22)
    }

    /// Toolbar toggle inactive text — dark: rgba(255,255,255,0.3), light: rgba(0,0,0,0.40)
    static let toolbarToggleInactiveText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 1.0, alpha: 0.3) : NSColor(white: 0.0, alpha: 0.40)
    }

}
