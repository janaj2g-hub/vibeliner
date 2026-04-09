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
/// Height: matches titlePillHeight token, fully rounded (999px radius).
final class TourTitlePill: NSView {

    private let name: String
    private let role: TourRole

    private let pillHeight: CGFloat = DesignTokens.titlePillHeight
    private let paddingH: CGFloat = 8
    private let tagPaddingH: CGFloat = 6
    private let tagHeight: CGFloat = 14
    private let gapBetween: CGFloat = 4

    init(name: String, role: TourRole) {
        self.name = name
        self.role = role

        // Calculate width
        let nameFont = NSFont.systemFont(ofSize: 9, weight: .semibold)
        let tagFont = NSFont.systemFont(ofSize: 8, weight: .bold)
        let nameSize = (name as NSString).size(withAttributes: [.font: nameFont])
        let tagText = TourTitlePill.tagText(for: role)
        let tagSize = (tagText as NSString).size(withAttributes: [.font: tagFont])
        let totalWidth = paddingH + nameSize.width + gapBetween + tagPaddingH + tagSize.width + tagPaddingH + paddingH

        super.init(frame: NSRect(x: 0, y: 0, width: ceil(totalWidth), height: pillHeight))
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { bounds.size }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let w = bounds.width
        let h = bounds.height

        // Main pill background
        let pillRect = CGRect(x: 0, y: 0, width: w, height: h)
        ctx.setFillColor(role.backgroundColor.cgColor)
        let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 999, cornerHeight: 999, transform: nil)
        ctx.addPath(pillPath)
        ctx.fillPath()

        // Name text
        let nameFont = NSFont.systemFont(ofSize: 9, weight: .semibold)
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: NSColor.white,
        ]
        let nameStr = NSAttributedString(string: name, attributes: nameAttrs)
        let nameSize = nameStr.size()
        let nameX = paddingH
        let nameY = (h - nameSize.height) / 2
        nameStr.draw(at: NSPoint(x: nameX, y: nameY))

        // Role tag inner pill
        let tagFont = NSFont.systemFont(ofSize: 8, weight: .bold)
        let tagText = TourTitlePill.tagText(for: role)
        let tagAttrs: [NSAttributedString.Key: Any] = [
            .font: tagFont,
            .foregroundColor: NSColor.white,
        ]
        let tagStr = NSAttributedString(string: tagText, attributes: tagAttrs)
        let tagSize = tagStr.size()
        let tagW = tagSize.width + tagPaddingH * 2
        let tagX = nameX + nameSize.width + gapBetween
        let tagY = (h - tagHeight) / 2
        let tagRect = CGRect(x: tagX, y: tagY, width: tagW, height: tagHeight)

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
        case .observed: return "observed"
        case .expected: return "expected"
        case .reference: return "reference"
        }
    }
}
