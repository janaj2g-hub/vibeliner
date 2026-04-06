import AppKit

final class RecentCapturesSubmenu: NSView {

    private var hideTimer: Timer?
    var onMouseEntered: (() -> Void)?
    var onMouseExited: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    // VIB-174: Match prototype PopoverScreen submenu styling
    private func setupView() {
        let submenuW: CGFloat = 300
        let rowH: CGFloat = 42

        wantsLayer = true
        layer?.cornerRadius = DesignTokens.popoverCornerRadius
        layer?.masksToBounds = true
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.separatorColor.cgColor

        // VIB-183: Use async version with cache, but fall back to sync for initial render
        // (async completion will rebuild if cache was stale)
        let captures = Array(CapturesManager.shared.listRecentCaptures(limit: 5).prefix(5))
        // Also pre-warm the cache asynchronously for next open
        CapturesManager.shared.listRecentCapturesAsync(limit: 5) { _ in }
        let openFolderH: CGFloat = 34
        let dividerH: CGFloat = 9

        if captures.isEmpty {
            let empty = NSTextField(labelWithString: "No captures yet")
            empty.font = NSFont.systemFont(ofSize: 12)
            empty.textColor = .tertiaryLabelColor
            empty.alignment = .center
            empty.frame = NSRect(x: 0, y: openFolderH + dividerH + 10, width: submenuW, height: 20)
            addSubview(empty)
            addOpenFolderRow(at: 4, width: submenuW)
            let divY = openFolderH + 2
            addDivider(at: divY, width: submenuW)
            let emptyH = openFolderH + dividerH + 50
            setFrameSize(NSSize(width: submenuW, height: emptyH))
            addEffectView(size: NSSize(width: submenuW, height: emptyH))
            return
        }

        // Layout from bottom: Open Folder → divider → capture rows → header
        var y: CGFloat = 4
        addOpenFolderRow(at: y, width: submenuW)
        y += openFolderH

        addDivider(at: y, width: submenuW)
        y += dividerH

        // Capture rows (most recent at top = highest y)
        for (i, capture) in captures.reversed().enumerated() {
            let row = CaptureRowView(capture: capture)
            row.frame = NSRect(x: 6, y: y + CGFloat(i) * rowH, width: submenuW - 12, height: rowH - 2)
            addSubview(row)
        }
        y += CGFloat(captures.count) * rowH

        // RECENT header
        let header = NSTextField(labelWithString: "RECENT")
        header.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        header.textColor = .quaternaryLabelColor
        header.frame = NSRect(x: 14, y: y, width: submenuW - 28, height: 14)
        addSubview(header)
        y += 22

        setFrameSize(NSSize(width: submenuW, height: y))
        addEffectView(size: NSSize(width: submenuW, height: y))
    }

    private func addEffectView(size: NSSize) {
        let effectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        effectView.material = .menu
        effectView.state = .active
        effectView.blendingMode = .behindWindow
        effectView.autoresizingMask = [.width, .height]
        addSubview(effectView, positioned: .below, relativeTo: nil)
    }

    private func addDivider(at y: CGFloat, width: CGFloat) {
        let div = NSView(frame: NSRect(x: 12, y: y + 4, width: width - 24, height: 1))
        div.wantsLayer = true
        div.layer?.backgroundColor = NSColor.separatorColor.cgColor
        addSubview(div)
    }

    private func addOpenFolderRow(at y: CGFloat, width: CGFloat) {
        let row = OpenFolderRowView(frame: NSRect(x: 6, y: y, width: width - 12, height: 30))
        addSubview(row)
    }

    func scheduleHide(after delay: TimeInterval = 0.2, action: @escaping () -> Void) {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }

    func cancelHide() {
        hideTimer?.invalidate()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { onMouseEntered?() }
    override func mouseExited(with event: NSEvent) { onMouseExited?() }
}

// VIB-174: "Open Captures Folder" row at bottom of submenu
final class OpenFolderRowView: NSView {
    private var isHovered = false { didSet { needsDisplay = true } }

    override init(frame: NSRect) {
        super.init(frame: frame)
        let icon = NSTextField(labelWithString: "📁")
        icon.font = NSFont.systemFont(ofSize: 12)
        icon.isBezeled = false
        icon.drawsBackground = false
        icon.frame = NSRect(x: 8, y: (frame.height - 16) / 2, width: 18, height: 16)
        addSubview(icon)

        let label = NSTextField(labelWithString: "Open Captures Folder")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.isBezeled = false
        label.drawsBackground = false
        label.frame = NSRect(x: 28, y: (frame.height - 16) / 2, width: 180, height: 16)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHovered {
            NSColor.labelColor.withAlphaComponent(0.1).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).fill()
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
        let url = URL(fileURLWithPath: ConfigManager.shared.expandedCapturesFolder)
        NSWorkspace.shared.open(url)
    }
}
