import AppKit

protocol ToolbarDelegate: AnyObject {
    func toolbarDidSelectTool(_ tool: AnnotationToolType)
    func toolbarDidRequestClose()
    func toolbarDidRequestDelete()
    func toolbarDidRequestUndo()
    func toolbarDidRequestRedo()
    func toolbarDidRequestCopyPrompt()
    func toolbarDidRequestCopyImage()
    func toolbarDidRequestNewCapture()
    func toolbarDidRequestAddImage()
}

final class ToolbarTintOverlayView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(
            self,
            background: DesignTokens.toolbarBg,
            cornerRadius: DesignTokens.toolbarCornerRadius,
            borderWidth: 0
        )
        layer?.masksToBounds = true
    }
}

final class ToolbarDividerView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleDividerSurface(self, color: DesignTokens.dynamicColor(dark: DesignTokens.neutralHairline, light: DesignTokens.neutralBorder))
    }
}


final class ToolbarView: NSView {

    weak var delegate: ToolbarDelegate?
    var onChromeHoverChanged: ((Bool) -> Void)?

    var selectedTool: AnnotationToolType = .pin
    var toolButtons: [AnnotationToolType: ToolButton] = [:]
    var trashButton: ToolButton?  // VIB-202: enabled/disabled based on selection
    var addImageButton: NSView?   // VIB-262: + Add image
    var captureButtonEnabled = true  // VIB-236: debounce new capture
    var copyImageButton: NSView?
    var copyPromptButton: CopyPillButton?
    var copyImagePillButton: CopyPillButton?
    enum CopyTarget { case prompt, image }
    let blurView = NSVisualEffectView()
    var tintOverlay: ToolbarTintOverlayView?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    func setupView() {
        wantsLayer = true
        layer?.cornerRadius = DesignTokens.toolbarCornerRadius
        layer?.masksToBounds = false  // VIB-165: must be false for diffuse shadow
        // VIB-165: Soft diffuse shadow matching prototype 0 4px 20px rgba(0,0,0,0.25)
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOffset = NSSize(width: 0, height: -4)
        layer?.shadowRadius = 20
        layer?.shadowOpacity = 0.25
        layer?.borderWidth = 1

        // Blur background — uses .popover which auto-adapts to light/dark
        blurView.material = .popover
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = DesignTokens.toolbarCornerRadius
        blurView.layer?.masksToBounds = true
        addSubview(blurView)

        // Tint overlay — appearance-aware background
        let tintView = ToolbarTintOverlayView()
        addSubview(tintView)
        self.tintOverlay = tintView

        refreshAppearanceColors()

        // Build button strip
        var x: CGFloat = 6  // 6px left padding (prototype: paddingLeft: 6)
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
        closeBtn.setAccessibilityLabel("Close editor")
        closeBtn.setAccessibilityRole(.button)
        let closeY = (DesignTokens.toolbarHeight - DesignTokens.closeButtonSize) / 2
        closeBtn.setFrameOrigin(NSPoint(x: x, y: closeY))
        addSubview(closeBtn)
        x += DesignTokens.closeButtonSize + 6

        // Divider
        x = addDivider(at: x)
        x += 10

        for definition in AnnotationToolType.toolbarDefinitions {
            let btn = ToolButton(
                style: .tool,
                tooltip: definition.toolbarTooltip,
                iconDrawer: ToolbarView.iconDrawer(for: definition.type)
            )
            let tool = definition.type
            btn.isActive = (tool == selectedTool)
            btn.onClick = { [weak self] in self?.selectTool(tool) }
            btn.setAccessibilityLabel("\(definition.displayName) tool")
            btn.setAccessibilityRole(.radioButton)
            btn.setFrameOrigin(NSPoint(x: x, y: centerY))
            addSubview(btn)
            toolButtons[tool] = btn
            x += DesignTokens.toolButtonSize + DesignTokens.toolbarToolButtonGap
        }

        x -= DesignTokens.toolbarToolButtonGap

        // VIB-202: Trash — now part of tool group, always visible, grayed when no selection
        let iconY = (DesignTokens.toolbarHeight - DesignTokens.iconButtonSize) / 2
        let trashBtn = ToolButton(style: .trash, tooltip: "Delete selected") { rect, color in
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
        trashBtn.isEnabled = false  // grayed by default — no selection
        trashBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestDelete() }
        trashBtn.setAccessibilityLabel("Delete selected annotation")
        trashBtn.setAccessibilityRole(.button)
        trashBtn.setFrameOrigin(NSPoint(x: x, y: iconY))
        addSubview(trashBtn)
        self.trashButton = trashBtn
        x += DesignTokens.iconButtonSize + 6

        x = addDivider(at: x)
        x += 10

        // VIB-160: Undo — manual path drawing (NOT SF Symbol which renders black)
        // Prototype SVG: <path d="M3 8h7a3 3 0 010 6H8"/><polyline points="6,5 3,8 6,11"/>
        let undoBtn = ToolButton(style: .icon, tooltip: "Undo (⌘Z)") { rect, color in
            let w = rect.width, h = rect.height
            func pt(_ sx: CGFloat, _ sy: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + sx / 16 * w, y: rect.maxY - sy / 16 * h)
            }
            let path = NSBezierPath()
            // Curved arrow body: M3,8 → line to 10,8 → arc to 10,14 → line to 8,14
            path.move(to: pt(3, 8))
            path.line(to: pt(10, 8))
            path.curve(to: pt(10, 14), controlPoint1: pt(13, 8), controlPoint2: pt(13, 14))
            path.line(to: pt(8, 14))
            path.lineWidth = 1.3
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            color.setStroke()
            path.stroke()
            // Chevron: polyline 6,5 → 3,8 → 6,11
            let chevron = NSBezierPath()
            chevron.move(to: pt(6, 5))
            chevron.line(to: pt(3, 8))
            chevron.line(to: pt(6, 11))
            chevron.lineWidth = 1.3
            chevron.lineCapStyle = .round
            chevron.lineJoinStyle = .round
            chevron.stroke()
        }
        undoBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestUndo() }
        undoBtn.setAccessibilityLabel("Undo")
        undoBtn.setAccessibilityRole(.button)
        undoBtn.setFrameOrigin(NSPoint(x: x, y: iconY))
        addSubview(undoBtn)
        x += DesignTokens.iconButtonSize + 1

        // VIB-160: Redo — manual path (mirrored undo)
        // Prototype SVG: <path d="M13 8H6a3 3 0 000 6h2"/><polyline points="10,5 13,8 10,11"/>
        let redoBtn = ToolButton(style: .icon, tooltip: "Redo (⌘⇧Z)") { rect, color in
            let w = rect.width, h = rect.height
            func pt(_ sx: CGFloat, _ sy: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + sx / 16 * w, y: rect.maxY - sy / 16 * h)
            }
            let path = NSBezierPath()
            path.move(to: pt(13, 8))
            path.line(to: pt(6, 8))
            path.curve(to: pt(6, 14), controlPoint1: pt(3, 8), controlPoint2: pt(3, 14))
            path.line(to: pt(8, 14))
            path.lineWidth = 1.3
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            color.setStroke()
            path.stroke()
            let chevron = NSBezierPath()
            chevron.move(to: pt(10, 5))
            chevron.line(to: pt(13, 8))
            chevron.line(to: pt(10, 11))
            chevron.lineWidth = 1.3
            chevron.lineCapStyle = .round
            chevron.lineJoinStyle = .round
            chevron.stroke()
        }
        redoBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestRedo() }
        redoBtn.setAccessibilityLabel("Redo")
        redoBtn.setAccessibilityRole(.button)
        redoBtn.setFrameOrigin(NSPoint(x: x, y: iconY))
        addSubview(redoBtn)
        x += DesignTokens.iconButtonSize + 6

        // VIB-387/448: Divider between redo and "+ Add image" — tightened gap
        x = addDivider(at: x)
        x += 10

        // VIB-262: + Add image button
        let addImgBtn = makeAddImageButton()
        addImgBtn.setFrameOrigin(NSPoint(x: x, y: (DesignTokens.toolbarHeight - addImgBtn.frame.height) / 2))
        addSubview(addImgBtn)
        addImgBtn.setAccessibilityLabel("Add another screenshot")
        addImgBtn.setAccessibilityRole(.button)
        self.addImageButton = addImgBtn
        x += addImgBtn.frame.width + 4

        // VIB-321: New capture button — purple pill next to + Add image
        let captureBtn = makeNewCaptureButton()
        captureBtn.setFrameOrigin(NSPoint(x: x, y: (DesignTokens.toolbarHeight - captureBtn.frame.height) / 2))
        addSubview(captureBtn)
        captureBtn.setAccessibilityLabel("Start new capture")
        captureBtn.setAccessibilityRole(.button)
        x += captureBtn.frame.width + 10

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
        toggle.setAccessibilityLabel("Copy mode")
        toggle.setAccessibilityRole(.radioGroup)
        x += toggle.frame.width + 10

        x = addDivider(at: x)
        x += 10

        // Copy Prompt button
        let copyPromptBtn = makeCopyButton(title: "Copy Prompt")
        copyPromptBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestCopyPrompt() }
        copyPromptBtn.setFrameOrigin(NSPoint(x: x, y: (DesignTokens.toolbarHeight - copyPromptBtn.frame.height) / 2))
        addSubview(copyPromptBtn)
        copyPromptBtn.setAccessibilityLabel("Copy prompt to clipboard")
        copyPromptBtn.setAccessibilityRole(.button)
        self.copyPromptButton = copyPromptBtn
        x += copyPromptBtn.frame.width + 4

        // Copy Image button
        let copyImageBtn = makeCopyButton(title: "Copy Image")
        copyImageBtn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestCopyImage() }
        copyImageBtn.setFrameOrigin(NSPoint(x: x, y: (DesignTokens.toolbarHeight - copyImageBtn.frame.height) / 2))
        addSubview(copyImageBtn)
        copyImageBtn.setAccessibilityLabel("Copy image to clipboard")
        copyImageBtn.setAccessibilityRole(.button)
        self.copyImageButton = copyImageBtn
        self.copyImagePillButton = copyImageBtn
        x += copyImageBtn.frame.width + 6  // 6px right padding (matches 6px left padding)

        // Set total size
        setFrameSize(NSSize(width: x, height: DesignTokens.toolbarHeight))
        blurView.frame = bounds
        tintView.frame = bounds

        // VIB-165: Set shadow path to pill shape for diffuse shadow
        updateShadowPath()

        updateCopyButtonVisibility(mode: ConfigManager.shared.copyMode)
    }

    // VIB-235: Live appearance update
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshAppearanceColors()
        // ToolButtons redraw via needsDisplay automatically since they use dynamic colors in draw()
        for subview in subviews {
            subview.needsDisplay = true
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshAppearanceColors()
    }

    func refreshAppearanceColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.borderColor = DesignTokens.neutralBorder.cgColor
        }
        tintOverlay?.refreshSurfaceAppearance()
        for case let divider as ToolbarDividerView in subviews {
            divider.refreshSurfaceAppearance()
        }
    }

    // VIB-214: Restore system cursor when entering the toolbar (drawing tools hide it)
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        onChromeHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onChromeHoverChanged?(false)
    }

}
