import AppKit

// MARK: - Custom dark popover window (NOT NSPopover — that uses system chrome)

final class PopoverWindow: NSPanel {

    private var popoverContent: PopoverContentView?
    private var clickMonitor: Any?

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false  // we draw our own shadow via the content's boxShadow
        level = .popUpMenu
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }

    /// Show below the status bar button
    func showRelativeTo(button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)

        // Build content
        let content = PopoverContentView()
        content.popoverWindow = self
        self.popoverContent = content

        let popW: CGFloat = 240
        let contentH = content.frame.height

        // Position: centered below the status bar button
        let x = screenFrame.midX - popW / 2
        let y = screenFrame.minY - contentH

        // Set window frame to exactly fit content
        let winFrame = NSRect(x: x, y: y, width: popW, height: contentH)
        setFrame(winFrame, display: false)

        // Set content view to a clear container, add our custom view inside
        let container = NSView(frame: NSRect(origin: .zero, size: winFrame.size))
        self.contentView = container
        content.frame.origin = .zero
        container.addSubview(content)

        orderFront(nil)

        // Close on click outside
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    func closePopover() {
        orderOut(nil)
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }
}

// MARK: - Popover content view (dark frosted glass with arrow)

final class PopoverContentView: NSView {

    weak var popoverWindow: PopoverWindow?
    private let arrowHeight: CGFloat = 8
    private let arrowWidth: CGFloat = 16
    private let cornerRadius: CGFloat = 10
    private let popWidth: CGFloat = 240

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        buildContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildContent() {
        let rowH: CGFloat = 32
        let rowGap: CGFloat = 2
        let vPad: CGFloat = 6
        let hPad: CGFloat = 6
        let dividerH: CGFloat = 9

        // Menu items
        struct MenuItem {
            let label: String
            let keys: [String]?
            let action: Selector
            let hasArrow: Bool
        }

        let items: [MenuItem] = [
            MenuItem(label: "Capture Now", keys: ["⌘", "⇧", "6"], action: #selector(captureNow), hasArrow: false),
            MenuItem(label: "Recent Captures", keys: nil, action: #selector(recentCaptures), hasArrow: true),
            MenuItem(label: "Open Captures", keys: nil, action: #selector(openCaptures), hasArrow: false),
            MenuItem(label: "Settings", keys: ["⌘", ","], action: #selector(openSettings), hasArrow: false),
        ]

        // Calculate total height: vPad + items + divider + quit + vPad + arrow
        let bodyH = vPad + CGFloat(items.count) * (rowH + rowGap) + dividerH + (rowH + rowGap) + vPad
        let totalH = bodyH + arrowHeight

        setFrameSize(NSSize(width: popWidth, height: totalH))

        // Layout rows top-down (AppKit y=0 is bottom, so start from bodyH and subtract)
        var y = bodyH - vPad

        for item in items {
            y -= rowH
            let row = makeRow(label: item.label, keys: item.keys, action: item.action, hasArrow: item.hasArrow, y: y, rowH: rowH, hPad: hPad)
            addSubview(row)
            // VIB-168: Add hover tracking on "Recent Captures" row
            if item.hasArrow {
                row.onHoverEnter = { [weak self] in self?.showRecentSubmenu() }
                row.onHoverExit = { [weak self] in self?.scheduleSubmenuHide() }
            }
            y -= rowGap
        }

        // Divider
        y -= dividerH / 2
        let divider = NSView(frame: NSRect(x: 14, y: y, width: popWidth - 28, height: 1))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor(white: 1, alpha: 0.06).cgColor
        addSubview(divider)
        y -= dividerH / 2

        // Quit row
        y -= rowH
        let quitRow = makeRow(label: "Quit Vibeliner", keys: ["⌘", "Q"], action: #selector(quitApp), hasArrow: false, y: y, rowH: rowH, hPad: hPad)
        addSubview(quitRow)
    }

    private func makeRow(label: String, keys: [String]?, action: Selector, hasArrow: Bool, y: CGFloat, rowH: CGFloat, hPad: CGFloat) -> PopoverRowView {
        let rowW = popWidth - hPad * 2
        let row = PopoverRowView(frame: NSRect(x: hPad, y: y, width: rowW, height: rowH))
        row.target = self
        row.action = action

        let textLabel = NSTextField(labelWithString: label)
        textLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        textLabel.textColor = NSColor(white: 1, alpha: 0.85)
        textLabel.sizeToFit()
        textLabel.frame.origin = NSPoint(x: 8, y: (rowH - textLabel.frame.height) / 2)
        row.addSubview(textLabel)

        if let keys = keys {
            var kx = rowW - 8
            for key in keys.reversed() {
                let kbd = makeKbdPill(key)
                kx -= kbd.frame.width
                kbd.frame.origin = NSPoint(x: kx, y: (rowH - kbd.frame.height) / 2)
                row.addSubview(kbd)
                kx -= 3
            }
        }

        if hasArrow {
            let arrowLabel = NSTextField(labelWithString: "›")
            arrowLabel.font = NSFont.systemFont(ofSize: 16)
            arrowLabel.textColor = NSColor(white: 1, alpha: 0.35)
            arrowLabel.isBezeled = false
            arrowLabel.drawsBackground = false
            arrowLabel.sizeToFit()
            arrowLabel.frame.origin = NSPoint(x: rowW - 8 - arrowLabel.frame.width, y: (rowH - arrowLabel.frame.height) / 2)
            row.addSubview(arrowLabel)
        }

        return row
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

        let bodyRect = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - arrowHeight)

        // Shadow
        let shadowPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadow.shadowOffset = NSSize(width: 0, height: -8)
        shadow.shadowBlurRadius = 32
        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        NSColor.black.setFill()
        shadowPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        // Background: rgba(30,30,30,0.95) with rounded corners
        let bgColor = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.95)
        let path = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
        bgColor.setFill()
        path.fill()

        // Arrow pointing up (centered at top)
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
        // VIB-169 (attempt 3): Post notification, let AppDelegate handle on next run loop
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("VibelinerTriggerCapture"), object: nil)
        }
    }

    private var submenuPanel: NSPanel?
    private var submenuHideTimer: Timer?

    @objc private func recentCaptures() {
        showRecentSubmenu()
    }

    func showRecentSubmenu() {
        submenuHideTimer?.invalidate()
        guard submenuPanel == nil, let popWin = popoverWindow else { return }

        let submenu = RecentCapturesSubmenu()
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: submenu.frame.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.isReleasedWhenClosed = false
        panel.contentView = submenu

        // Position to the right of popover, aligned with "Recent Captures" row
        let popFrame = popWin.frame
        let x = popFrame.maxX + 4
        let y = popFrame.maxY - 80 - submenu.frame.height  // align near row
        panel.setFrameOrigin(NSPoint(x: x, y: max(y, popFrame.minY)))
        panel.orderFront(nil)
        self.submenuPanel = panel

        // Track mouse exit on submenu to hide with delay
        submenu.onMouseExited = { [weak self] in
            self?.scheduleSubmenuHide()
        }
        submenu.onMouseEntered = { [weak self] in
            self?.submenuHideTimer?.invalidate()
        }
    }

    func scheduleSubmenuHide() {
        submenuHideTimer?.invalidate()
        submenuHideTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.submenuPanel?.close()
            self?.submenuPanel = nil
        }
    }

    func cancelSubmenuHide() {
        submenuHideTimer?.invalidate()
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
    var onHoverEnter: (() -> Void)?
    var onHoverExit: (() -> Void)?
    private var isHovered = false { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHovered {
            NSColor(white: 1, alpha: 0.06).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).fill()
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        onHoverEnter?()
    }
    override func mouseExited(with event: NSEvent) {
        isHovered = false
        onHoverExit?()
    }
    override func mouseDown(with event: NSEvent) {
        if let target = target, let action = action {
            NSApp.sendAction(action, to: target, from: self)
        }
    }
}
