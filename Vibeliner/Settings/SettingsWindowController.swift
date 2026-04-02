import AppKit

final class SettingsWindowController: NSWindowController {

    private var tabButtons: [NSButton] = []
    private var tabUnderlines: [NSView] = []
    private var tabViews: [NSView] = []
    private var contentContainer = NSView()
    private var activeTabIndex = 0

    private let purpleAccent = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 700),  // VIB-163: Min 700px so everything fits
            styleMask: [.titled, .closable, .miniaturizable],
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

        let tabBarHeight: CGFloat = 36
        let tabBar = NSView(frame: NSRect(x: 0, y: 480 - tabBarHeight, width: 540, height: tabBarHeight))

        let tabNames = ["General", "Prompt", "About"]
        let tabWidth: CGFloat = 80
        let startX = (540 - tabWidth * CGFloat(tabNames.count)) / 2

        for (i, name) in tabNames.enumerated() {
            let btn = NSButton(title: name, target: self, action: #selector(tabClicked(_:)))
            btn.isBordered = false
            btn.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            btn.tag = i
            btn.frame = NSRect(x: startX + CGFloat(i) * tabWidth, y: 6, width: tabWidth, height: 24)
            tabBar.addSubview(btn)
            tabButtons.append(btn)

            // Underline
            let underline = NSView(frame: NSRect(x: startX + CGFloat(i) * tabWidth + 10, y: 2, width: tabWidth - 20, height: 2))
            underline.wantsLayer = true
            underline.layer?.backgroundColor = purpleAccent.cgColor
            underline.layer?.cornerRadius = 1
            underline.isHidden = (i != 0)
            tabBar.addSubview(underline)
            tabUnderlines.append(underline)
        }
        contentView.addSubview(tabBar)

        // Divider below tabs
        let divider = NSView(frame: NSRect(x: 0, y: 480 - tabBarHeight, width: 540, height: 0.5))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        contentView.addSubview(divider)

        // Content container
        let contentHeight = 480 - tabBarHeight - 0.5
        contentContainer.frame = NSRect(x: 0, y: 0, width: 540, height: contentHeight)
        contentView.addSubview(contentContainer)

        // Create tab views
        let generalTab = GeneralTabView(frame: NSRect(origin: .zero, size: NSSize(width: 540, height: contentHeight)))
        let promptTab = PromptTabView(frame: NSRect(origin: .zero, size: NSSize(width: 540, height: contentHeight)))
        let aboutTab = AboutTabView(frame: NSRect(origin: .zero, size: NSSize(width: 540, height: contentHeight)))
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
            let isActive = (i == index)
            btn.contentTintColor = isActive ? purpleAccent : .secondaryLabelColor
            tabUnderlines[i].isHidden = !isActive
        }
    }
}
