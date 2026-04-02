import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var setupWindowController: SetupWindowController?
    var settingsWindowController: SettingsWindowController?
    private var popoverWindow: PopoverWindow?

    private var visualTestHarness: VisualTestHarness?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("AppDelegate launched")

        // Visual test mode — open test harness instead of normal flow
        if CommandLine.arguments.contains("--visual-test") {
            NSLog("Visual test mode — opening test harness")
            let harness = VisualTestHarness()
            harness.show()
            self.visualTestHarness = harness
            return
        }

        ConfigManager.shared.load()
        CapturesManager.shared.ensureBaseFolder()
        setupMenuBarIcon()

        HotkeyManager.shared.onHotkeyPressed = {
            CaptureCoordinator.shared.startCapture()
        }
        HotkeyManager.shared.register()

        // VIB-169: Listen for capture trigger from popover
        NotificationCenter.default.addObserver(forName: NSNotification.Name("VibelinerTriggerCapture"), object: nil, queue: .main) { _ in
            CaptureCoordinator.shared.startCapture()
        }

        // Show setup window on first launch
        if !ConfigManager.shared.setupComplete {
            let setup = SetupWindowController()
            setup.showWindow(nil)
            setup.window?.center()
            setupWindowController = setup
        }
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
        if let win = popoverWindow, win.isVisible {
            win.closePopover()
            popoverWindow = nil
            statusItem.button?.isHighlighted = false  // VIB-175
        } else {
            let win = PopoverWindow()
            if let button = statusItem.button {
                win.showRelativeTo(button: button)
                button.isHighlighted = true  // VIB-175
            }
            popoverWindow = win
        }
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
