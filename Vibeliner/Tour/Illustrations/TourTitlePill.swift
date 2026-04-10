import AppKit

/// Role variant for tour title pills, determining the pill background color.
enum TourRole {
    case observed   // purple — what we're looking at
    case expected   // green — what we expect to see
    case reference  // blue — supporting context

    var backgroundColor: NSColor {
        switch self {
        case .observed:
            return DesignTokens.roleObservedBg
        case .expected:
            return DesignTokens.roleExpectedBg
        case .reference:
            return DesignTokens.roleReferenceBg
        }
    }

    var borderColor: NSColor {
        switch self {
        case .observed:
            return DesignTokens.roleObservedBorder
        case .expected:
            return DesignTokens.roleExpectedBorder
        case .reference:
            return DesignTokens.roleReferenceBorder
        }
    }
}

/// Small pill label used in tour illustrations to identify and tag elements.
/// Shows a name and an inner role tag pill.
final class TourTitlePill: NSView {

    private let name: String
    private let role: TourRole

    private let pillHeight: CGFloat = DesignTokens.tourTitlePillHeight

    init(name: String, role: TourRole) {
        self.name = name
        self.role = role

        // Calculate width
        let nameFont = DesignTokens.tourTitlePillFont
        let tagFont = DesignTokens.tourTitlePillTagFont
        let nameSize = (name as NSString).size(withAttributes: [.font: nameFont])
        let tagText = TourTitlePill.tagText(for: role)
        let tagSize = (tagText as NSString).size(withAttributes: [.font: tagFont])
        let tagWidth = tagSize.width + DesignTokens.tourTitlePillTagPaddingH * 2
        let totalWidth = DesignTokens.tourTitlePillPaddingLeading
            + nameSize.width
            + DesignTokens.tourTitlePillGap
            + tagWidth
            + DesignTokens.tourTitlePillPaddingTrailing

        super.init(frame: NSRect(x: 0, y: 0, width: ceil(totalWidth), height: pillHeight))
        wantsLayer = true
        layer?.cornerRadius = pillHeight / 2
        layer?.masksToBounds = false
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { bounds.size }

    override func layout() {
        super.layout()
        let cornerRadius = bounds.height / 2
        layer?.cornerRadius = cornerRadius
        layer?.shadowPath = CGPath(
            roundedRect: bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let h = bounds.height

        // Name text
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: DesignTokens.tourTitlePillFont,
            .foregroundColor: DesignTokens.tourTitlePillText,
        ]
        let nameStr = NSAttributedString(string: name, attributes: nameAttrs)
        let nameSize = nameStr.size()
        let nameX = DesignTokens.tourTitlePillPaddingLeading
        let nameY = (h - nameSize.height) / 2
        nameStr.draw(at: NSPoint(x: nameX, y: nameY))

        // Role tag inner pill
        let tagText = TourTitlePill.tagText(for: role)
        let tagAttrs: [NSAttributedString.Key: Any] = [
            .font: DesignTokens.tourTitlePillTagFont,
            .foregroundColor: DesignTokens.tourTitlePillText,
        ]
        let tagStr = NSAttributedString(string: tagText, attributes: tagAttrs)
        let tagSize = tagStr.size()
        let tagW = tagSize.width + DesignTokens.tourTitlePillTagPaddingH * 2
        let tagH = tagSize.height + DesignTokens.tourTitlePillTagPaddingV * 2
        let tagX = nameX + nameSize.width + DesignTokens.tourTitlePillGap
        let tagY = (h - tagH) / 2
        let tagRect = CGRect(x: tagX, y: tagY, width: tagW, height: tagH)

        // Tag bg
        ctx.setFillColor(DesignTokens.tourRoleTagBg.cgColor)
        let tagPath = CGPath(roundedRect: tagRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(tagPath)
        ctx.fillPath()

        // Tag text
        tagStr.draw(at: NSPoint(
            x: tagRect.midX - tagSize.width / 2,
            y: tagRect.midY - tagSize.height / 2
        ))
    }

    private static func tagText(for role: TourRole) -> String {
        switch role {
        case .observed: return "Observed"
        case .expected: return "Expected"
        case .reference: return "Reference"
        }
    }

    private func updateAppearance() {
        layer?.backgroundColor = role.backgroundColor.cgColor
        layer?.shadowColor = DesignTokens.tourTitlePillShadowColor.cgColor
        layer?.shadowOffset = CGSize(width: 0, height: DesignTokens.tourTitlePillShadowYOffset)
        layer?.shadowRadius = DesignTokens.tourTitlePillShadowBlur
        layer?.shadowOpacity = 1
    }
}
