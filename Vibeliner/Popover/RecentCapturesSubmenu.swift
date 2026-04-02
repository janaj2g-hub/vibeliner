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

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = DesignTokens.darkChromePopover.cgColor
        layer?.cornerRadius = 10
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor(white: 1, alpha: 0.08).cgColor

        let captures = CapturesManager.shared.listRecentCaptures(limit: 10)

        if captures.isEmpty {
            let empty = NSTextField(labelWithString: "No captures yet")
            empty.font = NSFont.systemFont(ofSize: 12)
            empty.textColor = NSColor(white: 1, alpha: 0.3)
            empty.alignment = .center
            empty.frame = NSRect(x: 0, y: 20, width: 220, height: 20)
            addSubview(empty)
            return
        }

        // Header
        let header = NSTextField(labelWithString: "RECENT")
        header.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        header.textColor = NSColor(white: 1, alpha: 0.2)
        header.frame = NSRect(x: 12, y: CGFloat(captures.count) * 36 + 8, width: 196, height: 14)
        addSubview(header)

        for (i, capture) in captures.enumerated() {
            let row = CaptureRowView(capture: capture)
            row.frame = NSRect(x: 4, y: CGFloat(captures.count - 1 - i) * 36 + 4, width: 212, height: 34)
            addSubview(row)
        }

        setFrameSize(NSSize(width: 220, height: CGFloat(captures.count) * 36 + 30))
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
