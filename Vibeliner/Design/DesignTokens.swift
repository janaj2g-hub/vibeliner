import AppKit

enum DesignTokens {

    private static func isDarkAppearance(_ appearance: NSAppearance) -> Bool {
        let best = appearance.bestMatch(from: [.darkAqua, .aqua])
        return best == .darkAqua
    }

    private static func dynamicColor(dark: NSColor, light: NSColor) -> NSColor {
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

    /// #c4b8f5 — copy button hover
    static let purpleButtonHover = NSColor(red: 196/255, green: 184/255, blue: 245/255, alpha: 1.0)

    /// rgba(116, 97, 194, 0.25) — copy button fill
    static let purpleButtonBg = NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 0.25)

    /// rgba(116, 97, 194, 0.35) — copy button hover fill
    static let purpleButtonBgHover = NSColor(red: 116/255, green: 97/255, blue: 194/255, alpha: 0.35)

    /// #EF4444 — all annotation marks
    static let red = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)

    /// rgba(239, 68, 68, 0.06) — shape fills
    static let redFill = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.06)

    /// Note pill default: rgba(255, 248, 248, 0.82)
    static let redNoteBg = NSColor(red: 255/255, green: 248/255, blue: 248/255, alpha: 0.82)

    /// Note pill default border: rgba(239, 68, 68, 0.18)
    static let redNoteBorder = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.18)

    /// Note pill hover: rgba(255, 245, 245, 0.88)
    static let noteHoverBg = NSColor(red: 255/255, green: 245/255, blue: 245/255, alpha: 0.88)

    /// Note pill hover border: rgba(239, 68, 68, 0.4)
    static let noteHoverBorder = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.4)

    /// Note pill selected: rgba(255, 245, 245, 0.9)
    static let noteSelectedBg = NSColor(red: 255/255, green: 245/255, blue: 245/255, alpha: 0.9)

    /// Note pill selected border: rgba(239, 68, 68, 0.5)
    static let noteSelectedBorder = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.5)

    /// Note pill editing: rgba(255, 245, 245, 0.92)
    static let noteEditingBg = NSColor(red: 255/255, green: 245/255, blue: 245/255, alpha: 0.92)

    /// Note prefix color: rgba(153, 27, 27, 0.4)
    static let notePrefixColor = NSColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 0.4)

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

    /// rgba(30, 30, 30, 0.92) — toolbar
    static let darkChrome = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.92)

    /// rgba(30, 30, 30, 0.88) — status pill
    static let darkChromeStatus = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.88)

    /// rgba(30, 30, 30, 0.95) — popover
    static let darkChromePopover = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.95)


    /// rgba(22, 163, 74, 0.9) — copied state green
    static let copiedGreen = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 0.9)

    /// rgba(0, 0, 0, 0.5) — capture overlay dim
    static let dimOverlay = NSColor.black.withAlphaComponent(0.5)

    /// Divider — dark: rgba(255,255,255,0.08), light: rgba(0,0,0,0.08)
    static let dividerColor = dynamicColor(
        dark: NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.08),
        light: NSColor(red: 0, green: 0, blue: 0, alpha: 0.08)
    )

    /// rgba(255, 87, 87, 0.2) — close button hover
    static let closeHoverBg = NSColor(red: 255/255, green: 87/255, blue: 87/255, alpha: 0.2)

    /// rgba(255, 87, 87, 0.15) — trash button hover
    static let trashHoverBg = NSColor(red: 255/255, green: 87/255, blue: 87/255, alpha: 0.15)

    /// rgba(175, 169, 236, 0.12) — toolbar/canvas border
    static let chromeBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.12)

    /// rgba(255, 255, 255, 0.4) — default icon stroke
    static let iconDefault = NSColor(white: 1.0, alpha: 0.4)

    /// rgba(255, 255, 255, 0.8) — hover icon stroke
    static let iconHover = NSColor(white: 1.0, alpha: 0.8)

    /// rgba(255, 255, 255, 0.08) — button hover bg
    static let buttonHoverBg = NSColor(white: 1.0, alpha: 0.08)

    /// rgba(175, 169, 236, 0.2) — active tool bg
    static let toolActiveBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.2)

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

    // MARK: - Add Image Button (deprecated — use toolbarSecondary* tokens)

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

    /// Add image button hover border — dark: rgba(175,169,236,0.34), light: rgba(83,74,183,0.25)
    static let addImageHoverBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.34)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.25)
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

    /// rgba(175, 169, 236, 0.25) — toggle active bg
    static let toggleActiveBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.25)

    /// rgba(255, 255, 255, 0.06) — toggle bg
    static let toggleBg = NSColor(white: 1.0, alpha: 0.06)

    /// rgba(255, 255, 255, 0.3) — toggle inactive text
    static let toggleInactiveText = NSColor(white: 1.0, alpha: 0.3)

    /// #FF5F57 — close icon hover color
    static let closeIconHover = NSColor(red: 255/255, green: 95/255, blue: 87/255, alpha: 1.0)

    /// Settings field surface — prototype: --surface-field
    static let settingsFieldSurface = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.06)
        }
        // #eef0f6
        return NSColor(red: 238/255, green: 240/255, blue: 246/255, alpha: 1.0)
    }

    /// Settings framed section surface
    static let settingsFrameSurface = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.02)
        }
        return NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.02)
    }

    /// Settings preview surface
    static let settingsPreviewSurface = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(red: 21/255, green: 22/255, blue: 26/255, alpha: 1.0)
        }
        return NSColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0)
    }

    /// Settings segmented control track
    static let settingsSegmentedTrack = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.03)
        }
        return NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.04)
    }

    /// Settings segmented control active fill
    static let settingsSegmentedActive = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.22)
        }
        return NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.18)
    }

    /// Settings pill border color
    static let settingsPillBorder = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.36)
        }
        return NSColor(red: 114/255, green: 103/255, blue: 221/255, alpha: 0.26)
    }

    /// Settings pill fill color
    static let settingsPillFill = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.10)
        }
        return NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16)
    }

    /// Settings pill title color
    static let settingsPillText = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return purpleLight
        }
        return NSColor(red: 114/255, green: 103/255, blue: 221/255, alpha: 1.0)
    }

    /// Role observed border: #AFA9EC (purple)
    static let roleObservedBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1.0)

    /// Role observed background — purple tint (VIB-335: 0.85 alpha for readability)
    static let roleObservedBg = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.85)

    /// Role expected border: #22C55E (green)
    static let roleExpectedBorder = NSColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1.0)

    /// Role expected background — green tint (VIB-335: 0.85 alpha for readability)
    static let roleExpectedBg = NSColor(red: 22/255, green: 100/255, blue: 52/255, alpha: 0.85)

    /// Role reference border: #3B82F6 (blue)
    static let roleReferenceBorder = NSColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0)

    /// Role reference background — blue tint (VIB-335: 0.85 alpha for readability)
    static let roleReferenceBg = NSColor(red: 30/255, green: 70/255, blue: 140/255, alpha: 0.85)

    // VIB-322: Additional role preset colors
    /// Role orange border: #F97316
    static let roleOrangeBorder = NSColor(red: 249/255, green: 115/255, blue: 22/255, alpha: 1.0)
    /// Role pink border: #EC4899
    static let rolePinkBorder = NSColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)
    /// Role teal border: #14B8A6
    static let roleTealBorder = NSColor(red: 20/255, green: 184/255, blue: 166/255, alpha: 1.0)
    /// Role yellow border: #EAB308
    static let roleYellowBorder = NSColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 1.0)
    /// Role gray border: #6B7280
    static let roleGrayBorder = NSColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1.0)

    /// All 8 preset role colors: (name, hex, NSColor)
    static let rolePresetColors: [(name: String, hex: String, color: NSColor)] = [
        ("Purple", "#AFA9EC", roleObservedBorder),
        ("Green", "#22C55E", roleExpectedBorder),
        ("Blue", "#3B82F6", roleReferenceBorder),
        ("Orange", "#F97316", roleOrangeBorder),
        ("Pink", "#EC4899", rolePinkBorder),
        ("Teal", "#14B8A6", roleTealBorder),
        ("Yellow", "#EAB308", roleYellowBorder),
        ("Gray", "#6B7280", roleGrayBorder),
    ]

    /// Look up an NSColor for a role color hex string
    static func roleColor(forHex hex: String) -> NSColor {
        rolePresetColors.first { $0.hex.lowercased() == hex.lowercased() }?.color ?? roleObservedBorder
    }

    /// Look up a border NSColor for an ImageRole, using ConfigManager roles
    static func roleBorderColor(forRoleName name: String) -> NSColor {
        let roles = ConfigManager.shared.roles
        guard let role = roles.first(where: { $0.name.lowercased() == name.lowercased() }) else {
            return roleObservedBorder
        }
        return roleColor(forHex: role.colorHex)
    }

    /// Generate a semi-transparent background color for a role pill from its hex (VIB-335: 0.85 alpha)
    static func roleBgColor(forHex hex: String) -> NSColor {
        let border = roleColor(forHex: hex)
        return (border.blended(withFraction: 0.55, of: .black) ?? border).withAlphaComponent(0.85)
    }

    /// Settings field border color — dark: rgba(255,255,255,0.12), light: rgba(15,23,42,0.12)
    static let settingsFieldBorder = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.12)
        }
        return NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.12)
    }

    // MARK: - Dimensions

    /// 18px badge diameter (radius 9)
    static let badgeDiameter: CGFloat = 18

    /// 26px note pill height
    static let noteHeight: CGFloat = 26

    /// 13px note pill corner radius
    static let noteCornerRadius: CGFloat = 13

    /// 2.5px stroke width for all annotation tools
    static let strokeWidth: CGFloat = 2.5

    /// 10px pin stake length
    static let stakeLength: CGFloat = 10

    /// 2px pin stake width
    static let stakeWidth: CGFloat = 2

    /// 10px crosshair tick length
    static let crosshairTickLength: CGFloat = 10

    /// 2.3px crosshair line thickness
    static let crosshairThickness: CGFloat = 2.3

    /// 0.85 crosshair opacity
    static let crosshairOpacity: CGFloat = 0.85

    /// 1.5px selection border width
    static let selectionBorderWidth: CGFloat = 1.5

    /// 40px toolbar height
    static let toolbarHeight: CGFloat = 40

    /// 20px toolbar corner radius
    static let toolbarCornerRadius: CGFloat = 20

    /// 12px toolbar blur radius
    static let toolbarBlur: CGFloat = 12

    /// 12px status pill corner radius
    static let statusPillCornerRadius: CGFloat = 12

    /// 8px status pill blur radius
    static let statusPillBlur: CGFloat = 8

    /// 30px tool button size
    static let toolButtonSize: CGFloat = 30

    /// 28px icon button size
    static let iconButtonSize: CGFloat = 28

    /// 24px close button size
    static let closeButtonSize: CGFloat = 24

    /// Settings content horizontal padding
    static let settingsContentPadding: CGFloat = 28

    /// Settings section title width
    static let settingsSectionLabelWidth: CGFloat = 128

    /// Settings section vertical spacing
    static let settingsSectionPadding: CGFloat = 24

    /// Settings section inner gap
    static let settingsSectionGap: CGFloat = 14

    /// Settings framed section radius
    static let settingsFrameRadius: CGFloat = 18

    /// Settings framed section padding
    static let settingsFramePadding: CGFloat = 18

    /// Settings field height
    static let settingsFieldHeight: CGFloat = 32

    /// Settings segmented control height
    static let settingsSegmentedHeight: CGFloat = 28

    /// Settings segmented control inset
    static let settingsSegmentedInset: CGFloat = 2

    /// Settings pill button height
    static let settingsPillHeight: CGFloat = 28

    /// 12px arrow chevron arm length
    static let arrowChevronLength: CGFloat = 12

    /// 28 degrees arrow chevron angle
    static let arrowChevronAngle: CGFloat = 28

    /// 3px rectangle corner radius
    static let rectCornerRadius: CGFloat = 3

    /// 3 minimum points for freehand
    static let freehandMinPoints: Int = 3

    /// 3px freehand sample interval
    static let freehandSampleInterval: CGFloat = 3

    /// 5px dimension label corner radius
    static let dimensionLabelCornerRadius: CGFloat = 5

    /// 10px dimension label horizontal padding
    static let dimensionLabelPaddingH: CGFloat = 10

    /// 24px dimension label height
    static let dimensionLabelHeight: CGFloat = 24

    /// 10px gap below selection to dimension label
    static let dimensionLabelGap: CGFloat = 10

    /// 10px minimum selection size
    static let minimumSelectionSize: CGFloat = 10

    // MARK: - Filmstrip

    /// Filmstrip gap between cells: 14px
    static let filmstripGap: CGFloat = 14

    /// Filmstrip container padding: 14px
    static let filmstripPadding: CGFloat = 14

    /// Filmstrip container background — dark, ~65% opacity
    static let filmstripBg = NSColor(red: 15/255, green: 15/255, blue: 20/255, alpha: 0.65)

    /// Title pill height: 30px
    static let titlePillHeight: CGFloat = 30

    /// Gap between title pill bottom and image top: 6px
    static let titlePillGap: CGFloat = 6

    /// Title pill export shadow — contrast against any screenshot background
    static let titlePillExportShadow: NSShadow = {
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.shadowBlurRadius = 8
        shadow.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        return shadow
    }()

    // MARK: - Ghost preview

    /// Ghost anchor dot radius: 3px
    static let ghostDotRadius: CGFloat = 3

    /// Ghost anchor dot color: #AFA9EC at 85%
    static let ghostDotColor = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.85)

    /// Ghost silhouette stroke color: #EF4444 at 22%
    static let ghostStrokeColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.22)

    /// Ghost silhouette stroke width: 1.5px
    static let ghostStrokeWidth: CGFloat = 1.5

    /// Ghost silhouette dash pattern: 3,2
    static let ghostDashPattern: [CGFloat] = [3, 2]

    // MARK: - Fonts

    /// Badge number: system 9px weight 600
    static let badgeFont = NSFont.systemFont(ofSize: 9, weight: .semibold)

    /// Note number prefix: system 8px weight 600 (from prototype)
    static let noteNumberFont = NSFont.systemFont(ofSize: 8, weight: .semibold)




    /// Note text: system 12px weight regular
    static let noteTextFont = NSFont.systemFont(ofSize: 12, weight: .regular)

    /// Dimension label: monospace 11px weight 500
    static let dimensionLabelFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)

    /// Status pill: monospace 10px weight 500
    static let statusPillFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)

    /// Toolbar button label: system 11px weight 500
    static let toolbarButtonFont = NSFont.systemFont(ofSize: 11, weight: .medium)

    /// Tooltip body: system 12px weight regular
    static let tooltipBodyFont = NSFont.systemFont(ofSize: 12, weight: .regular)

    /// Tooltip label: system 13px weight 600
    static let tooltipLabelFont = NSFont.systemFont(ofSize: 13, weight: .semibold)

    /// Settings section label: system 13px weight 500
    static let settingsSectionFont = NSFont.systemFont(ofSize: 13, weight: .medium)

    /// Settings body copy: system 12px weight regular
    static let settingsBodyFont = NSFont.systemFont(ofSize: 12, weight: .regular)

    /// Settings field text: monospace 12px regular
    static let settingsFieldFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    /// Settings pill text: system 11px weight 600
    static let settingsPillFont = NSFont.systemFont(ofSize: 11, weight: .semibold)

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
    /// rgba(234, 179, 8, 0.08) — amber status background
    static let setupAmberBg = NSColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 0.08)
    /// #b45309 — amber status text
    static let setupAmberText = NSColor(red: 180/255, green: 83/255, blue: 9/255, alpha: 1.0)

    // Window/container backgrounds — appearance-aware
    /// Setup window background — follows system
    static let setupWindowBg = NSColor.windowBackgroundColor
    /// Setup title bar background — slightly offset from window bg
    static let setupTitleBarBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? NSColor(white: 0.165, alpha: 1) : NSColor(white: 0.96, alpha: 1)
    }
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

    // Action buttons — appearance-aware (matches settingsPill family)
    /// Setup action button fill
    static let setupButtonFill = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.10)
            : NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16)
    }
    /// Setup action button border
    static let setupButtonBorder = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.55)
            : NSColor(red: 114/255, green: 103/255, blue: 221/255, alpha: 0.26)
    }
    /// Setup action button/label text
    static let setupButtonText = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 111/255, green: 105/255, blue: 223/255, alpha: 1.0)
            : NSColor(red: 114/255, green: 103/255, blue: 221/255, alpha: 1.0)
    }
    /// Setup arrow hover bg
    static let setupButtonHoverBg = NSColor(name: nil) { appearance in
        isDarkAppearance(appearance)
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16)
            : NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.20)
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
    static let setupWindowRadius: CGFloat = 18
    static let setupPathBoxRadius: CGFloat = 8

    // MARK: - Setup Window Fonts

    static let setupWindowTitleFont = NSFont.systemFont(ofSize: 18, weight: .semibold)
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
    /// Primary action text
    static let tourPrimaryButtonText = dynamicColor(
        dark: purpleLight,
        light: NSColor.white
    )
    /// Primary action background
    static let tourPrimaryButtonBg = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16),
        light: purpleDark
    )
    /// Primary action border
    static let tourPrimaryButtonBorder = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.36),
        light: purpleDark
    )
    /// Primary action hover background
    static let tourPrimaryButtonHoverBg = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.22),
        light: NSColor(red: 96/255, green: 85/255, blue: 196/255, alpha: 1.0)
    )
    /// Primary action hover border
    static let tourPrimaryButtonHoverBorder = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.48),
        light: NSColor(red: 96/255, green: 85/255, blue: 196/255, alpha: 1.0)
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
    static let tourNextButtonPaddingH: CGFloat = 18

    // MARK: - Tour Window Fonts

    static let tourHeaderFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
    static let tourStepBadgeFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    static let tourTitleFont = NSFont.systemFont(ofSize: 22, weight: .bold)
    static let tourBodyFont = NSFont.systemFont(ofSize: 14, weight: .regular)
    static let tourProgressFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    static let tourButtonFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
    static let tourExitFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
    static let tourDoneTitleFont = NSFont.systemFont(ofSize: 26, weight: .bold)

    // MARK: - Tour Illustration

    // -- Illustration pane --
    static let tourIllustrationPadding: CGFloat = 24
    static let tourIllustrationBgTint = tourIllustrationPaneBg
    static let tourIllustrationGlow = dynamicColor(
        dark: NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.06),
        light: NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.05)
    )

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
    static let tourPromptSheetNumber = NSColor(red: 248/255, green: 113/255, blue: 113/255, alpha: 1)

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
    static let tourMiniScreenshotBadgeBg = red
    static let tourMiniScreenshotBadgeText = NSColor.white
    static let tourMiniScreenshotMarkColor = red
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
    static let tourChipPaddingV: CGFloat = 3

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
    static let tourFilmstripCellBadgeBg = red
    static let tourFilmstripCellBadgeText = NSColor.white

    // -- Dashed add-image cell --
    static let tourAddCellBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.3)
    static let tourAddCellBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.04)
    static let tourAddCellDashWidth: CGFloat = 2
    static let tourAddCellMinHeight: CGFloat = 70
    static let tourAddCellPlusSize: CGFloat = 22
    static let tourAddCellPlusBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16)
    static let tourAddCellLabelFont = NSFont.systemFont(ofSize: 10, weight: .semibold)

    // -- Editor frame (steps 2, 6) --
    static let tourEditorFrameBg = dynamicColor(
        dark: NSColor(red: 20/255, green: 20/255, blue: 24/255, alpha: 0.9),
        light: NSColor(red: 248/255, green: 248/255, blue: 254/255, alpha: 0.96)
    )
    static let tourEditorFrameBgLight = NSColor(red: 248/255, green: 248/255, blue: 254/255, alpha: 0.96)

    // -- Role tag inside title pills --
    static let tourRoleTagBg = NSColor(white: 1, alpha: 0.2)

    // -- Hint text --
    static let tourHintFont = NSFont.systemFont(ofSize: 10, weight: .regular)

    // MARK: - Vertically Centered Text Field

    /// Creates an NSTextField that is vertically centered within a given container height.
    /// Use this instead of setting frame = container bounds, which leaves text top-aligned.
    /// Usage: `DesignTokens.makeCenteredTextField("text", font: font, color: color, in: NSRect(...))`
    static func makeCenteredTextField(_ text: String, font: NSFont, color: NSColor, in containerFrame: NSRect) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.sizeToFit()
        let textH = label.frame.height
        let y = (containerFrame.height - textH) / 2
        label.frame = NSRect(x: containerFrame.origin.x, y: containerFrame.origin.y + y, width: containerFrame.width, height: textH)
        return label
    }
}

// MARK: - Vertically Centered Text Field Cell

/// NSTextFieldCell subclass that vertically centers text in its frame.
/// By default NSTextField/NSTextFieldCell draws text top-aligned, which looks
/// wrong in fixed-height containers (path boxes, settings fields, badges, etc.).
///
/// Usage:
///   let field = NSTextField()
///   field.cell = VerticallyCenteredTextFieldCell()
///   field.font = ...
///   field.stringValue = "text"
///   field.frame = NSRect(x: 0, y: 0, width: 200, height: 36)
///   // Text will be vertically centered in the 36px height
class VerticallyCenteredTextFieldCell: NSTextFieldCell {

    /// Horizontal padding applied to left and right of text. Default 12px.
    var horizontalPadding: CGFloat = 12

    private func paddedRect(_ rect: NSRect) -> NSRect {
        return NSRect(x: rect.origin.x + horizontalPadding,
                      y: rect.origin.y,
                      width: rect.width - horizontalPadding * 2,
                      height: rect.height)
    }

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        let padded = paddedRect(rect)
        var titleRect = super.titleRect(forBounds: padded)
        let textH = cellSize(forBounds: padded).height
        guard textH < rect.height else { return titleRect }
        titleRect.origin.y = rect.origin.y + (rect.height - textH) / 2
        titleRect.size.height = textH
        return titleRect
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: titleRect(forBounds: cellFrame), in: controlView)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: titleRect(forBounds: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: titleRect(forBounds: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }
}
