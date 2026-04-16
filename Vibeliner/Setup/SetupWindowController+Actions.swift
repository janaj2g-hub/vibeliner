import AppKit

extension SetupWindowController {

    // MARK: - Step completion

    // VIB-303: Step 1 = Captures folder chosen
    func completeStep1() {
        guard !step1Done else { return }
        step1Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel1Container.animator().alphaValue = 0.45
        }

        replaceBadge(&badge1View, num: 1, state: .done)
        step1ActionRow.isHidden = true
        status1.isHidden = true
        step1DoneArea.isHidden = false

        pathDisplay.stringValue = abbreviatePath(folderPath)
        pathDisplay.textColor = DesignTokens.setupTextPrimary

        // Unlock panel 2
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel2Container.animator().alphaValue = 1.0
        }

        replaceBadge(&badge2View, num: 2, state: .active)
        step2ActionRow.isHidden = false
        step2Helper.isHidden = false
        status2.isHidden = true

        // If accessibility already granted, auto-complete step 2
        if AXIsProcessTrusted() {
            completeStep2()
        }

        checkCompletion()
    }

    func completeStep2() {
        guard !step2Done else { return }
        step2Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel2Container.animator().alphaValue = 0.45
        }

        replaceBadge(&badge2View, num: 2, state: .done)
        step2ActionRow.isHidden = true
        step2Helper.isHidden = true
        status2.isHidden = false
        status2.stringValue = "Permission granted"
        applyStatusStyle(status2, style: .green)

        // Unlock panel 3 (Screen recording)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel3Container.animator().alphaValue = 1.0
        }

        replaceBadge(&badge3View, num: 3, state: .active)
        step3ActionRow.isHidden = false
        step3RestartNote.isHidden = false
        status3.isHidden = true

        // If screen recording already granted, auto-complete step 3
        if CGPreflightScreenCaptureAccess() {
            completeStep3()
        }

        checkCompletion()
    }

    // VIB-303: Step 3 = Screen recording granted
    func completeStep3() {
        guard !step3Done else { return }
        step3Done = true

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel3Container.animator().alphaValue = 0.45
        }

        replaceBadge(&badge3View, num: 3, state: .done)
        step3ActionRow.isHidden = true
        step3RestartNote.isHidden = true
        status3.isHidden = false
        status3.stringValue = "Permission granted"
        applyStatusStyle(status3, style: .green)

        checkCompletion()
    }

    /// Called when "Change folder" is clicked after step 1 is done — allow re-selecting
    func reopenFolderSelection() {
        step1Done = false
        step1DoneArea.isHidden = true
        step1ActionRow.isHidden = false

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.3
            panel1Container.animator().alphaValue = 1.0
        }
        replaceBadge(&badge1View, num: 1, state: .active)
        updateFooter()
    }

    func checkCompletion() {
        updateFooter()
    }

    /// VIB-332: Re-apply all layer-backed CGColors after an appearance change.
    /// Dynamic NSColor resolves correctly when .cgColor is called again.
    func reapplyLayerColors() {
        window?.backgroundColor = DesignTokens.setupWindowBg
        SettingsUI.styleSurface(footerContent, background: DesignTokens.setupFooterBg, borderWidth: 0)
        if let divider1 { SettingsUI.styleDividerSurface(divider1, color: DesignTokens.setupBorder) }
        if let divider2 { SettingsUI.styleDividerSurface(divider2, color: DesignTokens.setupBorder) }
        if let footerBorderView { SettingsUI.styleDividerSurface(footerBorderView, color: DesignTokens.setupBorder) }
        SettingsUI.styleSurface(
            pathDisplay,
            background: DesignTokens.setupFieldBg,
            border: DesignTokens.setupFieldBorder,
            cornerRadius: DesignTokens.setupPathBoxRadius
        )
        // Rebuild footer (shortcut group, start button) with fresh colors
        updateFooter()
        // Rebuild badges with fresh colors for current state
        replaceBadge(&badge1View, num: 1, state: step1Done ? .done : .active)
        replaceBadge(&badge2View, num: 2, state: step2Done ? .done : (step1Done ? .active : .locked))
        replaceBadge(&badge3View, num: 3, state: step3Done ? .done : (step2Done ? .active : .locked))
    }


    // MARK: - Actions

    @objc func openSystemSettings() {
        // Open System Settings directly — no macOS dialog
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"

        // Start from existing folder or default
        if !folderPath.isEmpty {
            let expanded = (folderPath as NSString).expandingTildeInPath
            panel.directoryURL = URL(fileURLWithPath: expanded)
        } else {
            panel.directoryURL = URL(fileURLWithPath: NSString("~/Documents").expandingTildeInPath)
        }

        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            self.folderPath = url.path
            ConfigManager.shared.capturesFolder = url.path
            ConfigManager.shared.save()
            BookmarkManager.shared.saveBookmark(for: url)
            // VIB-303: Folder is now step 1
            self.completeStep1()
        }
    }

    @objc func startClicked() {
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        permissionTimer?.invalidate()
        permissionTimer = nil
        window?.close()
    }

    /// VIB-360: Close setup (marking complete) and open the tour window
    @objc func tourClicked() {
        ConfigManager.shared.setupComplete = true
        ConfigManager.shared.save()
        permissionTimer?.invalidate()
        permissionTimer = nil
        window?.close()
        DispatchQueue.main.async {
            TourWindowController.shared.showTour()
        }
    }

    @objc func editShortcut() {
        guard let win = window else { return }
        HotkeyCapturePanel.present(from: win) { [weak self] _ in
            self?.updateFooter()
        }
    }

    // MARK: - Helpers

    func makeLabel(_ text: String, font: NSFont, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.sizeToFit()
        return label
    }

    func makeWrappingLabel(_ text: String, font: NSFont, color: NSColor, width: CGFloat) -> NSTextField {
        let label = makeLabel(text, font: font, color: color)
        label.maximumNumberOfLines = 0
        label.preferredMaxLayoutWidth = width
        label.lineBreakMode = .byWordWrapping
        label.setFrameSize(NSSize(width: width, height: label.fittingSize.height))
        return label
    }

    func makeDivider(x: CGFloat, y: CGFloat, height: CGFloat) -> NSView {
        let d = SetupDividerView(frame: NSRect(x: x, y: y, width: 1, height: height))
        return d
    }

    func abbreviatePath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        if path.hasPrefix("~/") {
            return path
        }
        return path
    }
}
