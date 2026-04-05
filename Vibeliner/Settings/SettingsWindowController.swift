import AppKit

final class SettingsWindowController: NSWindowController {

    private var tabButtons: [NSButton] = []
    private var tabUnderlines: [NSView] = []
    private var tabViews: [NSView] = []
    private let contentContainer = NSView()
    private var activeTabIndex = 0

    /// Maximum content width so sections stay readable when the window is wide.
    private static let maxContentWidth: CGFloat = 484

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 580),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Vibeliner Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.minSize = NSSize(width: 480, height: 520)
        self.init(window: window)
        setupTabs()
    }

    // MARK: - Setup

    private func setupTabs() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true

        let tabBarHeight: CGFloat = 36

        // --- Tab bar ---
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
            let buttonContainer = NSView()
            buttonContainer.translatesAutoresizingMaskIntoConstraints = false

            let button = NSButton(title: title, target: self, action: #selector(tabClicked(_:)))
            button.isBordered = false
            button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            buttonContainer.addSubview(button)

            let underlineWidth: CGFloat = 56
            let underline = NSView()
            underline.translatesAutoresizingMaskIntoConstraints = false
            underline.wantsLayer = true
            underline.layer?.backgroundColor = DesignTokens.purpleLight.cgColor
            underline.layer?.cornerRadius = 1
            underline.isHidden = index != 0
            buttonContainer.addSubview(underline)

            NSLayoutConstraint.activate([
                buttonContainer.widthAnchor.constraint(equalToConstant: tabWidth),
                buttonContainer.heightAnchor.constraint(equalToConstant: tabBarHeight),
                button.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
                button.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
                underline.centerXAnchor.constraint(equalTo: buttonContainer.centerXAnchor),
                underline.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: -2),
                underline.widthAnchor.constraint(equalToConstant: underlineWidth),
                underline.heightAnchor.constraint(equalToConstant: 2),
            ])

            tabStack.addArrangedSubview(buttonContainer)
            tabButtons.append(button)
            tabUnderlines.append(underline)
        }

        // --- Divider ---
        let divider = NSView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor
        contentView.addSubview(divider)

        // --- Content container ---
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: tabBarHeight),

            divider.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            contentContainer.topAnchor.constraint(equalTo: divider.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // --- Create all tab views once, add them all, show/hide to switch ---
        let generalTab = GeneralTabView()
        let promptTab = PromptTabView()
        let aboutTab = AboutTabView()
        tabViews = [generalTab, promptTab, aboutTab]

        for (index, tabView) in tabViews.enumerated() {
            tabView.translatesAutoresizingMaskIntoConstraints = false
            tabView.isHidden = index != 0
            contentContainer.addSubview(tabView)

            // Centering wrapper: constrain width with max, center horizontally
            let widthFill = tabView.widthAnchor.constraint(equalTo: contentContainer.widthAnchor)
            widthFill.priority = .defaultHigh // 750
            let widthCap = tabView.widthAnchor.constraint(lessThanOrEqualToConstant: Self.maxContentWidth)

            NSLayoutConstraint.activate([
                tabView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
                tabView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
                tabView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
                widthFill,
                widthCap,
            ])
        }

        selectTab(0)
    }

    // MARK: - Tab switching

    @objc private func tabClicked(_ sender: NSButton) {
        selectTab(sender.tag)
    }

    private func selectTab(_ index: Int) {
        guard index >= 0, index < tabViews.count else { return }

        // Hide all, show selected
        for (i, tabView) in tabViews.enumerated() {
            tabView.isHidden = i != index
        }
        activeTabIndex = index

        // Update tab bar styling
        for (buttonIndex, button) in tabButtons.enumerated() {
            let isActive = buttonIndex == index
            button.contentTintColor = isActive ? DesignTokens.purpleLight : .secondaryLabelColor
            tabUnderlines[buttonIndex].isHidden = !isActive
        }
    }
}
