import AppKit

final class CaptureCoordinator {
    static let shared = CaptureCoordinator()

    private var overlayWindows: [CaptureOverlayWindow] = []
    private var crosshairViews: [CrosshairView] = []
    private var dimensionLabel: DimensionLabelView?
    private var dragStartPoint: NSPoint?
    private var activeView: CrosshairView?
    private var isCapturing = false

    private init() {}

    func startCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        NSCursor.hide()

        for screen in NSScreen.screens {
            let window = CaptureOverlayWindow(screen: screen)
            let crosshairView = CrosshairView(frame: NSRect(origin: .zero, size: screen.frame.size))
            crosshairView.autoresizingMask = [.width, .height]

            window.contentView = crosshairView
            window.makeKeyAndOrderFront(nil)

            overlayWindows.append(window)
            crosshairViews.append(crosshairView)
        }
    }

    func cancelCapture() {
        dismissOverlays()
    }

    func completeSelection(rect: NSRect) {
        // Determine which screen the selection is on
        let screen = NSScreen.screens.first { $0.frame.intersects(rect) } ?? NSScreen.main ?? NSScreen.screens[0]

        // Hide overlays before capturing so they don't appear in the screenshot
        for window in overlayWindows {
            window.orderOut(nil)
        }

        // Wait one frame for overlays to fully disappear, then capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            guard let image = ScreenCapture.captureRegion(rect: rect, on: screen) else {
                print("Vibeliner: Capture failed")
                dismissOverlays()
                return
            }

            let folderURL = CapturesManager.shared.createCaptureFolder()
            let screenshotURL = folderURL.appendingPathComponent("screenshot.png")

            if image.savePNG(to: screenshotURL) {
                print("Captured to \(screenshotURL.path)")
            } else {
                print("Vibeliner: Failed to save screenshot")
            }

            cleanupAfterCapture()
        }
    }

    // MARK: - Mouse handling

    func handleMouseDown(at point: NSPoint, in view: CrosshairView) {
        dragStartPoint = point
        activeView = view
        view.isDragging = false
        view.selectionRect = nil
        removeDimensionLabel()
    }

    func handleMouseDragged(to point: NSPoint, in view: CrosshairView) {
        guard let start = dragStartPoint else { return }
        view.isDragging = true

        let rect = rectFromPoints(start, point)
        view.selectionRect = rect

        // Update all crosshair views with the same selection for multi-monitor
        for crosshairView in crosshairViews where crosshairView !== view {
            crosshairView.isDragging = true
            crosshairView.selectionRect = rect
        }

        // Update dimension label
        let w = Int(rect.width)
        let h = Int(rect.height)
        if w > 0 && h > 0 {
            let label = getOrCreateDimensionLabel(in: view)
            label.updateDuringDrag(width: w, height: h)
            label.positionRelativeTo(selectionRect: rect, in: view.bounds)
        }
    }

    func handleMouseUp(at point: NSPoint, in view: CrosshairView) {
        guard let start = dragStartPoint else {
            cancelCapture()
            return
        }

        let rect = rectFromPoints(start, point)
        dragStartPoint = nil

        // Click without drag or too-small selection = cancel
        if rect.width < DesignTokens.minimumSelectionSize ||
           rect.height < DesignTokens.minimumSelectionSize {
            cancelCapture()
            return
        }

        // Update label to final format
        dimensionLabel?.updateAfterRelease(width: Int(rect.width), height: Int(rect.height))

        // Convert to screen coordinates
        guard let window = view.window else {
            cancelCapture()
            return
        }

        let windowRect = view.convert(rect, to: nil)
        let screenRect = window.convertToScreen(windowRect)
        completeSelection(rect: screenRect)
    }

    // MARK: - Dimension label

    private func getOrCreateDimensionLabel(in view: CrosshairView) -> DimensionLabelView {
        if let existing = dimensionLabel {
            return existing
        }
        let label = DimensionLabelView(frame: .zero)
        view.addSubview(label)
        dimensionLabel = label
        return label
    }

    private func removeDimensionLabel() {
        dimensionLabel?.removeFromSuperview()
        dimensionLabel = nil
    }

    // MARK: - Private

    private func rectFromPoints(_ a: NSPoint, _ b: NSPoint) -> NSRect {
        let x = min(a.x, b.x)
        let y = min(a.y, b.y)
        let w = abs(a.x - b.x)
        let h = abs(a.y - b.y)
        return NSRect(x: x, y: y, width: w, height: h)
    }

    private func cleanupAfterCapture() {
        NSCursor.unhide()
        removeDimensionLabel()
        overlayWindows.removeAll()
        crosshairViews.removeAll()
        dragStartPoint = nil
        activeView = nil
        isCapturing = false
    }

    private func dismissOverlays() {
        NSCursor.unhide()
        removeDimensionLabel()

        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        crosshairViews.removeAll()
        dragStartPoint = nil
        activeView = nil
        isCapturing = false
    }
}
