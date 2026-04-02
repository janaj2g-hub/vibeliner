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

    // MARK: - Anchor type (matches prototype transform logic)
    // In SVG/prototype: tl means note's top-left is at the anchor point
    // In AppKit (y-up): we need to convert SVG y-down anchors to AppKit frame origins

    enum Anchor { case tl, tr, bl, br }

    struct PlacedNote {
        let point: CGPoint  // anchor point in prototype coords
        let anchor: Anchor
    }

    // MARK: - Note placement (matches prototype pinN/arrowN/rectN/circN functions)
    // IMPORTANT: prototype uses SVG y-down. AppKit uses y-up.
    // dy comparisons are FLIPPED: prototype dy>0 = down = AppKit dy<0

    static func notePillPosition(for annotation: Annotation, canvasSize: NSSize) -> CGPoint {
        let placement = notePlacement(for: annotation)
        return anchoredOrigin(point: placement.point, anchor: placement.anchor)
    }

    /// Convert an anchor point + anchor type to an AppKit frame origin (bottom-left corner)
    /// In prototype CSS: tl = translateY(-50%), tr = translateX(-100%) translateY(-50%), etc.
    /// We approximate pill size for the anchor transform.
    private static func anchoredOrigin(point: CGPoint, anchor: Anchor, pillWidth: CGFloat = 130) -> CGPoint {
        let h = DesignTokens.noteHeight
        switch anchor {
        case .tl:
            // Note extends right and down from point → AppKit: origin is below-right
            return CGPoint(x: point.x, y: point.y - h / 2)
        case .tr:
            // Note extends left and down → AppKit: origin shifted left by width
            return CGPoint(x: point.x - pillWidth, y: point.y - h / 2)
        case .bl:
            // Note extends right and up → AppKit: origin at point, shifted up
            return CGPoint(x: point.x, y: point.y - h)
        case .br:
            // Note extends left and up
            return CGPoint(x: point.x - pillWidth, y: point.y - h)
        }
    }

    private static func notePlacement(for annotation: Annotation) -> PlacedNote {
        let bx = annotation.badgePosition.x
        let by = annotation.badgePosition.y
        let br = DesignTokens.badgeDiameter / 2
        let gap: CGFloat = 6
        let off = br + gap + 2

        switch annotation.position {
        case .pin:
            return PlacedNote(point: CGPoint(x: bx + br + gap, y: by), anchor: .tl)

        case .arrow(_, let end):
            // arrowN: note goes OPPOSITE to arrow direction.
            // Prototype uses SVG y-down. AppKit is y-up.
            // Prototype dy>0 = arrow goes down (screen). AppKit dy<0 = arrow goes down.
            // For position offsets: prototype ny+off = lower on screen = AppKit ny-off.
            let dx = end.x - bx
            let dy = end.y - by  // AppKit: positive=up, negative=down
            let ax = abs(dx), ay = abs(dy)

            if ax > ay * 1.5 {
                // Primarily horizontal
                if dx > 0 {
                    // Arrow RIGHT → note BELOW-LEFT: proto {bx-off, by+off, "tr"}
                    return PlacedNote(point: CGPoint(x: bx - off, y: by - off), anchor: .tr)
                }
                // Arrow LEFT → note BELOW-RIGHT: proto {bx+off, by+off, "tl"}
                return PlacedNote(point: CGPoint(x: bx + off, y: by - off), anchor: .tl)
            }
            if ay > ax * 1.5 {
                // Primarily vertical
                if dy < 0 {
                    // Arrow DOWN (AppKit dy<0) = proto dy>0 → note RIGHT: {bx+off, by, "tl"}
                    return PlacedNote(point: CGPoint(x: bx + off, y: by), anchor: .tl)
                }
                // Arrow UP (AppKit dy>0) = proto dy<0 → note RIGHT: {bx+off, by, "tl"}
                return PlacedNote(point: CGPoint(x: bx + off, y: by), anchor: .tl)
            }
            // Diagonal — map prototype directions to AppKit
            if dx > 0 && dy > 0 {
                // AppKit right+up = proto NE (dx>0, dy<0) → BELOW-LEFT: {bx-off, by+off, "tr"}
                return PlacedNote(point: CGPoint(x: bx - off, y: by - off), anchor: .tr)
            }
            if dx > 0 && dy < 0 {
                // AppKit right+down = proto SE (dx>0, dy>0) → ABOVE-LEFT: {bx-off, by-off, "br"}
                return PlacedNote(point: CGPoint(x: bx - off, y: by + off), anchor: .br)
            }
            if dx < 0 && dy > 0 {
                // AppKit left+up = proto NW (dx<0, dy<0) → BELOW-RIGHT: {bx+off, by+off, "tl"}
                return PlacedNote(point: CGPoint(x: bx + off, y: by - off), anchor: .tl)
            }
            // AppKit left+down = proto SW (dx<0, dy>0) → ABOVE-RIGHT: {bx+off, by-off, "bl"}
            return PlacedNote(point: CGPoint(x: bx + off, y: by + off), anchor: .bl)

        case .rectangle(let origin, let size):
            // rectN: note outward from rect center through badge corner.
            // Prototype rectN() uses SVG y-down coords. AppKit is y-up.
            // Prototype dy>0 = badge below center (screen). AppKit dy<0 = badge below center.
            let cx = origin.x + size.width / 2
            let cy = origin.y + size.height / 2
            let dx = bx - cx
            let dy = by - cy  // AppKit y-up: positive = badge above center on screen

            if abs(dx) > abs(dy) {
                // Badge is more to the LEFT or RIGHT of center
                if dx > 0 {
                    // Badge on right side → note to the right
                    return PlacedNote(point: CGPoint(x: bx + off, y: by), anchor: .tl)
                }
                // Badge on left side → note to the left
                return PlacedNote(point: CGPoint(x: bx - off, y: by), anchor: .tr)
            }
            // Badge is more ABOVE or BELOW center
            if dy < 0 {
                // Badge below center (AppKit y-up: lower y = lower on screen)
                // = prototype dy>0 → note below badge
                return PlacedNote(point: CGPoint(x: bx + off, y: by - br - gap - 6), anchor: .tl)
            }
            // Badge above center (AppKit: higher y = higher on screen)
            // = prototype dy<0 → note above badge
            return PlacedNote(point: CGPoint(x: bx + off, y: by + br + gap + 6), anchor: .bl)

        case .circle(let center, _):
            // circN: radial outward from center through badge
            let dx = bx - center.x
            let dy = by - center.y  // AppKit y-up
            let ax = abs(dx), ay = abs(dy)

            if ax > ay * 1.5 {
                if dx > 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: by), anchor: .tl)
                }
                return PlacedNote(point: CGPoint(x: bx - off, y: by), anchor: .tr)
            }
            if ay > ax * 1.5 {
                if dy > 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: by + off), anchor: .bl)
                }
                return PlacedNote(point: CGPoint(x: bx + off, y: by - off), anchor: .tl)
            }
            // Diagonal
            if dx > 0 && dy > 0 {
                return PlacedNote(point: CGPoint(x: bx + off, y: by + off), anchor: .bl)
            }
            if dx > 0 && dy < 0 {
                return PlacedNote(point: CGPoint(x: bx + off, y: by - off), anchor: .tl)
            }
            if dx < 0 && dy > 0 {
                return PlacedNote(point: CGPoint(x: bx - off, y: by + off), anchor: .br)
            }
            return PlacedNote(point: CGPoint(x: bx - off, y: by - off), anchor: .tr)

        case .freehand:
            return PlacedNote(point: CGPoint(x: bx + br + gap, y: by), anchor: .tl)
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
