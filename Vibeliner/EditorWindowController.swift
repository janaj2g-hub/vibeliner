import AppKit

class EditorWindowController: NSWindowController, NSWindowDelegate {
    var onCaptureSaved: ((CaptureRecord) -> Void)?
    var onClose: (() -> Void)?
    var onError: ((UserFacingIssue) -> Void)?

    private let capturedImage: NSImage
    private var canvas: AnnotationCanvas!
    private var undoButton: NSButton!
    private var toolButtons: [AnnotationType: NSButton] = [:]
    private var savedRecord: CaptureRecord?
    private var keyEventMonitor: Any?

    private let toolbarColor = NSColor(red: 0.165, green: 0.165, blue: 0.173, alpha: 1.0)
    private let accentBlue = NSColor(red: 0.039, green: 0.518, blue: 1.0, alpha: 1.0)

    init(image: NSImage) {
        capturedImage = image

        let windowSize = EditorWindowController.windowSize(for: image)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.backgroundColor = .black
        panel.center()

        super.init(window: panel)

        panel.delegate = self
        setupContent(in: panel, size: windowSize)
        installEditMenu()
        installKeyEventMonitor()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContent(in panel: NSPanel, size: NSSize) {
        let toolbarHeight: CGFloat = 40
        let contentView = NSView(frame: NSRect(origin: .zero, size: size))

        let toolbar = NSView(frame: NSRect(
            x: 0,
            y: size.height - toolbarHeight,
            width: size.width,
            height: toolbarHeight
        ))
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = toolbarColor.cgColor
        toolbar.autoresizingMask = [.width, .minYMargin]
        contentView.addSubview(toolbar)

        buildToolbarButtons(in: toolbar, toolbarHeight: toolbarHeight)

        canvas = AnnotationCanvas(frame: NSRect(
            x: 0,
            y: 0,
            width: size.width,
            height: size.height - toolbarHeight
        ))
        canvas.backgroundImage = capturedImage
        canvas.autoresizingMask = [.width, .height]
        canvas.onToolChanged = { [weak self] _ in
            self?.updateToolHighlight()
        }
        canvas.onAnnotationsChanged = { [weak self] in
            self?.updateToolHighlight()
        }
        contentView.addSubview(canvas)
        panel.initialFirstResponder = canvas

        panel.contentView = contentView
        updateToolHighlight()
    }

    private func buildToolbarButtons(in toolbar: NSView, toolbarHeight: CGFloat) {
        let buttonSize: CGFloat = 28
        let padding: CGFloat = 8
        var x: CGFloat = padding

        let closeButton = makeIconButton(
            symbolName: "xmark",
            size: buttonSize,
            target: self,
            action: #selector(closeEditor)
        )
        closeButton.frame.origin = CGPoint(x: x, y: (toolbarHeight - buttonSize) / 2)
        toolbar.addSubview(closeButton)
        x += buttonSize + padding

        x = addSeparator(in: toolbar, at: x, height: toolbarHeight)

        let tools: [(AnnotationType, String)] = [
            (.freehand, "pencil.line"),
            (.arrow, "arrow.up.right"),
            (.circle, "circle"),
        ]

        for (tool, symbol) in tools {
            let button = makeIconButton(
                symbolName: symbol,
                size: buttonSize,
                target: self,
                action: #selector(toolSelected(_:))
            )
            button.tag = toolTag(for: tool)
            button.frame.origin = CGPoint(x: x, y: (toolbarHeight - buttonSize) / 2)
            toolbar.addSubview(button)
            toolButtons[tool] = button
            x += buttonSize + 4
        }
        x += padding - 4

        x = addSeparator(in: toolbar, at: x, height: toolbarHeight)

        undoButton = makeIconButton(
            symbolName: "arrow.uturn.backward",
            size: buttonSize,
            target: self,
            action: #selector(undoAction)
        )
        undoButton.frame.origin = CGPoint(x: x, y: (toolbarHeight - buttonSize) / 2)
        undoButton.isEnabled = false
        toolbar.addSubview(undoButton)

        let copyButton = makeTextButton(
            title: "Copy for LLM",
            backgroundColor: accentBlue,
            textColor: .white,
            target: self,
            action: #selector(copyForLLMAction)
        )
        copyButton.frame.origin = CGPoint(
            x: toolbar.bounds.width - copyButton.frame.width - padding,
            y: (toolbarHeight - copyButton.frame.height) / 2
        )
        copyButton.autoresizingMask = [.minXMargin]
        toolbar.addSubview(copyButton)

        let saveButton = makeTextButton(
            title: "Save",
            backgroundColor: NSColor(white: 0.35, alpha: 1.0),
            textColor: .white,
            target: self,
            action: #selector(saveAction)
        )
        saveButton.frame.origin = CGPoint(
            x: copyButton.frame.minX - saveButton.frame.width - 8,
            y: (toolbarHeight - saveButton.frame.height) / 2
        )
        saveButton.autoresizingMask = [.minXMargin]
        toolbar.addSubview(saveButton)

        let trashButton = makeIconButton(
            symbolName: "trash",
            size: buttonSize,
            target: self,
            action: #selector(deleteAction)
        )
        trashButton.contentTintColor = Constants.annotationRed
        trashButton.frame.origin = CGPoint(
            x: saveButton.frame.minX - buttonSize - 12,
            y: (toolbarHeight - buttonSize) / 2
        )
        trashButton.autoresizingMask = [.minXMargin]
        toolbar.addSubview(trashButton)
    }

    private func makeIconButton(symbolName: String, size: CGFloat, target: AnyObject, action: Selector) -> NSButton {
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: size, height: size))
        button.bezelStyle = .inline
        button.isBordered = false
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: symbolName)
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.contentTintColor = .lightGray
        button.target = target
        button.action = action
        button.wantsLayer = true
        return button
    }

    private func makeTextButton(title: String, backgroundColor: NSColor, textColor: NSColor, target: AnyObject, action: Selector) -> NSButton {
        let button = NSButton(frame: .zero)
        button.title = title
        button.bezelStyle = .inline
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        button.wantsLayer = true
        button.layer?.backgroundColor = backgroundColor.cgColor
        button.layer?.cornerRadius = 5
        button.contentTintColor = textColor
        button.target = target
        button.action = action
        button.sizeToFit()
        button.frame.size.width += 16
        button.frame.size.height = 24
        return button
    }

    private func addSeparator(in toolbar: NSView, at x: CGFloat, height: CGFloat) -> CGFloat {
        let separator = NSView(frame: NSRect(x: x, y: 8, width: 1, height: height - 16))
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor(white: 0.5, alpha: 0.4).cgColor
        toolbar.addSubview(separator)
        return x + 1 + 8
    }

    private func toolTag(for tool: AnnotationType) -> Int {
        switch tool {
        case .freehand: return 0
        case .arrow: return 1
        case .circle: return 2
        }
    }

    private func toolForTag(_ tag: Int) -> AnnotationType {
        switch tag {
        case 1: return .arrow
        case 2: return .circle
        default: return .freehand
        }
    }

    private func updateToolHighlight() {
        guard let canvas else {
            for (_, button) in toolButtons {
                button.layer?.backgroundColor = nil
                button.contentTintColor = .lightGray
            }
            undoButton?.isEnabled = false
            return
        }

        for (tool, button) in toolButtons {
            if tool == canvas.currentTool {
                button.layer?.backgroundColor = accentBlue.withAlphaComponent(0.3).cgColor
                button.layer?.cornerRadius = 5
                button.contentTintColor = .white
            } else {
                button.layer?.backgroundColor = nil
                button.contentTintColor = .lightGray
            }
        }

        undoButton.isEnabled = !canvas.annotations.isEmpty
    }

    @objc private func toolSelected(_ sender: NSButton) {
        canvas.finalizeActiveTextField()
        canvas.currentTool = toolForTag(sender.tag)
        updateToolHighlight()
    }

    @objc private func undoAction() {
        canvas.undoLastAnnotation()
        updateToolHighlight()
    }

    @objc private func closeEditor() {
        guard performSave() != nil else {
            return
        }

        window?.close()
    }

    @objc private func deleteAction() {
        if let record = savedRecord {
            CaptureStore.shared.delete(record: record)
            savedRecord = nil
        }

        window?.close()
    }

    @objc private func saveAction() {
        guard performSave() != nil else {
            return
        }

        showToast("Saved")
        updateToolHighlight()
    }

    @objc private func copyForLLMAction() {
        guard let record = performSave() else {
            return
        }

        do {
            let promptText = try CaptureStore.shared.clipboardPrompt(for: record)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(promptText, forType: .string)
            showToast("Copied")
            updateToolHighlight()
        } catch {
            presentError(
                title: "Copy for LLM failed",
                message: "Vibeliner could not load the saved prompt for this capture.",
                recoverySuggestion: "Try saving again. If it still fails, open the captures folder and confirm prompt.md and screenshot.png exist."
            )
        }
    }

    @objc private func menuUndoAction(_ sender: Any?) {
        if isTextEditingActive() {
            _ = window?.firstResponder?.tryToPerform(Selector(("undo:")), with: sender)
            return
        }

        undoAction()
    }

    @objc private func menuCopyAction(_ sender: Any?) {
        if isTextEditingActive() {
            _ = window?.firstResponder?.tryToPerform(#selector(NSText.copy(_:)), with: sender)
            return
        }

        copyForLLMAction()
    }

    @discardableResult
    private func performSave() -> CaptureRecord? {
        canvas.finalizeActiveTextField()

        let renderedImage = canvas.renderAnnotatedImage()
        let annotationTuples = canvas.annotations.map { (number: $0.number, note: $0.note) }
        let preamble = Config.shared.config.preambleSingle

        do {
            let record: CaptureRecord
            if let existing = savedRecord {
                record = try CaptureStore.shared.update(
                    record: existing,
                    image: renderedImage,
                    annotations: annotationTuples,
                    preamble: preamble
                )
            } else {
                record = try CaptureStore.shared.save(
                    image: renderedImage,
                    annotations: annotationTuples,
                    preamble: preamble
                )
            }

            savedRecord = record
            onCaptureSaved?(record)
            return record
        } catch {
            presentError(
                title: "Save failed",
                message: "Vibeliner could not write this capture to disk.",
                recoverySuggestion: "Check the captures folder status in the menu bar popover, then try saving again."
            )
            return nil
        }
    }

    private func presentError(title: String, message: String, recoverySuggestion: String) {
        onError?(
            UserFacingIssue(
                title: title,
                message: message,
                recoverySuggestion: recoverySuggestion,
                technicalDetails: nil
            )
        )
    }

    private func installEditMenu() {
        let mainMenu = NSApp.mainMenu ?? NSMenu()
        if NSApp.mainMenu == nil {
            NSApp.mainMenu = mainMenu
        }

        if mainMenu.item(withTitle: "Vibeliner") == nil {
            let appMenuItem = NSMenuItem(title: "Vibeliner", action: nil, keyEquivalent: "")
            let appMenu = NSMenu(title: "Vibeliner")
            appMenu.addItem(withTitle: "Quit Vibeliner", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            appMenuItem.submenu = appMenu
            mainMenu.addItem(appMenuItem)
        }

        let editMenuItem: NSMenuItem
        let editMenu: NSMenu
        if let existing = mainMenu.item(withTitle: "Edit"), let submenu = existing.submenu {
            editMenuItem = existing
            editMenu = submenu
        } else {
            editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
            editMenu = NSMenu(title: "Edit")
            editMenuItem.submenu = editMenu
            mainMenu.addItem(editMenuItem)
        }

        if editMenu.item(withTitle: "Undo") == nil {
            let undoItem = NSMenuItem(title: "Undo", action: #selector(menuUndoAction(_:)), keyEquivalent: "z")
            undoItem.keyEquivalentModifierMask = [.command]
            undoItem.target = self
            editMenu.addItem(undoItem)
        } else {
            editMenu.item(withTitle: "Undo")?.target = self
            editMenu.item(withTitle: "Undo")?.action = #selector(menuUndoAction(_:))
        }

        if editMenu.item(withTitle: "Copy") == nil {
            let copyItem = NSMenuItem(title: "Copy", action: #selector(menuCopyAction(_:)), keyEquivalent: "c")
            copyItem.keyEquivalentModifierMask = [.command]
            copyItem.target = self
            editMenu.addItem(copyItem)
        } else {
            editMenu.item(withTitle: "Copy")?.target = self
            editMenu.item(withTitle: "Copy")?.action = #selector(menuCopyAction(_:))
        }
    }

    private func installKeyEventMonitor() {
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window == self.window else {
                return event
            }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""

            if modifiers == [.command], characters == "c" {
                if self.isTextEditingActive() {
                    return event
                }
                self.copyForLLMAction()
                return nil
            }

            if modifiers == [], event.keyCode == 53 {
                if self.isTextEditingActive() {
                    return event
                }
                self.closeEditor()
                return nil
            }

            return event
        }
    }

    private func isTextEditingActive() -> Bool {
        guard let firstResponder = window?.firstResponder else {
            return false
        }

        if let textView = firstResponder as? NSTextView, textView.isFieldEditor {
            return true
        }

        return firstResponder is NSText
    }

    func windowWillClose(_ notification: Notification) {
        if let keyEventMonitor {
            NSEvent.removeMonitor(keyEventMonitor)
            self.keyEventMonitor = nil
        }

        onClose?()
    }

    private func showToast(_ message: String) {
        guard let contentView = window?.contentView else { return }

        let label = NSTextField(labelWithString: message)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        label.backgroundColor = NSColor.black.withAlphaComponent(0.8)
        label.isBordered = false
        label.isBezeled = false
        label.isEditable = false
        label.wantsLayer = true
        label.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        label.layer?.cornerRadius = 12
        label.layer?.masksToBounds = true
        label.alignment = .center
        label.sizeToFit()
        label.frame.size.width += 24
        label.frame.size.height += 8

        let x = (contentView.bounds.width - label.frame.width) / 2
        let y = contentView.bounds.height - 70
        label.frame.origin = CGPoint(x: x, y: y)
        label.alphaValue = 0

        contentView.addSubview(label)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            label.animator().alphaValue = 1.0
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    label.animator().alphaValue = 0
                }) {
                    label.removeFromSuperview()
                }
            }
        }
    }

    private static func windowSize(for image: NSImage) -> NSSize {
        guard let screen = NSScreen.main else {
            return NSSize(width: 800, height: 600)
        }

        let maxWidth = screen.visibleFrame.width * 0.8
        let maxHeight = screen.visibleFrame.height * 0.8
        let imageSize = image.size

        if imageSize.width <= maxWidth && imageSize.height <= maxHeight {
            return imageSize
        }

        let widthRatio = maxWidth / imageSize.width
        let heightRatio = maxHeight / imageSize.height
        let scale = min(widthRatio, heightRatio)

        return NSSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
    }
}
