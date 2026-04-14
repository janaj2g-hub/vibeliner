import AppKit

extension CanvasView {

    // MARK: - NotePillDelegate

    func notePillHovered(annotationId: UUID?) {
        let oldPillHovered = pillHoveredId
        pillHoveredId = annotationId
        if pillHoveredId != oldPillHovered {
            // VIB-203/215: Do NOT set marksLayer.hoveredId here — pill hover is independent from shape hover
            // VIB-221: Suppress ghost when pill hovered with drawing tool active
            refreshInteractionState()
            refreshNotePills()
        }
    }

    func notePillClicked(annotationId: UUID) {
        // Clicking a note pill opens it for editing
        guard let annotation = store.annotation(for: annotationId) else { return }
        openNoteEditor(for: annotation)
    }

    // Stored properties moved to main CanvasView class

    func openNoteEditor(for annotation: Annotation) {
        activeNoteField?.removeFromSuperview()
        activeEditorPill?.removeFromSuperview()

        // VIB-162: Get raw placement with anchor, apply anchor using EDITING pill width
        let placement = NotePillRenderer.notePlacementForEditing(for: annotation)
        let maxPillW: CGFloat = 180  // VIB-209: match resting pill max width to prevent reflow on commit
        // VIB-192 (attempt 5): Configure temp field with wrapping to get correct multi-line height
        let estTextX: CGFloat = 12 + 20 + 7  // prefix width (~20) + gap
        let maxTextW = maxPillW - estTextX - 12
        let tempField = NSTextField(labelWithString: annotation.noteText)
        tempField.font = DesignTokens.noteTextFont
        tempField.maximumNumberOfLines = 0
        tempField.lineBreakMode = .byWordWrapping
        tempField.cell?.wraps = true
        // VIB-204 (attempt 2): Use cellSize(forBounds:) — same pattern that works in NotePillView.init
        let cellBounds = NSRect(x: 0, y: 0, width: maxTextW, height: CGFloat.greatestFiniteMagnitude)
        let fittedSize = tempField.cell?.cellSize(forBounds: cellBounds) ?? NSSize(width: maxTextW, height: 16)
        let pillH = max(DesignTokens.noteHeight, fittedSize.height + 8)
        // Apply anchor transform with the EDITING pill width (200px, not resting 130px)
        let pillPos = NotePillRenderer.anchoredOrigin(point: placement.point, anchor: placement.anchor, pillWidth: maxPillW, pillHeight: pillH)

        let pillContainer = NSView(frame: NSRect(x: pillPos.x, y: pillPos.y, width: maxPillW, height: pillH))
        pillContainer.wantsLayer = true
        pillContainer.layer?.masksToBounds = false

        // Shadow
        pillContainer.layer?.shadowColor = DesignTokens.editorNoteShadow.cgColor
        pillContainer.layer?.shadowOffset = CGSize(width: 0, height: -1)
        pillContainer.layer?.shadowRadius = 4
        pillContainer.layer?.shadowOpacity = 1

        // VIB-197: Use PillChromeBuilder for blur, tint, and prefix (single source of truth)
        let chrome = PillChromeBuilder.build(size: NSSize(width: maxPillW, height: pillH), number: annotation.number)
        pillContainer.layer?.addSublayer(chrome.blurLayer)
        // Apply editing state colors directly
        chrome.tintView.layer?.backgroundColor = DesignTokens.editorNoteSurfaceEditing.cgColor
        chrome.tintView.layer?.borderColor = DesignTokens.red.cgColor
        pillContainer.addSubview(chrome.tintView)
        pillContainer.addSubview(chrome.prefixLabel)

        // VIB-197: Use PillChromeBuilder for editable text field
        let numberLabel = chrome.prefixLabel
        let textField = PillChromeBuilder.createEditableTextField(
            pillWidth: maxPillW, pillHeight: pillH,
            text: annotation.noteText, prefixWidth: numberLabel.frame.width
        )

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

        // VIB-204 (attempt 3): Set editingAnnotationId BEFORE adding pill to view
        // so refreshNotePills() removes the resting pill (no ghost behind editing pill)
        editingAnnotationId = annotation.id
        preEditNoteText = annotation.noteText  // VIB-327: save for cancel logic
        refreshNotePills()

        notesLayer.addSubview(pillContainer)
        activeNoteField = textField
        activeEditorPill = pillContainer

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
            self.refreshInteractionState()
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
        // VIB-204 (attempt 2): Use cellSize(forBounds:) — same pattern that works in NotePillView.init
        let cellBounds = NSRect(x: 0, y: 0, width: field.frame.width, height: CGFloat.greatestFiniteMagnitude)
        let fittedSize = measurer.cell?.cellSize(forBounds: cellBounds) ?? NSSize(width: field.frame.width, height: 16)
        let newH = max(minH, fittedSize.height + 8)

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

    func confirmNoteEditing() {
        guard let id = editingAnnotationId, let field = activeNoteField else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldText = store.annotation(for: id)?.noteText ?? ""
        store.update(id: id, noteText: text)
        if oldText != text {
            undoManager_?.record(.editText(id: id, oldText: oldText, newText: text))
        }
        // VIB-326: Resign field editor before removing pill — prevents the stale
        // NSTextView from lingering as first responder and blocking KeyEventGuard.
        window?.makeFirstResponder(nil)
        activeEditorPill?.removeFromSuperview()
        activeEditorPill = nil
        activeNoteField = nil
        editingAnnotationId = nil
        preEditNoteText = nil
        noteFieldDelegate = nil
        window?.makeFirstResponder(self)
        refreshNotePills()
        refreshInteractionState()
        marksLayer.needsDisplay = true
    }

    func cancelNoteEditing() {
        guard let id = editingAnnotationId else { return }

        // VIB-327: If this was a first-time edit (pre-edit text empty) and field is
        // still empty, the user is cancelling a brand-new annotation → delete it.
        let fieldText = activeNoteField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if (preEditNoteText ?? "").isEmpty && fieldText.isEmpty {
            if let annotation = store.annotation(for: id) {
                store.remove(id: id)
                undoManager_?.record(.remove(annotation: annotation))
            }
        }

        // VIB-326: Resign field editor before removing pill — prevents the stale
        // NSTextView from lingering as first responder and blocking KeyEventGuard.
        window?.makeFirstResponder(nil)
        activeEditorPill?.removeFromSuperview()
        activeEditorPill = nil
        activeNoteField = nil
        editingAnnotationId = nil
        preEditNoteText = nil
        noteFieldDelegate = nil
        window?.makeFirstResponder(self)
        refreshNotePills()
        refreshInteractionState()
        marksLayer.needsDisplay = true
    }

    var isEditingNote: Bool { activeNoteField != nil }

    override func mouseEntered(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updatePointerState(at: point, notifyActiveTool: false)
    }

    func refreshInteractionState() {
        updateSuppressedGhostState()
        emitCursorIntent()
        marksLayer.needsDisplay = true
    }

    func updatePointerState(at point: CGPoint?, notifyActiveTool: Bool) {
        ghostPosition = point
        isPointerInsideCanvas = point != nil
        marksLayer.ghostPosition = point

        if let point {
            if notifyActiveTool {
                activeTool?.mouseMoved(to: point, in: self)
            }
            let oldHovered = shapeHoveredId
            shapeHoveredId = hitTestAnnotation(at: point)
            if shapeHoveredId != oldHovered {
                marksLayer.hoveredId = shapeHoveredId
                refreshNotePills()
            }
        } else {
            shapeHoveredId = nil
            marksLayer.hoveredId = nil
        }

        updateSuppressedGhostState()
        emitCursorIntent()
        marksLayer.needsDisplay = true
    }

    func updateSuppressedGhostState() {
        let isDrawingToolActive = activeTool?.toolType.isDrawingTool == true
        let isHoveringAnnotation = (shapeHoveredId != nil || pillHoveredId != nil)
        let shouldSuppressGhost = isPointerInsideCanvas
            && isDrawingToolActive
            && isHoveringAnnotation
            && !(activeTool?.isActivelyDrawing == true)
        marksLayer.suppressGhost = shouldSuppressGhost
    }

    func emitCursorIntent() {
        let shouldHideCursor = isPointerInsideCanvas
            && activeTool?.toolType.isDrawingTool == true
            && !isEditingNote
            && !marksLayer.suppressGhost
        onCursorIntentChanged?(shouldHideCursor ? .hiddenForDrawing : .visibleArrow)
    }
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
