import AppKit

extension DesignTokens {

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

    /// 12px status pill corner radius
    static let statusPillCornerRadius: CGFloat = 12

    /// 30px tool button size
    static let toolButtonSize: CGFloat = 30

    /// 2px visual separation between adjacent tool buttons
    static let toolbarToolButtonGap: CGFloat = 2

    /// 28px icon button size
    static let iconButtonSize: CGFloat = 28

    /// 24px close button size
    static let closeButtonSize: CGFloat = 24

    /// Settings content horizontal padding
    static let settingsContentPadding: CGFloat = 28

    /// Settings section title width
    static let settingsSectionLabelWidth: CGFloat = 128

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

    /// Horizontal padding inside each selector item
    static let settingsSegmentedItemPadding: CGFloat = 14

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

    /// Note text: system 12px weight regular
    static let noteTextFont = NSFont.systemFont(ofSize: 12, weight: .regular)

    /// Dimension label: monospace 11px weight 500
    static let dimensionLabelFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)

    /// Status pill: monospace 10px weight 500
    static let statusPillFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)

    /// Settings section label: system 13px weight 500
    static let settingsSectionFont = NSFont.systemFont(ofSize: 13, weight: .medium)

    /// Settings body copy: system 12px weight regular
    static let settingsBodyFont = NSFont.systemFont(ofSize: 12, weight: .regular)

    /// Settings field text: monospace 12px regular
    static let settingsFieldFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

    /// Settings pill text: system 11px weight 600
    static let settingsPillFont = NSFont.systemFont(ofSize: 11, weight: .semibold)

    /// Primary settings selector label
    static let settingsSegmentedPrimaryFont = NSFont.systemFont(ofSize: 12, weight: .semibold)

    /// Secondary settings selector label
    static let settingsSegmentedSecondaryFont = NSFont.systemFont(ofSize: 11, weight: .medium)


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
