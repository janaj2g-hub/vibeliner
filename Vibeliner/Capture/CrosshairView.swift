import AppKit

final class CrosshairView: NSView {

    var mouseLocation: NSPoint = .zero {
        didSet { needsDisplay = true }
    }

    var selectionRect: NSRect? {
        didSet { needsDisplay = true }
    }

    var isDragging: Bool = false

    // VIB-318: Transparent cursor so no arrow shows alongside crosshairs.
    // resetCursorRects is more reliable than NSCursor.hide() for persistent hiding.
    private static let invisibleCursor: NSCursor = {
        let size = NSSize(width: 1, height: 1)
        let image = NSImage(size: size)
        return NSCursor(image: image, hotSpot: .zero)
    }()

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: CrosshairView.invisibleCursor)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw dim overlay with optional cutout
        if let selection = selectionRect, isDragging {
            // Even-odd fill: dim everywhere except the selection
            let fullPath = NSBezierPath(rect: bounds)
            let cutoutPath = NSBezierPath(rect: selection)
            fullPath.append(cutoutPath)
            fullPath.windingRule = .evenOdd

            DesignTokens.dimOverlay.setFill()
            fullPath.fill()

            // Purple border around selection
            let borderColor = DesignTokens.purpleLight.withAlphaComponent(DesignTokens.crosshairOpacity)
            borderColor.setStroke()
            let borderPath = NSBezierPath(rect: selection)
            borderPath.lineWidth = DesignTokens.selectionBorderWidth
            borderPath.stroke()
        } else {
            // No selection — full dim
            DesignTokens.dimOverlay.setFill()
            bounds.fill()
        }

        // Draw crosshair
        let tickLength = DesignTokens.crosshairTickLength
        let color = DesignTokens.purpleLight.withAlphaComponent(DesignTokens.crosshairOpacity)

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(DesignTokens.crosshairThickness)
        context.setLineCap(.round)

        let localMouse = mouseLocation

        // Horizontal tick
        context.move(to: CGPoint(x: localMouse.x - tickLength, y: localMouse.y))
        context.addLine(to: CGPoint(x: localMouse.x + tickLength, y: localMouse.y))
        context.strokePath()

        // Vertical tick
        context.move(to: CGPoint(x: localMouse.x, y: localMouse.y - tickLength))
        context.addLine(to: CGPoint(x: localMouse.x, y: localMouse.y + tickLength))
        context.strokePath()
    }

    // MARK: - Mouse tracking

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    override func mouseMoved(with event: NSEvent) {
        updateMousePosition(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        CaptureCoordinator.shared.handleMouseDown(at: point, in: self)
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        CaptureCoordinator.shared.handleMouseDragged(to: point, in: self)
        updateMousePosition(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        CaptureCoordinator.shared.handleMouseUp(at: point, in: self)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            CaptureCoordinator.shared.cancelCapture()
        }
    }

    private func updateMousePosition(with event: NSEvent) {
        mouseLocation = convert(event.locationInWindow, from: nil)
    }
}
