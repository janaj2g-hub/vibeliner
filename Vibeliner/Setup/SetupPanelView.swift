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
    private let statusBar = NSTextField(labelWithString: "")
    private let statusBg = NSView()
    private let stepNumber: Int

    init(stepNumber: Int, title: String) {
        self.stepNumber = stepNumber
        super.init(frame: .zero)

        // Badge
        badgeView.wantsLayer = true
        badgeView.layer?.cornerRadius = 14
        badgeView.frame = NSRect(x: 0, y: 0, width: 28, height: 28)
        badgeLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        badgeLabel.alignment = .center
        badgeLabel.isBezeled = false
        badgeLabel.drawsBackground = false
        badgeLabel.isEditable = false
        badgeLabel.textColor = .white
        badgeLabel.stringValue = "\(stepNumber)"
        badgeLabel.frame = NSRect(x: 0, y: 4, width: 28, height: 20)
        badgeView.addSubview(badgeLabel)

        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = NSColor(white: 0.2, alpha: 1)
        titleLabel.stringValue = title
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false

        // Status bar
        statusBg.wantsLayer = true
        statusBg.layer?.cornerRadius = 6
        statusBar.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        statusBar.alignment = .center
        statusBar.isBezeled = false
        statusBar.drawsBackground = false
        statusBar.isEditable = false

        addSubview(badgeView)
        addSubview(titleLabel)
        addSubview(contentView)
        addSubview(statusBg)
        addSubview(statusBar)

        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let pad: CGFloat = 16

        badgeView.frame = NSRect(x: (w - 28) / 2, y: bounds.height - 44, width: 28, height: 28)
        titleLabel.sizeToFit()
        titleLabel.frame = NSRect(x: (w - titleLabel.frame.width) / 2, y: bounds.height - 64, width: titleLabel.frame.width, height: 16)

        let statusH: CGFloat = 28
        statusBg.frame = NSRect(x: pad, y: 8, width: w - pad * 2, height: statusH)
        statusBar.frame = statusBg.frame

        contentView.frame = NSRect(x: pad, y: statusH + 16, width: w - pad * 2, height: bounds.height - 80 - statusH - 16)
    }

    func setStatus(text: String, color: NSColor) {
        statusBar.stringValue = text
        statusBar.textColor = .white
        statusBg.layer?.backgroundColor = color.cgColor
    }

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
