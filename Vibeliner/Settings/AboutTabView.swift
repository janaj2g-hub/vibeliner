import AppKit

final class AboutTabView: NSView {

    private let contentStack = NSStackView()
    private let versionLabel = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
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

        // VIB-342: Use real app icon instead of red placeholder
        let iconImage = NSImageView()
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        iconImage.image = NSApp.applicationIconImage
        iconImage.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            iconImage.widthAnchor.constraint(equalToConstant: 64),
            iconImage.heightAnchor.constraint(equalToConstant: 64)
        ])
        contentStack.addArrangedSubview(iconImage)

        let name = NSTextField(labelWithString: "Vibeliner")
        name.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        name.textColor = .labelColor
        name.alignment = .center
        contentStack.addArrangedSubview(name)

        versionLabel.stringValue = bundleVersionString()
        versionLabel.font = NSFont.systemFont(ofSize: 13)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center
        contentStack.addArrangedSubview(versionLabel)

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
            "Documentation": "https://github.com/janaj2g-hub/vibeliner/blob/main/docs/VIBELINER_PRD.md"
        ]
        if let urlStr = urls[sender.title], let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }

    private func bundleVersionString() -> String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (shortVersion, buildVersion) {
        case let (short?, build?) where !build.isEmpty && build != short:
            return "Version \(short) (\(build))"
        case let (short?, _):
            return "Version \(short)"
        case let (_, build?) where !build.isEmpty:
            return "Version \(build)"
        default:
            return "Version —"
        }
    }
}
