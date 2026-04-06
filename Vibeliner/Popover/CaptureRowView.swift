import AppKit

final class CaptureRowView: NSView {

    private let capture: CaptureInfo
    private var isHovered = false { didSet { needsDisplay = true; updateCopyButtonVisibility() } }
    private let timestampLabel = NSTextField(labelWithString: "")
    private let noteCountLabel = NSTextField(labelWithString: "")
    private var promptButton: NSButton?
    private var imageButton: NSButton?

    init(capture: CaptureInfo) {
        self.capture = capture
        super.init(frame: .zero)
        // VIB-174: Don't call buildSubviews here — frame is .zero at init time
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
        // VIB-174: Thumbnail 44×30px with 4px radius
        let thumbView = NSImageView(frame: NSRect(x: 4, y: (h - 30) / 2, width: 44, height: 30))
        thumbView.wantsLayer = true
        thumbView.layer?.cornerRadius = 4
        thumbView.layer?.masksToBounds = true
        thumbView.layer?.borderWidth = 0.5
        thumbView.layer?.borderColor = NSColor.separatorColor.cgColor
        thumbView.imageScaling = .scaleProportionallyUpOrDown

        // Load thumbnail async
        DispatchQueue.global(qos: .utility).async { [weak thumbView] in
            if let image = NSImage(contentsOf: self.capture.screenshotURL) {
                DispatchQueue.main.async {
                    thumbView?.image = image
                }
            }
        }
        addSubview(thumbView)

        // VIB-174: Timestamp 12px rgba(255,255,255,0.85)
        let textX: CGFloat = 58  // 44 thumb + 10 gap + 4 pad
        timestampLabel.stringValue = relativeTime(from: capture.timestamp)
        timestampLabel.font = NSFont.systemFont(ofSize: 12)
        timestampLabel.textColor = .labelColor
        timestampLabel.frame = NSRect(x: textX, y: h / 2 + 1, width: 120, height: 16)
        addSubview(timestampLabel)

        // VIB-174: Note count 10px rgba(255,255,255,0.25)
        noteCountLabel.stringValue = "\(capture.noteCount) notes"
        noteCountLabel.font = NSFont.systemFont(ofSize: 10)
        noteCountLabel.textColor = .tertiaryLabelColor
        noteCountLabel.frame = NSRect(x: textX, y: h / 2 - 14, width: 60, height: 14)
        addSubview(noteCountLabel)

        // Copy Prompt button (hidden until hover)
        let promptBtn = HoverButton(title: "Prompt", target: self, action: #selector(copyPrompt))
        promptBtn.isBordered = false
        promptBtn.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        promptBtn.wantsLayer = true
        promptBtn.layer?.backgroundColor = DesignTokens.chromeBorder.cgColor
        promptBtn.layer?.cornerRadius = 6
        promptBtn.contentTintColor = DesignTokens.purpleLight
        promptBtn.frame = NSRect(x: 150, y: 8, width: 52, height: 20)
        promptBtn.isHidden = true
        addSubview(promptBtn)
        self.promptButton = promptBtn

        // Copy Image button (hidden until hover)
        let imgBtn = HoverButton(title: "Image", target: self, action: #selector(copyImage))
        imgBtn.isBordered = false
        imgBtn.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        imgBtn.wantsLayer = true
        imgBtn.layer?.backgroundColor = DesignTokens.chromeBorder.cgColor
        imgBtn.layer?.cornerRadius = 6
        imgBtn.contentTintColor = DesignTokens.purpleLight
        imgBtn.frame = NSRect(x: 155, y: 8, width: 48, height: 20)
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
        guard let button else { return }
        button.title = "Copied"
        button.contentTintColor = .systemGreen
        button.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.12).cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak button] in
            button?.title = originalTitle
            button?.contentTintColor = DesignTokens.purpleLight
            button?.layer?.backgroundColor = DesignTokens.chromeBorder.cgColor
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHovered {
            NSColor.labelColor.withAlphaComponent(0.1).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).fill()
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
        NSWorkspace.shared.selectFile(capture.screenshotURL.path, inFileViewerRootedAtPath: capture.folderURL.path)
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

private final class HoverButton: NSButton {

    private var defaultBgColor: CGColor?

    convenience init(title: String, target: AnyObject?, action: Selector?) {
        self.init(frame: .zero)
        self.title = title
        self.target = target
        self.action = action
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self))
    }

    override func mouseEntered(with event: NSEvent) {
        defaultBgColor = layer?.backgroundColor
        layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.15).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = defaultBgColor
    }
}
