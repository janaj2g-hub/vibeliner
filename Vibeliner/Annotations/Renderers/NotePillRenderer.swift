import AppKit

/// Callback protocol for note pill interactions
protocol NotePillDelegate: AnyObject {
    func notePillHovered(annotationId: UUID?)
    func notePillClicked(annotationId: UUID)
}

final class NotePillRenderer {

    static let pillIdentifier = "notePill"

    /// VIB-181: Reuse pool — update existing pills, add/remove only as needed
    static func drawNotePills(in view: NSView, annotations: [Annotation], canvasSize: NSSize, hoveredId: UUID? = nil, selectedId: UUID? = nil, editingId: UUID? = nil, delegate: NotePillDelegate? = nil) {
        // Collect existing pills by annotation ID
        let existingPills = view.subviews.compactMap { $0 as? NotePillView }
        var pillsByID: [UUID: NotePillView] = [:]
        for pill in existingPills { pillsByID[pill.annotationId] = pill }

        // Determine which annotations need pills
        var neededIDs = Set<UUID>()
        for annotation in annotations {
            guard !annotation.noteText.isEmpty, annotation.id != editingId else { continue }
            neededIDs.insert(annotation.id)
        }

        // Remove pills for annotations that no longer need them
        for pill in existingPills where !neededIDs.contains(pill.annotationId) {
            pill.removeFromSuperview()
        }

        // Update existing pills or create new ones
        for annotation in annotations {
            guard !annotation.noteText.isEmpty, annotation.id != editingId else { continue }

            let state: NotePillState
            if annotation.id == selectedId { state = .selected }
            else if annotation.id == hoveredId { state = .hover }
            else { state = .default }

            let placement = notePlacement(for: annotation)

            if let existing = pillsByID[annotation.id] {
                // VIB-194: Update state always. Only reposition if badge moved.
                existing.updateState(state)
                let badgeMoved = hypot(
                    annotation.badgePosition.x - existing.lastBadgePosition.x,
                    annotation.badgePosition.y - existing.lastBadgePosition.y
                ) > 0.5
                if badgeMoved {
                    // VIB-206: Apply cached offset directly. No NSIntegralRect (causes
                    // cumulative rounding drift). No offset recalculation (compounds error).
                    existing.frame.origin = CGPoint(
                        x: annotation.badgePosition.x + existing.pillOffsetFromBadge.x,
                        y: annotation.badgePosition.y + existing.pillOffsetFromBadge.y
                    )
                    existing.lastBadgePosition = annotation.badgePosition
                }
            } else {
                // Create new pill
                let pill = NotePillView(
                    annotationId: annotation.id,
                    number: annotation.number,
                    text: annotation.noteText,
                    state: state,
                    delegate: delegate
                )
                pill.identifier = NSUserInterfaceItemIdentifier(pillIdentifier)
                pill.lastBadgePosition = annotation.badgePosition
                let origin = anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: pill.frame.width, pillHeight: pill.frame.height)
                pill.frame.origin = origin
                pill.frame = NSIntegralRect(pill.frame)
                // VIB-194 (attempt 5): Cache offset from badge to pill origin
                pill.pillOffsetFromBadge = CGPoint(
                    x: pill.frame.origin.x - annotation.badgePosition.x,
                    y: pill.frame.origin.y - annotation.badgePosition.y
                )
                view.addSubview(pill)
            }
        }
    }

    // MARK: - Anchor

    enum Anchor { case tl, tr, bl, br }

    struct PlacedNote {
        let point: CGPoint
        let anchor: Anchor
    }

    /// VIB-192: Anchor from TOP edge, pill grows downward. In AppKit y-up,
    /// "top" = highest y. Pill frame origin (bottom-left) = point.y - h.
    static func anchoredOrigin(point: CGPoint, anchor: Anchor, pillWidth: CGFloat, pillHeight: CGFloat? = nil) -> CGPoint {
        let h = pillHeight ?? DesignTokens.noteHeight
        switch anchor {
        case .tl: return CGPoint(x: point.x, y: point.y - h)       // top-left at point, grows down
        case .tr: return CGPoint(x: point.x - pillWidth, y: point.y - h)  // top-right at point, grows down
        case .bl: return CGPoint(x: point.x, y: point.y)           // bottom-left at point, grows up
        case .br: return CGPoint(x: point.x - pillWidth, y: point.y)      // bottom-right at point, grows up
        }
    }

    // MARK: - Note placement

    static func notePillPosition(for annotation: Annotation, canvasSize: NSSize) -> CGPoint {
        let placement = notePlacement(for: annotation)
        return anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: 130)
    }

    /// VIB-162: Get raw placement (point + anchor) for editing pill positioning
    static func notePlacementForEditing(for annotation: Annotation) -> PlacedNote {
        return notePlacement(for: annotation)
    }

    private static func notePlacement(for annotation: Annotation) -> PlacedNote {
        let bx = annotation.badgePosition.x
        let by = annotation.badgePosition.y
        let br = DesignTokens.badgeDiameter / 2
        let gap: CGFloat = 6
        let off = br + gap + 2

        switch annotation.position {
        case .pin:
            // VIB-192: point at badge TOP (by + br) so pill top aligns with badge top
            return PlacedNote(point: CGPoint(x: bx + br + gap, y: by + br), anchor: .tl)

        case .arrow(_, let end):
            // VIB-192: Use badge top (by+br) for .tl/.tr, badge bottom (by-br) for .bl/.br
            let dx = end.x - bx
            let dy = end.y - by
            let ax = abs(dx), ay = abs(dy)
            let top = by + br  // badge top edge
            let bot = by - br  // badge bottom edge

            if ax > ay * 1.5 {
                if dx > 0 {
                    return PlacedNote(point: CGPoint(x: bx - off, y: bot - gap), anchor: .tr)
                }
                return PlacedNote(point: CGPoint(x: bx + off, y: bot - gap), anchor: .tl)
            }
            if ay > ax * 1.5 {
                if dy < 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: top), anchor: .tl)
                }
                return PlacedNote(point: CGPoint(x: bx + off, y: top), anchor: .tl)
            }
            if dx > 0 && dy > 0 {
                return PlacedNote(point: CGPoint(x: bx - off, y: bot - gap), anchor: .tr)
            }
            if dx > 0 && dy < 0 {
                return PlacedNote(point: CGPoint(x: bx - off, y: bot), anchor: .br)
            }
            if dx < 0 && dy > 0 {
                return PlacedNote(point: CGPoint(x: bx + off, y: bot - gap), anchor: .tl)
            }
            return PlacedNote(point: CGPoint(x: bx + off, y: bot), anchor: .bl)

        case .rectangle(let origin, let size):
            // VIB-192/194: badge top/bottom + 1.2× bias threshold
            let cx = origin.x + size.width / 2
            let cy = origin.y + size.height / 2
            let dx = bx - cx
            let dy = by - cy

            if abs(dx) > abs(dy) * 1.2 {
                if dx > 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: by + br), anchor: .tl)
                }
                return PlacedNote(point: CGPoint(x: bx - off, y: by + br), anchor: .tr)
            }
            if abs(dy) > abs(dx) * 1.2 {
                if dy < 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: by - br - gap - 6), anchor: .tl)
                }
                return PlacedNote(point: CGPoint(x: bx + off, y: by - br), anchor: .bl)
            }
            if dx > 0 {
                return PlacedNote(point: CGPoint(x: bx + off, y: by + br), anchor: .tl)
            }
            return PlacedNote(point: CGPoint(x: bx - off, y: by + br), anchor: .tr)

        case .circle(let center, _):
            // VIB-192: Use badge top/bottom for anchor points
            let dx = bx - center.x
            let dy = by - center.y
            let ax = abs(dx), ay = abs(dy)

            if ax > ay * 1.5 {
                if dx > 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: by + br), anchor: .tl)
                }
                return PlacedNote(point: CGPoint(x: bx - off, y: by + br), anchor: .tr)
            }
            if ay > ax * 1.5 {
                if dy > 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: by + off), anchor: .bl)
                }
                return PlacedNote(point: CGPoint(x: bx + off, y: by - off), anchor: .tl)
            }
            if dx > 0 && dy > 0 {
                return PlacedNote(point: CGPoint(x: bx + off, y: by - br), anchor: .bl)
            }
            if dx > 0 && dy < 0 {
                return PlacedNote(point: CGPoint(x: bx + off, y: by + br), anchor: .tl)
            }
            if dx < 0 && dy > 0 {
                return PlacedNote(point: CGPoint(x: bx - off, y: by - br), anchor: .br)
            }
            return PlacedNote(point: CGPoint(x: bx - off, y: by + br), anchor: .tr)

        case .freehand:
            // VIB-192: badge top
            return PlacedNote(point: CGPoint(x: bx + br + gap, y: by + br), anchor: .tl)
        }
    }

    // MARK: - State enum

    enum NotePillState {
        case `default`, hover, selected, editing
    }

    /// Public for visual test harness
    static func createNotePillForTest(number: Int, text: String, state: NotePillState) -> NSView {
        return NotePillView(annotationId: UUID(), number: number, text: text, state: state, delegate: nil)
    }
}

// MARK: - Shared Pill Chrome Builder

/// VIB-197: Single source of truth for pill chrome (blur, tint, border, number prefix).
/// Used by both NotePillView (resting) and CanvasView.openNoteEditor (editing).
enum PillChromeBuilder {
    struct PillChrome {
        let blurLayer: CALayer
        let tintView: NSView
        let prefixLabel: NSTextField
    }

    static func build(size: NSSize, number: Int) -> PillChrome {
        // Blur layer
        let blurLayer = CALayer()
        blurLayer.frame = NSRect(origin: .zero, size: size)
        blurLayer.cornerRadius = DesignTokens.noteCornerRadius
        blurLayer.masksToBounds = true
        if let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10]) {
            blurLayer.backgroundFilters = [blurFilter]
        }

        // Tint view
        let tintView = NSView(frame: NSRect(origin: .zero, size: size))
        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = DesignTokens.noteCornerRadius
        tintView.layer?.masksToBounds = true
        tintView.layer?.borderWidth = 2  // VIB-186 constant — single source of truth
        tintView.layer?.allowsEdgeAntialiasing = true

        // Number prefix
        let prefixLabel = NSTextField(labelWithString: "\(number)")
        prefixLabel.font = NSFont.systemFont(ofSize: 8, weight: .semibold)
        prefixLabel.textColor = NSColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 0.45)
        prefixLabel.isBezeled = false
        prefixLabel.drawsBackground = false
        prefixLabel.sizeToFit()
        prefixLabel.frame.origin = NSPoint(x: 12, y: (size.height - prefixLabel.frame.height) / 2)

        return PillChrome(blurLayer: blurLayer, tintView: tintView, prefixLabel: prefixLabel)
    }

    static func createEditableTextField(pillWidth: CGFloat, pillHeight: CGFloat, text: String, prefixWidth: CGFloat) -> NSTextField {
        let textField = NSTextField()
        textField.font = DesignTokens.noteTextFont
        textField.textColor = DesignTokens.noteTextColor
        textField.backgroundColor = .clear
        textField.drawsBackground = false
        textField.isBordered = false
        textField.isBezeled = false
        textField.focusRingType = .none
        textField.wantsLayer = true
        textField.usesSingleLineMode = false
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFontManager.shared.convert(NSFont.systemFont(ofSize: 12), toHaveTrait: .italicFontMask),
            .foregroundColor: NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 0.35)
        ]
        textField.placeholderAttributedString = NSAttributedString(string: "describe…", attributes: placeholderAttrs)
        textField.stringValue = text
        let textX = 12 + prefixWidth + 7
        textField.frame = NSRect(x: textX, y: 4, width: pillWidth - textX - 12, height: pillHeight - 8)
        return textField
    }
}

// MARK: - Interactive Note Pill View

