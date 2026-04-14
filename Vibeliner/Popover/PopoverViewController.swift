import AppKit

final class PopoverContentView: PopoverBorderedSurfaceView {

    weak var popoverWindow: PopoverWindow?
    private let cornerRadius: CGFloat = 10
    private let popWidth: CGFloat = 240

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        surfaceCornerRadius = cornerRadius
        buildContent()
    }

    required init?(coder: NSCoder) { fatalError() }

    func buildContent() {
        let rowH: CGFloat = 32
        let rowGap: CGFloat = 2
        let vPad: CGFloat = 6
        let hPad: CGFloat = 6
        let dividerH: CGFloat = 9

        // Menu items — VIB-219: use closures instead of selectors for first-click support
        struct MenuItem {
            let label: String
            let keys: [String]?
            let action: () -> Void
            let hasArrow: Bool
            let hasDividerBefore: Bool
        }

        let items: [MenuItem] = [
            MenuItem(label: "Capture Now", keys: ["⌘", "⇧", "6"], action: { [weak self] in self?.captureNow() }, hasArrow: false, hasDividerBefore: false),
            MenuItem(label: "Recent Captures", keys: nil, action: { [weak self] in self?.showRecentSubmenu() }, hasArrow: true, hasDividerBefore: false),
            MenuItem(label: "Open Captures", keys: nil, action: { [weak self] in self?.openCaptures() }, hasArrow: false, hasDividerBefore: false),
            MenuItem(label: "Settings", keys: nil, action: { [weak self] in self?.openSettings() }, hasArrow: false, hasDividerBefore: false),
            MenuItem(label: "Re-run Setup", keys: nil, action: { [weak self] in self?.reRunSetup() }, hasArrow: false, hasDividerBefore: true),
        ]

        // Count dividers: one before Quit + any hasDividerBefore items
        let extraDividers = items.filter { $0.hasDividerBefore }.count
        // Calculate total height: vPad + items + extra dividers + quit divider + quit + vPad
        let bodyH = vPad + CGFloat(items.count) * (rowH + rowGap) + CGFloat(extraDividers) * dividerH + dividerH + (rowH + rowGap) + vPad

        setFrameSize(NSSize(width: popWidth, height: bodyH))

        // NSVisualEffectView for frosted glass background
        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: NSSize(width: popWidth, height: bodyH)))
        effectView.material = .menu
        effectView.state = .active
        effectView.blendingMode = .behindWindow
        effectView.autoresizingMask = [.width, .height]
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = cornerRadius
        effectView.layer?.masksToBounds = true
        addSubview(effectView, positioned: .below, relativeTo: nil)

        // Layout rows top-down (AppKit y=0 is bottom, so start from bodyH and subtract)
        var y = bodyH - vPad

        for item in items {
            // VIB-362: Draw divider before items that need one
            if item.hasDividerBefore {
                y -= dividerH / 2
                let div = PopoverDividerView(frame: NSRect(x: 14, y: y, width: popWidth - 28, height: 1))
                addSubview(div)
                y -= dividerH / 2
            }

            y -= rowH
            let row = makeRow(label: item.label, keys: item.keys, onAction: item.action, hasArrow: item.hasArrow, y: y, rowH: rowH, hPad: hPad)
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
        let divider = PopoverDividerView(frame: NSRect(x: 14, y: y, width: popWidth - 28, height: 1))
        addSubview(divider)
        y -= dividerH / 2

        // Quit row
        y -= rowH
        let quitRow = makeRow(label: "Quit Vibeliner", keys: nil, onAction: { [weak self] in self?.quitApp() }, hasArrow: false, y: y, rowH: rowH, hPad: hPad)
        quitRow.setAccessibilityLabel("Quit Vibeliner")
        quitRow.setAccessibilityRole(.menuItem)
        addSubview(quitRow)
    }

    func makeRow(label: String, keys: [String]?, onAction: @escaping () -> Void, hasArrow: Bool, y: CGFloat, rowH: CGFloat, hPad: CGFloat) -> PopoverRowView {
        let rowW = popWidth - hPad * 2
        let row = PopoverRowView(frame: NSRect(x: hPad, y: y, width: rowW, height: rowH))
        row.onAction = onAction  // VIB-219: closure-based action for first-click support
        row.setAccessibilityLabel(label)
        row.setAccessibilityRole(.menuItem)

        let textLabel = NSTextField(labelWithString: label)
        textLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        textLabel.textColor = .labelColor
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
            arrowLabel.textColor = .tertiaryLabelColor
            arrowLabel.isBezeled = false
            arrowLabel.drawsBackground = false
            arrowLabel.sizeToFit()
            arrowLabel.frame.origin = NSPoint(x: rowW - 8 - arrowLabel.frame.width, y: (rowH - arrowLabel.frame.height) / 2)
            row.addSubview(arrowLabel)
        }

        return row
    }

    func makeKbdPill(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        label.sizeToFit()

        let w = max(22, label.frame.width + 10)
        let h: CGFloat = 22
        let pill = PopoverKeyboardPillView(frame: NSRect(x: 0, y: 0, width: w, height: h))

        label.frame = NSRect(x: (w - label.frame.width) / 2, y: (h - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)
        pill.addSubview(label)

        return pill
    }

    // MARK: - Actions

    @objc func captureNow() {
        // VIB-317: Close popover first, then defer capture by one run-loop cycle
        // so the popover fully releases key-window status before the overlay takes over.
        popoverWindow?.closePopover()
        DispatchQueue.main.async {
            CaptureCoordinator.shared.startCapture()
        }
    }

    private var submenuPanel: NSPanel?
    private var submenuHideTimer: Timer?

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

        // Position to the right of popover, with top aligned near "Recent Captures" row
        let popFrame = popWin.frame
        let x = popFrame.maxX + 4
        let rowOffsetFromTop: CGFloat = 40  // approx distance from popover top to Recent Captures row
        let preferredY = popFrame.maxY - rowOffsetFromTop - submenu.frame.height
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        let clampedY = max(screenFrame.minY + 8, min(preferredY, screenFrame.maxY - submenu.frame.height - 8))
        panel.setFrameOrigin(NSPoint(x: x, y: clampedY))
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

    @objc func openCaptures() {
        popoverWindow?.closePopover()
        let url = URL(fileURLWithPath: ConfigManager.shared.expandedCapturesFolder)
        NSWorkspace.shared.open(url)
    }

    @objc func openSettings() {
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

    func reRunSetup() {
        popoverWindow?.closePopover()
        ConfigManager.shared.setupComplete = false
        ConfigManager.shared.save()
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.showSetupWindow()
        }
    }

    func takeATour() {
        popoverWindow?.closePopover()
        DispatchQueue.main.async {
            TourWindowController.shared.showTour()
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Hover Row

final class PopoverRowView: PopoverHoverSurfaceView {
    var onAction: (() -> Void)?  // VIB-219: direct closure, works on first click
    var onHoverEnter: (() -> Void)?
    var onHoverExit: (() -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        isSurfaceHovered = true
        onHoverEnter?()
    }
    override func mouseExited(with event: NSEvent) {
        isSurfaceHovered = false
        onHoverExit?()
    }
    // VIB-219: accept first click even when popover isn't the key window
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        onAction?()
    }
}
