import Foundation

extension Notification.Name {
    static let annotationsDidChange = Notification.Name("annotationsDidChange")
}

final class AnnotationStore {

    private(set) var annotations: [Annotation] = []
    private var nextNumber: Int = 1

    /// VIB-268: Provides current image frames in canvas coordinates.
    /// Set by EditorPanel when the canvas is ready. Returns empty array when unset.
    var imageFrameProvider: (() -> [CGRect])?

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

        // VIB-268: Compute image-relative coordinates from absolute position
        computeRelativeCoords(for: &a)

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

        // VIB-268: Recompute relative coordinates for the new position
        computeRelativeCoords(for: &annotations[index])

        notifyChange()
    }

    func updateBadgePosition(id: UUID, badgePosition: CGPoint) {
        guard let index = annotations.firstIndex(where: { $0.id == id }) else { return }
        annotations[index].badgePosition = badgePosition

        // VIB-268: Recompute relative badge position within the parent image
        if let frames = imageFrameProvider?(), !frames.isEmpty {
            let imgIdx = min(annotations[index].parentImageIndex, frames.count - 1)
            annotations[index].relativeBadgePosition = CoordinateConverter.absoluteToRelative(
                point: badgePosition, imageFrame: frames[imgIdx]
            )
        }

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
        var a = annotation

        // VIB-268: If relative coordinates exist and frames are available,
        // recompute absolute position from relative (handles layout changes
        // since the annotation was removed, e.g., image added between remove and redo).
        if let relPos = a.relativePosition,
           let frames = imageFrameProvider?(), !frames.isEmpty {
            let parentIdx = min(a.parentImageIndex, frames.count - 1)
            let endFrame: CGRect?
            if let endIdx = a.endImageIndex, endIdx < frames.count {
                endFrame = frames[endIdx]
            } else {
                endFrame = nil
            }
            a.position = CoordinateConverter.positionToAbsolute(
                relPos, parentFrame: frames[parentIdx], endFrame: endFrame
            )
            if let relBadge = a.relativeBadgePosition {
                a.badgePosition = CoordinateConverter.relativeToAbsolute(
                    point: relBadge, imageFrame: frames[parentIdx]
                )
            }
        }

        annotations.append(a)
        notifyChange()
    }

    // MARK: - VIB-271: Batch operations for image deletion

    /// Remove all annotations whose parentImageIndex matches the given index.
    /// Also removes cross-image arrows that reference the deleted image as endImageIndex.
    /// Returns the removed annotations (for undo).
    func removeAnnotations(forImageIndex deletedIndex: Int) -> [Annotation] {
        let removed = annotations.filter { a in
            if a.parentImageIndex == deletedIndex { return true }
            // Cross-image arrows: remove if end point is on the deleted image
            if let endIdx = a.endImageIndex, endIdx == deletedIndex { return true }
            return false
        }
        annotations.removeAll { a in
            if a.parentImageIndex == deletedIndex { return true }
            if let endIdx = a.endImageIndex, endIdx == deletedIndex { return true }
            return false
        }
        return removed
    }

    /// Shift parentImageIndex (and endImageIndex) for annotations on images after the deleted index.
    /// Call after removing an image so annotation indices stay aligned with the data model.
    func shiftImageIndices(above deletedIndex: Int) {
        for i in annotations.indices {
            if annotations[i].parentImageIndex > deletedIndex {
                annotations[i].parentImageIndex -= 1
            }
            if let endIdx = annotations[i].endImageIndex, endIdx > deletedIndex {
                annotations[i].endImageIndex = endIdx - 1
            }
        }
        renumber()
        notifyChange()
    }

    /// Restore annotations from a previous image deletion (undo).
    /// Re-inserts all annotations and renumbers.
    func restoreAnnotations(_ restoredAnnotations: [Annotation]) {
        annotations.append(contentsOf: restoredAnnotations)
        // Sort by original number to restore order
        annotations.sort { $0.number < $1.number }
        renumber()
        notifyChange()
    }

    /// Shift image indices UP for annotations on images at or above the given index.
    /// Used when undoing an image deletion — makes room for the restored image.
    func shiftImageIndicesUp(at restoredIndex: Int) {
        for i in annotations.indices {
            if annotations[i].parentImageIndex >= restoredIndex {
                annotations[i].parentImageIndex += 1
            }
            if let endIdx = annotations[i].endImageIndex, endIdx >= restoredIndex {
                annotations[i].endImageIndex = endIdx + 1
            }
        }
    }

    // MARK: - VIB-268: Image-relative coordinate system

    /// Compute image-relative coordinates for an annotation from its absolute position.
    private func computeRelativeCoords(for annotation: inout Annotation) {
        guard let frames = imageFrameProvider?(), !frames.isEmpty else { return }

        // Determine parent image from badge position
        let parentIdx = CoordinateConverter.imageIndex(
            for: annotation.badgePosition, imageFrames: frames
        )
        annotation.parentImageIndex = parentIdx

        // For arrows, also determine the end image index (cross-image support)
        var endFrame: CGRect?
        if case .arrow(_, let end) = annotation.position {
            let endIdx = CoordinateConverter.imageIndex(for: end, imageFrames: frames)
            annotation.endImageIndex = (endIdx != parentIdx) ? endIdx : nil
            if let eIdx = annotation.endImageIndex, eIdx < frames.count {
                endFrame = frames[eIdx]
            }
        } else {
            annotation.endImageIndex = nil
        }

        let parentFrame = frames[min(parentIdx, frames.count - 1)]
        annotation.relativePosition = CoordinateConverter.positionToRelative(
            annotation.position, parentFrame: parentFrame, endFrame: endFrame
        )
        annotation.relativeBadgePosition = CoordinateConverter.absoluteToRelative(
            point: annotation.badgePosition, imageFrame: parentFrame
        )
    }

    /// Recalculate all absolute positions from stored relative coordinates.
    /// Call after any layout change (image added/removed, filmstrip resize).
    func recalculateAbsolutePositions() {
        guard let frames = imageFrameProvider?(), !frames.isEmpty else { return }

        var changed = false
        for i in annotations.indices {
            guard let relPos = annotations[i].relativePosition else { continue }

            let parentIdx = min(annotations[i].parentImageIndex, frames.count - 1)
            let parentFrame = frames[parentIdx]

            let endFrame: CGRect?
            if let endIdx = annotations[i].endImageIndex, endIdx < frames.count {
                endFrame = frames[endIdx]
            } else {
                endFrame = nil
            }

            annotations[i].position = CoordinateConverter.positionToAbsolute(
                relPos, parentFrame: parentFrame, endFrame: endFrame
            )

            if let relBadge = annotations[i].relativeBadgePosition {
                annotations[i].badgePosition = CoordinateConverter.relativeToAbsolute(
                    point: relBadge, imageFrame: parentFrame
                )
            }
            changed = true
        }

        if changed {
            notifyChange()
        }
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .annotationsDidChange, object: self)
    }
}
