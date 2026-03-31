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

    /// rgba(239, 68, 68, 0.05) — note pill background
    static let redNoteBg = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.05)

    /// rgba(239, 68, 68, 0.1) — note pill border
    static let redNoteBorder = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.1)

    /// rgba(30, 30, 30, 0.92) — toolbar
    static let darkChrome = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.92)

    /// rgba(30, 30, 30, 0.88) — status pill
    static let darkChromeStatus = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.88)

    /// rgba(30, 30, 30, 0.95) — popover
    static let darkChromePopover = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.95)

    /// #f0edf9 — tooltip background
    static let tooltipBg = NSColor(red: 240/255, green: 237/255, blue: 249/255, alpha: 1.0)

    /// #d4cef0 — tooltip border
    static let tooltipBorder = NSColor(red: 212/255, green: 206/255, blue: 240/255, alpha: 1.0)

    /// rgba(22, 163, 74, 0.9) — copied state green
    static let copiedGreen = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 0.9)

    /// rgba(255, 255, 255, 0.08) — divider
    static let dividerColor = NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.08)

    /// rgba(255, 87, 87, 0.2) — close button hover
    static let closeHoverBg = NSColor(red: 255/255, green: 87/255, blue: 87/255, alpha: 0.2)

    /// rgba(255, 87, 87, 0.15) — trash button hover
    static let trashHoverBg = NSColor(red: 255/255, green: 87/255, blue: 87/255, alpha: 0.15)

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

    // MARK: - Fonts

    /// Badge number: system 9px weight 600
    static let badgeFont = NSFont.systemFont(ofSize: 9, weight: .semibold)

    /// Note number prefix: system 9px weight 600
    static let noteNumberFont = NSFont.systemFont(ofSize: 9, weight: .semibold)

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
