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

        let captures = CapturesManager.shared.listRecentCaptures(limit: 10)

        if captures.isEmpty {
            let empty = NSTextField(labelWithString: "No captures yet")
            empty.font = NSFont.systemFont(ofSize: 12)
            empty.textColor = NSColor(white: 1, alpha: 0.3)
            empty.alignment = .center
            empty.frame = NSRect(x: 0, y: 20, width: submenuW, height: 20)
            addSubview(empty)
            setFrameSize(NSSize(width: submenuW, height: 60))
            return
        }

        // VIB-174: "RECENT" header — 10px uppercase weight 600 rgba(255,255,255,0.2), letterSpacing 0.5
        let header = NSTextField(labelWithString: "RECENT")
        header.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        header.textColor = NSColor(white: 1, alpha: 0.2)
        let headerY = CGFloat(captures.count) * rowH + 8
        header.frame = NSRect(x: 14, y: headerY, width: submenuW - 28, height: 14)
        addSubview(header)

        // VIB-174: Capture rows — 7px 10px padding, 1px 6px margin, 6px radius
        for (i, capture) in captures.enumerated() {
            let row = CaptureRowView(capture: capture)
            row.frame = NSRect(x: 6, y: CGFloat(captures.count - 1 - i) * rowH + 4, width: submenuW - 12, height: rowH - 2)
            addSubview(row)
        }

        setFrameSize(NSSize(width: submenuW, height: CGFloat(captures.count) * rowH + 30))
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
