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
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        // Thumbnail
        let thumbView = NSImageView(frame: NSRect(x: 4, y: 3, width: 40, height: 28))
        thumbView.wantsLayer = true
        thumbView.layer?.cornerRadius = 4
        thumbView.layer?.masksToBounds = true
        thumbView.layer?.borderWidth = 0.5
        thumbView.layer?.borderColor = NSColor(white: 1, alpha: 0.06).cgColor
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

        // Timestamp
        timestampLabel.stringValue = relativeTime(from: capture.timestamp)
        timestampLabel.font = NSFont.systemFont(ofSize: 11)
        timestampLabel.textColor = NSColor(white: 1, alpha: 0.6)
        timestampLabel.frame = NSRect(x: 50, y: 12, width: 100, height: 16)
        addSubview(timestampLabel)

        // Note count
        noteCountLabel.stringValue = "\(capture.noteCount) notes"
        noteCountLabel.font = NSFont.systemFont(ofSize: 9)
        noteCountLabel.textColor = NSColor(white: 1, alpha: 0.25)
        noteCountLabel.frame = NSRect(x: 50, y: 0, width: 60, height: 14)
        addSubview(noteCountLabel)

        // Copy Prompt button (hidden until hover)
        let promptBtn = NSButton(title: "Prompt", target: self, action: #selector(copyPrompt))
        promptBtn.isBordered = false
        promptBtn.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        promptBtn.wantsLayer = true
        promptBtn.layer?.backgroundColor = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.12).cgColor
        promptBtn.layer?.cornerRadius = 6
        promptBtn.contentTintColor = DesignTokens.purpleLight
        promptBtn.frame = NSRect(x: 150, y: 8, width: 52, height: 20)
        promptBtn.isHidden = true
        addSubview(promptBtn)
        self.promptButton = promptBtn

        // Copy Image button (hidden until hover)
        let imgBtn = NSButton(title: "Image", target: self, action: #selector(copyImage))
        imgBtn.isBordered = false
        imgBtn.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        imgBtn.wantsLayer = true
        imgBtn.layer?.backgroundColor = NSColor(red: 175/255, green: 169/255, blue: 236/255, alpha: 0.12).cgColor
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
        // Load annotations from prompt.txt and copy
        let promptURL = capture.folderURL.appendingPathComponent("prompt.txt")
        if let text = try? String(contentsOf: promptURL, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
    }

    @objc private func copyImage() {
        if let image = NSImage(contentsOf: capture.screenshotURL) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([image])
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHovered {
            NSColor(white: 1, alpha: 0.06).setFill()
            NSBezierPath(roundedRect: bounds, xRadius: 5, yRadius: 5).fill()
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
