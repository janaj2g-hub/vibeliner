import AppKit

final class NotePillView: NSView {

    let annotationId: UUID
    /// VIB-194: Track badge position to detect moves vs hover-only refreshes
    var lastBadgePosition: CGPoint = .zero
    /// VIB-194 (attempt 5): Cache offset from badge to pill origin — apply directly on drag
    var pillOffsetFromBadge: CGPoint = .zero
    private weak var pillDelegate: NotePillDelegate?
    private var tintView: NSView!
    private var currentState: NotePillRenderer.NotePillState
    private var isHoveredByMouse = false

    init(annotationId: UUID, number: Int, text: String, state: NotePillRenderer.NotePillState, delegate: NotePillDelegate?) {
        self.annotationId = annotationId
        self.pillDelegate = delegate
        self.currentState = state

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
            tintView.layer?.backgroundColor = DesignTokens.editorNoteSurfaceDefault.cgColor
            tintView.layer?.borderColor = DesignTokens.editorNoteBorderDefault.cgColor
            layer?.shadowRadius = 0
            layer?.shadowOpacity = 0
        case .hover:
            tintView.layer?.backgroundColor = DesignTokens.editorNoteSurfaceHover.cgColor
            tintView.layer?.borderColor = DesignTokens.editorNoteBorderHover.cgColor
            layer?.shadowRadius = 0
            layer?.shadowOpacity = 0
        case .selected:
            tintView.layer?.backgroundColor = DesignTokens.editorNoteSurfaceSelected.cgColor
            tintView.layer?.borderColor = DesignTokens.editorNoteBorderSelected.cgColor
            layer?.shadowRadius = 0
            layer?.shadowOpacity = 0
        case .editing:
            tintView.layer?.backgroundColor = DesignTokens.editorNoteSurfaceEditing.cgColor
            tintView.layer?.borderColor = DesignTokens.red.cgColor
            layer?.shadowColor = DesignTokens.red.cgColor
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
