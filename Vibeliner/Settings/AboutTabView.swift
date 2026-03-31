import AppKit

final class AboutTabView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        let centerX = frame.width / 2
        var y = frame.height - 60

        // App icon
        let iconView = NSView(frame: NSRect(x: centerX - 32, y: y - 64, width: 64, height: 64))
        iconView.wantsLayer = true
        iconView.layer?.backgroundColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1).cgColor
        iconView.layer?.cornerRadius = 16
        addSubview(iconView)

        // Crosshair on icon
        let iconImage = NSImageView(frame: NSRect(x: 16, y: 16, width: 32, height: 32))
        let crosshairImage = NSImage(size: NSSize(width: 32, height: 32))
        crosshairImage.lockFocus()
        NSColor.white.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 16, y: 6))
        path.line(to: NSPoint(x: 16, y: 26))
        path.move(to: NSPoint(x: 6, y: 16))
        path.line(to: NSPoint(x: 26, y: 16))
        path.lineWidth = 2
        path.stroke()
        let circle = NSBezierPath(ovalIn: NSRect(x: 8, y: 8, width: 16, height: 16))
        circle.lineWidth = 2
        circle.stroke()
        crosshairImage.unlockFocus()
        iconImage.image = crosshairImage
        iconView.addSubview(iconImage)
        y -= 80

        // App name
        let name = NSTextField(labelWithString: "Vibeliner")
        name.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        name.textColor = NSColor(white: 0.2, alpha: 1)
        name.alignment = .center
        name.frame = NSRect(x: 0, y: y, width: frame.width, height: 24)
        addSubview(name)
        y -= 22

        // Version
        let version = NSTextField(labelWithString: "Version 1.0.0")
        version.font = NSFont.systemFont(ofSize: 13)
        version.textColor = NSColor(white: 0.53, alpha: 1)
        version.alignment = .center
        version.frame = NSRect(x: 0, y: y, width: frame.width, height: 18)
        addSubview(version)
        y -= 40

        // Links
        let links = ["GitHub Repository", "Report an Issue", "Documentation"]
        for link in links {
            let btn = NSButton(title: link, target: self, action: #selector(linkClicked(_:)))
            btn.isBordered = false
            btn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            btn.contentTintColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)
            btn.frame = NSRect(x: (frame.width - 160) / 2, y: y, width: 160, height: 20)
            addSubview(btn)
            y -= 24
        }
        y -= 16

        // Tagline
        let tagline = NSTextField(labelWithString: "Made for developers shipping with AI tools.")
        tagline.font = NSFont.systemFont(ofSize: 11)
        tagline.textColor = NSColor(white: 0.73, alpha: 1)
        tagline.alignment = .center
        tagline.frame = NSRect(x: 0, y: y, width: frame.width, height: 16)
        addSubview(tagline)
    }

    @objc private func linkClicked(_ sender: NSButton) {
        // Placeholder — would open URLs
        print("Link clicked: \(sender.title)")
    }
}
