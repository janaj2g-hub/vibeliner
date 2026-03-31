import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("AppDelegate launched")
        ConfigManager.shared.load()
        CapturesManager.shared.ensureBaseFolder()
        setupMenuBarIcon()

        HotkeyManager.shared.onHotkeyPressed = {
            CaptureCoordinator.shared.startCapture()
        }
        HotkeyManager.shared.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }

    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = createCrosshairImage()
            button.action = #selector(statusItemClicked)
            button.target = self
        }
    }

    @objc private func statusItemClicked() {
        print("Popover triggered")
    }

    private func createCrosshairImage() -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let center = NSPoint(x: size / 2, y: size / 2)
        let radius: CGFloat = 6
        let tickLength: CGFloat = 4
        let lineWidth: CGFloat = 1.5

        NSColor.black.setStroke()

        // Circle
        let circlePath = NSBezierPath(
            ovalIn: NSRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
        circlePath.lineWidth = lineWidth
        circlePath.stroke()

        // Top tick
        let top = NSBezierPath()
        top.move(to: NSPoint(x: center.x, y: center.y + radius))
        top.line(to: NSPoint(x: center.x, y: center.y + radius + tickLength))
        top.lineWidth = lineWidth
        top.stroke()

        // Bottom tick
        let bottom = NSBezierPath()
        bottom.move(to: NSPoint(x: center.x, y: center.y - radius))
        bottom.line(to: NSPoint(x: center.x, y: center.y - radius - tickLength))
        bottom.lineWidth = lineWidth
        bottom.stroke()

        // Right tick
        let right = NSBezierPath()
        right.move(to: NSPoint(x: center.x + radius, y: center.y))
        right.line(to: NSPoint(x: center.x + radius + tickLength, y: center.y))
        right.lineWidth = lineWidth
        right.stroke()

        // Left tick
        let left = NSBezierPath()
        left.move(to: NSPoint(x: center.x - radius, y: center.y))
        left.line(to: NSPoint(x: center.x - radius - tickLength, y: center.y))
        left.lineWidth = lineWidth
        left.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
