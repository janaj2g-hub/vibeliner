import AppKit

enum PanelState {
    case active, complete, locked
}

final class SetupPanelView: NSView {

    var state: PanelState = .locked { didSet { updateAppearance() } }
    let contentView = NSView()
    private let badgeView = NSView()
    private let badgeLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let statusBg = NSView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let stepNumber: Int

    init(stepNumber: Int, title: String) {
        self.stepNumber = stepNumber
        super.init(frame: .zero)

        wantsLayer = true

        // Badge — 28px circle
        badgeView.wantsLayer = true
        badgeView.layer?.cornerRadius = 14
        badgeLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.alignment = .center
        badgeLabel.isBezeled = false
        badgeLabel.drawsBackground = false
        badgeLabel.isEditable = false
        badgeLabel.textColor = .white
        badgeLabel.stringValue = "\(stepNumber)"
        badgeView.addSubview(badgeLabel)
        addSubview(badgeView)

        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = NSColor(white: 0.2, alpha: 1)
        titleLabel.stringValue = title
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        addSubview(titleLabel)

        addSubview(contentView)

        // Status bar
        statusBg.wantsLayer = true
        statusBg.layer?.cornerRadius = 5
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.alignment = .center
        statusLabel.isBezeled = false
        statusLabel.drawsBackground = false
        statusLabel.isEditable = false
        addSubview(statusBg)
        addSubview(statusLabel)

        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let pad: CGFloat = 16

        // Header: badge + title in a row
        badgeView.frame = NSRect(x: pad, y: bounds.height - 20 - 28, width: 28, height: 28)
        badgeLabel.frame = NSRect(x: 0, y: 4, width: 28, height: 20)
        titleLabel.sizeToFit()
        titleLabel.frame = NSRect(x: pad + 36, y: bounds.height - 20 - 22, width: titleLabel.frame.width, height: 20)

        // Status bar at bottom
        let statusH: CGFloat = 24
        statusBg.frame = NSRect(x: pad, y: 10, width: w - pad * 2, height: statusH)
        statusLabel.frame = statusBg.frame

        // Content between header and status
        contentView.frame = NSRect(x: pad, y: statusH + 20, width: w - pad * 2, height: bounds.height - 56 - statusH - 20)
    }

    func setStatus(text: String, style: StatusStyle) {
        statusLabel.stringValue = text
        switch style {
        case .amber:
            statusBg.layer?.backgroundColor = NSColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 0.1).cgColor
            statusBg.layer?.borderColor = NSColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 0.15).cgColor
            statusBg.layer?.borderWidth = 0.5
            statusLabel.textColor = NSColor(red: 146/255, green: 64/255, blue: 14/255, alpha: 1)
        case .green:
            statusBg.layer?.backgroundColor = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 0.08).cgColor
            statusBg.layer?.borderColor = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 0.12).cgColor
            statusBg.layer?.borderWidth = 0.5
            statusLabel.textColor = NSColor(red: 21/255, green: 128/255, blue: 61/255, alpha: 1)
        case .gray:
            statusBg.layer?.backgroundColor = NSColor(white: 0, alpha: 0.03).cgColor
            statusBg.layer?.borderColor = NSColor.clear.cgColor
            statusBg.layer?.borderWidth = 0
            statusLabel.textColor = NSColor(white: 0.6, alpha: 1)
        case .info:
            statusBg.layer?.backgroundColor = NSColor(red: 55/255, green: 138/255, blue: 221/255, alpha: 0.08).cgColor
            statusBg.layer?.borderColor = NSColor(red: 55/255, green: 138/255, blue: 221/255, alpha: 0.12).cgColor
            statusBg.layer?.borderWidth = 0.5
            statusLabel.textColor = NSColor(red: 55/255, green: 138/255, blue: 221/255, alpha: 1)
        }
    }

    enum StatusStyle { case amber, green, gray, info }

    private func updateAppearance() {
        switch state {
        case .active:
            alphaValue = 1.0
            badgeView.layer?.backgroundColor = NSColor(red: 55/255, green: 138/255, blue: 221/255, alpha: 1).cgColor
            badgeLabel.stringValue = "\(stepNumber)"
        case .complete:
            alphaValue = 0.5
            badgeView.layer?.backgroundColor = NSColor(red: 22/255, green: 163/255, blue: 74/255, alpha: 1).cgColor
            badgeLabel.stringValue = "✓"
        case .locked:
            alphaValue = 0.4
            badgeView.layer?.backgroundColor = NSColor(white: 0.6, alpha: 1).cgColor
            badgeLabel.stringValue = "🔒"
        }
    }
}
