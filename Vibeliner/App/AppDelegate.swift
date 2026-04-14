import AppKit
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    var setupWindowController: SetupWindowController?
    var settingsWindowController: SettingsWindowController?
    private var popoverWindow: PopoverWindow?

    #if DEBUG
    private var visualTestHarness: VisualTestHarness?
    #endif

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        NSLog("AppDelegate launched")
        #endif

        // Visual test mode — open test harness instead of normal flow
        #if DEBUG
        if CommandLine.arguments.contains("--visual-test") {
            NSLog("Visual test mode — opening test harness")
            let harness = VisualTestHarness()
            harness.show()
            self.visualTestHarness = harness
            return
        }
        #endif

        ConfigManager.shared.load()
        CapturesManager.shared.ensureBaseFolder()
        applyAppearanceSetting()
        setupMenuBarIcon()

        // VIB-392: LSUIElement apps have no menu bar, so text fields lack the
        // Edit menu that provides Cmd+C/V/X/A/Z. Add one programmatically.
        installEditMenu()

        HotkeyManager.shared.onHotkeyPressed = {
            CaptureCoordinator.shared.startCapture()
        }
        HotkeyManager.shared.register()

        // VIB-169: Listen for capture trigger from popover
        NotificationCenter.default.addObserver(forName: NSNotification.Name("VibelinerTriggerCapture"), object: nil, queue: .main) { _ in
            CaptureCoordinator.shared.startCapture()
        }

        // Show setup window when needed:
        //   1. First-time (no config or setupComplete=false)
        //   2. Permission revoked (Screen Recording or Accessibility)
        //   3. Captures folder deleted
        let needsSetup: Bool = {
            let config = ConfigManager.shared
            guard config.setupComplete else { return true }
            guard CGPreflightScreenCaptureAccess() else { return true }
            guard AXIsProcessTrusted() else { return true }
            guard config.capturesFolderExists else { return true }
            return false
        }()

        if needsSetup {
            showSetupWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }

    func showSetupWindow() {
        let setup = SetupWindowController()
        setup.showWindow(nil)
        setup.window?.center()
        NSApp.activate(ignoringOtherApps: true)
        setupWindowController = setup
    }

    /// VIB-392: Create a minimal main menu with an Edit submenu so that standard
    /// text-editing shortcuts (Cmd+C/V/X/A/Z) work in Settings and other windows.
    /// The EditorPanel has its own performKeyEquivalent that fires before the menu,
    /// so its Cmd+C (copy prompt) and Cmd+Z (undo annotation) behavior is unchanged.
    private func installEditMenu() {
        let mainMenu = NSMenu()

        // App menu (required first item)
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func applyAppearanceSetting() {
        switch ConfigManager.shared.appearance {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":  NSApp.appearance = NSAppearance(named: .darkAqua)
        default:      NSApp.appearance = nil // follow system
        }
    }

    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // VIB-175/456: Pin icon (ring + stake) replaces crosshair
        normalIcon = createPinImage()
        normalIcon?.isTemplate = true

        highlightedIcon = createPinImage(color: .white)
        highlightedIcon?.isTemplate = false  // Won't adapt to menu bar — stays white/bright

        if let button = statusItem?.button {
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
            statusItem?.button?.image = normalIcon
        } else {
            let win = PopoverWindow()
            win.onClose = { [weak self] in
                self?.statusItem?.button?.image = self?.normalIcon
            }
            if let button = statusItem?.button {
                win.showRelativeTo(button: button)
                // VIB-175: Swap to non-template highlighted icon (always white/bright)
                statusItem?.button?.image = highlightedIcon
            }
            popoverWindow = win
        }
    }

    // VIB-456: Pin icon (ring + stake, no number) for menu bar
    private func createPinImage(color: NSColor? = nil) -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            let cx: CGFloat = size / 2       // 9
            let ringCenterY: CGFloat = 11    // upper portion (flipped=false → higher Y = higher on screen)
            let ringRadius: CGFloat = 5
            let lineWidth: CGFloat = 1.5

            (color ?? .black).setStroke()

            // Open ring
            let ring = NSBezierPath(
                ovalIn: NSRect(
                    x: cx - ringRadius,
                    y: ringCenterY - ringRadius,
                    width: ringRadius * 2,
                    height: ringRadius * 2
                )
            )
            ring.lineWidth = lineWidth
            ring.stroke()

            // Stake below ring
            let stake = NSBezierPath()
            stake.move(to: NSPoint(x: cx, y: ringCenterY - ringRadius))
            stake.line(to: NSPoint(x: cx, y: 2))
            stake.lineWidth = lineWidth
            stake.lineCapStyle = .round
            stake.stroke()

            return true
        }
        return image
    }
}
