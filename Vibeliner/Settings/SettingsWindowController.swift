import AppKit

final class SettingsWindowController: NSWindowController {

    private struct TabDefinition {
        let title: String
        let makeView: () -> NSView
    }

    private var tabButtons: [NSButton] = []
    private var tabUnderlines: [NSView] = []
    private var tabDefinitions: [TabDefinition] = []
    private let contentContainer = NSView()
    private var activeTabIndex = 0

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 580),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Vibeliner Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        self.init(window: window)
        setupTabs()
    }

    private func setupTabs() {
        guard let contentView = window?.contentView else { return }

        let winW = contentView.frame.width
        let winH = contentView.frame.height
        let tabBarHeight: CGFloat = 36
        let tabBarY = winH - tabBarHeight

        let tabBar = NSView(frame: NSRect(x: 0, y: tabBarY, width: winW, height: tabBarHeight))
        contentView.addSubview(tabBar)

        tabDefinitions = [
            TabDefinition(title: "General", makeView: { GeneralTabView(frame: .zero) }),
            TabDefinition(title: "Prompt", makeView: { PromptTabView(frame: .zero) }),
            TabDefinition(title: "About", makeView: { AboutTabView(frame: .zero) }),
        ]

        let tabWidth: CGFloat = 96
        let startX = (winW - (tabWidth * CGFloat(tabDefinitions.count))) / 2

        for (index, definition) in tabDefinitions.enumerated() {
            let button = NSButton(title: definition.title, target: self, action: #selector(tabClicked(_:)))
            button.isBordered = false
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            button.tag = index
            button.frame = NSRect(x: startX + (CGFloat(index) * tabWidth), y: 6, width: tabWidth, height: 24)
            tabBar.addSubview(button)
            tabButtons.append(button)

            let underlineWidth: CGFloat = 56
            let underline = NSView(frame: NSRect(x: button.frame.midX - (underlineWidth / 2), y: 2, width: underlineWidth, height: 2))
            underline.wantsLayer = true
            underline.layer?.backgroundColor = DesignTokens.purpleLight.cgColor
            underline.layer?.cornerRadius = 1
            underline.isHidden = index != 0
            tabBar.addSubview(underline)
            tabUnderlines.append(underline)
        }

        let divider = NSView(frame: NSRect(x: 0, y: tabBarY, width: winW, height: 0.5))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        contentView.addSubview(divider)

        contentContainer.frame = NSRect(x: 0, y: 0, width: winW, height: tabBarY)
        contentContainer.autoresizingMask = [.width, .height]
        contentView.addSubview(contentContainer)

        selectTab(0)
    }

    @objc private func tabClicked(_ sender: NSButton) {
        selectTab(sender.tag)
    }

    private func selectTab(_ index: Int) {
        guard index >= 0, index < tabDefinitions.count else { return }

        activeTabIndex = index
        contentContainer.subviews.forEach { $0.removeFromSuperview() }

        let tabView = tabDefinitions[index].makeView()
        tabView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(tabView)
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            tabView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            tabView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])

        for (buttonIndex, button) in tabButtons.enumerated() {
            let isActive = buttonIndex == index
            button.contentTintColor = isActive ? DesignTokens.purpleLight : .secondaryLabelColor
            tabUnderlines[buttonIndex].isHidden = !isActive
        }
    }
}
