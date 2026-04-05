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

    private func setupTabs() {
        guard let contentView = window?.contentView else { return }

        // Use Auto Layout for the entire window content
        contentView.wantsLayer = true

        let tabBarHeight: CGFloat = 36

        // --- Tab bar ---
        let tabBar = NSView()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabBar)

        tabDefinitions = [
            TabDefinition(title: "General", makeView: { GeneralTabView() }),
            TabDefinition(title: "Prompt", makeView: { PromptTabView() }),
            TabDefinition(title: "About", makeView: { AboutTabView() }),
        ]

        let tabWidth: CGFloat = 96

        // Use a centering container for tab buttons
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

        for (index, definition) in tabDefinitions.enumerated() {
            let buttonContainer = NSView()
            buttonContainer.translatesAutoresizingMaskIntoConstraints = false

            let button = NSButton(title: definition.title, target: self, action: #selector(tabClicked(_:)))
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

        // --- Auto Layout for all three regions ---
        NSLayoutConstraint.activate([
            // Tab bar: pinned to top
            tabBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: tabBarHeight),

            // Divider: just below tab bar
            divider.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            // Content container: fills remaining space
            contentContainer.topAnchor.constraint(equalTo: divider.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

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
            tabView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
        ])

        for (buttonIndex, button) in tabButtons.enumerated() {
            let isActive = buttonIndex == index
            button.contentTintColor = isActive ? DesignTokens.purpleLight : .secondaryLabelColor
            tabUnderlines[buttonIndex].isHidden = !isActive
        }
    }
}
