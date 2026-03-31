import AppKit

protocol AnnotationTool: AnyObject {
    var toolType: AnnotationToolType { get }
    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager)
    func mouseMoved(to point: CGPoint, in canvas: CanvasView)
    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager)
    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager)
    func drawGhost(at point: CGPoint, in context: CGContext)
}

extension AnnotationTool {
    func mouseMoved(to point: CGPoint, in canvas: CanvasView) {}
    func mouseDragged(to point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {}
    func mouseUp(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {}
    func drawGhost(at point: CGPoint, in context: CGContext) {}
}

final class PinTool: AnnotationTool {
    let toolType: AnnotationToolType = .pin

    weak var editorPanel: EditorPanel?
    private var ghostPosition: CGPoint?
    private var editingAnnotationId: UUID?
    private var noteTextField: NSTextField?

    func mouseDown(at point: CGPoint, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        // Check if clicking an existing annotation for selection
        for annotation in store.annotations.reversed() {
            if annotation.type == .pin {
                if case .pin(let tip) = annotation.position {
                    let badgeCenter = CGPoint(x: tip.x, y: tip.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2)
                    let distance = hypot(point.x - badgeCenter.x, point.y - badgeCenter.y)
                    if distance <= DesignTokens.badgeDiameter {
                        store.select(id: annotation.id)
                        return
                    }
                }
            }
        }

        // Place new pin
        store.deselectAll()
        let tip = point

        let annotation = Annotation(
            type: .pin,
            number: 0,
            noteText: "",
            position: .pin(tip: tip),
            badgePosition: CGPoint(x: tip.x, y: tip.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2)
        )

        let added = store.add(annotation)
        undoManager.record(.add(annotation: added))
        editingAnnotationId = added.id

        // Open note text field
        openNoteEditor(for: added, in: canvas, store: store, undoManager: undoManager)
    }

    func drawGhost(at point: CGPoint, in context: CGContext) {
        context.saveGState()
        context.setAlpha(0.5)

        let tip = point
        let badgeCenterY = tip.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2
        let badgeRadius = DesignTokens.badgeDiameter / 2

        // Stake
        context.setStrokeColor(DesignTokens.red.cgColor)
        context.setLineWidth(DesignTokens.stakeWidth)
        context.setLineCap(.round)
        context.move(to: tip)
        context.addLine(to: CGPoint(x: tip.x, y: tip.y + DesignTokens.stakeLength))
        context.strokePath()

        // Badge circle
        context.setFillColor(DesignTokens.red.cgColor)
        let badgeRect = CGRect(
            x: tip.x - badgeRadius,
            y: badgeCenterY - badgeRadius,
            width: DesignTokens.badgeDiameter,
            height: DesignTokens.badgeDiameter
        )
        context.fillEllipse(in: badgeRect)

        context.restoreGState()
    }

    // MARK: - Note editing

    private func openNoteEditor(for annotation: Annotation, in canvas: CanvasView, store: AnnotationStore, undoManager: UndoRedoManager) {
        guard case .pin(let tip) = annotation.position else { return }

        let badgeCenterY = tip.y + DesignTokens.stakeLength + DesignTokens.badgeDiameter / 2
        let noteX = tip.x + DesignTokens.badgeDiameter / 2 + 10
        let noteY = badgeCenterY - DesignTokens.noteHeight / 2

        let textField = NSTextField()
        textField.font = DesignTokens.noteTextFont
        textField.textColor = NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 1.0)
        textField.backgroundColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.05)
        textField.isBordered = true
        textField.focusRingType = .none
        textField.frame = NSRect(x: noteX, y: noteY, width: 180, height: DesignTokens.noteHeight)
        textField.placeholderString = "Add note..."
        textField.target = self
        textField.action = #selector(noteFieldAction(_:))
        textField.delegate = NoteFieldDelegate(
            onEscape: { [weak self, weak store, weak undoManager] in
                guard let self, let store, let undoManager else { return }
                self.cancelNoteEditing(store: store, undoManager: undoManager)
            }
        )

        canvas.notesLayer.addSubview(textField)
        textField.becomeFirstResponder()
        self.noteTextField = textField
    }

    @objc private func noteFieldAction(_ sender: NSTextField) {
        guard let id = editingAnnotationId else { return }
        guard let panel = editorPanel else { return }
        let text = sender.stringValue
        panel.annotationStore.update(id: id, noteText: text)
        sender.removeFromSuperview()
        noteTextField = nil
        editingAnnotationId = nil
    }

    private func cancelNoteEditing(store: AnnotationStore, undoManager: UndoRedoManager) {
        guard let id = editingAnnotationId else { return }
        if let annotation = store.annotation(for: id) {
            store.remove(id: id)
            undoManager.record(.remove(annotation: annotation))
        }
        noteTextField?.removeFromSuperview()
        noteTextField = nil
        editingAnnotationId = nil
    }
}

// MARK: - Note field delegate for Escape handling

final class NoteFieldDelegate: NSObject, NSTextFieldDelegate {
    private let onEscape: () -> Void

    init(onEscape: @escaping () -> Void) {
        self.onEscape = onEscape
        super.init()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            onEscape()
            return true
        }
        return false
    }
}
