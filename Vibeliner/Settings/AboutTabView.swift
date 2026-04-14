import AppKit
import CoreText

final class AboutTabView: NSView {

    // MARK: - UI elements

    private let contentStack = NSStackView()
    private let wordmark = NSTextField(labelWithString: "")
    private let subtitle = NSTextField(labelWithString: "")
    private let linksStack = NSStackView()
    private let versionLabel = NSTextField(labelWithString: "")
    private let taglineLabel = NSTextField(labelWithString: "")
    private let cursorView = NSView()

    // MARK: - Typing animation state

    private let taglineText = "made with ❤ for AI creators"
    private var typingTimer: Timer?
    private var cursorBlinkTimer: Timer?
    private var charIndex = 0
    private var cursorVisible = true

    // MARK: - Colors (inline dynamic, no new tokens per constraints)

    private static let subtitleColor = NSColor(name: nil) { a in
        DesignTokens.isDarkAppearance(a)
            ? NSColor(white: 1, alpha: 0.22)
            : NSColor(white: 0, alpha: 0.32)
    }
    private static let versionColor = NSColor(name: nil) { a in
        DesignTokens.isDarkAppearance(a)
            ? NSColor(white: 1, alpha: 0.16)
            : NSColor(white: 0, alpha: 0.30)
    }
    private static let taglineColor = NSColor(name: nil) { a in
        DesignTokens.isDarkAppearance(a)
            ? NSColor(white: 1, alpha: 0.18)
            : NSColor(white: 0, alpha: 0.35)
    }
    private static let linkColor = NSColor(name: nil) { a in
        DesignTokens.isDarkAppearance(a)
            ? DesignTokens.purpleLight
            : DesignTokens.purpleDark
    }

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        Self.registerJersey25IfNeeded()
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:)") }

    // MARK: - Font registration

    private static var fontRegistered = false
    private static func registerJersey25IfNeeded() {
        guard !fontRegistered else { return }
        fontRegistered = true
        if let url = Bundle.main.url(forResource: "Jersey25-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private func jersey25(size: CGFloat) -> NSFont {
        NSFont(name: "Jersey25-Regular", size: size)
            ?? NSFont.systemFont(ofSize: size, weight: .bold)
    }

    // MARK: - Layout

    private func setupView() {
        contentStack.orientation = .vertical
        contentStack.alignment = .centerX
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
        ])

        // -- Wordmark --
        wordmark.font = jersey25(size: 42)
        wordmark.textColor = DesignTokens.red
        wordmark.alignment = .center
        wordmark.stringValue = "vibeliner"
        contentStack.addArrangedSubview(wordmark)
        contentStack.setCustomSpacing(6, after: wordmark)

        // -- Subtitle --
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
            .foregroundColor: Self.subtitleColor,
            .kern: 0.5,
        ]
        subtitle.attributedStringValue = NSAttributedString(
            string: "SCREENSHOT · ANNOTATE · PROMPT",
            attributes: subtitleAttrs
        )
        subtitle.alignment = .center
        contentStack.addArrangedSubview(subtitle)
        contentStack.setCustomSpacing(24, after: subtitle)

        // -- Links --
        linksStack.orientation = .horizontal
        linksStack.spacing = 16
        linksStack.alignment = .centerY
        linksStack.translatesAutoresizingMaskIntoConstraints = false

        let linkTitles = ["github", "issues", "docs"]
        for title in linkTitles {
            let btn = AboutLinkButton(title: title, target: self, action: #selector(linkClicked(_:)))
            linksStack.addArrangedSubview(btn)
        }
        contentStack.addArrangedSubview(linksStack)
        contentStack.setCustomSpacing(28, after: linksStack)

        // -- Version --
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        versionLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        versionLabel.textColor = Self.versionColor
        versionLabel.alignment = .center
        versionLabel.stringValue = "v\(version)"
        contentStack.addArrangedSubview(versionLabel)
        contentStack.setCustomSpacing(10, after: versionLabel)

        // -- Tagline row (text + cursor) --
        let taglineRow = NSView()
        taglineRow.translatesAutoresizingMaskIntoConstraints = false

        taglineLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        taglineLabel.textColor = Self.taglineColor
        taglineLabel.alignment = .natural
        taglineLabel.stringValue = ""
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineRow.addSubview(taglineLabel)

        cursorView.wantsLayer = true
        cursorView.layer?.backgroundColor = Self.taglineColor.cgColor
        cursorView.translatesAutoresizingMaskIntoConstraints = false
        taglineRow.addSubview(cursorView)

        NSLayoutConstraint.activate([
            taglineLabel.leadingAnchor.constraint(equalTo: taglineRow.leadingAnchor),
            taglineLabel.centerYAnchor.constraint(equalTo: taglineRow.centerYAnchor),
            cursorView.leadingAnchor.constraint(equalTo: taglineLabel.trailingAnchor, constant: 1),
            cursorView.centerYAnchor.constraint(equalTo: taglineRow.centerYAnchor),
            cursorView.widthAnchor.constraint(equalToConstant: 6),
            cursorView.heightAnchor.constraint(equalToConstant: 11),
            taglineRow.trailingAnchor.constraint(greaterThanOrEqualTo: cursorView.trailingAnchor),
            taglineRow.heightAnchor.constraint(equalToConstant: 16),
        ])

        contentStack.addArrangedSubview(taglineRow)
    }

    // MARK: - Visibility handling

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if superview != nil {
            resetAndStartTyping()
        } else {
            stopAllTimers()
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        cursorView.layer?.backgroundColor = Self.taglineColor.cgColor
    }

    // MARK: - Typing animation

    private func resetAndStartTyping() {
        stopAllTimers()
        charIndex = 0
        taglineLabel.stringValue = ""
        cursorVisible = true
        cursorView.isHidden = false

        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
            self?.typeNextChar()
        }
    }

    private func typeNextChar() {
        guard charIndex < taglineText.count else {
            startCursorBlink()
            return
        }

        let idx = taglineText.index(taglineText.startIndex, offsetBy: charIndex)
        charIndex += 1

        // Build attributed string with red heart
        let typed = String(taglineText[taglineText.startIndex...idx])
        taglineLabel.attributedStringValue = styledTagline(typed)

        let delay = Double.random(in: 0.04...0.08)
        typingTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.typeNextChar()
        }
    }

    private func styledTagline(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
                .foregroundColor: Self.taglineColor,
            ]
        )
        // Color the heart red
        let nsText = text as NSString
        let heartRange = nsText.range(of: "❤")
        if heartRange.location != NSNotFound {
            result.addAttribute(.foregroundColor, value: DesignTokens.red, range: heartRange)
        }
        return result
    }

    private func startCursorBlink() {
        cursorBlinkTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.cursorVisible.toggle()
            self.cursorView.isHidden = !self.cursorVisible
        }
    }

    private func stopAllTimers() {
        typingTimer?.invalidate()
        typingTimer = nil
        cursorBlinkTimer?.invalidate()
        cursorBlinkTimer = nil
    }

    // MARK: - Link handling

    @objc private func linkClicked(_ sender: NSButton) {
        let urls: [String: String] = [
            "github": "https://github.com/janaj2g-hub/vibeliner",
            "issues": "https://github.com/janaj2g-hub/vibeliner/issues",
            "docs": "https://github.com/janaj2g-hub/vibeliner/blob/main/docs/VIBELINER_PRD.md",
        ]
        if let urlStr = urls[sender.title], let url = URL(string: urlStr) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Link button with hover

private final class AboutLinkButton: NSButton {

    private var trackingRef: NSTrackingArea?
    private var isHovered = false

    init(title: String, target: AnyObject?, action: Selector) {
        super.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        font = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)
        contentTintColor = Self.linkNormalColor
        setButtonType(.momentaryPushIn)
        focusRingType = .none

        let cursor = NSCursor.pointingHand
        addCursorRect(bounds, cursor: cursor)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:)") }

    private static let linkNormalColor = NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1.0)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)
    }

    private static let linkHoverColor = NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 1.0)
            : NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingRef { removeTrackingArea(t) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self)
        addTrackingArea(area)
        trackingRef = area
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        let underlined = NSMutableAttributedString(string: title, attributes: [
            .font: font ?? NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular),
            .foregroundColor: Self.linkHoverColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ])
        attributedTitle = underlined
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        let plain = NSMutableAttributedString(string: title, attributes: [
            .font: font ?? NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular),
            .foregroundColor: Self.linkNormalColor,
        ])
        attributedTitle = plain
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
