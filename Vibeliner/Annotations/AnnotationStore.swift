import Foundation

extension Notification.Name {
    static let annotationsDidChange = Notification.Name("annotationsDidChange")
}

final class AnnotationStore {

    private(set) var annotations: [Annotation] = []
    private var nextNumber: Int = 1

    /// VIB-269: Current image index in filmstrip mode. Set by EditorPanel when
    /// the filmstrip selection changes. Tools read this to set parentImageIndex.
    var currentImageIndex: Int = 0

    var count: Int { annotations.count }

    var selectedAnnotation: Annotation? {
        annotations.first { $0.isSelected }
    }

    var toolTypesUsed: Set<AnnotationToolType> {
        Set(annotations.map { $0.type })
    }

    func add(_ annotation: Annotation) -> Annotation {
        var a = annotation
        a.number = nextNumber
        nextNumber += 1
        annotations.append(a)
        notifyChange()
        return a
    }

    func remove(id: UUID) {
        annotations.removeAll { $0.id == id }
        // Renumber all annotations sequentially after deletion
        renumber()
        notifyChange()
    }

    private func renumber() {
        for i in annotations.indices {
            annotations[i].number = i + 1
        }
        nextNumber = annotations.count + 1
    }

    func update(id: UUID, noteText: String) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[index].noteText = noteText
        notifyChange()
    }

    func updatePosition(id: UUID, position: AnnotationPosition) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[index].position = position
        notifyChange()
    }

    func updateBadgePosition(id: UUID, badgePosition: CGPoint) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[index].badgePosition = badgePosition
        notifyChange()
    }

    func updateNoteOffset(id: UUID, noteOffset: CGPoint) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[index].noteOffset = noteOffset
        notifyChange()
    }

    func select(id: UUID) {
        for i in annotations.indices {
            annotations[i].isSelected = (annotations[i].id == id)
        }
        notifyChange()
    }

    func deselectAll() {
        for i in annotations.indices {
            annotations[i].isSelected = false
        }
        notifyChange()
    }

    func annotation(for id: UUID) -> Annotation? {
        annotations.first { $0.id == id }
    }

    func reinsert(_ annotation: Annotation) {
        annotations.append(annotation)
        notifyChange()
    }

    /// VIB-271: Remove all annotations belonging to a deleted image.
    func removeAnnotations(forImageIndex imageIndex: Int) {
        annotations.removeAll { $0.parentImageIndex == imageIndex }
        // Also remove cross-image arrows that reference the deleted image
        annotations.removeAll { $0.endImageIndex == imageIndex }
        renumber()
        notifyChange()
    }

    /// VIB-271: Shift parentImageIndex down by 1 for annotations on images after the deleted one.
    func shiftImageIndices(above deletedIndex: Int) {
        for i in annotations.indices {
            if annotations[i].parentImageIndex > deletedIndex {
                annotations[i].parentImageIndex -= 1
            }
            if let endIdx = annotations[i].endImageIndex, endIdx > deletedIndex {
                annotations[i].endImageIndex = endIdx - 1
            }
        }
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .annotationsDidChange, object: self)
    }
}
