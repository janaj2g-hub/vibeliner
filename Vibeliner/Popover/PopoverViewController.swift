import AppKit

// MARK: - Custom dark popover window (NOT NSPopover — that uses system chrome)

final class PopoverWindow: NSPanel {

    private var contentContainer: PopoverContentView?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 10),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false

        let content = PopoverContentView(frame: NSRect(x: 0, y: 0, width: 240, height: 10))
        content.popoverWindow = self
        self.contentView = content
        self.contentContainer = content
    }

    override var canBecomeKey: Bool { true }

    /// Show below the status bar button
    func showRelativeTo(button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)

        let popW: CGFloat = 240
        let contentH = contentContainer?.frame.height ?? 260
        let arrowH: CGFloat = 8
        let totalH = contentH + arrowH

        // Position: centered below the status bar button
        let x = screenFrame.midX - popW / 2
        let y = screenFrame.minY - totalH

        setFrame(NSRect(x: x, y: y, width: popW, height: totalH), display: true)
        orderFront(nil)

        // Close on click outside
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    func closePopover() {
        orderOut(nil)
    }
}

// MARK: - Popover content view (dark frosted glass with arrow)

final class PopoverContentView: NSView {

    weak var popoverWindow: PopoverWindow?
    private let arrowHeight: CGFloat = 8
    private let arrowWidth: CGFloat = 16
    private let cornerRadius: CGFloat = 10

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupContent() {
        // Build menu items
        let items: [(String, [String]?, Selector?, Bool)] = [
            ("Capture Now", ["⌘", "⇧", "6"], #selector(captureNow), false),
            ("Recent Captures", nil, #selector(recentCaptures), true),
            ("Open Captures", nil, #selector(openCaptures), false),
            ("Settings", ["⌘", ","], #selector(openSettings), false),
        ]

        let rowH: CGFloat = 32
        let padding: CGFloat = 6
        let dividerH: CGFloat = 9
        let totalRows = CGFloat(items.count + 1) // +1 for Quit
        let contentH = totalRows * (rowH + 2) + dividerH + padding * 2
        let totalH = contentH + arrowHeight

        setFrameSize(NSSize(width: 240, height: totalH))

        // Rows from top (in AppKit bottom-up, start from contentH and go down)
        var y = contentH - padding

        for (title, keys, action, hasArrow) in items {
            y -= rowH + 2
            let row = PopoverRowView(frame: NSRect(x: padding, y: y, width: 240 - padding * 2, height: rowH))
            row.target = self
            row.action = action

            let label = NSTextField(labelWithString: title)
            label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
            label.textColor = NSColor(white: 1, alpha: 0.85)
            label.frame = NSRect(x: 8, y: (rowH - 18) / 2, width: 130, height: 18)
            row.addSubview(label)

            if let keys = keys {
                var kx = row.frame.width - 8
                for key in keys.reversed() {
                    let kbd = makeKbdPill(key)
                    kx -= kbd.frame.width + 3
                    kbd.frame.origin = NSPoint(x: kx, y: (rowH - kbd.frame.height) / 2)
                    row.addSubview(kbd)
                }
            }

            if hasArrow {
                let arrow = NSTextField(labelWithString: "›")
                arrow.font = NSFont.systemFont(ofSize: 16)
                arrow.textColor = NSColor(white: 1, alpha: 0.35)
                arrow.isBezeled = false
                arrow.drawsBackground = false
                arrow.frame = NSRect(x: row.frame.width - 20, y: (rowH - 20) / 2, width: 16, height: 20)
                row.addSubview(arrow)
            }

            addSubview(row)
        }

        // Divider
        y -= dividerH
        let divider = NSView(frame: NSRect(x: 14, y: y + dividerH / 2, width: 240 - 28, height: 1))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor(white: 1, alpha: 0.06).cgColor
        addSubview(divider)

        // Quit
        y -= rowH + 2
        let quitRow = PopoverRowView(frame: NSRect(x: padding, y: y, width: 240 - padding * 2, height: rowH))
        quitRow.target = self
        quitRow.action = #selector(quitApp)

        let quitLabel = NSTextField(labelWithString: "Quit Vibeliner")
        quitLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        quitLabel.textColor = NSColor(white: 1, alpha: 0.85)
        quitLabel.frame = NSRect(x: 8, y: (rowH - 18) / 2, width: 130, height: 18)
        quitRow.addSubview(quitLabel)

        let quitKbd = makeKbdPill("⌘")
        let quitKbd2 = makeKbdPill("Q")
        var kx = quitRow.frame.width - 8
        kx -= quitKbd2.frame.width
        quitKbd2.frame.origin = NSPoint(x: kx, y: (rowH - quitKbd2.frame.height) / 2)
        kx -= 3 + quitKbd.frame.width
        quitKbd.frame.origin = NSPoint(x: kx, y: (rowH - quitKbd.frame.height) / 2)
        quitRow.addSubview(quitKbd)
        quitRow.addSubview(quitKbd2)
        addSubview(quitRow)
    }

    private func makeKbdPill(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = NSColor(white: 1, alpha: 0.55)
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        label.sizeToFit()

        let w = max(22, label.frame.width + 10)
        let h: CGFloat = 22
        let pill = NSView(frame: NSRect(x: 0, y: 0, width: w, height: h))
        pill.wantsLayer = true
        pill.layer?.backgroundColor = NSColor(white: 1, alpha: 0.08).cgColor
        pill.layer?.borderColor = NSColor(white: 1, alpha: 0.12).cgColor
        pill.layer?.borderWidth = 1
        pill.layer?.cornerRadius = 5

        label.frame = NSRect(x: (w - label.frame.width) / 2, y: (h - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)
        pill.addSubview(label)

        return pill
    }

    // MARK: - Drawing (dark bg with arrow)

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let bodyRect = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - arrowHeight)

        // Background: rgba(30,30,30,0.95) with rounded corners
        let bgColor = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.95)
        let path = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
        bgColor.setFill()
        path.fill()

        // Arrow pointing up (centered)
        let arrowPath = NSBezierPath()
        let arrowCenterX = bounds.width / 2
        let arrowBaseY = bodyRect.maxY
        arrowPath.move(to: NSPoint(x: arrowCenterX - arrowWidth / 2, y: arrowBaseY))
        arrowPath.line(to: NSPoint(x: arrowCenterX, y: arrowBaseY + arrowHeight))
        arrowPath.line(to: NSPoint(x: arrowCenterX + arrowWidth / 2, y: arrowBaseY))
        arrowPath.close()
        bgColor.setFill()
        arrowPath.fill()

        // Border: 0.5px solid rgba(255,255,255,0.08)
        let borderColor = NSColor(white: 1, alpha: 0.08)
        borderColor.setStroke()
        let borderPath = NSBezierPath(roundedRect: bodyRect.insetBy(dx: 0.25, dy: 0.25), xRadius: cornerRadius, yRadius: cornerRadius)
        borderPath.lineWidth = 0.5
        borderPath.stroke()
    }

    // MARK: - Actions

    @objc private func captureNow() {
        popoverWindow?.closePopover()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CaptureCoordinator.shared.startCapture()
        }
    }

    @objc private func recentCaptures() {
        // TODO: submenu
    }

    @objc private func openCaptures() {
        popoverWindow?.closePopover()
        let url = URL(fileURLWithPath: ConfigManager.shared.expandedCapturesFolder)
        NSWorkspace.shared.open(url)
    }

    @objc private func openSettings() {
        popoverWindow?.closePopover()
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

final class PopoverRowView: NSView {
    var target: AnyObject?
    var action: Selector?
    private var isHovered = false { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHovered {
            NSColor(white: 1, alpha: 0.06).setFill()
            let path = NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6)
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
