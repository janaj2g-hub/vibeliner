import AppKit

final class CaptureCoordinator {
    static let shared = CaptureCoordinator()

    private var overlayWindows: [CaptureOverlayWindow] = []
    private var crosshairViews: [CrosshairView] = []
    private var dragStartPoint: NSPoint?
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
        print("Selection completed: \(rect)")
        dismissOverlays()
    }

    // MARK: - Mouse handling

    func handleMouseDown(at point: NSPoint, in view: CrosshairView) {
        dragStartPoint = point
        view.isDragging = false
        view.selectionRect = nil
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

        // Convert to screen coordinates
        guard let window = view.window else {
            cancelCapture()
            return
        }

        let windowRect = view.convert(rect, to: nil)
        let screenRect = window.convertToScreen(windowRect)
        completeSelection(rect: screenRect)
    }

    // MARK: - Private

    private func rectFromPoints(_ a: NSPoint, _ b: NSPoint) -> NSRect {
        let x = min(a.x, b.x)
        let y = min(a.y, b.y)
        let w = abs(a.x - b.x)
        let h = abs(a.y - b.y)
        return NSRect(x: x, y: y, width: w, height: h)
    }

    private func dismissOverlays() {
        NSCursor.unhide()

        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        crosshairViews.removeAll()
        dragStartPoint = nil
        isCapturing = false
    }
}
