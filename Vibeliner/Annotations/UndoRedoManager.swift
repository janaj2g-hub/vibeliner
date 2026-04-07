import Foundation

enum UndoAction {
    case add(annotation: Annotation)
    case remove(annotation: Annotation)
    case move(id: UUID, oldPosition: AnnotationPosition, newPosition: AnnotationPosition)
    case resize(id: UUID, oldPosition: AnnotationPosition, newPosition: AnnotationPosition)
    case editText(id: UUID, oldText: String, newText: String)
    /// VIB-271: Image deletion — stores the removed image and its annotations for undo.
    case removeImage(image: CaptureImage, annotations: [Annotation], imageIndex: Int)
}

/// VIB-271: Delegate for image-level undo/redo operations.
/// EditorPanel conforms to this — it knows how to restore/remove images,
/// refresh the filmstrip, and update the capture store.
protocol ImageUndoDelegate: AnyObject {
    func undoImageDeletion(image: CaptureImage, annotations: [Annotation], at index: Int)
    func redoImageDeletion(at index: Int, removedAnnotations: [Annotation])
}

final class UndoRedoManager {

    private let store: AnnotationStore
    private var undoStack: [UndoAction] = []
    private var redoStack: [UndoAction] = []
    private var isApplying = false

    /// VIB-271: Delegate for image-level undo/redo.
    weak var imageUndoDelegate: ImageUndoDelegate?

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
        case .removeImage(let image, let annotations, let idx):
            imageUndoDelegate?.undoImageDeletion(image: image, annotations: annotations, at: idx)
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
        case .removeImage(_, let annotations, let idx):
            imageUndoDelegate?.redoImageDeletion(at: idx, removedAnnotations: annotations)
        }
    }
}
