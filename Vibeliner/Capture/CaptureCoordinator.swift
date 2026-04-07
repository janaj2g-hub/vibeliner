import AppKit

final class CaptureCoordinator {
    static let shared = CaptureCoordinator()

    private var overlayWindows: [CaptureOverlayWindow] = []
    private var crosshairViews: [CrosshairView] = []
    private var dimensionLabel: DimensionLabelView?
    private var dragStartPoint: NSPoint?
    private var activeView: CrosshairView?
    private var editorPanel: EditorPanel?
    private var isCapturing = false
    /// VIB-262: When set, captured image is returned to this handler instead of opening a new editor.
    private var addImageCompletion: ((NSImage) -> Void)?

    private init() {}

    /// VIB-262: Start capture in add-image mode — image returned via completion instead of new editor.
    func startAddImageCapture(completion: @escaping (NSImage) -> Void) {
        addImageCompletion = completion
        startCapture()
    }

    func startCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        CursorManager.shared.hideCursor()

        for screen in NSScreen.screens {
            let window = CaptureOverlayWindow(screen: screen)
            let crosshairView = CrosshairView(frame: NSRect(origin: .zero, size: screen.frame.size))
            crosshairView.autoresizingMask = [.width, .height]

            window.contentView = crosshairView
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(crosshairView)

            overlayWindows.append(window)
            crosshairViews.append(crosshairView)
        }
    }

    func cancelCapture() {
        addImageCompletion = nil
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
                self.addImageCompletion = nil
                dismissOverlays()
                return
            }

            // VIB-262: Add-image mode — return image to editor instead of opening new one
            if let completion = self.addImageCompletion {
                self.addImageCompletion = nil
                self.cleanupAfterCapture()
                completion(image)
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

            // Open editor panel
            let panel = EditorPanel(image: image, on: screen, captureFolder: folderURL)
            panel.makeKeyAndOrderFront(nil)
            self.editorPanel = panel
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

        // VIB-185: Do NOT update other screens' crosshair views.
        // Only the active screen shows the selection rectangle.
        // Other screens stay dimmed without selection/crosshair.

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
        CursorManager.shared.forceShow()
        removeDimensionLabel()
        overlayWindows.removeAll()
        crosshairViews.removeAll()
        dragStartPoint = nil
        activeView = nil
        isCapturing = false
    }

    private func dismissOverlays() {
        CursorManager.shared.forceShow()
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
