import AppKit

final class PromptPreviewView: NSView {

    private let titleLabel = NSTextField(labelWithString: "Live preview")
    private let previewText: NSTextView
    private let scrollView: NSScrollView

    override init(frame frameRect: NSRect) {
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: frameRect.width, height: frameRect.height - 24))
        previewText = NSTextView(frame: NSRect(origin: .zero, size: scrollView.contentSize))
        super.init(frame: frameRect)
        setupView()
        refresh()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = NSColor(white: 0.53, alpha: 1)
        titleLabel.frame = NSRect(x: 0, y: frame.height - 20, width: 100, height: 16)
        addSubview(titleLabel)

        previewText.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        previewText.textColor = NSColor(white: 0.33, alpha: 1)
        previewText.isEditable = false
        previewText.isRichText = false
        previewText.drawsBackground = false

        scrollView.frame = NSRect(x: 0, y: 0, width: frame.width, height: frame.height - 28)
        scrollView.documentView = previewText
        scrollView.hasVerticalScroller = true
        scrollView.wantsLayer = true
        scrollView.layer?.backgroundColor = NSColor(white: 0.97, alpha: 1).cgColor
        scrollView.layer?.borderWidth = 1
        scrollView.layer?.borderColor = NSColor(white: 0.93, alpha: 1).cgColor
        scrollView.layer?.cornerRadius = 8
        addSubview(scrollView)
    }

    func refresh() {
        let sampleAnnotations: [Annotation] = [
            Annotation(type: .pin, number: 1, noteText: "padding too tight", position: .pin(tip: .zero), badgePosition: .zero),
            Annotation(type: .arrow, number: 2, noteText: "wrong border radius", position: .arrow(start: .zero, end: .zero), badgePosition: .zero),
            Annotation(type: .arrow, number: 3, noteText: "move this element left", position: .arrow(start: .zero, end: .zero), badgePosition: .zero),
        ]

        let capturesFolder = ConfigManager.shared.expandedCapturesFolder
        let samplePath = "\(capturesFolder)/2026-03-30_143022/screenshot.png"
        let prompt = PromptGenerator.generatePrompt(
            annotations: sampleAnnotations,
            screenshotPath: samplePath,
            mode: .clipboardIDE(absolutePath: samplePath)
        )
        previewText.string = prompt
    }
}
