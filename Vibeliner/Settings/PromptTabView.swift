import AppKit

final class PromptTabView: NSView {

    private var subTabButtons: [NSButton] = []
    private var subTabUnderlines: [NSView] = []
    private var preambleEditor: NSTextView!
    private var footerEditor: NSTextView!
    private var toolFields: [String: NSTextField] = [:]
    private var contentContainer = NSView()
    private var previewView: PromptPreviewView!
    private let subTabNames = ["Preamble", "Tool descriptions", "Footer"]
    private var activeSubTab = 0
    private let purpleAccent = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        let tabBarY = frame.height - 30
        let tabWidth: CGFloat = 120
        let startX = (frame.width - tabWidth * CGFloat(subTabNames.count)) / 2

        for (i, name) in subTabNames.enumerated() {
            let btn = NSButton(title: name, target: self, action: #selector(subTabClicked(_:)))
            btn.isBordered = false
            btn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            btn.tag = i
            btn.frame = NSRect(x: startX + CGFloat(i) * tabWidth, y: tabBarY, width: tabWidth, height: 22)
            addSubview(btn)
            subTabButtons.append(btn)

            let underline = NSView(frame: NSRect(x: startX + CGFloat(i) * tabWidth + 10, y: tabBarY - 2, width: tabWidth - 20, height: 2))
            underline.wantsLayer = true
            underline.layer?.backgroundColor = purpleAccent.cgColor
            underline.layer?.cornerRadius = 1
            underline.isHidden = (i != 0)
            addSubview(underline)
            subTabUnderlines.append(underline)
        }

        // Divider below sub-tabs
        let div = NSView(frame: NSRect(x: 0, y: tabBarY - 4, width: frame.width, height: 0.5))
        div.wantsLayer = true
        div.layer?.backgroundColor = NSColor.separatorColor.cgColor
        addSubview(div)

        contentContainer.frame = NSRect(x: 28, y: 200, width: frame.width - 56, height: tabBarY - 212)
        addSubview(contentContainer)

        // Preview divider
        let previewDiv = NSView(frame: NSRect(x: 28, y: 194, width: frame.width - 56, height: 0.5))
        previewDiv.wantsLayer = true
        previewDiv.layer?.backgroundColor = NSColor.separatorColor.cgColor
        addSubview(previewDiv)

        previewView = PromptPreviewView(frame: NSRect(x: 28, y: 10, width: frame.width - 56, height: 180))
        addSubview(previewView)

        selectSubTab(0)
    }

    @objc private func subTabClicked(_ sender: NSButton) { selectSubTab(sender.tag) }

    private func selectSubTab(_ index: Int) {
        activeSubTab = index
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        for (i, btn) in subTabButtons.enumerated() {
            let isActive = (i == index)
            btn.contentTintColor = isActive ? purpleAccent : .secondaryLabelColor
            subTabUnderlines[i].isHidden = !isActive
        }
        switch index {
        case 0: showPreambleEditor()
        case 1: showToolDescriptions()
        case 2: showFooterEditor()
        default: break
        }
    }

    private func showPreambleEditor() {
        let w = contentContainer.bounds.width
        let desc = makeDescription("Text before the annotation list. [Screenshot Path] inserts the image path. [Tool Description] auto-generates based on tools used.")
        desc.frame = NSRect(x: 0, y: contentContainer.bounds.height - 36, width: w, height: 32)
        contentContainer.addSubview(desc)

        let scrollView = makeScrollableEditor(text: ConfigManager.shared.preamble, height: contentContainer.bounds.height - 80)
        scrollView.frame.origin = NSPoint(x: 0, y: 38)
        contentContainer.addSubview(scrollView)
        preambleEditor = (scrollView.documentView as? NSTextView)

        addSaveResetButtons(onSave: { [weak self] in
            guard let self else { return }
            ConfigManager.shared.preamble = self.preambleEditor.string
            ConfigManager.shared.save()
            self.previewView.refresh()
        }, onReset: { [weak self] in
            let def = "This is a screenshot of my running app. View it at [Screenshot Path]\n\n[Tool Description] Each annotation has a number and a description.\n\nFix each issue:"
            self?.preambleEditor.string = def
            ConfigManager.shared.preamble = def
            ConfigManager.shared.save()
            self?.previewView.refresh()
        })
    }

    private func showToolDescriptions() {
        let w = contentContainer.bounds.width
        let desc = makeDescription("Each tool's description feeds into [Tool Description] when that tool is used.")
        desc.frame = NSRect(x: 0, y: contentContainer.bounds.height - 22, width: w, height: 18)
        contentContainer.addSubview(desc)

        let tools: [(String, String, String)] = [
            ("mappin", "Pin", "pin"),
            ("arrow.right", "Arrow", "arrow"),
            ("rectangle", "Rectangle", "rectangle"),
            ("circle", "Circle", "circle"),
            ("scribble.variable", "Freehand", "freehand"),
        ]
        var y = contentContainer.bounds.height - 56
        toolFields.removeAll()

        for (iconName, name, key) in tools {
            // SF Symbol icon
            if let img = NSImage(systemSymbolName: iconName, accessibilityDescription: name) {
                let iconView = NSImageView(frame: NSRect(x: 0, y: y - 2, width: 20, height: 20))
                iconView.image = img
                iconView.contentTintColor = .secondaryLabelColor
                contentContainer.addSubview(iconView)
            }

            let label = NSTextField(labelWithString: name)
            label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
            label.textColor = .labelColor
            label.frame = NSRect(x: 28, y: y, width: 68, height: 18)
            contentContainer.addSubview(label)

            let field = NSTextField()
            field.stringValue = ConfigManager.shared.toolDescriptions[key] ?? ""
            field.font = NSFont.systemFont(ofSize: 12)
            field.frame = NSRect(x: 100, y: y - 3, width: w - 104, height: 24)
            field.wantsLayer = true
            field.layer?.cornerRadius = 6
            contentContainer.addSubview(field)
            toolFields[key] = field
            y -= 32
        }

        addSaveResetButtons(onSave: { [weak self] in
            guard let self else { return }
            for (key, field) in self.toolFields {
                ConfigManager.shared.toolDescriptions[key] = field.stringValue
            }
            ConfigManager.shared.save()
            self.previewView.refresh()
        }, onReset: { [weak self] in
            let defaults = ["pin": "points to a specific issue", "arrow": "points at or between elements", "rectangle": "highlights a region or container", "circle": "calls out a specific element", "freehand": "marks an irregular area"]
            for (key, val) in defaults {
                self?.toolFields[key]?.stringValue = val
                ConfigManager.shared.toolDescriptions[key] = val
            }
            ConfigManager.shared.save()
            self?.previewView.refresh()
        })
    }

    private func showFooterEditor() {
        let w = contentContainer.bounds.width
        let desc = makeDescription("Text after the annotation list. Leave empty for no footer.")
        desc.frame = NSRect(x: 0, y: contentContainer.bounds.height - 22, width: w, height: 18)
        contentContainer.addSubview(desc)

        let scrollView = makeScrollableEditor(text: ConfigManager.shared.footer, height: contentContainer.bounds.height - 64)
        scrollView.frame.origin = NSPoint(x: 0, y: 38)
        contentContainer.addSubview(scrollView)
        footerEditor = (scrollView.documentView as? NSTextView)

        addSaveResetButtons(onSave: { [weak self] in
            guard let self else { return }
            ConfigManager.shared.footer = self.footerEditor.string
            ConfigManager.shared.save()
            self.previewView.refresh()
        }, onReset: { [weak self] in
            let def = "Make the changes and verify they match the design."
            self?.footerEditor.string = def
            ConfigManager.shared.footer = def
            ConfigManager.shared.save()
            self?.previewView.refresh()
        })
    }

    // MARK: - Helpers

    private func makeDescription(_ text: String) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.font = NSFont.systemFont(ofSize: 11)
        field.textColor = .tertiaryLabelColor
        field.isEditable = false
        field.isBordered = false
        field.drawsBackground = false
        return field
    }

    private func makeScrollableEditor(text: String, height: CGFloat) -> NSScrollView {
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: contentContainer.bounds.width, height: height))
        let textView = NSTextView(frame: NSRect(origin: .zero, size: scrollView.contentSize))
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.string = text
        textView.isRichText = false
        textView.isEditable = true
        textView.textContainerInset = NSSize(width: 8, height: 8)
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.wantsLayer = true
        scrollView.layer?.borderWidth = 1
        scrollView.layer?.borderColor = NSColor.separatorColor.cgColor
        scrollView.layer?.cornerRadius = 8
        return scrollView
    }

    private var _saveAction: (() -> Void)?
    private var _resetAction: (() -> Void)?

    private func addSaveResetButtons(onSave: @escaping () -> Void, onReset: @escaping () -> Void) {
        _saveAction = onSave
        _resetAction = onReset

        let saveBtn = NSButton(title: "Save", target: self, action: #selector(saveAction))
        saveBtn.wantsLayer = true
        saveBtn.isBordered = false
        saveBtn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        saveBtn.contentTintColor = .white
        saveBtn.layer?.backgroundColor = purpleAccent.cgColor
        saveBtn.layer?.cornerRadius = 6
        saveBtn.frame = NSRect(x: 0, y: 6, width: 60, height: 26)
        contentContainer.addSubview(saveBtn)

        let resetBtn = NSButton(title: "Reset to default", target: self, action: #selector(resetAction))
        resetBtn.isBordered = false
        resetBtn.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        resetBtn.contentTintColor = purpleAccent
        resetBtn.frame = NSRect(x: contentContainer.bounds.width - 110, y: 8, width: 110, height: 20)
        contentContainer.addSubview(resetBtn)
    }

    @objc private func saveAction() { _saveAction?() }
    @objc private func resetAction() { _resetAction?() }
}
