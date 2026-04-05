import AppKit

final class PromptPreviewView: NSView {

    private let titleLabel = SettingsUI.sectionTitle("Full Prompt Preview")
    private let previewContainer = NSView()
    private let scrollView = NSScrollView()
    private let previewText = NSTextView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        SettingsUI.stylePreviewSurface(previewContainer)
        addSubview(previewContainer)

        // ScrollView setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        previewContainer.addSubview(scrollView)

        // NSTextView as documentView — do NOT set translatesAutoresizingMaskIntoConstraints
        // on the documentView; NSScrollView manages its frame internally.
        previewText.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        previewText.textColor = .labelColor
        previewText.isEditable = false
        previewText.isSelectable = true
        previewText.isRichText = false
        previewText.drawsBackground = false
        previewText.textContainerInset = NSSize(width: 10, height: 10)

        // Make text wrap to the scroll view's width
        previewText.isHorizontallyResizable = false
        previewText.isVerticallyResizable = true
        previewText.textContainer?.widthTracksTextView = true
        previewText.textContainer?.heightTracksTextView = false
        previewText.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = previewText

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            previewContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            previewContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -4),
        ])
    }

    func refresh(
        preamble: String? = nil,
        footer: String? = nil,
        toolDescriptions: [String: String]? = nil
    ) {
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
            mode: .clipboardIDE(absolutePath: samplePath),
            preambleOverride: preamble,
            footerOverride: footer,
            toolDescriptionsOverride: toolDescriptions
        )

        previewText.string = prompt
    }
}
