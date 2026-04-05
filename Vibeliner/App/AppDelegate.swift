import AppKit
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    var setupWindowController: SetupWindowController?
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

        // Check permissions for returning users
        if ConfigManager.shared.setupComplete {
            let hasScreenRecording = CGPreflightScreenCaptureAccess()
            let hasAccessibility = AXIsProcessTrusted()
            if !hasScreenRecording || !hasAccessibility {
                DispatchQueue.main.async {
                    self.showPermissionAlert(missingScreenRecording: !hasScreenRecording, missingAccessibility: !hasAccessibility)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }

    private func showPermissionAlert(missingScreenRecording: Bool, missingAccessibility: Bool) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Vibeliner needs permission"
        let hotkeyDisplay = HotkeyManager.shared.displayParts(for: ConfigManager.shared.hotkey).joined()

        var msgs: [String] = []
        if missingScreenRecording { msgs.append("Screen Recording is required to capture screenshots.") }
        if missingAccessibility { msgs.append("Accessibility is required for the \(hotkeyDisplay) hotkey.") }
        alert.informativeText = msgs.joined(separator: "\n")

        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if missingScreenRecording {
                CGRequestScreenCaptureAccess()
            } else if missingAccessibility {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }

    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // VIB-175: Create normal (template) and highlighted (non-template, always white) icons
        normalIcon = createCrosshairImage()
        normalIcon?.isTemplate = true

        highlightedIcon = createCrosshairImage(color: .white)
        highlightedIcon?.isTemplate = false  // Won't adapt to menu bar — stays white/bright

        if let button = statusItem.button {
            button.image = normalIcon
            button.action = #selector(statusItemClicked)
            button.target = self
        }
    }

    private var normalIcon: NSImage?
    private var highlightedIcon: NSImage?

    @objc private func statusItemClicked() {
        if let win = popoverWindow, win.isVisible {
            win.closePopover()
            popoverWindow = nil
            // VIB-175: Swap back to normal template icon
            statusItem.button?.image = normalIcon
        } else {
            let win = PopoverWindow()
            win.onClose = { [weak self] in
                self?.statusItem.button?.image = self?.normalIcon
            }
            if let button = statusItem.button {
                win.showRelativeTo(button: button)
                // VIB-175: Swap to non-template highlighted icon (always white/bright)
                statusItem.button?.image = highlightedIcon
            }
            popoverWindow = win
        }
    }

    private func createCrosshairImage(color: NSColor? = nil) -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let center = NSPoint(x: size / 2, y: size / 2)
        let radius: CGFloat = 6
        let tickLength: CGFloat = 4
        let lineWidth: CGFloat = 1.5

        (color ?? .black).setStroke()

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
        return image
    }
}
