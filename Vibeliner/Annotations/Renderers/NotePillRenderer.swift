import AppKit

/// Callback protocol for note pill interactions
protocol NotePillDelegate: AnyObject {
    func notePillHovered(annotationId: UUID?)
    func notePillClicked(annotationId: UUID)
}

final class NotePillRenderer {

    static let pillIdentifier = "notePill"

    /// VIB-181: Reuse pool — update existing pills, add/remove only as needed
    /// VIB-269: `imagePrefixes` maps annotation ID → image prefix string (e.g., "Image 2") for composite mode.
    static func drawNotePills(in view: NSView, annotations: [Annotation], canvasSize: NSSize, hoveredId: UUID? = nil, selectedId: UUID? = nil, editingId: UUID? = nil, delegate: NotePillDelegate? = nil, imagePrefixes: [UUID: String] = [:]) {
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

            let currentPrefix = imagePrefixes[annotation.id]
            if let existing = pillsByID[annotation.id],
               existing.currentImagePrefix == currentPrefix {
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
                // VIB-269: Remove stale pill if prefix changed (e.g., image title renamed)
                pillsByID[annotation.id]?.removeFromSuperview()
                // Create new pill
                let pill = NotePillView(
                    annotationId: annotation.id,
                    number: annotation.number,
                    text: annotation.noteText,
                    imagePrefix: imagePrefixes[annotation.id],
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

final class NotePillView: NSView {

    let annotationId: UUID
    /// VIB-194: Track badge position to detect moves vs hover-only refreshes
    var lastBadgePosition: CGPoint = .zero
    /// VIB-194 (attempt 5): Cache offset from badge to pill origin — apply directly on drag
    var pillOffsetFromBadge: CGPoint = .zero
    /// VIB-269: Track image prefix to detect changes (e.g., title rename)
    var currentImagePrefix: String?
    private weak var pillDelegate: NotePillDelegate?
    private var tintView: NSView!
    private var currentState: NotePillRenderer.NotePillState
    private var isHoveredByMouse = false

    init(annotationId: UUID, number: Int, text: String, imagePrefix: String? = nil, state: NotePillRenderer.NotePillState, delegate: NotePillDelegate?) {
        self.annotationId = annotationId
        self.pillDelegate = delegate
        self.currentState = state
        self.currentImagePrefix = imagePrefix

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

        // Calculate text width: maxPillW - prefix area - padding
        let prefixW = prefixSize.width
        let textX = padding + prefixW + prefixGap
        let maxTextW = maxPillW - textX - padding

        // VIB-269: Build attributed text with optional image prefix in dimmer color
        let displayAttrString: NSAttributedString
        if let imgPrefix = imagePrefix {
            let attrText = NSMutableAttributedString()
            attrText.append(NSAttributedString(string: "\(imgPrefix): ", attributes: [
                .font: textFont,
                .foregroundColor: DesignTokens.notePrefixColor
            ]))
            attrText.append(NSAttributedString(string: text, attributes: [
                .font: textFont,
                .foregroundColor: DesignTokens.noteTextColor
            ]))
            displayAttrString = attrText
        } else {
            displayAttrString = NSAttributedString(string: text, attributes: [
                .font: textFont,
                .foregroundColor: DesignTokens.noteTextColor
            ])
        }

        // Create text field with wrapping and attributed text
        let textField = NSTextField(labelWithString: "")
        textField.attributedStringValue = displayAttrString
        textField.font = textFont
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.maximumNumberOfLines = 0  // VIB-161: unlimited lines
        textField.lineBreakMode = .byWordWrapping
        textField.preferredMaxLayoutWidth = maxTextW
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // VIB-204: Use cellSize to measure wrapped text height — no double sizeToFit
        let cellBounds = NSRect(x: 0, y: 0, width: maxTextW, height: CGFloat.greatestFiniteMagnitude)
        let fittedSize = textField.cell?.cellSize(forBounds: cellBounds) ?? NSSize(width: maxTextW, height: lineH)
        let actualTextW = min(fittedSize.width, maxTextW)
        let contentH = max(lineH, fittedSize.height)
        let pillWidth = min(maxPillW, textX + actualTextW + padding)
        let pillHeight = max(DesignTokens.noteHeight, contentH + vertPad * 2) // min 26px

        super.init(frame: NSRect(x: 0, y: 0, width: pillWidth, height: pillHeight))
        wantsLayer = true
        layer?.masksToBounds = false

        // VIB-197: Use PillChromeBuilder for blur, tint, and prefix (single source of truth)
        let chrome = PillChromeBuilder.build(size: NSSize(width: pillWidth, height: pillHeight), number: number)
        layer?.addSublayer(chrome.blurLayer)
        tintView = chrome.tintView
        addSubview(tintView)
        addSubview(chrome.prefixLabel)

        // VIB-166: Text field — vertically centered in pill
        textField.frame = NSRect(
            x: textX,
            y: (pillHeight - fittedSize.height) / 2,
            width: actualTextW,
            height: fittedSize.height
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
