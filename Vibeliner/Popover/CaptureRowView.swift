import AppKit

final class CaptureRowView: PopoverHoverSurfaceView {

    private let capture: CaptureInfo
    private var isHovered = false { didSet { isSurfaceHovered = isHovered; updateCopyButtonVisibility() } }
    private let timestampLabel = NSTextField(labelWithString: "")
    private let noteCountLabel = NSTextField(labelWithString: "")
    private var promptButton: PopoverCopyButton?
    private var imageButton: PopoverCopyButton?

    init(capture: CaptureInfo) {
        self.capture = capture
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError() }

    private var didLayout = false

    override func layout() {
        super.layout()
        guard !didLayout, bounds.height > 0 else { return }
        didLayout = true
        buildSubviews()
    }

    private func buildSubviews() {
        let h = bounds.height

        // Thumbnail
        let thumbView = NSImageView(frame: NSRect(x: 4, y: (h - 30) / 2, width: 44, height: 30))
        thumbView.wantsLayer = true
        thumbView.layer?.cornerRadius = 4
        thumbView.layer?.masksToBounds = true
        thumbView.layer?.borderWidth = 0.5
        thumbView.layer?.borderColor = NSColor.separatorColor.cgColor
        thumbView.imageScaling = .scaleProportionallyUpOrDown

        // VIB-356: Load downsampled thumbnail (88px = 44pt × 2x) instead of full-res
        DispatchQueue.global(qos: .utility).async { [weak thumbView] in
            let image = ImageUtils.downsampledImage(at: self.capture.screenshotURL, maxPixelSize: 88)
                ?? NSImage(contentsOf: self.capture.screenshotURL)
            if let image {
                DispatchQueue.main.async {
                    thumbView?.image = image
                }
            }
        }
        addSubview(thumbView)

        // Timestamp
        let textX: CGFloat = 58
        timestampLabel.stringValue = relativeTime(from: capture.timestamp)
        timestampLabel.font = NSFont.systemFont(ofSize: 12)
        timestampLabel.textColor = .labelColor
        timestampLabel.frame = NSRect(x: textX, y: h / 2 + 1, width: 120, height: 16)
        addSubview(timestampLabel)

        // Note count
        noteCountLabel.stringValue = "\(capture.noteCount) notes"
        noteCountLabel.font = NSFont.systemFont(ofSize: 10)
        noteCountLabel.textColor = .tertiaryLabelColor
        noteCountLabel.frame = NSRect(x: textX, y: h / 2 - 14, width: 60, height: 14)
        addSubview(noteCountLabel)

        // VIB-394: Vertically center buttons in row
        let buttonY = (h - 20) / 2

        // Copy Prompt button (hidden until hover)
        let promptBtn = PopoverCopyButton(title: "Prompt", target: self, action: #selector(copyPrompt))
        promptBtn.frame = NSRect(x: 150, y: buttonY, width: 52, height: 20)
        promptBtn.isHidden = true
        addSubview(promptBtn)
        self.promptButton = promptBtn

        // Copy Image button (hidden until hover)
        let imgBtn = PopoverCopyButton(title: "Image", target: self, action: #selector(copyImage))
        imgBtn.frame = NSRect(x: 155, y: buttonY, width: 48, height: 20)
        imgBtn.isHidden = true
        addSubview(imgBtn)
        self.imageButton = imgBtn
    }

    private func updateCopyButtonVisibility() {
        promptButton?.isHidden = !isHovered
        imageButton?.isHidden = !isHovered
        if isHovered {
            promptButton?.frame.origin.x = frame.width - 108
            imageButton?.frame.origin.x = frame.width - 52
        }
    }

    @objc private func copyPrompt() {
        let promptURL = capture.folderURL.appendingPathComponent("prompt.txt")
        if let text = try? String(contentsOf: promptURL, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
        showCopiedFeedback(on: promptButton, originalTitle: "Prompt")
    }

    @objc private func copyImage() {
        if let image = NSImage(contentsOf: capture.screenshotURL) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
        }
        showCopiedFeedback(on: imageButton, originalTitle: "Image")
    }

    private func showCopiedFeedback(on button: NSButton?, originalTitle: String) {
        guard let button = button as? PopoverCopyButton else { return }
        button.title = "Copied"
        button.isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak button] in
            button?.title = originalTitle
            button?.isCopied = false
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }

    override func mouseDown(with event: NSEvent) {
        BookmarkManager.shared.withBookmarkAccess { _ in
            NSWorkspace.shared.selectFile(capture.screenshotURL.path, inFileViewerRootedAtPath: capture.folderURL.path)
        }
    }

    private func relativeTime(from date: Date) -> String {
        let seconds = -date.timeIntervalSinceNow
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60)) min ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600)) hours ago" }
        if seconds < 172800 { return "Yesterday" }
        if seconds < 604800 { return "\(Int(seconds / 86400)) days ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Button with hover highlight

private final class PopoverCopyButton: AppearanceAwareSurfaceButton {
    var isCopied = false {
        didSet { refreshSurfaceAppearance() }
    }
    private var isHovered = false {
        didSet { refreshSurfaceAppearance() }
    }

    convenience init(title: String, target: AnyObject?, action: Selector?) {
        self.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
        isBordered = false
        bezelStyle = .regularSquare
        focusRingType = .none
        font = NSFont.systemFont(ofSize: 10, weight: .medium)
        wantsLayer = true
        setButtonType(.momentaryPushIn)
        refreshSurfaceAppearance()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func refreshSurfaceAppearance() {
        if isCopied {
            contentTintColor = DesignTokens.copiedGreenText
            SettingsUI.styleSurface(
                self,
                background: DesignTokens.copiedGreenBg,
                border: DesignTokens.copiedGreenBorder,
                cornerRadius: 6
            )
            return
        }

        contentTintColor = DesignTokens.purpleBrand
        let borderColor = isHovered ? DesignTokens.purpleBrand : NSColor.separatorColor
        SettingsUI.styleSurface(
            self,
            background: isHovered ? DesignTokens.toolbarButtonHoverBg : DesignTokens.purpleStrong,
            border: borderColor,
            cornerRadius: 6
        )
    }
}
