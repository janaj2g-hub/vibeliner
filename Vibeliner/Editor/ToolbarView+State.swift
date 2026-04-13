import AppKit

extension ToolbarView {

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

    func updateShadowPath() {
        // VIB-176: Dynamic pill radius = half height for perfect semicircular ends
        let r = bounds.height / 2.0
        layer?.cornerRadius = r
        blurView.layer?.cornerRadius = r
        tintOverlay?.layer?.cornerRadius = r
        let path = CGPath(roundedRect: bounds, cornerWidth: r, cornerHeight: r, transform: nil)
        layer?.shadowPath = path
    }

    func updateCopyButtonVisibility(mode: String) {
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

    func addDivider(at x: CGFloat) -> CGFloat {
        let divider = ToolbarDividerView(frame: NSRect(x: x, y: (DesignTokens.toolbarHeight - 16) / 2, width: 1, height: 16))
        addSubview(divider)
        return x + 1
    }

    func makeCopyButton(title: String) -> CopyPillButton {
        return CopyPillButton(title: title)
    }

    // VIB-330: + Add image — secondary button style (subtle, neutral)
    func makeAddImageButton() -> SecondaryPillButton {
        let btn = SecondaryPillButton(title: "+ Add image")
        btn.onClick = { [weak self] in self?.delegate?.toolbarDidRequestAddImage() }
        return btn
    }

    @objc private func addImageClicked() {
        delegate?.toolbarDidRequestAddImage()
    }

    // VIB-330: New capture — secondary button style (subtle, neutral)
    func makeNewCaptureButton() -> SecondaryPillButton {
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

}
