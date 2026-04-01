import AppKit

final class NotePillRenderer {

    static let pillIdentifier = "notePill"

    static func drawNotePills(in view: NSView, annotations: [Annotation], canvasSize: NSSize, hoveredId: UUID? = nil) {
        // Remove existing note pill subviews
        for subview in view.subviews where subview.identifier?.rawValue == pillIdentifier {
            subview.removeFromSuperview()
        }

        for annotation in annotations {
            guard !annotation.noteText.isEmpty else { continue }

            let isHovered = (annotation.id == hoveredId)
            let pillPos = notePillPosition(for: annotation, canvasSize: canvasSize)
            let pill = createNotePill(number: annotation.number, text: annotation.noteText, isHovered: isHovered)
            pill.identifier = NSUserInterfaceItemIdentifier(pillIdentifier)
            pill.frame.origin = pillPos
            view.addSubview(pill)
        }
    }

    static func notePillPosition(for annotation: Annotation, canvasSize: NSSize) -> CGPoint {
        let badgePos = annotation.badgePosition
        let gap: CGFloat = 10

        switch annotation.position {
        case .pin(let tip):
            let badgeCenterY = tip.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2
            let x = badgePos.x + DesignTokens.badgeDiameter / 2 + gap
            let y = badgeCenterY - DesignTokens.noteHeight / 2
            return CGPoint(x: x, y: y)
        case .arrow(let start, _):
            return CGPoint(x: start.x + DesignTokens.badgeDiameter / 2 + gap, y: start.y - DesignTokens.noteHeight / 2)
        case .rectangle(let origin, let size):
            return CGPoint(x: origin.x + size.width + gap, y: origin.y + size.height - DesignTokens.noteHeight)
        case .circle(let center, let radius):
            let dx = badgePos.x - center.x
            let dy = badgePos.y - center.y
            let dist = hypot(dx, dy)
            guard dist > 0 else { return CGPoint(x: badgePos.x + gap, y: badgePos.y) }
            let ux = dx / dist
            let uy = dy / dist
            return CGPoint(x: badgePos.x + ux * (DesignTokens.badgeDiameter / 2 + gap), y: badgePos.y + uy * (DesignTokens.badgeDiameter / 2 + gap) - DesignTokens.noteHeight / 2)
        case .freehand:
            return CGPoint(x: badgePos.x + DesignTokens.badgeDiameter / 2 + gap, y: badgePos.y - DesignTokens.noteHeight / 2)
        }
    }

    private static func createNotePill(number: Int, text: String, isHovered: Bool = false) -> NSView {
        let numberStr = "\(number) "
        let fullText = numberStr + text

        let font = DesignTokens.noteTextFont
        let numberFont = DesignTokens.noteNumberFont

        let attrStr = NSMutableAttributedString()
        attrStr.append(NSAttributedString(string: numberStr, attributes: [
            .font: numberFont,
            .foregroundColor: NSColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 0.35)
        ]))
        attrStr.append(NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 1.0)
        ]))

        let textField = NSTextField(labelWithString: "")
        textField.attributedStringValue = attrStr
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.sizeToFit()

        let padding: CGFloat = 10
        let pillWidth = textField.frame.width + padding * 2
        let pillHeight = max(DesignTokens.noteHeight, textField.frame.height + 6)

        let pill = NSView(frame: NSRect(x: 0, y: 0, width: pillWidth, height: pillHeight))
        pill.wantsLayer = true
        if isHovered {
            pill.layer?.backgroundColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.08).cgColor
            pill.layer?.borderColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.30).cgColor
            pill.layer?.borderWidth = 1
        } else {
            pill.layer?.backgroundColor = DesignTokens.redNoteBg.cgColor
            pill.layer?.borderColor = DesignTokens.redNoteBorder.cgColor
            pill.layer?.borderWidth = 0.5
        }
        pill.layer?.cornerRadius = DesignTokens.noteCornerRadius

        textField.frame = NSRect(x: padding, y: (pillHeight - textField.frame.height) / 2, width: textField.frame.width, height: textField.frame.height)
        pill.addSubview(textField)

        return pill
    }
}
