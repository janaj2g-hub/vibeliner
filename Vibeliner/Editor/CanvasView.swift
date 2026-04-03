import AppKit

final class CanvasView: NSView, NotePillDelegate {

    let marksLayer: MarksLayerView
    let notesLayer: NSView
    var activeTool: AnnotationTool?
    var store: AnnotationStore
    var undoManager_: UndoRedoManager?
    private var storeObserver: Any?
    private var ghostPosition: CGPoint?

    init(frame: NSRect, store: AnnotationStore) {
        self.store = store
        marksLayer = MarksLayerView(frame: NSRect(origin: .zero, size: frame.size), store: store)
        marksLayer.wantsLayer = true
        marksLayer.layer?.masksToBounds = true

        notesLayer = NSView(frame: NSRect(origin: .zero, size: frame.size))
        notesLayer.wantsLayer = true
        notesLayer.layer?.masksToBounds = false

        super.init(frame: NSRect(origin: .zero, size: frame.size))
        // VIB-167: CanvasView must not clip notes layer
        wantsLayer = true
        layer?.masksToBounds = false

        addSubview(marksLayer)
        addSubview(notesLayer)

        storeObserver = NotificationCenter.default.addObserver(
            forName: .annotationsDidChange, object: store, queue: .main
        ) { [weak self] _ in
            self?.marksLayer.needsDisplay = true
            self?.refreshNotePills()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let observer = storeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeAlways, .mouseEnteredAndExited], owner: self))
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        ghostPosition = point
        activeTool?.mouseMoved(to: point, in: self)
        marksLayer.ghostPosition = point
        marksLayer.ghostTool = activeTool

        // Hit-test for hover
        let oldHovered = hoveredAnnotationId
        hoveredAnnotationId = hitTestAnnotation(at: point)
        if hoveredAnnotationId != oldHovered {
            marksLayer.hoveredId = hoveredAnnotationId
            refreshNotePills()
        }

        marksLayer.needsDisplay = true
    }

    // Hit testing matching prototype ht() function
    // Priority: badge(12px) → arrow endpoint(10px) → rect corners(10px) → circle resize(10px) → body containment → freehand CPs(8px)
    private func hitTestAnnotation(at point: CGPoint) -> UUID? {
        for annotation in store.annotations.reversed() {
            // Badge proximity (12px)
            if hypot(point.x - annotation.badgePosition.x, point.y - annotation.badgePosition.y) < 12 {
                return annotation.id
            }

            switch annotation.position {
            case .arrow(_, let end):
                // Arrow endpoint (10px)
                if hypot(point.x - end.x, point.y - end.y) < 10 {
                    return annotation.id
                }

            case .rectangle(let origin, let size):
                // Rectangle corners (10px)
                let corners = [
                    CGPoint(x: origin.x, y: origin.y),
                    CGPoint(x: origin.x + size.width, y: origin.y),
                    CGPoint(x: origin.x, y: origin.y + size.height),
                    CGPoint(x: origin.x + size.width, y: origin.y + size.height)
                ]
                for corner in corners {
                    if hypot(point.x - corner.x, point.y - corner.y) < 10 {
                        return annotation.id
                    }
                }
                // Body containment (±5px)
                if point.x >= origin.x - 5 && point.x <= origin.x + size.width + 5 &&
                   point.y >= origin.y - 5 && point.y <= origin.y + size.height + 5 {
                    return annotation.id
                }

            case .circle(let center, let radius):
                // Opposite handle (10px)
                let bx = annotation.badgePosition.x
                let by = annotation.badgePosition.y
                let ox = center.x * 2 - bx
                let oy = center.y * 2 - by
                if hypot(point.x - ox, point.y - oy) < 10 {
                    return annotation.id
                }
                // Body containment
                if hypot(point.x - center.x, point.y - center.y) < radius + 8 {
                    return annotation.id
                }

            case .freehand(let pts):
                // Control point proximity (8px)
                for cp in pts {
                    if hypot(point.x - cp.x, point.y - cp.y) < 8 {
                        return annotation.id
                    }
                }

            case .pin:
                break // badge already checked above
            }
        }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        // VIB-193: Click outside editing pill = commit text
        if isEditingNote {
            let clickInPill = activeEditorPill.map { $0.frame.contains(point) } ?? false
            if !clickInPill {
                confirmNoteEditing()
                return  // Don't process as a tool action
            }
        }

        guard let undoMgr = undoManager_ else { return }
        activeTool?.mouseDown(at: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        // VIB-193: Don't intercept drags while editing — let text field handle selection
        if isEditingNote { return }
        let point = convert(event.locationInWindow, from: nil)
        guard let undoMgr = undoManager_ else { return }
        activeTool?.mouseDragged(to: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        // VIB-193: Don't intercept mouseUp while editing
        if isEditingNote { return }
        let point = convert(event.locationInWindow, from: nil)
        guard let undoMgr = undoManager_ else { return }
        activeTool?.mouseUp(at: point, in: self, store: store, undoManager: undoMgr)
        marksLayer.needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        ghostPosition = nil
        marksLayer.ghostPosition = nil
        marksLayer.needsDisplay = true
    }

    func refreshNotePills() {
        NotePillRenderer.drawNotePills(in: notesLayer, annotations: store.annotations, canvasSize: bounds.size, hoveredId: hoveredAnnotationId, selectedId: store.selectedAnnotation?.id, editingId: editingAnnotationId, delegate: self)
    }

    // MARK: - NotePillDelegate

    func notePillHovered(annotationId: UUID?) {
        let oldHovered = hoveredAnnotationId
        hoveredAnnotationId = annotationId
        if hoveredAnnotationId != oldHovered {
            marksLayer.hoveredId = hoveredAnnotationId
            marksLayer.needsDisplay = true
            refreshNotePills()
        }
    }

    func notePillClicked(annotationId: UUID) {
        // Clicking a note pill opens it for editing
        guard let annotation = store.annotation(for: annotationId) else { return }
        openNoteEditor(for: annotation)
    }

    var activeNoteField: NSTextField?
    private var editingAnnotationId: UUID?
    private var noteFieldDelegate: CanvasNoteFieldDelegate?
    private(set) var hoveredAnnotationId: UUID?

    private var activeEditorPill: NSView?
    /// VIB-193 (attempt 5): Temporary Edit menu for Cmd+key during note editing
    private var editingMenu: NSMenu?

    func openNoteEditor(for annotation: Annotation) {
        activeNoteField?.removeFromSuperview()
        activeEditorPill?.removeFromSuperview()

        // VIB-162: Get raw placement with anchor, apply anchor using EDITING pill width
        let placement = NotePillRenderer.notePlacementForEditing(for: annotation)
        let maxPillW: CGFloat = 200
        // VIB-192 (attempt 5): Configure temp field with wrapping to get correct multi-line height
        let estTextX: CGFloat = 12 + 20 + 7  // prefix width (~20) + gap
        let maxTextW = maxPillW - estTextX - 12
        let tempField = NSTextField(labelWithString: annotation.noteText)
        tempField.font = DesignTokens.noteTextFont
        tempField.maximumNumberOfLines = 0
        tempField.lineBreakMode = .byWordWrapping
        tempField.cell?.wraps = true
        tempField.preferredMaxLayoutWidth = maxTextW
        tempField.frame = NSRect(x: 0, y: 0, width: maxTextW, height: 0)
        tempField.sizeToFit()
        let pillH = max(DesignTokens.noteHeight, tempField.frame.height + 8)
        // Apply anchor transform with the EDITING pill width (200px, not resting 130px)
        let pillPos = NotePillRenderer.anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: maxPillW, pillHeight: pillH)

        let pillContainer = NSView(frame: NSRect(x: pillPos.x, y: pillPos.y, width: maxPillW, height: pillH))
        pillContainer.wantsLayer = true
        pillContainer.layer?.masksToBounds = false

        // Shadow
        pillContainer.layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
        pillContainer.layer?.shadowOffset = CGSize(width: 0, height: -1)
        pillContainer.layer?.shadowRadius = 4
        pillContainer.layer?.shadowOpacity = 1

        // Blur backdrop
        let blurLayer = CALayer()
        blurLayer.frame = NSRect(origin: .zero, size: pillContainer.frame.size)
        blurLayer.cornerRadius = DesignTokens.noteCornerRadius
        blurLayer.masksToBounds = true
        if let blurFilter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10]) {
            blurLayer.backgroundFilters = [blurFilter]
        }
        pillContainer.layer?.addSublayer(blurLayer)

        // Tinted background + red border (editing state)
        let tintView = NSView(frame: NSRect(origin: .zero, size: pillContainer.frame.size))
        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = DesignTokens.noteCornerRadius
        tintView.layer?.masksToBounds = true
        tintView.layer?.backgroundColor = NSColor(red: 1.0, green: 0.961, blue: 0.961, alpha: 0.92).cgColor
        tintView.layer?.borderColor = DesignTokens.red.cgColor
        tintView.layer?.borderWidth = 2  // VIB-192: match VIB-186 constant
        pillContainer.addSubview(tintView)

        // Number prefix label
        let numberLabel = NSTextField(labelWithString: "\(annotation.number)")
        numberLabel.font = NSFont.systemFont(ofSize: 8, weight: .semibold)
        numberLabel.textColor = DesignTokens.notePrefixColor
        numberLabel.isBezeled = false
        numberLabel.drawsBackground = false
        numberLabel.sizeToFit()
        // VIB-192: Use actual pillH for centering, not hardcoded DesignTokens.noteHeight
        numberLabel.frame.origin = NSPoint(x: 12, y: (pillH - numberLabel.frame.height) / 2)
        pillContainer.addSubview(numberLabel)

        // Text field (borderless, transparent, inside pill)
        let textField = NSTextField()
        textField.font = DesignTokens.noteTextFont
        textField.textColor = DesignTokens.noteTextColor
        textField.backgroundColor = .clear
        textField.drawsBackground = false
        textField.isBordered = false
        textField.isBezeled = false
        textField.focusRingType = .none
        textField.wantsLayer = true
        // VIB-162: Allow text wrapping, no truncation, unlimited lines
        textField.usesSingleLineMode = false
        textField.cell?.wraps = true
        textField.cell?.isScrollable = false
        textField.lineBreakMode = .byWordWrapping
        textField.maximumNumberOfLines = 0

        // Placeholder: "describe…" italic rgba(127,29,29,0.35)
        let placeholderAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFontManager.shared.convert(NSFont.systemFont(ofSize: 12), toHaveTrait: .italicFontMask),
            .foregroundColor: NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 0.35)
        ]
        textField.placeholderAttributedString = NSAttributedString(string: "describe…", attributes: placeholderAttrs)
        textField.stringValue = annotation.noteText

        // Position after number prefix + 7px gap
        let textX = 12 + numberLabel.frame.width + 7
        textField.frame = NSRect(x: textX, y: 4, width: maxPillW - textX - 12, height: pillH - 8)

        // Red caret color
        if let fieldEditor = textField.window?.fieldEditor(true, for: textField) as? NSTextView {
            fieldEditor.insertionPointColor = DesignTokens.red
        }

        let delegate = CanvasNoteFieldDelegate(canvas: self)
        self.noteFieldDelegate = delegate
        textField.delegate = delegate
        textField.target = delegate
        textField.action = #selector(CanvasNoteFieldDelegate.confirmNote(_:))

        pillContainer.addSubview(textField)
        notesLayer.addSubview(pillContainer)

        editingAnnotationId = annotation.id
        activeNoteField = textField
        activeEditorPill = pillContainer

        // VIB-193 (attempt 5): Install Edit menu so Cmd+C/V/A/Z validate against field editor
        installEditMenu()

        // VIB-193: Force panel to become key so makeFirstResponder works
        DispatchQueue.main.async { [weak self, weak textField] in
            guard let self, let window = self.window, let tf = textField else { return }
            window.makeKeyAndOrderFront(nil)  // Must be key window for first responder
            window.makeFirstResponder(tf)
            if let fieldEditor = window.fieldEditor(true, for: tf) as? NSTextView {
                fieldEditor.insertionPointColor = DesignTokens.red
                // VIB-192 (attempt 5): Place cursor at END of text, not select-all
                fieldEditor.setSelectedRange(NSRange(location: fieldEditor.string.count, length: 0))
            }
        }
    }

    /// VIB-162: Resize editing pill as text grows
    func resizeEditingPill() {
        guard let pill = activeEditorPill, let field = activeNoteField else { return }
        let minH = DesignTokens.noteHeight
        // VIB-204: Get LIVE text from the field editor, not stale stringValue
        let liveText: String
        if let fieldEditor = field.currentEditor() as? NSTextView {
            liveText = fieldEditor.string
        } else {
            liveText = field.stringValue
        }
        guard !liveText.isEmpty else { return }
        // Measure with a temp label matching the editing field's wrapping config
        let measurer = NSTextField(labelWithString: liveText)
        measurer.font = DesignTokens.noteTextFont
        measurer.maximumNumberOfLines = 0
        measurer.lineBreakMode = .byWordWrapping
        measurer.cell?.wraps = true
        measurer.preferredMaxLayoutWidth = field.frame.width
        measurer.frame = NSRect(x: 0, y: 0, width: field.frame.width, height: 0)
        measurer.sizeToFit()
        let newH = max(minH, measurer.frame.height + 8)

        if abs(pill.frame.height - newH) > 1 {
            let heightDelta = newH - pill.frame.height
            pill.frame.origin.y -= heightDelta  // keep top edge fixed (AppKit y-up)
            pill.setFrameSize(NSSize(width: pill.frame.width, height: newH))
            for sub in pill.subviews {
                if sub.layer?.cornerRadius == DesignTokens.noteCornerRadius {
                    sub.frame = NSRect(origin: .zero, size: pill.frame.size)
                }
            }
            if let blurLayer = pill.layer?.sublayers?.first(where: { $0.cornerRadius == DesignTokens.noteCornerRadius }) {
                blurLayer.frame = NSRect(origin: .zero, size: pill.frame.size)
            }
            field.frame = NSRect(x: field.frame.origin.x, y: 4, width: field.frame.width, height: newH - 8)
            for sub in pill.subviews {
                if let label = sub as? NSTextField, label.font?.pointSize == 8 {
                    label.frame.origin.y = (newH - label.frame.height) / 2
                    break
                }
            }
        }
    }

    /// VIB-193 (attempt 5): Install a temporary Edit menu on the window so AppKit's
    /// menu validation finds Cut/Copy/Paste/Select All/Undo items for the field editor.
    /// Borderless panels have no menu bar, so without this, Cmd+C/V/A/Z beep.
    private func installEditMenu() {
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        self.editingMenu = editMenu
        self.window?.menu = editMenu
    }

    private func removeEditMenu() {
        self.window?.menu = nil
        self.editingMenu = nil
    }

    func confirmNoteEditing() {
        guard let id = editingAnnotationId, let field = activeNoteField else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            store.remove(id: id)
        } else {
            store.update(id: id, noteText: text)
        }
        removeEditMenu()
        activeEditorPill?.removeFromSuperview()
        activeEditorPill = nil
        activeNoteField = nil
        editingAnnotationId = nil
        noteFieldDelegate = nil
        refreshNotePills()
        marksLayer.needsDisplay = true
    }

    func cancelNoteEditing() {
        guard let id = editingAnnotationId else { return }
        if let annotation = store.annotation(for: id), annotation.noteText.isEmpty {
            store.remove(id: id)
        }
        removeEditMenu()
        activeEditorPill?.removeFromSuperview()
        activeEditorPill = nil
        activeNoteField = nil
        editingAnnotationId = nil
        noteFieldDelegate = nil
        refreshNotePills()
    }

    var isEditingNote: Bool { activeNoteField != nil }
}

// MARK: - Note field delegate

final class CanvasNoteFieldDelegate: NSObject, NSTextFieldDelegate {
    weak var canvas: CanvasView?

    init(canvas: CanvasView) {
        self.canvas = canvas
        super.init()
    }

    @objc func confirmNote(_ sender: NSTextField) {
        canvas?.confirmNoteEditing()
    }

    // VIB-162: Resize pill on text changes so all text is visible
    func controlTextDidChange(_ obj: Notification) {
        canvas?.resizeEditingPill()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            canvas?.cancelNoteEditing()
            return true
        }
        return false
    }
}

// MARK: - Marks Layer (draws annotations + ghost)

final class MarksLayerView: NSView {

    var ghostPosition: CGPoint?
    var ghostTool: AnnotationTool?
    var hoveredId: UUID?
    var selectedId: UUID?
    private let store: AnnotationStore
    private let pinRenderer = PinRenderer()
    private let arrowRenderer = ArrowRenderer()
    private let rectangleRenderer = RectangleRenderer()
    private let circleRenderer = CircleRenderer()
    private let freehandRenderer = FreehandRenderer()

    init(frame: NSRect, store: AnnotationStore) {
        self.store = store
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw all annotations
        pinRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)
        arrowRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)
        rectangleRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)
        circleRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)
        freehandRenderer.drawMarks(in: context, annotations: store.annotations, canvasSize: bounds.size)

        // Draw hover glow
        if let hId = hoveredId, let annotation = store.annotations.first(where: { $0.id == hId }) {
            let bp = annotation.badgePosition
            let glowRadius = DesignTokens.badgeDiameter / 2 + 7 // prototype: badgeR + 7
            context.setFillColor(NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.08).cgColor)
            context.fillEllipse(in: CGRect(x: bp.x - glowRadius, y: bp.y - glowRadius, width: glowRadius * 2, height: glowRadius * 2))
        }

        // Draw selected state: dashed purple ring + handles
        if let sId = selectedId, let annotation = store.annotations.first(where: { $0.id == sId }) {
            let bp = annotation.badgePosition
            let ringRadius = DesignTokens.badgeDiameter / 2 + 5 // prototype: badgeR + 5

            // Dashed purple ring: #AFA9EC, 1.5px, dash 3,2
            context.setStrokeColor(DesignTokens.purpleLight.cgColor)
            context.setLineWidth(1.5)
            context.setLineDash(phase: 0, lengths: [3, 2])
            context.strokeEllipse(in: CGRect(x: bp.x - ringRadius, y: bp.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
            context.setLineDash(phase: 0, lengths: []) // reset dash

            // Draw handles per tool type
            switch annotation.position {
            case .arrow(_, let end):
                drawHandle(in: context, at: end)
            case .rectangle(let origin, let size):
                let corners = [
                    CGPoint(x: origin.x, y: origin.y),
                    CGPoint(x: origin.x + size.width, y: origin.y),
                    CGPoint(x: origin.x, y: origin.y + size.height),
                    CGPoint(x: origin.x + size.width, y: origin.y + size.height)
                ]
                for corner in corners {
                    // Skip badge corner
                    if hypot(corner.x - bp.x, corner.y - bp.y) > 5 {
                        drawHandle(in: context, at: corner)
                    }
                }
            case .circle(let center, _):
                // Opposite handle
                let ox = center.x * 2 - bp.x
                let oy = center.y * 2 - bp.y
                drawHandle(in: context, at: CGPoint(x: ox, y: oy))
            case .freehand(let pts):
                for pt in pts {
                    drawHandle(in: context, at: pt)
                }
            case .pin:
                break
            }
        }

        // Draw ghost preview
        if let pos = ghostPosition, let tool = ghostTool {
            tool.drawGhost(at: pos, in: context)
        }
    }

    /// Handle: white circle, 5px radius, #AFA9EC 2px border
    private func drawHandle(in context: CGContext, at point: CGPoint) {
        let r: CGFloat = 5
        let handleRect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        context.setFillColor(NSColor.white.cgColor)
        context.fillEllipse(in: handleRect)
        context.setStrokeColor(DesignTokens.purpleLight.cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [])
        context.strokeEllipse(in: handleRect)
    }
}
