import AppKit

final class AboutTabView: NSView {

    private let purpleAccent = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        let centerX = frame.width / 2
        var y = frame.height - 50

        // App icon — 64px red rounded square
        let iconView = NSView(frame: NSRect(x: centerX - 32, y: y - 64, width: 64, height: 64))
        iconView.wantsLayer = true
        iconView.layer?.backgroundColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1).cgColor
        iconView.layer?.cornerRadius = 16
        addSubview(iconView)

        // Crosshair on icon
        let crosshairImage = NSImage(size: NSSize(width: 32, height: 32))
        crosshairImage.lockFocus()
        NSColor.white.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 16, y: 6)); path.line(to: NSPoint(x: 16, y: 26))
        path.move(to: NSPoint(x: 6, y: 16)); path.line(to: NSPoint(x: 26, y: 16))
        path.lineWidth = 2; path.stroke()
        let circle = NSBezierPath(ovalIn: NSRect(x: 8, y: 8, width: 16, height: 16))
        circle.lineWidth = 2; circle.stroke()
        crosshairImage.unlockFocus()
        let iconImage = NSImageView(frame: NSRect(x: 16, y: 16, width: 32, height: 32))
        iconImage.image = crosshairImage
        iconView.addSubview(iconImage)
        y -= 80

        // App name
        let name = NSTextField(labelWithString: "Vibeliner")
        name.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        name.textColor = .labelColor
        name.alignment = .center
        name.frame = NSRect(x: 0, y: y, width: frame.width, height: 24)
        addSubview(name)
        y -= 22

        // Version
        let version = NSTextField(labelWithString: "Version 1.0.0")
        version.font = NSFont.systemFont(ofSize: 13)
        version.textColor = .secondaryLabelColor
        version.alignment = .center
        version.frame = NSRect(x: 0, y: y, width: frame.width, height: 18)
        addSubview(version)
        y -= 36

        // Links
        for title in ["GitHub Repository", "Report an Issue", "Documentation"] {
            let btn = NSButton(title: title, target: self, action: #selector(linkClicked(_:)))
            btn.isBordered = false
            btn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            btn.contentTintColor = purpleAccent
            btn.frame = NSRect(x: (frame.width - 160) / 2, y: y, width: 160, height: 20)
            addSubview(btn)
            y -= 24
        }
        y -= 12

        // Tagline
        let tagline = NSTextField(labelWithString: "Made for developers shipping with AI tools.")
        tagline.font = NSFont.systemFont(ofSize: 11)
        tagline.textColor = .tertiaryLabelColor
        tagline.alignment = .center
        tagline.frame = NSRect(x: 0, y: y, width: frame.width, height: 16)
        addSubview(tagline)
    }

    @objc private func linkClicked(_ sender: NSButton) {
        let urls: [String: String] = [
            "GitHub Repository": "https://github.com/janaj2g-hub/vibeliner",
            "Report an Issue": "https://github.com/janaj2g-hub/vibeliner/issues",
            "Documentation": "https://github.com/janaj2g-hub/vibeliner#readme"
        ]
        if let urlStr = urls[sender.title], let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }
}
