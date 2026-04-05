import AppKit

final class AboutTabView: NSView {

    private let contentStack = NSStackView()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {

        contentStack.orientation = .vertical
        contentStack.alignment = .centerX
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 54),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.settingsContentPadding),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.settingsContentPadding),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -DesignTokens.settingsContentPadding)
        ])

        let iconView = NSView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.wantsLayer = true
        iconView.layer?.backgroundColor = DesignTokens.red.cgColor
        iconView.layer?.cornerRadius = 16
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64)
        ])
        contentStack.addArrangedSubview(iconView)

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
        let iconImage = NSImageView()
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconImage.image = crosshairImage
        iconView.addSubview(iconImage)
        NSLayoutConstraint.activate([
            iconImage.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImage.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 32),
            iconImage.heightAnchor.constraint(equalToConstant: 32)
        ])

        let name = NSTextField(labelWithString: "Vibeliner")
        name.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        name.textColor = .labelColor
        name.alignment = .center
        contentStack.addArrangedSubview(name)

        let version = NSTextField(labelWithString: "Version 1.0.0")
        version.font = NSFont.systemFont(ofSize: 13)
        version.textColor = .secondaryLabelColor
        version.alignment = .center
        contentStack.addArrangedSubview(version)

        let linksStack = NSStackView()
        linksStack.orientation = .vertical
        linksStack.alignment = .centerX
        linksStack.spacing = 8
        linksStack.translatesAutoresizingMaskIntoConstraints = false

        for title in ["GitHub Repository", "Report an Issue", "Documentation"] {
            let btn = NSButton(title: title, target: self, action: #selector(linkClicked(_:)))
            btn.isBordered = false
            btn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            btn.contentTintColor = DesignTokens.settingsPillText
            btn.setButtonType(.momentaryPushIn)
            btn.focusRingType = .none
            linksStack.addArrangedSubview(btn)
        }
        contentStack.addArrangedSubview(linksStack)

        let tagline = NSTextField(labelWithString: "Made for developers shipping with AI tools.")
        tagline.font = NSFont.systemFont(ofSize: 11)
        tagline.textColor = .tertiaryLabelColor
        tagline.alignment = .center
        contentStack.addArrangedSubview(tagline)
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
