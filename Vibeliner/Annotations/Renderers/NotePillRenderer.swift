import AppKit

/// Callback protocol for note pill interactions
protocol NotePillDelegate: AnyObject {
    func notePillHovered(annotationId: UUID?)
    func notePillClicked(annotationId: UUID)
}

final class NotePillRenderer {

    static let pillIdentifier = "notePill"

    static func drawNotePills(in view: NSView, annotations: [Annotation], canvasSize: NSSize, hoveredId: UUID? = nil, selectedId: UUID? = nil, editingId: UUID? = nil, delegate: NotePillDelegate? = nil) {
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

            let placement = notePlacement(for: annotation)
            let pill = NotePillView(
                annotationId: annotation.id,
                number: annotation.number,
                text: annotation.noteText,
                state: state,
                delegate: delegate
            )
            pill.identifier = NSUserInterfaceItemIdentifier(pillIdentifier)

            // Apply anchor: convert anchor point to AppKit frame origin using actual pill width
            let origin = anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: pill.frame.width)
            pill.frame.origin = origin
            view.addSubview(pill)
        }
    }

    // MARK: - Anchor

    enum Anchor { case tl, tr, bl, br }

    struct PlacedNote {
        let point: CGPoint
        let anchor: Anchor
    }

    /// Convert anchor point + anchor type to AppKit frame origin using ACTUAL pill width
    private static func anchoredOrigin(point: CGPoint, anchor: Anchor, pillWidth: CGFloat) -> CGPoint {
        let h = DesignTokens.noteHeight
        switch anchor {
        case .tl: return CGPoint(x: point.x, y: point.y - h / 2)
        case .tr: return CGPoint(x: point.x - pillWidth, y: point.y - h / 2)
        case .bl: return CGPoint(x: point.x, y: point.y - h)
        case .br: return CGPoint(x: point.x - pillWidth, y: point.y - h)
        }
    }

    // MARK: - Note placement

    static func notePillPosition(for annotation: Annotation, canvasSize: NSSize) -> CGPoint {
        let placement = notePlacement(for: annotation)
        return anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: 130)
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
            let dx = end.x - bx
            let dy = end.y - by
            let ax = abs(dx), ay = abs(dy)

            if ax > ay * 1.5 {
                if dx > 0 {
                    return PlacedNote(point: CGPoint(x: bx - off, y: by - off), anchor: .tr)
                }
                return PlacedNote(point: CGPoint(x: bx + off, y: by - off), anchor: .tl)
            }
            if ay > ax * 1.5 {
                if dy < 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: by), anchor: .tl)
                }
                return PlacedNote(point: CGPoint(x: bx + off, y: by), anchor: .tl)
            }
            if dx > 0 && dy > 0 {
                return PlacedNote(point: CGPoint(x: bx - off, y: by - off), anchor: .tr)
            }
            if dx > 0 && dy < 0 {
                return PlacedNote(point: CGPoint(x: bx - off, y: by + off), anchor: .br)
            }
            if dx < 0 && dy > 0 {
                return PlacedNote(point: CGPoint(x: bx + off, y: by - off), anchor: .tl)
            }
            return PlacedNote(point: CGPoint(x: bx + off, y: by + off), anchor: .bl)

        case .rectangle(let origin, let size):
            let cx = origin.x + size.width / 2
            let cy = origin.y + size.height / 2
            let dx = bx - cx
            let dy = by - cy

            if abs(dx) > abs(dy) {
                if dx > 0 {
                    return PlacedNote(point: CGPoint(x: bx + off, y: by), anchor: .tl)
                }
                return PlacedNote(point: CGPoint(x: bx - off, y: by), anchor: .tr)
            }
            if dy < 0 {
                return PlacedNote(point: CGPoint(x: bx + off, y: by - br - gap - 6), anchor: .tl)
            }
            return PlacedNote(point: CGPoint(x: bx + off, y: by + br + gap + 6), anchor: .bl)

        case .circle(let center, _):
            let dx = bx - center.x
            let dy = by - center.y
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

    // MARK: - State enum

    enum NotePillState {
        case `default`, hover, selected, editing
    }

    /// Public for visual test harness
    static func createNotePillForTest(number: Int, text: String, state: NotePillState) -> NSView {
        return NotePillView(annotationId: UUID(), number: number, text: text, state: state, delegate: nil)
    }
}

// MARK: - Interactive Note Pill View

final class NotePillView: NSView {

    let annotationId: UUID
    private weak var pillDelegate: NotePillDelegate?
    private let tintView: NSView
    private var currentState: NotePillRenderer.NotePillState
    private var isHoveredByMouse = false

    init(annotationId: UUID, number: Int, text: String, state: NotePillRenderer.NotePillState, delegate: NotePillDelegate?) {
        self.annotationId = annotationId
        self.pillDelegate = delegate
        self.currentState = state
        self.tintView = NSView()

        // VIB-161/VIB-166: Proper max width, wrapping, and vertical centering
        let padding: CGFloat = 12
        let vertPad: CGFloat = 4
        let prefixGap: CGFloat = 7
        let maxPillW: CGFloat = 180  // VIB-161: max width resting
        let lineH: CGFloat = 16

        // Number prefix label (separate from text for independent sizing)
        let numberFont = NSFont.systemFont(ofSize: 8, weight: .semibold)
        let prefixStr = "\(number)" as NSString
        let prefixAttrs: [NSAttributedString.Key: Any] = [.font: numberFont]
        let prefixSize = prefixStr.size(withAttributes: prefixAttrs)

        // Text label
        let textFont = DesignTokens.noteTextFont
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: textFont,
            .foregroundColor: NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 1.0)
        ]

        // Calculate text width: maxPillW - prefix area - padding
        let prefixW = prefixSize.width
        let textX = padding + prefixW + prefixGap
        let maxTextW = maxPillW - textX - padding

        // Create text field with wrapping
        let textField = NSTextField(labelWithString: text)
        textField.font = textFont
        textField.textColor = NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 1.0)
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.maximumNumberOfLines = 0  // VIB-161: unlimited lines
        textField.lineBreakMode = .byWordWrapping
        textField.preferredMaxLayoutWidth = maxTextW
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Size to fit within max text width
        textField.frame = NSRect(x: 0, y: 0, width: maxTextW, height: 0)
        textField.sizeToFit()
        // If text is short, shrink width to fit content
        let actualTextW = min(textField.frame.width, maxTextW)
        textField.sizeToFit()

        // VIB-166: Pill dimensions with exact padding: 4px top, 4px bottom, 12px left, 12px right
        let contentH = max(lineH, textField.frame.height)
        let pillWidth = min(maxPillW, textX + actualTextW + padding)
        let pillHeight = max(DesignTokens.noteHeight, contentH + vertPad * 2) // min 26px

        super.init(frame: NSRect(x: 0, y: 0, width: pillWidth, height: pillHeight))
        wantsLayer = true
        layer?.masksToBounds = false

        // Shadow
        layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
        layer?.shadowOffset = CGSize(width: 0, height: -1)
        layer?.shadowRadius = 4
        layer?.shadowOpacity = 1

        // Blur backdrop
        let blurLayer = CALayer()
        blurLayer.frame = bounds
        blurLayer.cornerRadius = DesignTokens.noteCornerRadius
        blurLayer.masksToBounds = true
        if let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10]) {
            blurLayer.backgroundFilters = [blurFilter]
        }
        layer?.addSublayer(blurLayer)

        // Tint overlay — matches pill bounds exactly (VIB-166: concentric border)
        tintView.frame = bounds
        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = DesignTokens.noteCornerRadius
        tintView.layer?.masksToBounds = true
        addSubview(tintView)

        // VIB-166: Number prefix — vertically centered in pill
        let prefixLabel = NSTextField(labelWithString: "\(number)")
        prefixLabel.font = numberFont
        prefixLabel.textColor = NSColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 0.4)
        prefixLabel.isBezeled = false
        prefixLabel.drawsBackground = false
        prefixLabel.sizeToFit()
        prefixLabel.frame.origin = NSPoint(
            x: padding,
            y: (pillHeight - prefixLabel.frame.height) / 2
        )
        addSubview(prefixLabel)

        // VIB-166: Text field — vertically centered in pill
        textField.frame = NSRect(
            x: textX,
            y: (pillHeight - textField.frame.height) / 2,
            width: actualTextW,
            height: textField.frame.height
        )
        addSubview(textField)

        applyState(state)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - State

    private func applyState(_ state: NotePillRenderer.NotePillState) {
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
    }

    // MARK: - Mouse tracking (hover + click)

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        isHoveredByMouse = true
        if currentState == .default {
            applyState(.hover)
        }
        pillDelegate?.notePillHovered(annotationId: annotationId)
    }

    override func mouseExited(with event: NSEvent) {
        isHoveredByMouse = false
        if currentState == .default {
            applyState(.default)
        }
        pillDelegate?.notePillHovered(annotationId: nil)
    }

    override func mouseDown(with event: NSEvent) {
        pillDelegate?.notePillClicked(annotationId: annotationId)
    }
}
