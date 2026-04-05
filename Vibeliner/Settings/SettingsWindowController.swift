import AppKit

final class SettingsWindowController: NSWindowController {

    // MARK: - State

    private var tabButtons: [NSButton] = []
    private var tabUnderlines: [NSView] = []
    private let contentContainer = NSView()
    private var activeTabIndex = -1

    /// Cached tab views — created lazily on first display.
    private var cachedTabViews: [Int: NSView] = [:]

    private static let tabBarHeight: CGFloat = 36

    // MARK: - Lifecycle

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 740),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: true
        )
        window.title = "Vibeliner Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.minSize = NSSize(width: 520, height: 560)
        self.init(window: window)
        buildWindowLayout()
    }

    // MARK: - Layout

    private func buildWindowLayout() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true

        // ── Tab bar ──

        let tabBar = NSView()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabBar)

        let tabTitles = ["General", "Prompt", "About"]
        let tabWidth: CGFloat = 96

        let tabStack = NSStackView()
        tabStack.orientation = .horizontal
        tabStack.alignment = .centerY
        tabStack.spacing = 0
        tabStack.translatesAutoresizingMaskIntoConstraints = false
        tabBar.addSubview(tabStack)

        NSLayoutConstraint.activate([
            tabStack.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor),
            tabStack.centerYAnchor.constraint(equalTo: tabBar.centerYAnchor),
        ])

        for (index, title) in tabTitles.enumerated() {
            let container = NSView()
            container.translatesAutoresizingMaskIntoConstraints = false

            let button = NSButton(title: title, target: self, action: #selector(tabClicked(_:)))
            button.isBordered = false
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(button)

            let underline = NSView()
            underline.translatesAutoresizingMaskIntoConstraints = false
            underline.wantsLayer = true
            underline.layer?.backgroundColor = DesignTokens.purpleLight.cgColor
            underline.layer?.cornerRadius = 1
            underline.isHidden = true
            container.addSubview(underline)

            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: tabWidth),
                container.heightAnchor.constraint(equalToConstant: Self.tabBarHeight),
                button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                underline.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                underline.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
                underline.widthAnchor.constraint(equalToConstant: 56),
                underline.heightAnchor.constraint(equalToConstant: 2),
            ])

            tabStack.addArrangedSubview(container)
            tabButtons.append(button)
            tabUnderlines.append(underline)
        }

        // ── Divider ──

        let divider = NSView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        contentView.addSubview(divider)

        // ── Scroll view wrapping the content area ──

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.borderType = .noBorder
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsetsZero
        contentView.addSubview(scrollView)

        let documentView = FlippedDocumentView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        // Content container fills the document view (no max-width cap —
        // the window padding inside each tab provides the visual inset,
        // so the edit frame stays concentric with the window at any size)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: Self.tabBarHeight),

            divider.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            scrollView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        let clipView = scrollView.contentView
        NSLayoutConstraint.activate([
            documentView.topAnchor.constraint(equalTo: clipView.topAnchor),
            documentView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
        ])

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: documentView.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
        ])

        selectTab(0)
    }

    // MARK: - Tab switching

    @objc private func tabClicked(_ sender: NSButton) {
        selectTab(sender.tag)
    }

    private func selectTab(_ index: Int) {
        guard index >= 0, index < 3, index != activeTabIndex else { return }

        if let oldView = cachedTabViews[activeTabIndex] {
            oldView.removeFromSuperview()
        }

        activeTabIndex = index

        let tabView: NSView
        if let cached = cachedTabViews[index] {
            tabView = cached
        } else {
            tabView = createTabView(for: index)
            cachedTabViews[index] = tabView
        }

        tabView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(tabView)
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            tabView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            tabView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])

        if let scrollView = contentContainer.enclosingScrollView,
           let documentView = scrollView.documentView {
            documentView.scroll(.zero)
        }

        for (i, button) in tabButtons.enumerated() {
            let active = i == index
            button.contentTintColor = active ? DesignTokens.purpleLight : .secondaryLabelColor
            tabUnderlines[i].isHidden = !active
        }
    }

    private func createTabView(for index: Int) -> NSView {
        switch index {
        case 0:
            return GeneralTabView()
        case 1:
            let prompt = PromptTabView()
            DispatchQueue.main.async {
                prompt.loadContent()
            }
            return prompt
        case 2:
            return AboutTabView()
        default:
            return NSView()
        }
    }
}

private final class FlippedDocumentView: NSView {
    override var isFlipped: Bool { true }
}
