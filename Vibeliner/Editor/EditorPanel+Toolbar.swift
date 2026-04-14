import AppKit

extension EditorPanel {

    // MARK: - ToolbarDelegate

    func toolbarDidSelectTool(_ tool: AnnotationToolType) {
        toolController.select(tool, on: canvasOverlay)
        canvasOverlay?.refreshInteractionState()
    }

    func toolbarDidRequestClose() {
        autoSaveManager?.saveNow()
        close()
    }

    func toolbarDidRequestDelete() {
        deleteSelectedAnnotation()
    }

    /// VIB-435: Shared delete path — called by both the toolbar trash button
    /// and the Backspace/Delete keyboard shortcut. Removes the selected
    /// annotation's mark, badge, and note pill, renumbers remaining
    /// annotations, registers with undo/redo, and triggers auto-save
    /// via the store's .annotationsDidChange notification.
    func deleteSelectedAnnotation() {
        guard let selected = annotationStore.selectedAnnotation else { return }
        // If a note pill is being edited on this annotation, confirm/dismiss first
        if canvasOverlay?.isEditingNote == true {
            canvasOverlay?.confirmNoteEditing()
        }
        undoRedoManager.record(.remove(annotation: selected))
        annotationStore.remove(id: selected.id)
        // VIB-449: Ensure cursor is visible after delete — prevents Backspace-triggered
        // cursor disappearance from state desync between note editing and cursor manager.
        CursorManager.shared.forceShow()
    }

    func toolbarDidRequestUndo() {
        undoRedoManager.undo()
    }

    func toolbarDidRequestRedo() {
        undoRedoManager.redo()
    }

    func toolbarDidRequestCopyPrompt() {
        guard let folder = captureFolder else { return }
        ClipboardManager.copyPromptToClipboard(annotations: annotationStore.annotations, captureFolder: folder, captureSession: captureSession)
        statusPill.showCopied(message: "Prompt copied")
        toolbarView.markCopyState(.prompt)
    }

    func toolbarDidRequestNewCapture() {
        autoSaveManager?.saveNow()
        close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            CaptureCoordinator.shared.startCapture()
        }
    }

    func toolbarDidRequestCopyImage() {
        // VIB-372: Use actual canvas bounds — in filmstrip mode this is the imageAreaRect
        // (wider than the primary image), not displayWidth × displayHeight.
        let canvasSize = canvasOverlay?.bounds.size ?? CGSize(width: displayWidth, height: displayHeight)
        // VIB-357: Completion handler fires after async stitching finishes
        let originalImage = captureSession.primaryImage?.sourceImage ?? images.first ?? NSImage()
        ClipboardManager.copyImageToClipboard(
            original: originalImage,
            annotations: annotationStore.annotations,
            canvasSize: canvasSize,
            captureSession: captureSession
        ) { [weak self] in
            self?.statusPill.showCopied(message: "Image copied")
            self?.toolbarView.markCopyState(.image)
        }
    }

    // MARK: - VIB-262/329: Add image

    func toolbarDidRequestAddImage() {
        guard captureSession.images.count < 12 else { return }

        // Auto-save before hiding
        autoSaveManager?.saveNow()

        // VIB-329: Hide editor completely so it doesn't appear in the screenshot
        orderOut(nil)

        // Start add-image capture with cancel handler to restore editor
        CaptureCoordinator.shared.startAddImageCapture(
            completion: { [weak self] newImage in
                guard let self else { return }

                // Add the new image
                let nextIndex = self.captureSession.images.count
                self.captureSession.addImage(
                    newImage,
                    title: "Image \(nextIndex + 1)",
                    role: .observed
                )

                // Restore editor
                self.alphaValue = 1.0
                self.makeKeyAndOrderFront(nil)

                // Transition to filmstrip if going from 1→2, or refresh if already in filmstrip
                if self.captureSession.images.count >= 2 {
                    if !self.isFilmstripMode {
                        self.transitionToFilmstrip()
                    } else {
                        self.refreshFilmstrip()
                    }
                }

                // Update add image button state
                self.toolbarView.updateAddImageState(imageCount: self.captureSession.images.count)
            },
            onCancel: { [weak self] in
                // VIB-329: Restore editor after canceled add-image capture
                self?.alphaValue = 1.0
                self?.makeKeyAndOrderFront(nil)
            }
        )
    }

}
