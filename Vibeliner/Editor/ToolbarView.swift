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

private final class ToolbarTintOverlayView: AppearanceAwareSurfaceView {
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

private final class ToolbarDividerView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleDividerSurface(self, color: DesignTokens.toolbarDivider)
    }
}

private enum ToolbarIconGeometry {
    static let viewBox: CGFloat = 15

    static func point(in rect: NSRect, _ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(
            x: rect.minX + (x / viewBox) * rect.width,
            y: rect.maxY - (y / viewBox) * rect.height
        )
    }

    static func outlineRect(in rect: NSRect, inset: CGFloat = 1.25) -> NSRect {
        rect.insetBy(dx: inset, dy: inset)
    }
}

final class ToolbarView: NSView {

    weak var delegate: ToolbarDelegate?
    var onChromeHoverChanged: ((Bool) -> Void)?

    private(set) var selectedTool: AnnotationToolType = .pin
    private var toolButtons: [AnnotationToolType: ToolButton] = [:]
    private var trashButton: ToolButton?  // VIB-202: enabled/disabled based on selection
    private var addImageButton: NSView?   // VIB-262: + Add image
    private var captureButtonEnabled = true  // VIB-236: debounce new capture
    private var copyImageButton: NSView?
    private let blurView = NSVisualEffectView()
    private var tintOverlay: ToolbarTintOverlayView?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
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
        x += DesignTokens.iconButtonSize + 10

        x = addDivider(at: x)
        x += 20

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
        x += DesignTokens.iconButtonSize + 10

        // VIB-387: Divider between redo and "+ Add image"
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

    private func refreshAppearanceColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.layer?.borderColor = DesignTokens.toolbarBorder.cgColor
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

    func selectTool(_ tool: AnnotationToolType) {
        selectedTool = tool
        for (t, btn) in toolButtons {
            btn.isActive = (t == tool)
            let toolName = btn.toolTip ?? "Tool"
            let baseName = toolName.components(separatedBy: " (").first ?? toolName
            btn.setAccessibilityLabel(t == tool ? "\(baseName) tool, selected" : "\(baseName) tool")
        }
        delegate?.toolbarDidSelectTool(tool)
    }

    enum CopyTarget { case prompt, image }

    private var copyPromptButton: CopyPillButton?
    private var copyImagePillButton: CopyPillButton?

    func updateAnnotationCount(_ count: Int) {
        // VIB-164: Pin icon no longer has counter — this is now a no-op
    }

    // VIB-202: Enable/disable trash based on whether an annotation is selected
    func updateTrashState(hasSelection: Bool) {
        trashButton?.isEnabled = hasSelection
    }

    func markCopyState(_ target: CopyTarget) {
        switch target {
        case .prompt:
            copyPromptButton?.showCopied()
            copyPromptButton?.setAccessibilityLabel("Prompt copied")
        case .image:
            copyImagePillButton?.showCopied()
            copyImagePillButton?.setAccessibilityLabel("Image copied")
        }
    }

    func resetCopyState() {
        copyPromptButton?.resetState()
        copyPromptButton?.setAccessibilityLabel("Copy prompt to clipboard")
        copyImagePillButton?.resetState()
        copyImagePillButton?.setAccessibilityLabel("Copy image to clipboard")
    }

    private func updateShadowPath() {
        // VIB-176: Dynamic pill radius = half height for perfect semicircular ends
        let r = bounds.height / 2.0
        layer?.cornerRadius = r
        blurView.layer?.cornerRadius = r
        tintOverlay?.layer?.cornerRadius = r
        let path = CGPath(roundedRect: bounds, cornerWidth: r, cornerHeight: r, transform: nil)
        layer?.shadowPath = path
    }

    private func updateCopyButtonVisibility(mode: String) {
        let isIDE = (mode == "ide")
        copyImageButton?.isHidden = isIDE

        // Recalculate toolbar width: shrink when Copy Image is hidden
        if let copyPrompt = copyPromptButton, let copyImage = copyImagePillButton {
            let newWidth: CGFloat
            if isIDE {
                // End after Copy Prompt + 6px right padding
                newWidth = copyPrompt.frame.maxX + 6
            } else {
                // End after Copy Image + 6px right padding
                newWidth = copyImage.frame.maxX + 6
            }
            setFrameSize(NSSize(width: newWidth, height: DesignTokens.toolbarHeight))
            blurView.frame = bounds
            tintOverlay?.frame = bounds
            updateShadowPath()
        }
    }

    private func addDivider(at x: CGFloat) -> CGFloat {
        let divider = ToolbarDividerView(frame: NSRect(x: x, y: (DesignTokens.toolbarHeight - 16) / 2, width: 1, height: 16))
        addSubview(divider)
        return x + 1
    }

    private func makeCopyButton(title: String) -> CopyPillButton {
        return CopyPillButton(title: title)
    }

    // VIB-330: + Add image — secondary button style (subtle, neutral)
    private func makeAddImageButton() -> SecondaryPillButton {
        let btn = SecondaryPillButton(title: "+ Add image")
        btn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestAddImage() }
        return btn
    }

    @objc private func addImageClicked() {
        delegate?.toolbarDidRequestAddImage()
    }

    // VIB-330: New capture — secondary button style (subtle, neutral)
    private func makeNewCaptureButton() -> SecondaryPillButton {
        let btn = SecondaryPillButton(title: "New capture")
        btn.onClick = { [weak self] in self?.newCaptureClicked() }
        return btn
    }

    @objc private func newCaptureClicked() {
        guard captureButtonEnabled else { return }
        captureButtonEnabled = false
        delegate?.toolbarDidRequestNewCapture()
    }

    /// VIB-262/330: Disable the button at 12 images — no alphaValue, use isEnabled.
    func updateAddImageState(imageCount: Int) {
        if let btn = addImageButton as? SecondaryPillButton {
            btn.isButtonEnabled = imageCount < 12
        }
    }

    // MARK: - Icon drawing functions

    /// Pin icon: filled circle + stake, 15×15 viewBox, same pattern as all other tool icons.
    /// Uses currentColor — no special colors, no counter.
    static func drawPinIcon(_ rect: NSRect, _ color: NSColor) {
        // Filled circle at (7.5, 5), r=3.5 in 15×15 viewBox
        let center = ToolbarIconGeometry.point(in: rect, 7.5, 5)
        let r = 3.5 * (rect.width / ToolbarIconGeometry.viewBox)
        let circle = NSBezierPath(ovalIn: NSRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        color.setFill()
        circle.fill()
        // Stake line from (7.5, 9) to (7.5, 14)
        let stake = NSBezierPath()
        stake.move(to: ToolbarIconGeometry.point(in: rect, 7.5, 9))
        stake.line(to: ToolbarIconGeometry.point(in: rect, 7.5, 14))
        stake.lineWidth = 1.8 * (rect.width / ToolbarIconGeometry.viewBox)
        stake.lineCapStyle = .round
        color.setStroke()
        stake.stroke()
    }

    static func drawArrowIcon(_ rect: NSRect, _ color: NSColor) {
        let path = NSBezierPath()
        // Diagonal line
        path.move(to: ToolbarIconGeometry.point(in: rect, 2, 13))
        path.line(to: ToolbarIconGeometry.point(in: rect, 13, 2))
        // Arrowhead chevron
        path.move(to: ToolbarIconGeometry.point(in: rect, 8, 2))
        path.line(to: ToolbarIconGeometry.point(in: rect, 13, 2))
        path.line(to: ToolbarIconGeometry.point(in: rect, 13, 7))
        path.lineWidth = 1.4
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        color.setStroke()
        path.stroke()
    }

    static func drawRectIcon(_ rect: NSRect, _ color: NSColor) {
        let inset = ToolbarIconGeometry.outlineRect(in: rect)
        let path = NSBezierPath(roundedRect: inset, xRadius: 2, yRadius: 2)
        path.lineWidth = 1.5
        color.setStroke()
        path.stroke()
    }

    static func drawCircleIcon(_ rect: NSRect, _ color: NSColor) {
        let inset = ToolbarIconGeometry.outlineRect(in: rect)
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

    private static func iconDrawer(for tool: AnnotationToolType) -> (NSRect, NSColor) -> Void {
        switch tool {
        case .select:
            return { rect, color in
                let w = rect.width
                let h = rect.height
                func pt(_ sx: CGFloat, _ sy: CGFloat) -> NSPoint {
                    NSPoint(x: rect.minX + sx / 15 * w, y: rect.maxY - sy / 15 * h)
                }
                let path = NSBezierPath()
                path.move(to: pt(3, 2))
                path.line(to: pt(12, 7.5))
                path.line(to: pt(8, 8.5))
                path.line(to: pt(10.5, 13))
                path.line(to: pt(9, 13.8))
                path.line(to: pt(6.5, 9.3))
                path.line(to: pt(3.5, 12.3))
                path.close()
                color.setFill()
                path.fill()
                color.setStroke()
                path.lineWidth = 0.5
                path.lineJoinStyle = .round
                path.stroke()
            }
        case .pin:
            return drawPinIcon
        case .arrow:
            return drawArrowIcon
        case .rectangle:
            return drawRectIcon
        case .circle:
            return drawCircleIcon
        case .freehand:
            return drawFreehandIcon
        }
    }
}

// MARK: - Mode Toggle

final class ModeToggleView: NSView {

    var onModeChange: ((String) -> Void)?

    private let ideLabel = NSTextField(labelWithString: "IDE")
    private let appLabel = NSTextField(labelWithString: "App")
    private let highlightView = ToolbarModeToggleHighlightView()
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
        SettingsUI.styleSurface(self, background: DesignTokens.toolbarToggleBg, cornerRadius: 14, borderWidth: 0)
        addSubview(highlightView)

        for label in [ideLabel, appLabel] {
            label.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
            label.alignment = .center
            label.isBezeled = false
            label.drawsBackground = false
            label.isEditable = false
            label.isSelectable = false
            label.usesSingleLineMode = true
            label.cell?.isScrollable = false
            label.cell?.wraps = false
            addSubview(label)
        }

        // Labels positioned to vertically center the 9px text within 24px segments
        // Segments are at y=2 within the 28px container
        let labelH: CGFloat = 14  // enough for 9px font
        let labelY: CGFloat = 2 + (24 - labelH) / 2  // center within segment
        ideLabel.frame = NSRect(x: 2, y: labelY, width: segW, height: labelH)
        appLabel.frame = NSRect(x: 2 + segW, y: labelY, width: segW, height: labelH)

        updateAppearance()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshToggleColors()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refreshToggleColors()
    }

    private func refreshToggleColors() {
        SettingsUI.styleSurface(self, background: DesignTokens.toolbarToggleBg, cornerRadius: 14, borderWidth: 0)
        highlightView.refreshSurfaceAppearance()
        updateAppearance()
    }

    private func updateAppearance() {
        if currentMode == "ide" {
            highlightView.frame = NSRect(x: 2, y: 2, width: segW, height: 24)
            ideLabel.textColor = DesignTokens.toolbarPurpleActive
            appLabel.textColor = DesignTokens.toolbarToggleInactiveText
        } else {
            highlightView.frame = NSRect(x: 2 + segW, y: 2, width: segW, height: 24)
            appLabel.textColor = DesignTokens.toolbarPurpleActive
            ideLabel.textColor = DesignTokens.toolbarToggleInactiveText
        }
    }

    override func mouseDown(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        currentMode = localPoint.x < bounds.midX ? "ide" : "app"
        updateAppearance()
        onModeChange?(currentMode)
    }
}

private final class ToolbarModeToggleHighlightView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(self, background: DesignTokens.toolbarToggleActiveBg, cornerRadius: 12, borderWidth: 0)
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
        label.textColor = DesignTokens.toolbarPurpleButtonText
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
        centerLabel()
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
        centerLabel()
        updateAppearance()
    }

    private func centerLabel() {
        label.sizeToFit()
        let h = frame.height
        label.frame = NSRect(
            x: (frame.width - label.frame.width) / 2,
            y: (h - label.frame.height) / 2,
            width: label.frame.width,
            height: label.frame.height
        )
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateAppearance()
    }

    private func updateAppearance() {
        if isCopied {
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.copiedGreenBg,
                border: DesignTokens.copiedGreenBorder,
                cornerRadius: 14,
                borderWidth: 1.5
            )
            label.textColor = DesignTokens.copiedGreenText
        } else {
            let borderColor = isHovered ? DesignTokens.toolbarPurpleButtonHoverBorder : DesignTokens.toolbarPurpleButtonBorder
            let bgColor = isHovered ? DesignTokens.toolbarPurpleButtonHoverBg : DesignTokens.toolbarPurpleButtonBg
            SettingsUI.styleSurface(
                self,
                background: bgColor,
                border: borderColor,
                cornerRadius: 14,
                borderWidth: 1.5
            )
            label.textColor = isHovered ? DesignTokens.toolbarPurpleButtonHoverText : DesignTokens.toolbarPurpleButtonText
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

// MARK: - VIB-330: Secondary Pill Button

/// Subtle outlined pill button for secondary actions (+ Add image, New capture).
/// Uses `toolbarSecondary*` design tokens — neutral border/text, no purple, fully opaque.
final class SecondaryPillButton: NSView {

    var onClick: (() -> Void)?
    var isButtonEnabled: Bool = true {
        didSet { updateAppearance() }
    }
    private let label: NSTextField
    private var isHovered = false { didSet { updateAppearance() } }

    init(title: String) {
        label = NSTextField(labelWithString: title)
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 13
        layer?.masksToBounds = true
        layer?.borderWidth = 1

        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        addSubview(label)

        label.sizeToFit()
        let w = label.frame.width + 24  // 12px padding each side
        let h: CGFloat = 26
        setFrameSize(NSSize(width: w, height: h))
        label.frame = NSRect(
            x: 12,
            y: (h - label.frame.height) / 2,
            width: label.frame.width,
            height: label.frame.height
        )

        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func updateAppearance() {
        if !isButtonEnabled {
            label.textColor = DesignTokens.toolbarSecondaryText.withAlphaComponent(0.3)
            SettingsUI.styleSurface(
                self,
                background: .clear,
                border: DesignTokens.toolbarSecondaryBorder.withAlphaComponent(0.15),
                cornerRadius: 13
            )
        } else if isHovered {
            label.textColor = DesignTokens.toolbarSecondaryHoverText
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.toolbarSecondaryHoverBg,
                border: DesignTokens.toolbarSecondaryHoverBorder,
                cornerRadius: 13
            )
        } else {
            label.textColor = DesignTokens.toolbarSecondaryText
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.toolbarSecondaryBg,
                border: DesignTokens.toolbarSecondaryBorder,
                cornerRadius: 13
            )
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateAppearance()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }
    override func mouseDown(with event: NSEvent) {
        guard isButtonEnabled else { return }
        onClick?()
    }
}
