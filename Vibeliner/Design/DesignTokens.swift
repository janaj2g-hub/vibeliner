import AppKit

enum DesignTokens {

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
}
