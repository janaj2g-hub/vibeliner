import AppKit

enum DesignTokens {

    private static func isDarkAppearance(_ appearance: NSAppearance) -> Bool {
        let best = appearance.bestMatch(from: [.darkAqua, .aqua])
        return best == .darkAqua
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

    /// rgba(255, 255, 255, 0.08) — divider
    static let dividerColor = NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.08)

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

    /// Settings field border color
    static let settingsFieldBorder = NSColor(name: nil) { appearance in
        if isDarkAppearance(appearance) {
            return NSColor(white: 1.0, alpha: 0.12)
        }
        return NSColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.08)
    }

    // MARK: - Image Selection (VIB-271)

    /// VIB-271: Selected image cell border — purple highlight
    static let imageSelectionBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.70)

    /// VIB-271: Selected image cell background tint
    static let imageSelectionBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.08)

    // MARK: - Add Image Button

    /// rgba(175, 169, 236, 0.14) — add image button bg
    static let addImageBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.14)

    /// rgba(175, 169, 236, 0.22) — add image button border / hover bg
    static let addImageBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.22)

    /// rgba(175, 169, 236, 0.34) — add image button hover border
    static let addImageHoverBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.34)

    // MARK: - Role Colors (Filmstrip)
    // VIB-295: Role-tinted backgrounds with higher opacity for readability.

    /// VIB-312: Observed role background — purple tint, brighter against dark filmstrip bg
    static let roleObservedBg = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 0.50)

    /// VIB-312: Expected role background — green tint, brighter against dark filmstrip bg
    static let roleExpectedBg = NSColor(red: 22/255, green: 100/255, blue: 52/255, alpha: 0.45)

    /// VIB-312: Reference role background — blue tint, brighter against dark filmstrip bg
    static let roleReferenceBg = NSColor(red: 30/255, green: 70/255, blue: 140/255, alpha: 0.45)

    /// VIB-312: Observed role border — purple tint, more visible
    static let roleObservedBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.55)

    /// VIB-312: Expected role border — green tint, more visible
    static let roleExpectedBorder = NSColor(red: 134/255, green: 239/255, blue: 172/255, alpha: 0.55)

    /// VIB-312: Reference role border — blue tint, more visible
    static let roleReferenceBorder = NSColor(red: 147/255, green: 197/255, blue: 253/255, alpha: 0.55)

    // MARK: - Title Pill (Filmstrip)

    /// 30px title pill height
    static let titlePillHeight: CGFloat = 30

    /// 6px gap between title pill bottom and image top
    static let titlePillGap: CGFloat = 6

    /// Title pill export shadow — contrast against any screenshot background
    static let titlePillExportShadow: NSShadow = {
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        shadow.shadowBlurRadius = 8
        shadow.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        return shadow
    }()

    // MARK: - Filmstrip Container

    /// 14px gap between filmstrip cells
    static let filmstripGap: CGFloat = 14

    /// VIB-293: Filmstrip padding equals filmstripGap for uniform spacing on all sides
    static let filmstripPadding: CGFloat = 14

    /// VIB-293: Filmstrip container background — dark, ~65% opacity for visual separation
    static let filmstripBg = NSColor(red: 15/255, green: 15/255, blue: 20/255, alpha: 0.65)

    /// VIB-293: Filmstrip container border — purple-tinted, more visible
    static let filmstripBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.20)

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

    // MARK: - Setup Window Colors

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

    /// #1e1e1e — setup window background
    static let setupWindowBg = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)

    /// #2a2a2a — setup title bar background
    static let setupTitleBarBg = NSColor(red: 42/255, green: 42/255, blue: 42/255, alpha: 1.0)

    /// #222222 — setup footer background
    static let setupFooterBg = NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)

    /// #333333 — setup dividers and borders
    static let setupBorder = NSColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)

    /// rgba(255, 255, 255, 0.05) — setup field background
    static let setupFieldBg = NSColor(white: 1.0, alpha: 0.05)

    /// rgba(255, 255, 255, 0.08) — setup field border
    static let setupFieldBorder = NSColor(white: 1.0, alpha: 0.08)

    /// #e0e0e0 — setup primary text
    static let setupTextPrimary = NSColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1.0)

    /// #888888 — setup secondary text
    static let setupTextSecondary = NSColor(red: 136/255, green: 136/255, blue: 136/255, alpha: 1.0)

    /// #666666 — setup dim/helper text
    static let setupTextDim = NSColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1.0)

    /// #555555 — setup locked badge/gray status text
    static let setupGrayText = NSColor(red: 85/255, green: 85/255, blue: 85/255, alpha: 1.0)

    /// rgba(255, 255, 255, 0.03) — setup locked badge bg
    static let setupGrayBg = NSColor(white: 1.0, alpha: 0.03)

    /// rgba(175, 169, 236, 0.08) — setup action button fill
    static let setupButtonFill = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.08)

    /// rgba(175, 169, 236, 0.55) — setup action button border
    static let setupButtonBorder = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.55)

    /// #6f69df — setup action button/label text
    static let setupButtonText = NSColor(red: 111/255, green: 105/255, blue: 223/255, alpha: 1.0)

    /// rgba(175, 169, 236, 0.16) — setup arrow hover bg
    static let setupButtonHoverBg = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.16)

    /// rgba(255, 255, 255, 0.12) — setup kbd pill border
    static let setupKbdBorder = NSColor(white: 1.0, alpha: 0.12)

    /// rgba(255, 255, 255, 0.08) — setup kbd pill bg
    static let setupKbdBg = NSColor(white: 1.0, alpha: 0.08)

    /// rgba(255, 255, 255, 0.55) — setup kbd pill text
    static let setupKbdText = NSColor(white: 1.0, alpha: 0.55)

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
