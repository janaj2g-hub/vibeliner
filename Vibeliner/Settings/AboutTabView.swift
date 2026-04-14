import AppKit
import CoreText

final class AboutTabView: NSView {

    // MARK: - UI elements

    private let contentStack = NSStackView()
    private let wordmarkLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let linksStack = NSStackView()
    private let versionLabel = NSTextField(labelWithString: "")
    private let taglineLabel = NSTextField(labelWithString: "")
    private let cursorView = NSView()

    // MARK: - Typing animation state

    private let taglineFullText = "made with ❤ for AI creators"
    private var typingTimer: Timer?
    private var cursorBlinkTimer: Timer?
    private var charIndex = 0
    private var cursorVisible = true

    // MARK: - Appearance-aware colors (no new tokens)

    private static let subtitleColor = DesignTokens.dynamicColor(
        dark: NSColor(white: 1, alpha: 0.22),
        light: NSColor(white: 0, alpha: 0.32)
    )
    private static let versionColor = DesignTokens.dynamicColor(
        dark: NSColor(white: 1, alpha: 0.16),
        light: NSColor(white: 0, alpha: 0.30)
    )
    private static let taglineColor = DesignTokens.dynamicColor(
        dark: NSColor(white: 1, alpha: 0.18),
        light: NSColor(white: 0, alpha: 0.35)
    )
    private static let cursorColor = DesignTokens.dynamicColor(
        dark: NSColor(white: 1, alpha: 0.35),
        light: NSColor(white: 0, alpha: 0.30)
    )
    private static let linkColor = DesignTokens.dynamicColor(
        dark: DesignTokens.purpleLight,
        light: DesignTokens.purpleDark
    )

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        Self.registerJersey25IfNeeded()
        buildLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:)") }

    // MARK: - Font registration (belt-and-suspenders: Info.plist + programmatic)

    private static var fontRegistered = false
    private static func registerJersey25IfNeeded() {
        guard !fontRegistered else { return }
        fontRegistered = true
        if let url = Bundle.main.url(forResource: "Jersey25-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static func jersey25(size: CGFloat) -> NSFont {
        // Try known PostScript names for Jersey 25
        for name in ["Jersey25-Regular", "Jersey 25", "Jersey25"] {
            if let font = NSFont(name: name, size: size) { return font }
        }
        // Fallback to system bold
        return NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
    }

    // MARK: - Layout

    private func buildLayout() {
        // Ensure this view fills the scroll clip area so centerY works.
        // Settings window content is ~660px visible (740 - 40 tab bar - 40 chrome).
        heightAnchor.constraint(greaterThanOrEqualToConstant: 560).isActive = true

        contentStack.orientation = .vertical
        contentStack.alignment = .centerX
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
        ])

        // ── Element 1: Logo wordmark ──
        wordmarkLabel.stringValue = "vibeliner"
        wordmarkLabel.font = Self.jersey25(size: 42)
        wordmarkLabel.textColor = DesignTokens.red
        wordmarkLabel.alignment = .center
        contentStack.addArrangedSubview(wordmarkLabel)
        contentStack.setCustomSpacing(6, after: wordmarkLabel)

        // ── Element 2: Subtitle ──
        subtitleLabel.attributedStringValue = NSAttributedString(
            string: "SCREENSHOT · ANNOTATE · PROMPT",
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .medium),
                .foregroundColor: Self.subtitleColor,
                .kern: 0.5 as NSNumber,
            ]
        )
        subtitleLabel.alignment = .center
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.setCustomSpacing(24, after: subtitleLabel)

        // ── Element 3: Links row ──
        linksStack.orientation = .horizontal
        linksStack.spacing = 16
        linksStack.alignment = .centerY
        linksStack.translatesAutoresizingMaskIntoConstraints = false

        for title in ["github", "issues", "docs"] {
            let btn = NSButton(title: title, target: self, action: #selector(linkClicked(_:)))
            btn.isBordered = false
            btn.font = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .medium)
            btn.contentTintColor = Self.linkColor
            btn.setButtonType(.momentaryPushIn)
            btn.focusRingType = .none
            linksStack.addArrangedSubview(btn)
        }
        contentStack.addArrangedSubview(linksStack)
        contentStack.setCustomSpacing(28, after: linksStack)

        // ── Element 4: Version ──
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        versionLabel.stringValue = "v\(version)"
        versionLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        versionLabel.textColor = Self.versionColor
        versionLabel.alignment = .center
        contentStack.addArrangedSubview(versionLabel)
        contentStack.setCustomSpacing(10, after: versionLabel)

        // ── Element 5: Typing tagline with cursor ──
        let taglineRow = NSView()
        taglineRow.translatesAutoresizingMaskIntoConstraints = false

        taglineLabel.stringValue = ""
        taglineLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        taglineLabel.textColor = Self.taglineColor
        taglineLabel.alignment = .natural
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        taglineRow.addSubview(taglineLabel)

        cursorView.wantsLayer = true
        cursorView.layer?.backgroundColor = Self.cursorColor.cgColor
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

    // MARK: - Visibility — reset animation on tab switch

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
        cursorView.layer?.backgroundColor = Self.cursorColor.cgColor
    }

    // MARK: - Typing animation

    private func resetAndStartTyping() {
        stopAllTimers()
        charIndex = 0
        taglineLabel.stringValue = ""
        cursorVisible = true
        cursorView.isHidden = false

        // 600ms delay before first character
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
            self?.typeNextChar()
        }
    }

    private func typeNextChar() {
        guard charIndex < taglineFullText.count else {
            startCursorBlink()
            return
        }

        let idx = taglineFullText.index(taglineFullText.startIndex, offsetBy: charIndex)
        charIndex += 1

        let typed = String(taglineFullText[taglineFullText.startIndex...idx])
        taglineLabel.attributedStringValue = styledTagline(typed)

        // Randomize delay: spaces slightly slower
        let currentChar = taglineFullText[idx]
        let delay: Double = currentChar == " "
            ? Double.random(in: 0.06...0.09)
            : Double.random(in: 0.04...0.08)

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

    // MARK: - Link clicks

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
