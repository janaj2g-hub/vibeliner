import AppKit

final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    // MARK: - State

    private var tabStrip: UnderlineTabStripView?
    private let contentContainer = NSView()
    private var activeTabIndex = -1

    /// Cached tab views — created lazily on first display.
    private var cachedTabViews: [Int: NSView] = [:]
    private var measuredTabSizes: [Int: NSSize] = [:]
    private var preferredContentWidth: CGFloat = SettingsWindowController.defaultContentSize.width
    private var preferredContentHeight: CGFloat = SettingsWindowController.defaultContentSize.height
    private var isApplyingShellSizing = false

    private static let tabBarHeight: CGFloat = 44
    private static let defaultContentSize = NSSize(width: 600, height: 740)
    private static let minimumContentSize = NSSize(width: 520, height: 560)

    // MARK: - Lifecycle

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.defaultContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: true
        )
        window.title = "Vibeliner Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.minSize = Self.minimumContentSize
        window.maxSize = NSSize(width: Self.defaultContentSize.width, height: CGFloat.greatestFiniteMagnitude)
        self.init(window: window)
        window.delegate = self
        buildWindowLayout()
    }

    // MARK: - Layout

    private func buildWindowLayout() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true

        // ── Tab bar with segmented control ──

        let tabBar = NSView()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabBar)

        // VIB-431: Underline-style tab strip
        let strip = UnderlineTabStripView(items: ["General", "Prompt", "About"])
        tabBar.addSubview(strip)
        self.tabStrip = strip

        NSLayoutConstraint.activate([
            strip.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            strip.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            strip.topAnchor.constraint(equalTo: tabBar.topAnchor),
            strip.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor),
        ])

        strip.onSelectionChanged = { [weak self] index in
            self?.selectTab(index)
        }

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

            // VIB-431: Divider is now part of the tab strip
            scrollView.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
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

        // Sync tab strip for programmatic tab switches
        if tabStrip?.selectedIndex != index {
            tabStrip?.setSelectedIndex(index, notify: false)
        }

        applyShellSizing(for: index, tabView: tabView)
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

    private func applyShellSizing(for index: Int, tabView: NSView) {
        guard let window else { return }

        contentContainer.layoutSubtreeIfNeeded()
        tabView.layoutSubtreeIfNeeded()
        measuredTabSizes[index] = tabView.fittingSize

        let currentContentSize = window.contentRect(forFrameRect: window.frame).size
        let targetSize = NSSize(
            width: max(preferredContentWidth, Self.minimumContentSize.width),
            height: max(preferredContentHeight, Self.minimumContentSize.height)
        )

        guard abs(currentContentSize.width - targetSize.width) > 0.5 ||
                abs(currentContentSize.height - targetSize.height) > 0.5 else {
            return
        }

        isApplyingShellSizing = true
        window.setContentSize(targetSize)
        isApplyingShellSizing = false
    }

    func windowDidResize(_ notification: Notification) {
        guard !isApplyingShellSizing, let window else { return }
        let contentSize = window.contentRect(forFrameRect: window.frame).size
        preferredContentWidth = max(Self.minimumContentSize.width, contentSize.width)
        preferredContentHeight = max(Self.minimumContentSize.height, contentSize.height)
    }
}

private final class FlippedDocumentView: NSView {
    override var isFlipped: Bool { true }
}
