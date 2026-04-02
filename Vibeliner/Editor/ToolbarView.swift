import AppKit

protocol ToolbarDelegate: AnyObject {
    func toolbarDidSelectTool(_ tool: AnnotationToolType)
    func toolbarDidRequestClose()
    func toolbarDidRequestDelete()
    func toolbarDidRequestUndo()
    func toolbarDidRequestRedo()
    func toolbarDidRequestCopyPrompt()
    func toolbarDidRequestCopyImage()
}

final class ToolbarView: NSView {

    weak var delegate: ToolbarDelegate?

    private(set) var selectedTool: AnnotationToolType = .pin
    private var toolButtons: [AnnotationToolType: ToolButton] = [:]
    private var copyImageButton: NSView?
    private var pinCounterIcon: PinCounterIcon?
    private let blurView = NSVisualEffectView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = DesignTokens.toolbarCornerRadius
        layer?.masksToBounds = true
        layer?.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        layer?.shadowOffset = NSSize(width: 0, height: -4)
        layer?.shadowRadius = 20
        layer?.shadowOpacity = 1.0
        layer?.masksToBounds = false

        // Blur background
        blurView.material = .hudWindow
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.appearance = NSAppearance(named: .darkAqua)
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = DesignTokens.toolbarCornerRadius
        blurView.layer?.masksToBounds = true
        addSubview(blurView)

        // Dark tint overlay
        let tintView = NSView()
        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = DesignTokens.darkChrome.cgColor
        tintView.layer?.cornerRadius = DesignTokens.toolbarCornerRadius
        tintView.layer?.masksToBounds = true
        addSubview(tintView)

        // Build button strip
        var x: CGFloat = 4
        let centerY: CGFloat = (DesignTokens.toolbarHeight - DesignTokens.toolButtonSize) / 2

        // Close button
        let closeBtn = ToolButton(style: .close, tooltip: "Close (Esc)") { rect, color in
            let path = NSBezierPath()
            path.move(to: NSPoint(x: rect.minX, y: rect.maxY))
            path.line(to: NSPoint(x: rect.maxX, y: rect.minY))
            path.move(to: NSPoint(x: rect.maxX, y: rect.maxY))
            path.line(to: NSPoint(x: rect.minX, y: rect.minY))
            path.lineWidth = 1.5
            color.setStroke()
            path.stroke()
        }
        closeBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestClose() }
        let closeY = (DesignTokens.toolbarHeight - DesignTokens.closeButtonSize) / 2
        closeBtn.setFrameOrigin(NSPoint(x: x, y: closeY))
        addSubview(closeBtn)
        x += DesignTokens.closeButtonSize + 30

        // Divider
        x = addDivider(at: x)
        x += 10

        // Pin tool button with counter icon
        let pinBtn = ToolButton(style: .tool, tooltip: "Pin") { [weak self] rect, color in
            // Draw nothing — PinCounterIcon overlay handles it
            _ = self
        }
        pinBtn.isActive = (selectedTool == .pin)
        pinBtn.onClick = { [weak self] in self?.selectTool(.pin) }
        pinBtn.setFrameOrigin(NSPoint(x: x, y: centerY))
        addSubview(pinBtn)
        toolButtons[.pin] = pinBtn

        let pinIcon = PinCounterIcon(frame: NSRect(x: 0, y: 0, width: DesignTokens.toolButtonSize, height: DesignTokens.toolButtonSize))
        pinIcon.isActive = (selectedTool == .pin)
        pinBtn.addSubview(pinIcon)
        self.pinCounterIcon = pinIcon
        x += DesignTokens.toolButtonSize

        // Other tool buttons
        let toolDefs: [(AnnotationToolType, String, (NSRect, NSColor) -> Void)] = [
            (.arrow, "Arrow", ToolbarView.drawArrowIcon),
            (.rectangle, "Rectangle", ToolbarView.drawRectIcon),
            (.circle, "Circle", ToolbarView.drawCircleIcon),
            (.freehand, "Freehand", ToolbarView.drawFreehandIcon),
        ]

        for (tool, name, drawer) in toolDefs {
            let btn = ToolButton(style: .tool, tooltip: name, iconDrawer: drawer)
            btn.isActive = (tool == selectedTool)
            btn.onClick = { [weak self] in self?.selectTool(tool) }
            btn.setFrameOrigin(NSPoint(x: x, y: centerY))
            addSubview(btn)
            toolButtons[tool] = btn
            x += DesignTokens.toolButtonSize
        }

        x += 10
        x = addDivider(at: x)
        x += 20

        // Trash
        let trashBtn = ToolButton(style: .trash, tooltip: "Delete") { rect, color in
            let inset = rect.insetBy(dx: 1, dy: 0)
            let path = NSBezierPath()
            // Can body
            path.move(to: NSPoint(x: inset.minX + 1, y: inset.maxY - 3))
            path.line(to: NSPoint(x: inset.minX + 2, y: inset.minY))
            path.line(to: NSPoint(x: inset.maxX - 2, y: inset.minY))
            path.line(to: NSPoint(x: inset.maxX - 1, y: inset.maxY - 3))
            // Lid
            path.move(to: NSPoint(x: inset.minX, y: inset.maxY - 3))
            path.line(to: NSPoint(x: inset.maxX, y: inset.maxY - 3))
            // Handle
            path.move(to: NSPoint(x: inset.midX - 2, y: inset.maxY - 3))
            path.line(to: NSPoint(x: inset.midX - 2, y: inset.maxY))
            path.line(to: NSPoint(x: inset.midX + 2, y: inset.maxY))
            path.line(to: NSPoint(x: inset.midX + 2, y: inset.maxY - 3))
            path.lineWidth = 1.2
            color.setStroke()
            path.stroke()
        }
        trashBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestDelete() }
        let iconY = (DesignTokens.toolbarHeight - DesignTokens.iconButtonSize) / 2
        trashBtn.setFrameOrigin(NSPoint(x: x, y: iconY))
        addSubview(trashBtn)
        x += DesignTokens.iconButtonSize + 10

        // Undo — use SF Symbol
        let undoBtn = ToolButton(style: .icon, tooltip: "Undo") { rect, color in
            if let img = NSImage(systemSymbolName: "arrow.uturn.backward", accessibilityDescription: "Undo") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                let configured = img.withSymbolConfiguration(config) ?? img
                let imgSize = configured.size
                let imgRect = NSRect(x: rect.midX - imgSize.width / 2, y: rect.midY - imgSize.height / 2, width: imgSize.width, height: imgSize.height)
                configured.draw(in: imgRect)
            }
        }
        undoBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestUndo() }
        undoBtn.setFrameOrigin(NSPoint(x: x, y: iconY))
        addSubview(undoBtn)
        x += DesignTokens.iconButtonSize + 1

        // Redo — use SF Symbol
        let redoBtn = ToolButton(style: .icon, tooltip: "Redo") { rect, color in
            if let img = NSImage(systemSymbolName: "arrow.uturn.forward", accessibilityDescription: "Redo") {
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                let configured = img.withSymbolConfiguration(config) ?? img
                let imgSize = configured.size
                let imgRect = NSRect(x: rect.midX - imgSize.width / 2, y: rect.midY - imgSize.height / 2, width: imgSize.width, height: imgSize.height)
                configured.draw(in: imgRect)
            }
        }
        redoBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestRedo() }
        redoBtn.setFrameOrigin(NSPoint(x: x, y: iconY))
        addSubview(redoBtn)
        x += DesignTokens.iconButtonSize + 20

        x = addDivider(at: x)
        x += 10

        // IDE/App toggle
        let toggle = ModeToggleView()
        toggle.setFrameOrigin(NSPoint(x: x, y: (DesignTokens.toolbarHeight - toggle.frame.height) / 2))
        toggle.onModeChange = { [weak self] mode in
            ConfigManager.shared.copyMode = mode
            ConfigManager.shared.save()
            self?.updateCopyButtonVisibility(mode: mode)
            // Reset copy buttons on mode switch
            self?.resetCopyState()
        }
        addSubview(toggle)
        x += toggle.frame.width + 10

        x = addDivider(at: x)
        x += 10

        // Copy Prompt button
        let copyPromptBtn = makeCopyButton(title: "Copy Prompt")
        copyPromptBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestCopyPrompt() }
        copyPromptBtn.setFrameOrigin(NSPoint(x: x, y: (DesignTokens.toolbarHeight - copyPromptBtn.frame.height) / 2))
        addSubview(copyPromptBtn)
        self.copyPromptButton = copyPromptBtn
        x += copyPromptBtn.frame.width + 4

        // Copy Image button
        let copyImageBtn = makeCopyButton(title: "Copy Image")
        copyImageBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestCopyImage() }
        copyImageBtn.setFrameOrigin(NSPoint(x: x, y: (DesignTokens.toolbarHeight - copyImageBtn.frame.height) / 2))
        addSubview(copyImageBtn)
        self.copyImageButton = copyImageBtn
        self.copyImagePillButton = copyImageBtn
        x += copyImageBtn.frame.width + 4

        // Set total size
        setFrameSize(NSSize(width: x, height: DesignTokens.toolbarHeight))
        blurView.frame = bounds
        tintView.frame = bounds

        updateCopyButtonVisibility(mode: ConfigManager.shared.copyMode)
    }

    func selectTool(_ tool: AnnotationToolType) {
        selectedTool = tool
        for (t, btn) in toolButtons { btn.isActive = (t == tool) }
        pinCounterIcon?.isActive = (tool == .pin)
        delegate?.toolbarDidSelectTool(tool)
    }

    enum CopyTarget { case prompt, image }

    private var copyPromptButton: CopyPillButton?
    private var copyImagePillButton: CopyPillButton?

    func updateAnnotationCount(_ count: Int) {
        pinCounterIcon?.count = count
    }

    func markCopyState(_ target: CopyTarget) {
        switch target {
        case .prompt: copyPromptButton?.showCopied()
        case .image: copyImagePillButton?.showCopied()
        }
    }

    func resetCopyState() {
        copyPromptButton?.resetState()
        copyImagePillButton?.resetState()
    }

    private func updateCopyButtonVisibility(mode: String) {
        copyImageButton?.isHidden = (mode == "ide")
    }

    private func addDivider(at x: CGFloat) -> CGFloat {
        let divider = NSView(frame: NSRect(x: x, y: (DesignTokens.toolbarHeight - 16) / 2, width: 1, height: 16))
        divider.wantsLayer = true
        divider.layer?.backgroundColor = DesignTokens.dividerColor.cgColor
        addSubview(divider)
        return x + 1
    }

    private func makeCopyButton(title: String) -> CopyPillButton {
        return CopyPillButton(title: title)
    }

    // MARK: - Icon drawing functions

    static func drawPinIcon(_ rect: NSRect, _ color: NSColor) {
        let cx = rect.midX, cy = rect.midY + 2
        let r: CGFloat = 5
        let path = NSBezierPath(ovalIn: NSRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        color.setFill()
        path.fill()
        let line = NSBezierPath()
        line.move(to: NSPoint(x: cx, y: cy - r))
        line.line(to: NSPoint(x: cx, y: rect.minY))
        line.lineWidth = 1.8
        color.setStroke()
        line.stroke()
    }

    static func drawArrowIcon(_ rect: NSRect, _ color: NSColor) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX, y: rect.minY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY))
        // Chevron
        path.move(to: NSPoint(x: rect.maxX - 5, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.maxY - 5))
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }

    static func drawRectIcon(_ rect: NSRect, _ color: NSColor) {
        let inset = rect.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: inset, xRadius: 2, yRadius: 2)
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }

    static func drawCircleIcon(_ rect: NSRect, _ color: NSColor) {
        let inset = rect.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(ovalIn: inset)
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }

    static func drawFreehandIcon(_ rect: NSRect, _ color: NSColor) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX, y: rect.midY))
        path.curve(to: NSPoint(x: rect.midX, y: rect.midY),
                   controlPoint1: NSPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY),
                   controlPoint2: NSPoint(x: rect.midX - rect.width * 0.1, y: rect.minY))
        path.curve(to: NSPoint(x: rect.maxX, y: rect.midY),
                   controlPoint1: NSPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY),
                   controlPoint2: NSPoint(x: rect.maxX - rect.width * 0.2, y: rect.minY))
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }
}

// MARK: - Mode Toggle

final class ModeToggleView: NSView {

    var onModeChange: ((String) -> Void)?

    private let ideLabel = NSTextField(labelWithString: "IDE")
    private let appLabel = NSTextField(labelWithString: "App")
    private let highlightView = NSView()
    private var currentMode: String

    // Prototype: container height 28, borderRadius 14, bg rgba(255,255,255,0.06), padding 2
    // Segments: height 24, borderRadius 12, padding 0 12px, fontSize 9 weight 600
    private let segW: CGFloat = 36
    private let containerH: CGFloat = 28

    override init(frame frameRect: NSRect) {
        currentMode = ConfigManager.shared.copyMode
        super.init(frame: NSRect(origin: .zero, size: NSSize(width: segW * 2 + 4, height: containerH)))
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = DesignTokens.toggleBg.cgColor

        highlightView.wantsLayer = true
        highlightView.layer?.cornerRadius = 12
        highlightView.layer?.backgroundColor = DesignTokens.toggleActiveBg.cgColor
        addSubview(highlightView)

        for label in [ideLabel, appLabel] {
            label.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
            label.alignment = .center
            label.isBezeled = false
            label.drawsBackground = false
            label.isEditable = false
            label.isSelectable = false
            addSubview(label)
        }

        ideLabel.frame = NSRect(x: 2, y: 2, width: segW, height: 24)
        appLabel.frame = NSRect(x: 2 + segW, y: 2, width: segW, height: 24)

        updateAppearance()
    }

    private func updateAppearance() {
        if currentMode == "ide" {
            highlightView.frame = NSRect(x: 2, y: 2, width: segW, height: 24)
            ideLabel.textColor = DesignTokens.purpleLight
            appLabel.textColor = DesignTokens.toggleInactiveText
        } else {
            highlightView.frame = NSRect(x: 2 + segW, y: 2, width: segW, height: 24)
            appLabel.textColor = DesignTokens.purpleLight
            ideLabel.textColor = DesignTokens.toggleInactiveText
        }
    }

    override func mouseDown(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        currentMode = localPoint.x < bounds.midX ? "ide" : "app"
        updateAppearance()
        onModeChange?(currentMode)
    }
}

// MARK: - Copy Pill Button

final class CopyPillButton: NSView {

    var onClick: (() -> Void)?
    private let label: NSTextField
    private let originalTitle: String
    private var isHovered = false { didSet { needsDisplay = true; updateAppearance() } }
    private(set) var isCopied = false
    private var revertTimer: Timer?

    init(title: String) {
        self.originalTitle = title
        label = NSTextField(labelWithString: title)
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = true
        layer?.borderWidth = 1.5

        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = DesignTokens.purpleButton
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        addSubview(label)

        label.sizeToFit()
        let w = label.frame.width + 28  // padding 0 14px each side = 28
        let h: CGFloat = 28
        setFrameSize(NSSize(width: w, height: h))
        label.frame = NSRect(x: 14, y: (h - label.frame.height) / 2, width: label.frame.width, height: label.frame.height)

        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    func showCopied() {
        isCopied = true
        label.stringValue = "✓ Copied"
        updateAppearance()
        revertTimer?.invalidate()
        revertTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.resetState()
        }
    }

    func resetState() {
        revertTimer?.invalidate()
        isCopied = false
        label.stringValue = originalTitle
        updateAppearance()
    }

    private func updateAppearance() {
        if isCopied {
            layer?.borderColor = DesignTokens.copiedGreenBorder.cgColor
            layer?.backgroundColor = DesignTokens.copiedGreenBg.cgColor
            label.textColor = DesignTokens.copiedGreenText
        } else {
            let borderColor = isHovered ? DesignTokens.purpleButtonHover : DesignTokens.purpleButton
            let bgColor = isHovered ? DesignTokens.purpleButtonBgHover : DesignTokens.purpleButtonBg
            layer?.borderColor = borderColor.cgColor
            layer?.backgroundColor = bgColor.cgColor
            label.textColor = isHovered ? DesignTokens.purpleButtonHover : DesignTokens.purpleButton
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func mouseDown(with event: NSEvent) { onClick?() }
}
