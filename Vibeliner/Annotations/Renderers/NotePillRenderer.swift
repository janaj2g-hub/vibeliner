import AppKit

final class NotePillRenderer {

    static let pillIdentifier = "notePill"

    static func drawNotePills(in view: NSView, annotations: [Annotation], canvasSize: NSSize, hoveredId: UUID? = nil, selectedId: UUID? = nil, editingId: UUID? = nil) {
        // Remove existing note pill subviews
        for subview in view.subviews where subview.identifier?.rawValue == pillIdentifier {
            subview.removeFromSuperview()
        }

        for annotation in annotations {
            guard !annotation.noteText.isEmpty else { continue }
            guard annotation.id != editingId else { continue }

            let state: NotePillState
            if annotation.id == selectedId {
                state = .selected
            } else if annotation.id == hoveredId {
                state = .hover
            } else {
                state = .default
            }

            let pillPos = notePillPosition(for: annotation, canvasSize: canvasSize)
            let pill = createNotePill(number: annotation.number, text: annotation.noteText, state: state)
            pill.identifier = NSUserInterfaceItemIdentifier(pillIdentifier)
            pill.frame.origin = pillPos
            view.addSubview(pill)
        }
    }

    // MARK: - Note placement (matches prototype pinN/arrowN/rectN/circN functions)

    static func notePillPosition(for annotation: Annotation, canvasSize: NSSize) -> CGPoint {
        let bx = annotation.badgePosition.x
        let by = annotation.badgePosition.y
        let br = DesignTokens.badgeDiameter / 2
        let gap: CGFloat = 6

        switch annotation.position {
        case .pin:
            // pinN: note to the right of badge, vertically centered
            return CGPoint(x: bx + br + gap, y: by - DesignTokens.noteHeight / 2)

        case .arrow(let start, let end):
            // arrowN: 8-direction logic, note goes opposite to arrow direction
            let dx = end.x - bx
            let dy = end.y - by
            let ax = abs(dx)
            let ay = abs(dy)
            let off = br + gap + 2

            if ax > ay * 1.5 {
                // Primarily horizontal arrow
                if dx > 0 {
                    // Arrow points right → note below-left
                    return CGPoint(x: bx - off, y: by + off)
                }
                // Arrow points left → note below-right
                return CGPoint(x: bx + off, y: by + off)
            }
            if ay > ax * 1.5 {
                // Primarily vertical arrow → note to the right
                return CGPoint(x: bx + off, y: by - DesignTokens.noteHeight / 2)
            }
            // Diagonal
            if dx > 0 && dy < 0 {
                // NE → note below-left
                return CGPoint(x: bx - off, y: by + off)
            }
            if dx > 0 && dy > 0 {
                // SE → note above-left
                return CGPoint(x: bx - off, y: by - off - DesignTokens.noteHeight)
            }
            if dx < 0 && dy < 0 {
                // NW → note below-right
                return CGPoint(x: bx + off, y: by + off)
            }
            // SW → note above-right
            return CGPoint(x: bx + off, y: by - off - DesignTokens.noteHeight)

        case .rectangle(let origin, let size):
            // rectN: outward from rectangle center through badge corner
            let cx = origin.x + size.width / 2
            let cy = origin.y + size.height / 2
            let dx = bx - cx
            let dy = by - cy
            let off = br + gap + 2

            if abs(dx) > abs(dy) {
                if dx > 0 {
                    return CGPoint(x: bx + off, y: by - DesignTokens.noteHeight / 2)
                }
                return CGPoint(x: bx - off, y: by - DesignTokens.noteHeight / 2)
            }
            if dy > 0 {
                return CGPoint(x: bx + off, y: by + off)
            }
            return CGPoint(x: bx + off, y: by - off - DesignTokens.noteHeight)

        case .circle(let center, _):
            // circN: 8-direction radial outward from center through badge
            let dx = bx - center.x
            let dy = by - center.y
            let ax = abs(dx)
            let ay = abs(dy)
            let off = br + gap + 2

            if ax > ay * 1.5 {
                // Primarily horizontal
                if dx > 0 {
                    return CGPoint(x: bx + off, y: by - DesignTokens.noteHeight / 2)
                }
                return CGPoint(x: bx - off, y: by - DesignTokens.noteHeight / 2)
            }
            if ay > ax * 1.5 {
                // Primarily vertical
                if dy > 0 {
                    return CGPoint(x: bx + off, y: by + off)
                }
                return CGPoint(x: bx + off, y: by - off - DesignTokens.noteHeight)
            }
            // Diagonal
            if dx > 0 && dy < 0 {
                return CGPoint(x: bx + off, y: by - off - DesignTokens.noteHeight)
            }
            if dx > 0 && dy > 0 {
                return CGPoint(x: bx + off, y: by + off)
            }
            if dx < 0 && dy < 0 {
                return CGPoint(x: bx - off, y: by - off - DesignTokens.noteHeight)
            }
            return CGPoint(x: bx - off, y: by + off)

        case .freehand:
            // Same as pin: note to the right of badge
            return CGPoint(x: bx + br + gap, y: by - DesignTokens.noteHeight / 2)
        }
    }

    // MARK: - Note pill states (matches prototype NP component)

    enum NotePillState {
        case `default`, hover, selected, editing
    }

    /// Public for visual test harness
    static func createNotePillForTest(number: Int, text: String, state: NotePillState) -> NSView {
        return createNotePill(number: number, text: text, state: state)
    }

    private static func createNotePill(number: Int, text: String, state: NotePillState = .default) -> NSView {
        let numberStr = "\(number)"

        let font = DesignTokens.noteTextFont
        let numberFont = NSFont.systemFont(ofSize: 8, weight: .semibold)

        let attrStr = NSMutableAttributedString()
        // Number prefix: 8px weight 600, rgba(153,27,27,0.4), marginRight 7px
        attrStr.append(NSAttributedString(string: numberStr, attributes: [
            .font: numberFont,
            .foregroundColor: NSColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 0.4)
        ]))
        // 7px gap via kern on the number
        attrStr.addAttribute(.kern, value: 7.0, range: NSRange(location: numberStr.count - 1, length: 1))
        // Note text: 12px, #7f1d1d
        attrStr.append(NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 1.0)
        ]))

        let textField = NSTextField(labelWithString: "")
        textField.attributedStringValue = attrStr
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.maximumNumberOfLines = 0
        textField.lineBreakMode = .byWordWrapping
        textField.preferredMaxLayoutWidth = 160
        textField.sizeToFit()

        let padding: CGFloat = 12
        let vertPadding: CGFloat = 4
        let pillWidth = textField.frame.width + padding * 2
        let pillHeight = max(DesignTokens.noteHeight, textField.frame.height + vertPadding * 2)

        // Outer container (holds shadow, does NOT clip)
        let pill = NSView(frame: NSRect(x: 0, y: 0, width: pillWidth, height: pillHeight))
        pill.wantsLayer = true
        pill.layer?.masksToBounds = false

        // Shadow: 0 1px 4px rgba(0,0,0,0.06)
        pill.layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
        pill.layer?.shadowOffset = CGSize(width: 0, height: -1)
        pill.layer?.shadowRadius = 4
        pill.layer?.shadowOpacity = 1

        // Frosted glass backdrop blur via CALayer backgroundFilters (blur 10px)
        // This applies a Gaussian blur to content behind the pill without adding
        // NSVisualEffectView's built-in material tinting.
        let blurLayer = CALayer()
        blurLayer.frame = NSRect(origin: .zero, size: pill.frame.size)
        blurLayer.cornerRadius = DesignTokens.noteCornerRadius
        blurLayer.masksToBounds = true
        if let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10]) {
            blurLayer.backgroundFilters = [blurFilter]
        }
        pill.layer?.addSublayer(blurLayer)

        // Warm-tinted overlay on top of blur (translucent off-white per state)
        let tintView = NSView(frame: NSRect(origin: .zero, size: pill.frame.size))
        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = DesignTokens.noteCornerRadius
        tintView.layer?.masksToBounds = true

        // Background and border per state (from prototype NP component)
        // Colors: rgba(255,248,248,0.82) = NSColor(r:1, g:0.973, b:0.973, a:0.82)
        switch state {
        case .default:
            tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.973, blue: 0.973, alpha: 0.82).cgColor
            tintView.layer?.borderColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.18).cgColor
            tintView.layer?.borderWidth = 1
        case .hover:
            tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.961, blue: 0.961, alpha: 0.88).cgColor
            tintView.layer?.borderColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.4).cgColor
            tintView.layer?.borderWidth = 1
        case .selected:
            tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.961, blue: 0.961, alpha: 0.9).cgColor
            tintView.layer?.borderColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.5).cgColor
            tintView.layer?.borderWidth = 1.5
        case .editing:
            tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.961, blue: 0.961, alpha: 0.92).cgColor
            tintView.layer?.borderColor = DesignTokens.red.cgColor
            tintView.layer?.borderWidth = 1.5
        }
        pill.addSubview(tintView)

        textField.frame = NSRect(x: padding, y: (pillHeight - textField.frame.height) / 2, width: textField.frame.width, height: textField.frame.height)
        pill.addSubview(textField)

        return pill
    }
}
