import AppKit

final class PromptPreviewView: NSView {

    private let titleLabel = SettingsUI.sectionTitle("Generated Prompt Preview")
    private let subtitleLabel = SettingsUI.bodyCopy(
        "Representative single-image and multi-image outputs generated from the same prompt builder used by copy, export, and saved prompts."
    )
    private let previewContainer = AppearanceAwarePreviewSurfaceView()
    private let sampleStack = NSStackView()
    private let singleSampleView = PromptPreviewSampleView(title: "Single-image sample")
    private let multiSampleView = PromptPreviewSampleView(title: "Multi-image sample")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(previewContainer)

        sampleStack.orientation = .vertical
        sampleStack.alignment = .leading
        sampleStack.spacing = 10
        sampleStack.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.addSubview(sampleStack)

        sampleStack.addArrangedSubview(singleSampleView)
        sampleStack.addArrangedSubview(multiSampleView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            previewContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            previewContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            sampleStack.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 10),
            sampleStack.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),
            sampleStack.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -10),
            sampleStack.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -10),
        ])

        singleSampleView.widthAnchor.constraint(equalTo: sampleStack.widthAnchor).isActive = true
        multiSampleView.widthAnchor.constraint(equalTo: sampleStack.widthAnchor).isActive = true
    }

    func refresh(
        preamble: String? = nil,
        footer: String? = nil,
        toolDescriptions: [String: String]? = nil,
        roles: [RoleConfig]? = nil,
        isDirty: Bool = false
    ) {
        subtitleLabel.stringValue = isDirty
            ? "Previewing your unsaved draft. Save to use these prompt settings for copy, export, and prompt.txt."
            : "Previewing the saved prompt settings currently used for copy, export, and prompt.txt."
        let previewRoles = normalizedPreviewRoles(from: roles)
        singleSampleView.update(text: singleImagePrompt(
            preamble: preamble,
            footer: footer,
            toolDescriptions: toolDescriptions,
            roles: previewRoles
        ))
        multiSampleView.update(text: multiImagePrompt(
            preamble: preamble,
            footer: footer,
            toolDescriptions: toolDescriptions,
            roles: previewRoles
        ))
    }

    private func singleImagePrompt(
        preamble: String?,
        footer: String?,
        toolDescriptions: [String: String]?,
        roles: [RoleConfig]
    ) -> String {
        let samplePath = "\(ConfigManager.shared.expandedCapturesFolder)/2026-04-12_091500/screenshot.png"
        let annotations: [Annotation] = [
            Annotation(type: .pin, number: 1, noteText: "increase the outer card padding", position: .pin(tip: .zero), badgePosition: .zero),
            Annotation(type: .rectangle, number: 2, noteText: "match this button radius to the rest of the form", position: .rectangle(origin: .zero, size: .zero), badgePosition: .zero),
        ]

        return PromptGenerator.generatePrompt(
            annotations: annotations,
            screenshotPath: samplePath,
            mode: .clipboardIDE(absolutePath: samplePath),
            preambleOverride: preamble,
            footerOverride: footer,
            toolDescriptionsOverride: toolDescriptions,
            rolesOverride: roles
        )
    }

    private func multiImagePrompt(
        preamble: String?,
        footer: String?,
        toolDescriptions: [String: String]?,
        roles: [RoleConfig]
    ) -> String {
        let samplePath = "\(ConfigManager.shared.expandedCapturesFolder)/2026-04-12_092200/screenshot.png"
        let session = makePreviewSession(from: roles)
        guard session.images.count >= 2 else {
            return singleImagePrompt(
                preamble: preamble,
                footer: footer,
                toolDescriptions: toolDescriptions,
                roles: roles
            )
        }

        let firstImage = session.images[0]
        let secondImage = session.images[1]

        var firstAnnotation = Annotation(
            type: .pin,
            number: 1,
            noteText: "tighten the spacing between the headline and helper text",
            position: .pin(tip: .zero),
            badgePosition: .zero
        )
        firstAnnotation.parentImageIndex = firstImage.index
        firstAnnotation.parentImageID = firstImage.id

        var secondAnnotation = Annotation(
            type: .arrow,
            number: 2,
            noteText: "match the primary button treatment from the comparison image",
            position: .arrow(start: .zero, end: .zero),
            badgePosition: .zero
        )
        secondAnnotation.parentImageIndex = firstImage.index
        secondAnnotation.parentImageID = firstImage.id
        secondAnnotation.endImageIndex = secondImage.index
        secondAnnotation.endImageID = secondImage.id

        return PromptGenerator.generatePrompt(
            annotations: [firstAnnotation, secondAnnotation],
            screenshotPath: samplePath,
            mode: .clipboardIDE(absolutePath: samplePath),
            captureSession: session,
            preambleOverride: preamble,
            footerOverride: footer,
            toolDescriptionsOverride: toolDescriptions,
            rolesOverride: roles
        )
    }

    private func normalizedPreviewRoles(from roles: [RoleConfig]?) -> [RoleConfig] {
        var normalized = (roles?.isEmpty == false ? roles : nil) ?? RoleConfig.defaultRoles
        while normalized.count < 2 {
            normalized.append(RoleConfig.defaultRoles[normalized.count])
        }
        return Array(normalized.prefix(3))
    }

    private func makePreviewSession(from roles: [RoleConfig]) -> CaptureSession {
        let titles = ["Current state", "Target state", "Reference detail"]
        let images = roles.enumerated().map { index, role in
            CaptureImage(
                sourceImage: NSImage(size: NSSize(width: 16, height: 16)),
                title: titles.indices.contains(index) ? titles[index] : "Image \(index + 1)",
                role: ImageRole(name: role.name),
                originalSize: NSSize(width: 16, height: 16),
                index: index
            )
        }
        return CaptureSession(images: images)
    }
}

private final class AppearanceAwarePreviewSurfaceView: AppearanceAwareSurfaceView {
    override func refreshSurfaceAppearance() {
        SettingsUI.stylePreviewSurface(self)
    }
}

private final class PromptPreviewSampleView: AppearanceAwareFieldView {

    private let titleLabel: NSTextField
    private let promptLabel = NSTextField(wrappingLabelWithString: "")

    init(title: String) {
        self.titleLabel = SettingsUI.regularLabel(title)
        super.init(frame: .zero)
        fieldCornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        promptLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        promptLabel.textColor = .labelColor
        promptLabel.maximumNumberOfLines = 0
        promptLabel.lineBreakMode = .byWordWrapping
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(promptLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            promptLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            promptLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            promptLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            promptLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    func update(text: String) {
        promptLabel.stringValue = text
    }
}
