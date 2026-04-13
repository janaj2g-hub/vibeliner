import AppKit

extension EditorPanel {

    // MARK: - Filmstrip transition

    func transitionToFilmstrip() {
        isFilmstripMode = true
        guard contentView != nil else { return }

        // Save original layout for restoration
        if singleImageWindowFrame == nil {
            singleImageWindowFrame = frame
            singleImageToolbarOrigin = toolbarView.frame.origin
            singleImagePillOrigin = statusPill.frame.origin
        }

        canvasView.isHidden = true
        layoutFilmstripMode(newFilmstrip: true)

        // Wire canvas click-through for cell selection (VIB-271: only with select tool)
        canvasOverlay?.onBackgroundClick = { [weak self] point in
            guard let self, let canvas = self.canvasOverlay, let filmstrip = self.filmstripView else { return }
            // Only switch filmstrip selection when the select tool is active
            guard self.toolbarView.selectedTool == .select else { return }
            let contentPoint = canvas.convert(point, to: filmstrip.scrollableContentView)
            filmstrip.selectCellAtPoint(contentPoint)
            self.filmstripCellSelected(filmstrip.selectedIndex)
        }

        // VIB-333: Resolve click point to image index for annotation assignment
        canvasOverlay?.imageIndexAtPoint = { [weak self] point in
            guard let self, let canvas = self.canvasOverlay, let filmstrip = self.filmstripView else { return 0 }
            let contentPoint = canvas.convert(point, to: filmstrip.scrollableContentView)
            return filmstrip.imageIndexAtPoint(contentPoint)
        }
        canvasOverlay?.imageIDAtPoint = { [weak self] point in
            guard let self, let canvas = self.canvasOverlay, let filmstrip = self.filmstripView else { return nil }
            let contentPoint = canvas.convert(point, to: filmstrip.scrollableContentView)
            let imageIndex = filmstrip.imageIndexAtPoint(contentPoint)
            return self.captureSession.imageID(at: imageIndex)
        }

        filmstripCellSelected(images.count - 1)
        statusPill.updateNoteCount(annotationStore.count)
    }

    func refreshFilmstrip() {
        layoutFilmstripMode(newFilmstrip: false)
    }

    /// Shared layout engine for filmstrip mode. Resizes the window, positions
    /// the filmstrip, toolbar, and status pill, and attaches the canvas overlay.
    func layoutFilmstripMode(newFilmstrip: Bool) {
        guard let container = contentView, let screen = self.screen ?? NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let overflowPad: CGFloat = 200
        let toolbarGap: CGFloat = 48
        let bottomGap: CGFloat = 44
        let shadowPad: CGFloat = 24
        let gap = DesignTokens.filmstripGap
        let pillTotalH = DesignTokens.titlePillHeight + DesignTokens.titlePillGap
        let sessionImages = captureSession.images
        let imageSizes = sessionImages.map(\.sourceImage.size)

        // VIB-339: Window grows to accommodate images — up to 85% of screen width.
        // Images should never shrink more than ~15% from single-image display.
        let maxFilmstripW = screenFrame.width * 0.85 - overflowPad * 2

        // Compute row height at max width (respects 250px min cell width)
        let rowHeight = FilmstripGridView.computeFittingRowHeight(
            imageSizes: imageSizes,
            availableWidth: maxFilmstripW,
            availableHeight: LayoutCalculator.maxRowHeight,
            gap: gap
        )

        // Content width at this row height
        let (_, contentWidth) = LayoutCalculator.computeFrames(
            imageSizes: imageSizes, rowHeight: rowHeight, gap: gap, titlePillTotalHeight: pillTotalH
        )

        // Filmstrip dimensions: fit content up to max, scroll for the rest
        let filmstripWidth = min(contentWidth, maxFilmstripW)
        let filmstripHeight = rowHeight + pillTotalH

        // Window dimensions
        let winWidth = max(filmstripWidth, toolbarView.frame.width) + overflowPad * 2
        let winHeight = filmstripHeight + toolbarGap + bottomGap + shadowPad + overflowPad
        // VIB-339: Center window on screen, clamp to visible area
        let winX = max(screenFrame.minX, min(screenFrame.maxX - winWidth, screenFrame.midX - winWidth / 2))
        let winY = max(screenFrame.minY, min(screenFrame.maxY - winHeight, screenFrame.midY - winHeight / 2))
        let newFrame = NSRect(
            x: winX,
            y: winY,
            width: winWidth,
            height: winHeight
        )
        setFrame(newFrame, display: true, animate: false)
        container.frame = NSRect(origin: .zero, size: newFrame.size)

        // Filmstrip position: centered horizontally
        let filmstripX = (winWidth - filmstripWidth) / 2
        let filmstripY = bottomGap + overflowPad / 2

        if newFilmstrip {
            // Create filmstrip
            let filmstrip = FilmstripGridView(frame: NSRect(
                x: filmstripX, y: filmstripY, width: filmstripWidth, height: filmstripHeight
            ))
            filmstrip.setImages(sessionImages, selectedIndex: sessionImages.count - 1)
            filmstrip.onCellSelected = { [weak self] index in
                self?.filmstripCellSelected(index)
            }
            filmstrip.onRoleChanged = { [weak self] index, newRole in
                self?.captureSession.updateRole(at: index, role: newRole)
            }
            filmstrip.onTitleChanged = { [weak self] index, newTitle in
                self?.captureSession.updateTitle(at: index, title: newTitle)
            }
            filmstrip.onDeleteImage = { [weak self] index in
                self?.removeImageAtIndex(index)
            }
            canvasOverlay?.removeFromSuperview()
            container.addSubview(filmstrip)
            self.filmstripView = filmstrip
        } else if let filmstrip = filmstripView {
            // Update existing filmstrip
            canvasOverlay?.removeFromSuperview()
            filmstrip.frame = NSRect(
                x: filmstripX, y: filmstripY, width: filmstripWidth, height: filmstripHeight
            )
            let idx = min(filmstrip.selectedIndex, max(captureSession.images.count - 1, 0))
            filmstrip.setImages(captureSession.images, selectedIndex: idx)
        }

        guard let filmstrip = filmstripView else { return }

        // Reposition toolbar above filmstrip
        let toolbarX = (winWidth - toolbarView.frame.width) / 2
        let toolbarY = filmstripY + filmstripHeight + (toolbarGap - DesignTokens.toolbarHeight) / 2
        toolbarView.setFrameOrigin(NSPoint(x: toolbarX, y: toolbarY))

        // Status pill 32px below filmstrip
        let pillX = (winWidth - statusPill.frame.width) / 2
        let pillY = filmstripY - 32 - statusPill.frame.height
        statusPill.setFrameOrigin(NSPoint(x: pillX, y: pillY))

        // Canvas overlay in filmstrip's scrollable content view
        canvasOverlay?.frame = filmstrip.imageAreaRect
        filmstrip.scrollableContentView.addSubview(canvasOverlay ?? NSView())
        canvasOverlay?.updateTrackingAreas()

        // VIB-372: Update auto-save canvas size to match the actual filmstrip canvas bounds
        autoSaveManager?.canvasSize = filmstrip.imageAreaRect.size

        // VIB-339: Recalculate annotation positions after layout change
        recalculateAnnotationPositions()
    }

    func removeImageAtIndex(_ index: Int) {
        guard captureSession.images.count > 1,
              let removedImage = captureSession.removeImage(at: index) else { return }

        annotationStore.removeAnnotations(forImageID: removedImage.id)
        annotationStore.synchronizeImageOwnership(using: captureSession)

        if captureSession.images.count == 1 {
            transitionBackToSingleImage()
        } else {
            refreshFilmstrip()
        }

        let selectedIndex = min(index, max(captureSession.images.count - 1, 0))
        annotationStore.updateCurrentImage(id: captureSession.imageID(at: selectedIndex), index: selectedIndex)
        canvasOverlay?.marksLayer.needsDisplay = true
        canvasOverlay?.refreshNotePills()
        toolbarView.updateAddImageState(imageCount: captureSession.images.count)
    }

    func transitionBackToSingleImage() {
        isFilmstripMode = false

        filmstripView?.removeFromSuperview()
        filmstripView = nil

        // Restore original window frame and positions
        if let originalFrame = singleImageWindowFrame {
            setFrame(originalFrame, display: true, animate: false)
            contentView?.frame = NSRect(origin: .zero, size: originalFrame.size)
        }
        if let origin = singleImageToolbarOrigin {
            toolbarView.setFrameOrigin(origin)
        }
        if let origin = singleImagePillOrigin {
            statusPill.setFrameOrigin(origin)
        }
        singleImageWindowFrame = nil
        singleImageToolbarOrigin = nil
        singleImagePillOrigin = nil

        canvasView.isHidden = false
        canvasOverlay?.removeFromSuperview()
        canvasOverlay?.frame = NSRect(x: 0, y: 0, width: displayWidth, height: displayHeight)
        canvasOverlay?.onBackgroundClick = nil
        canvasOverlay?.imageIndexAtPoint = nil
        canvasOverlay?.imageIDAtPoint = nil
        canvasView.addSubview(canvasOverlay ?? NSView())
        canvasOverlay?.updateTrackingAreas()

        if let singleImage = captureSession.primaryImage?.sourceImage {
            canvasView.updateImage(singleImage)
            statusPill.updateDimensions(width: Int(singleImage.size.width), height: Int(singleImage.size.height))
        }

        annotationStore.updateCurrentImage(id: captureSession.imageID(at: 0), index: 0)

        // VIB-339: Recalculate annotation positions after returning to single-image
        recalculateAnnotationPositions()
    }

    func filmstripCellSelected(_ index: Int) {
        // VIB-269: Track which image is active so new annotations get the right parentImageIndex
        annotationStore.updateCurrentImage(id: captureSession.imageID(at: index), index: index)
    }

    // MARK: - VIB-339: Coordinate system helpers

    /// Returns the image frame for the given index in CanvasView-local coordinates.
    /// In single-image mode, this is the full canvas bounds.
    /// In filmstrip mode, this is the cell's image area relative to imageAreaRect.
    func imageFrameInCanvas(at index: Int) -> NSRect {
        if let filmstrip = filmstripView, isFilmstripMode {
            return filmstrip.imageCellFrameInCanvas(at: index)
        }
        // Single image: entire canvas
        return canvasOverlay?.bounds ?? NSRect(x: 0, y: 0, width: displayWidth, height: displayHeight)
    }

    /// VIB-339: Recalculate absolute annotation positions from their stored relative
    /// coordinates after any layout change (filmstrip transition, add/delete image, resize).
    func recalculateAnnotationPositions() {
        annotationStore.synchronizeImageOwnership(using: captureSession)
        annotationStore.recalculateAbsolutePositions { [weak self] imageIndex in
            self?.imageFrameInCanvas(at: imageIndex) ?? .zero
        }
        canvasOverlay?.marksLayer.needsDisplay = true
        canvasOverlay?.refreshNotePills()
    }

    /// VIB-339: Compute and store relative coordinates for an annotation,
    /// given its current absolute position. Called after creation and after drag.
    func setRelativeCoords(for annotationId: UUID) {
        guard let annotation = annotationStore.annotation(for: annotationId) else { return }
        let parentIndex = annotation.parentImageID.flatMap(captureSession.index(forImageID:)) ?? annotation.parentImageIndex
        let imageFrame = imageFrameInCanvas(at: parentIndex)

        let endFrame: CGRect?
        if let endID = annotation.endImageID, let endIdx = captureSession.index(forImageID: endID) {
            endFrame = imageFrameInCanvas(at: endIdx)
        } else if let endIdx = annotation.endImageIndex {
            endFrame = imageFrameInCanvas(at: endIdx)
        } else {
            endFrame = nil
        }

        let relPos = CoordinateConverter.positionToRelative(
            annotation.position, parentFrame: imageFrame, endFrame: endFrame
        )
        let relBadge = CoordinateConverter.absoluteToRelative(
            point: annotation.badgePosition, imageFrame: imageFrame
        )
        annotationStore.setRelativeCoords(id: annotationId, relativePosition: relPos, relativeBadgePosition: relBadge)
    }
}
