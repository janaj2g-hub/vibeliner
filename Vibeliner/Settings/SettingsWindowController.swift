import AppKit

final class SettingsWindowController: NSWindowController {

    private var tabButtons: [NSButton] = []
    private var tabViews: [NSView] = []
    private var contentContainer = NSView()
    private var activeTabIndex = 0

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Vibeliner Settings"
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        setupTabs()
    }

    private func setupTabs() {
        guard let contentView = window?.contentView else { return }

        let tabBar = NSView(frame: NSRect(x: 0, y: 440, width: 540, height: 40))

        let tabNames = ["General", "Prompt", "About"]
        let tabWidth: CGFloat = 80
        let startX = (540 - tabWidth * CGFloat(tabNames.count)) / 2

        for (i, name) in tabNames.enumerated() {
            let btn = NSButton(title: name, target: self, action: #selector(tabClicked(_:)))
            btn.bezelStyle = .inline
            btn.isBordered = false
            btn.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            btn.tag = i
            btn.frame = NSRect(x: startX + CGFloat(i) * tabWidth, y: 8, width: tabWidth, height: 24)
            tabBar.addSubview(btn)
            tabButtons.append(btn)
        }
        contentView.addSubview(tabBar)

        // Divider
        let divider = NSView(frame: NSRect(x: 0, y: 440, width: 540, height: 0.5))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor(white: 0.9, alpha: 1).cgColor
        contentView.addSubview(divider)

        // Content container
        contentContainer.frame = NSRect(x: 0, y: 0, width: 540, height: 440)
        contentView.addSubview(contentContainer)

        // Create tab views
        let generalTab = GeneralTabView(frame: NSRect(origin: .zero, size: NSSize(width: 540, height: 440)))
        let promptTab = PromptTabView(frame: NSRect(origin: .zero, size: NSSize(width: 540, height: 440)))
        let aboutTab = AboutTabView(frame: NSRect(origin: .zero, size: NSSize(width: 540, height: 440)))
        tabViews = [generalTab, promptTab, aboutTab]

        selectTab(0)
    }

    @objc private func tabClicked(_ sender: NSButton) {
        selectTab(sender.tag)
    }

    private func selectTab(_ index: Int) {
        activeTabIndex = index
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        let view = tabViews[index]
        view.frame = contentContainer.bounds
        contentContainer.addSubview(view)

        for (i, btn) in tabButtons.enumerated() {
            btn.contentTintColor = i == index ? NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1) : NSColor(white: 0.5, alpha: 1)
        }
    }
}
