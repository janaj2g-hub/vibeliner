import AppKit

final class PopoverViewController: NSViewController {

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 210, height: 220))
        container.wantsLayer = true
        self.view = container

        var y: CGFloat = container.frame.height - 8

        // Menu items
        let items: [(String, String?, Selector)] = [
            ("Capture Now", "⌘⇧6", #selector(captureNow)),
            ("Recent Captures", "▸", #selector(recentCaptures)),
            ("Open Captures", nil, #selector(openCaptures)),
            ("Settings", "⌘,", #selector(openSettings)),
        ]

        for (title, shortcut, action) in items {
            y -= 34
            let row = makeRow(title: title, shortcut: shortcut, action: action, y: y)
            container.addSubview(row)
        }

        // Divider
        y -= 10
        let divider = NSView(frame: NSRect(x: 10, y: y, width: 190, height: 0.5))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor(white: 1, alpha: 0.08).cgColor
        container.addSubview(divider)

        // Quit
        y -= 34
        let quitRow = makeRow(title: "Quit Vibeliner", shortcut: "⌘Q", action: #selector(quitApp), y: y)
        container.addSubview(quitRow)
    }

    private func makeRow(title: String, shortcut: String?, action: Selector, y: CGFloat) -> NSView {
        let row = HoverRowView(frame: NSRect(x: 4, y: y, width: 202, height: 32))
        row.target = self
        row.action = action

        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = NSColor(white: 1, alpha: 0.8)
        label.frame = NSRect(x: 10, y: 6, width: 130, height: 20)
        row.addSubview(label)

        if let sc = shortcut {
            let badge = NSTextField(labelWithString: sc)
            badge.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
            badge.textColor = NSColor(white: 1, alpha: 0.35)
            badge.alignment = .right
            badge.frame = NSRect(x: 140, y: 6, width: 54, height: 20)
            row.addSubview(badge)
        }

        return row
    }

    @objc private func captureNow() {
        dismiss(nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CaptureCoordinator.shared.startCapture()
        }
    }

    private var submenuWindow: NSWindow?

    @objc private func recentCaptures() {
        guard submenuWindow == nil else { return }

        let submenu = RecentCapturesSubmenu()
        let window = NSWindow(contentRect: submenu.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .popUpMenu
        window.contentView = submenu

        // Position to the right of the popover
        if let parentWindow = view.window {
            let parentFrame = parentWindow.frame
            window.setFrameOrigin(NSPoint(x: parentFrame.maxX + 4, y: parentFrame.maxY - submenu.frame.height - 32))
        }
        window.orderFront(nil)
        self.submenuWindow = window

        // Auto-hide after a delay when mouse leaves
        submenu.scheduleHide(after: 0.3) { [weak self] in
            self?.submenuWindow?.close()
            self?.submenuWindow = nil
        }
    }

    @objc private func openCaptures() {
        dismiss(nil)
        let url = URL(fileURLWithPath: ConfigManager.shared.expandedCapturesFolder)
        NSWorkspace.shared.open(url)
    }

    @objc private func openSettings() {
        dismiss(nil)
        if let delegate = NSApp.delegate as? AppDelegate {
            if delegate.settingsWindowController == nil {
                delegate.settingsWindowController = SettingsWindowController()
            }
            delegate.settingsWindowController?.showWindow(nil)
            delegate.settingsWindowController?.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Hover Row

final class HoverRowView: NSView {
    var target: AnyObject?
    var action: Selector?
    private var isHovered = false { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHovered {
            NSColor(white: 1, alpha: 0.06).setFill()
            let path = NSBezierPath(roundedRect: bounds, xRadius: 5, yRadius: 5)
            path.fill()
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func mouseDown(with event: NSEvent) {
        if let target = target, let action = action {
            NSApp.sendAction(action, to: target, from: self)
        }
    }
}
