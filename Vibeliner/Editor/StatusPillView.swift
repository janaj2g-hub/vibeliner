import AppKit

final class StatusPillView: NSView {

    private let label = NSTextField(labelWithString: "")
    private let blurView = NSVisualEffectView()
    private let tintView = NSView()
    private var revertTimer: Timer?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = DesignTokens.statusPillCornerRadius
        layer?.masksToBounds = false
        layer?.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.15).cgColor
        layer?.shadowOffset = NSSize(width: 0, height: -2)
        layer?.shadowRadius = 8
        layer?.shadowOpacity = 1.0

        blurView.material = .popover
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = DesignTokens.statusPillCornerRadius
        blurView.layer?.masksToBounds = true
        addSubview(blurView)

        tintView.wantsLayer = true
        tintView.layer?.cornerRadius = DesignTokens.statusPillCornerRadius
        tintView.layer?.masksToBounds = true
        tintView.layer?.borderWidth = 1
        addSubview(tintView)

        label.font = DesignTokens.statusPillFont
        label.textColor = DesignTokens.statusPillTextColor
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        addSubview(label)

        refreshAppearanceColors()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refreshAppearanceColors()
    }

    private func refreshAppearanceColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            self.tintView.layer?.backgroundColor = DesignTokens.statusPillBg.cgColor
            self.tintView.layer?.borderColor = DesignTokens.statusPillBorder.cgColor
        }
        label.textColor = DesignTokens.statusPillTextColor
    }

    func updateDimensions(width: Int, height: Int) {
        updateText("\(width) × \(height) · 0 notes")
    }

    func updateNoteCount(_ count: Int) {
        // Parse existing dimensions from label
        let parts = label.stringValue.components(separatedBy: " · ")
        let dims = parts.first ?? ""
        let noteText = count == 1 ? "1 note" : "\(count) notes"
        updateText("\(dims) · \(noteText)")
    }

    func showCopied(message: String = "Copied") {
        revertTimer?.invalidate()
        let savedText = label.stringValue

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.3
            tintView.animator().layer?.backgroundColor = DesignTokens.copiedGreen.cgColor
        })
        label.stringValue = message
        sizeToFitContent()

        revertTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.3
                self.tintView.animator().layer?.backgroundColor = DesignTokens.statusPillBg.cgColor
            })
            self.label.stringValue = savedText
            self.sizeToFitContent()
        }
    }

    private func updateText(_ text: String) {
        label.stringValue = text
        sizeToFitContent()
    }

    private func sizeToFitContent() {
        label.sizeToFit()
        let w = label.frame.width + 28
        let h: CGFloat = label.frame.height + 6
        setFrameSize(NSSize(width: w, height: h))
        label.frame = NSRect(x: 14, y: 3, width: label.frame.width, height: label.frame.height)
        blurView.frame = bounds
        tintView.frame = bounds
    }
}
