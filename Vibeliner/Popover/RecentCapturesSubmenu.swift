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
        // VIB-174: rgba(30,30,30,0.95) bg, 10px radius, 0.5px border
        layer?.backgroundColor = NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.95).cgColor
        layer?.cornerRadius = 10
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor(white: 1, alpha: 0.08).cgColor

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
            empty.textColor = NSColor(white: 1, alpha: 0.3)
            empty.alignment = .center
            empty.frame = NSRect(x: 0, y: openFolderH + dividerH + 10, width: submenuW, height: 20)
            addSubview(empty)
            addOpenFolderRow(at: 4, width: submenuW)
            let divY = openFolderH + 2
            addDivider(at: divY, width: submenuW)
            setFrameSize(NSSize(width: submenuW, height: openFolderH + dividerH + 50))
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
        header.textColor = NSColor(white: 1, alpha: 0.2)
        header.frame = NSRect(x: 14, y: y, width: submenuW - 28, height: 14)
        addSubview(header)
        y += 22

        setFrameSize(NSSize(width: submenuW, height: y))
    }

    private func addDivider(at y: CGFloat, width: CGFloat) {
        let div = NSView(frame: NSRect(x: 12, y: y + 4, width: width - 24, height: 1))
        div.wantsLayer = true
        div.layer?.backgroundColor = NSColor(white: 1, alpha: 0.06).cgColor
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
        label.textColor = NSColor(white: 1, alpha: 0.6)
        label.isBezeled = false
        label.drawsBackground = false
        label.frame = NSRect(x: 28, y: (frame.height - 16) / 2, width: 180, height: 16)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

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

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func mouseDown(with event: NSEvent) {
        let url = URL(fileURLWithPath: ConfigManager.shared.expandedCapturesFolder)
        NSWorkspace.shared.open(url)
    }
}
