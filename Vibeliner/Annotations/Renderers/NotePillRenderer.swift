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
                // Reuse: update position and state without recreating view hierarchy
                existing.updateState(state)
                let origin = anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: existing.frame.width)
                existing.frame.origin = origin
                // VIB-186: Round to integral pixels
                existing.frame = NSIntegralRect(existing.frame)
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
                let origin = anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: pill.frame.width)
                pill.frame.origin = origin
                // VIB-186: Round to integral pixels for crisp borders
                pill.frame = NSIntegralRect(pill.frame)
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

    /// Convert anchor point + anchor type to AppKit frame origin using ACTUAL pill width
    static func anchoredOrigin(point: CGPoint, anchor: Anchor, pillWidth: CGFloat, pillHeight: CGFloat? = nil) -> CGPoint {
        let h = pillHeight ?? DesignTokens.noteHeight
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
            .foregroundColor: DesignTokens.noteTextColor
        ]

        // Calculate text width: maxPillW - prefix area - padding
        let prefixW = prefixSize.width
        let textX = padding + prefixW + prefixGap
        let maxTextW = maxPillW - textX - padding

        // Create text field with wrapping
        let textField = NSTextField(labelWithString: text)
        textField.font = textFont
        textField.textColor = DesignTokens.noteTextColor
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

        // VIB-186/188: Shadow starts at zero — editing state adds red glow
        layer?.shadowRadius = 0
        layer?.shadowOpacity = 0

        // Blur backdrop
        let blurLayer = CALayer()
        blurLayer.frame = bounds
        blurLayer.cornerRadius = DesignTokens.noteCornerRadius
        blurLayer.masksToBounds = true
        if let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10]) {
            blurLayer.backgroundFilters = [blurFilter]
        }
        layer?.addSublayer(blurLayer)

        // Tint overlay — matches pill bounds exactly
        tintView.frame = bounds
        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = DesignTokens.noteCornerRadius
        tintView.layer?.masksToBounds = true
        // VIB-186: Constant borderWidth = 2, NEVER changes in applyState
        tintView.layer?.borderWidth = 2
        tintView.layer?.allowsEdgeAntialiasing = true
        addSubview(tintView)

        // VIB-166: Number prefix — vertically centered in pill
        let prefixLabel = NSTextField(labelWithString: "\(number)")
        prefixLabel.font = numberFont
        // VIB-188: Slightly more visible prefix (alpha 0.45 vs 0.35)
        prefixLabel.textColor = NSColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 0.45)
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

    /// VIB-181: Update visual state without recreating view hierarchy
    func updateState(_ newState: NotePillRenderer.NotePillState) {
        guard newState != currentState else { return }
        currentState = newState
        applyState(newState)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - State

    /// VIB-186: borderWidth is ALWAYS 2 (set in init) — NEVER changed here.
    /// VIB-188: Concept B — gray→red border shift with red glow on editing.
    private func applyState(_ state: NotePillRenderer.NotePillState) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)

        switch state {
        case .default:
            // Translucent warm white, neutral GRAY border (barely visible)
            tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.957, blue: 0.957, alpha: 0.72).cgColor
            tintView.layer?.borderColor = NSColor(red: 180/255, green: 180/255, blue: 180/255, alpha: 0.22).cgColor
            layer?.shadowRadius = 0
            layer?.shadowOpacity = 0
        case .hover:
            // Slightly more opaque, RED border appears
            tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.957, blue: 0.957, alpha: 0.80).cgColor
            tintView.layer?.borderColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.45).cgColor
            layer?.shadowRadius = 0
            layer?.shadowOpacity = 0
        case .selected:
            // More opaque, stronger red border
            tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.957, blue: 0.957, alpha: 0.88).cgColor
            tintView.layer?.borderColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.55).cgColor
            layer?.shadowRadius = 0
            layer?.shadowOpacity = 0
        case .editing:
            // Nearly opaque, solid red border + red glow halo
            tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.980, blue: 0.980, alpha: 0.96).cgColor
            tintView.layer?.borderColor = DesignTokens.red.cgColor
            layer?.shadowColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0).cgColor
            layer?.shadowOffset = .zero
            layer?.shadowRadius = 10
            layer?.shadowOpacity = 0.22
        }

        CATransaction.commit()
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
