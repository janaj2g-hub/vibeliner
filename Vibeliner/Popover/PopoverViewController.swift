import AppKit

final class PopoverViewController: NSViewController {

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 210, height: 194))
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
            y -= 30
            let row = makeRow(title: title, shortcut: shortcut, action: action, y: y)
            container.addSubview(row)
        }

        // Divider
        y -= 8
        let divider = NSView(frame: NSRect(x: 8, y: y, width: 194, height: 0.5))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor(white: 1, alpha: 0.06).cgColor
        container.addSubview(divider)

        // Quit
        y -= 30
        let quitRow = makeRow(title: "Quit Vibeliner", shortcut: "⌘Q", action: #selector(quitApp), y: y)
        container.addSubview(quitRow)
    }

    private func makeRow(title: String, shortcut: String?, action: Selector, y: CGFloat) -> NSView {
        let row = HoverRowView(frame: NSRect(x: 4, y: y, width: 202, height: 28))
        row.target = self
        row.action = action

        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = NSColor(white: 1, alpha: 0.8)
        label.frame = NSRect(x: 8, y: 4, width: 140, height: 20)
        row.addSubview(label)

        if let sc = shortcut {
            let badge = NSTextField(labelWithString: sc)
            badge.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
            badge.textColor = NSColor(white: 1, alpha: 0.25)
            badge.alignment = .right
            badge.frame = NSRect(x: 150, y: 4, width: 44, height: 20)
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

    @objc private func recentCaptures() {
        // Submenu handled in VIB-141
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
