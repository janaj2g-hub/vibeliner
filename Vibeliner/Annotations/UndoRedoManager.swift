import Foundation

enum UndoAction {
    case add(annotation: Annotation)
    case remove(annotation: Annotation)
    case move(id: UUID, oldPosition: AnnotationPosition, newPosition: AnnotationPosition)
    case resize(id: UUID, oldPosition: AnnotationPosition, newPosition: AnnotationPosition)
    case editText(id: UUID, oldText: String, newText: String)
}

final class UndoRedoManager {

    private let store: AnnotationStore
    private var undoStack: [UndoAction] = []
    private var redoStack: [UndoAction] = []
    private var isApplying = false

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    init(store: AnnotationStore) {
        self.store = store
    }

    func record(_ action: UndoAction) {
        guard !isApplying else { return }
        undoStack.append(action)
        redoStack.removeAll()
    }

    /// VIB-268: Clear both stacks. Called when the filmstrip layout changes
    /// (image added/removed) because stored absolute positions become stale.
    func clearStacks() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    func undo() {
        guard let action = undoStack.popLast() else { return }
        isApplying = true
        applyReverse(action)
        redoStack.append(action)
        isApplying = false
    }

    func redo() {
        guard let action = redoStack.popLast() else { return }
        isApplying = true
        applyForward(action)
        undoStack.append(action)
        isApplying = false
    }

    private func applyReverse(_ action: UndoAction) {
        switch action {
        case .add(let annotation):
            store.remove(id: annotation.id)
        case .remove(let annotation):
            store.reinsert(annotation)
        case .move(let id, let oldPosition, _):
            store.updatePosition(id: id, position: oldPosition)
        case .resize(let id, let oldPosition, _):
            store.updatePosition(id: id, position: oldPosition)
        case .editText(let id, let oldText, _):
            store.update(id: id, noteText: oldText)
        }
    }

    private func applyForward(_ action: UndoAction) {
        switch action {
        case .add(let annotation):
            store.reinsert(annotation)
        case .remove(let annotation):
            store.remove(id: annotation.id)
        case .move(let id, _, let newPosition):
            store.updatePosition(id: id, position: newPosition)
        case .resize(let id, _, let newPosition):
            store.updatePosition(id: id, position: newPosition)
        case .editText(let id, _, let newText):
            store.update(id: id, noteText: newText)
        }
    }
}
