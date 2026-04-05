import AppKit

final class PromptPreviewView: NSView {

    private let titleLabel = SettingsUI.sectionTitle("Full Prompt Preview")
    private let previewContainer = NSView()
    private let previewText = NSTextView()
    private let scrollView = NSScrollView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
        refresh()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        SettingsUI.stylePreviewSurface(previewContainer)
        addSubview(previewContainer)

        previewText.translatesAutoresizingMaskIntoConstraints = false
        previewText.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        previewText.textColor = .labelColor
        previewText.isEditable = false
        previewText.isRichText = false
        previewText.drawsBackground = false
        previewText.textContainerInset = NSSize(width: 8, height: 10)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = previewText
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        previewContainer.addSubview(scrollView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            previewContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            previewContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 18),
            scrollView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -18),
            scrollView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -16)
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
