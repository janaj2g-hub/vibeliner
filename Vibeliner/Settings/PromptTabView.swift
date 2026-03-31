import AppKit

final class PromptTabView: NSView {

    private var subTabButtons: [NSButton] = []
    private var preambleEditor: NSTextView!
    private var footerEditor: NSTextView!
    private var toolFields: [String: NSTextField] = [:]
    private var contentContainer = NSView()
    private var previewView: PromptPreviewView!
    private let subTabNames = ["Preamble", "Tool descriptions", "Footer"]
    private var activeSubTab = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        // Sub-tab bar
        let tabBarY = frame.height - 34
        let tabWidth: CGFloat = 120
        let startX = (frame.width - tabWidth * CGFloat(subTabNames.count)) / 2

        for (i, name) in subTabNames.enumerated() {
            let btn = NSButton(title: name, target: self, action: #selector(subTabClicked(_:)))
            btn.bezelStyle = .inline
            btn.isBordered = false
            btn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            btn.tag = i
            btn.frame = NSRect(x: startX + CGFloat(i) * tabWidth, y: tabBarY, width: tabWidth, height: 24)
            addSubview(btn)
            subTabButtons.append(btn)
        }

        // Divider below sub-tabs
        let div = NSView(frame: NSRect(x: 0, y: tabBarY - 4, width: frame.width, height: 0.5))
        div.wantsLayer = true
        div.layer?.backgroundColor = NSColor(white: 0.92, alpha: 1).cgColor
        addSubview(div)

        // Content area
        contentContainer.frame = NSRect(x: 24, y: 200, width: frame.width - 48, height: tabBarY - 210)
        addSubview(contentContainer)

        // Preview at bottom
        previewView = PromptPreviewView(frame: NSRect(x: 24, y: 10, width: frame.width - 48, height: 180))
        addSubview(previewView)

        // Preview divider
        let previewDiv = NSView(frame: NSRect(x: 24, y: 194, width: frame.width - 48, height: 0.5))
        previewDiv.wantsLayer = true
        previewDiv.layer?.backgroundColor = NSColor(white: 0.94, alpha: 1).cgColor
        addSubview(previewDiv)

        selectSubTab(0)
    }

    @objc private func subTabClicked(_ sender: NSButton) {
        selectSubTab(sender.tag)
    }

    private func selectSubTab(_ index: Int) {
        activeSubTab = index
        contentContainer.subviews.forEach { $0.removeFromSuperview() }

        for (i, btn) in subTabButtons.enumerated() {
            btn.contentTintColor = i == index ? NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1) : NSColor(white: 0.6, alpha: 1)
        }

        switch index {
        case 0: showPreambleEditor()
        case 1: showToolDescriptions()
        case 2: showFooterEditor()
        default: break
        }
    }

    private func showPreambleEditor() {
        let desc = NSTextField(wrappingLabelWithString: "Text before the annotation list. [Screenshot Path] inserts the image path. [Tool Description] auto-generates based on tools used.")
        desc.font = NSFont.systemFont(ofSize: 11)
        desc.textColor = NSColor(white: 0.5, alpha: 1)
        desc.isEditable = false
        desc.isBordered = false
        desc.drawsBackground = false
        desc.frame = NSRect(x: 0, y: contentContainer.bounds.height - 40, width: contentContainer.bounds.width, height: 36)
        contentContainer.addSubview(desc)

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 40, width: contentContainer.bounds.width, height: contentContainer.bounds.height - 86))
        let textView = NSTextView(frame: NSRect(origin: .zero, size: scrollView.contentSize))
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.string = ConfigManager.shared.preamble
        textView.isRichText = false
        textView.isEditable = true
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.wantsLayer = true
        scrollView.layer?.borderWidth = 1
        scrollView.layer?.borderColor = NSColor(white: 0.86, alpha: 1).cgColor
        scrollView.layer?.cornerRadius = 8
        contentContainer.addSubview(scrollView)
        preambleEditor = textView

        addSaveResetButtons { [weak self] in
            guard let self else { return }
            ConfigManager.shared.preamble = self.preambleEditor.string
            ConfigManager.shared.save()
            self.previewView.refresh()
        } onReset: { [weak self] in
            self?.preambleEditor.string = "This is a screenshot of my running app. View it at [Screenshot Path]\n\n[Tool Description] Each annotation has a number and a description.\n\nFix each issue:"
            ConfigManager.shared.preamble = self?.preambleEditor.string ?? ""
            ConfigManager.shared.save()
            self?.previewView.refresh()
        }
    }

    private func showToolDescriptions() {
        let desc = NSTextField(wrappingLabelWithString: "Each tool's description feeds into [Tool Description] when that tool is used.")
        desc.font = NSFont.systemFont(ofSize: 11)
        desc.textColor = NSColor(white: 0.5, alpha: 1)
        desc.isEditable = false
        desc.isBordered = false
        desc.drawsBackground = false
        desc.frame = NSRect(x: 0, y: contentContainer.bounds.height - 24, width: contentContainer.bounds.width, height: 20)
        contentContainer.addSubview(desc)

        let tools: [(String, String)] = [
            ("Pin", "pin"), ("Arrow", "arrow"), ("Rectangle", "rectangle"), ("Circle", "circle"), ("Freehand", "freehand")
        ]
        var y = contentContainer.bounds.height - 56

        for (name, key) in tools {
            let label = NSTextField(labelWithString: name)
            label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = NSColor(white: 0.2, alpha: 1)
            label.frame = NSRect(x: 36, y: y, width: 68, height: 20)
            contentContainer.addSubview(label)

            let field = NSTextField()
            field.stringValue = ConfigManager.shared.toolDescriptions[key] ?? ""
            field.font = NSFont.systemFont(ofSize: 12)
            field.frame = NSRect(x: 110, y: y - 2, width: contentContainer.bounds.width - 114, height: 24)
            field.wantsLayer = true
            field.layer?.cornerRadius = 6
            contentContainer.addSubview(field)
            toolFields[key] = field
            y -= 34
        }

        addSaveResetButtons { [weak self] in
            guard let self else { return }
            for (key, field) in self.toolFields {
                ConfigManager.shared.toolDescriptions[key] = field.stringValue
            }
            ConfigManager.shared.save()
            self.previewView.refresh()
        } onReset: { [weak self] in
            let defaults = ["pin": "points to a specific issue", "arrow": "points at or between elements", "rectangle": "highlights a region or container", "circle": "calls out a specific element", "freehand": "marks an irregular area"]
            for (key, val) in defaults {
                self?.toolFields[key]?.stringValue = val
                ConfigManager.shared.toolDescriptions[key] = val
            }
            ConfigManager.shared.save()
            self?.previewView.refresh()
        }
    }

    private func showFooterEditor() {
        let desc = NSTextField(wrappingLabelWithString: "Text after the annotation list. Leave empty for no footer.")
        desc.font = NSFont.systemFont(ofSize: 11)
        desc.textColor = NSColor(white: 0.5, alpha: 1)
        desc.isEditable = false
        desc.isBordered = false
        desc.drawsBackground = false
        desc.frame = NSRect(x: 0, y: contentContainer.bounds.height - 24, width: contentContainer.bounds.width, height: 20)
        contentContainer.addSubview(desc)

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 40, width: contentContainer.bounds.width, height: contentContainer.bounds.height - 70))
        let textView = NSTextView(frame: NSRect(origin: .zero, size: scrollView.contentSize))
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.string = ConfigManager.shared.footer
        textView.isRichText = false
        textView.isEditable = true
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.wantsLayer = true
        scrollView.layer?.borderWidth = 1
        scrollView.layer?.borderColor = NSColor(white: 0.86, alpha: 1).cgColor
        scrollView.layer?.cornerRadius = 8
        contentContainer.addSubview(scrollView)
        footerEditor = textView

        addSaveResetButtons { [weak self] in
            guard let self else { return }
            ConfigManager.shared.footer = self.footerEditor.string
            ConfigManager.shared.save()
            self.previewView.refresh()
        } onReset: { [weak self] in
            self?.footerEditor.string = "Make the changes and verify they match the design."
            ConfigManager.shared.footer = self?.footerEditor.string ?? ""
            ConfigManager.shared.save()
            self?.previewView.refresh()
        }
    }

    private func addSaveResetButtons(onSave: @escaping () -> Void, onReset: @escaping () -> Void) {
        let saveBtn = NSButton(title: "Save", target: nil, action: nil)
        saveBtn.bezelStyle = .rounded
        saveBtn.wantsLayer = true
        saveBtn.contentTintColor = .white
        saveBtn.layer?.backgroundColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1).cgColor
        saveBtn.layer?.cornerRadius = 6
        saveBtn.isBordered = false
        saveBtn.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        saveBtn.frame = NSRect(x: 0, y: 6, width: 60, height: 26)
        saveBtn.target = self
        saveBtn.tag = 100
        contentContainer.addSubview(saveBtn)

        let resetBtn = NSButton(title: "Reset to default", target: nil, action: nil)
        resetBtn.isBordered = false
        resetBtn.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        resetBtn.contentTintColor = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1)
        resetBtn.frame = NSRect(x: contentContainer.bounds.width - 110, y: 8, width: 110, height: 20)
        resetBtn.target = self
        resetBtn.tag = 101
        contentContainer.addSubview(resetBtn)

        // Store closures via objc target/action proxy
        _saveAction = onSave
        _resetAction = onReset
        saveBtn.action = #selector(saveAction)
        resetBtn.action = #selector(resetAction)
    }

    private var _saveAction: (() -> Void)?
    private var _resetAction: (() -> Void)?

    @objc private func saveAction() { _saveAction?() }
    @objc private func resetAction() { _resetAction?() }
}
