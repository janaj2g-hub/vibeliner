import AppKit

extension DesignTokens {

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
            return NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16)
        }
        return NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.14)
    }

    /// Settings segmented control track border
    static let settingsSegmentedBorder = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.08)
        }
        return NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.08)
    }

    /// Settings segmented control active border
    static let settingsSegmentedActiveBorder = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.20)
        }
        return NSColor(red: 114/255, green: 103/255, blue: 221/255, alpha: 0.18)
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

    /// Settings selector active title color
    static let settingsSegmentedActiveText = settingsPillText

    /// Settings selector inactive title color
    static let settingsSegmentedInactiveText = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.58)
        }
        return NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.58)
    }

    /// Role swatch outer outline for light and dark mode visibility
    static let roleSwatchOutline = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.16)
        }
        return NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.16)
    }

    /// Role swatch inner contrast border
    static let roleSwatchInnerBorder = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 0.0, alpha: 0.22)
        }
        return NSColor(white: 1.0, alpha: 0.82)
    }

    /// Role swatch selected ring
    static let roleSwatchSelectedRing = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.92)
        }
        return NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.78)
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
        // VIB-387: Fully opaque so filmstrip title bars don't show screenshot bleed-through
        return border.blended(withFraction: 0.55, of: .black) ?? border
    }

    /// Settings field border color — dark: rgba(255,255,255,0.12), light: rgba(15,23,42,0.12)
    static let settingsFieldBorder = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.12)
        }
        return NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.12)
    }

    // MARK: - Editor interaction tokens (VIB-411)

    /// Editor annotation hover fill halo
    static let editorAnnotationHoverFill = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.08)

    /// Editor annotation hover outline/shadow accent
    static let editorAnnotationHoverStroke = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.30)

    /// Editor annotation hover shadow glow
    static let editorAnnotationHoverShadow = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.20)

    /// Editor annotation hover fill for shapes
    static let editorAnnotationHoverShapeFill = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.14)

    /// Editor note chrome shadow
    static let editorNoteShadow = NSColor.black.withAlphaComponent(0.06)

    /// Editor note pill surface — resting
    static let editorNoteSurfaceDefault = NSColor(red: 1.0, green: 0.957, blue: 0.957, alpha: 0.72)

    /// Editor note pill surface — hover
    static let editorNoteSurfaceHover = NSColor(red: 1.0, green: 0.957, blue: 0.957, alpha: 0.80)

    /// Editor note pill surface — selected
    static let editorNoteSurfaceSelected = NSColor(red: 1.0, green: 0.957, blue: 0.957, alpha: 0.88)

    /// Editor note pill surface — editing
    static let editorNoteSurfaceEditing = NSColor(red: 1.0, green: 0.980, blue: 0.980, alpha: 0.96)

    /// Editor note pill border — resting
    static let editorNoteBorderDefault = NSColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.22)

    /// Editor note pill border — hover
    static let editorNoteBorderHover = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.45)

    /// Editor note pill border — selected
    static let editorNoteBorderSelected = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.55)

    /// Editor note pill glow while editing
    static let editorNoteEditingGlow = red
}
