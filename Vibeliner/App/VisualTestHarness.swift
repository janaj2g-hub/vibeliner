import AppKit

#if DEBUG
/// Debug facility that opens a reusable verification gallery for runtime surfaces.
/// Launch with: open Vibeliner.app --args --visual-test
final class VisualTestHarness {

    private var window: NSWindow?

    func show() {
        let win = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1520, height: 980),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Vibeliner Visual Harness"
        win.isReleasedWhenClosed = false
        win.minSize = NSSize(width: 1220, height: 760)
        win.backgroundColor = .windowBackgroundColor
        win.contentView = HarnessGalleryRootView(frame: win.contentLayoutRect)
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }
}

private enum HarnessAppearance {
    case light
    case dark

    var nsAppearance: NSAppearance? {
        switch self {
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }

    var label: String {
        switch self {
        case .light: return "Light mode"
        case .dark: return "Dark mode"
        }
    }
}

private final class HarnessDocumentView: NSView {
    override var isFlipped: Bool { true }
}

private final class HarnessGalleryRootView: NSView {
    private let scrollView = NSScrollView()
    private let documentView = HarnessDocumentView()
    private let galleryStack = NSStackView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        addSubview(scrollView)

        documentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = documentView

        galleryStack.orientation = .vertical
        galleryStack.alignment = .leading
        galleryStack.spacing = 22
        galleryStack.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(galleryStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            documentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            documentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            documentView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),

            galleryStack.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 28),
            galleryStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 28),
            galleryStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -28),
            galleryStack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -28),
        ])

        galleryStack.addArrangedSubview(makeHeader())
        galleryStack.addArrangedSubview(makeSettingsSection())
        galleryStack.addArrangedSubview(makeSetupAndPopoverSection())
        galleryStack.addArrangedSubview(makeEditorSection())
    }

    private func makeHeader() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let title = NSTextField(labelWithString: "Reusable verification gallery")
        title.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        title.textColor = .labelColor
        title.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(title)

        let body = NSTextField(wrappingLabelWithString:
            "This local-only harness renders real settings, popover, and editor surfaces, plus setup and dense annotation probes. Use the dense editor scenes for hover, selection, and drag regression checks before or after UI polish work."
        )
        body.font = NSFont.systemFont(ofSize: 13)
        body.textColor = .secondaryLabelColor
        body.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(body)

        let command = NSTextField(labelWithString: "Launch: open dist/Vibeliner.app --args --visual-test")
        command.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .medium)
        command.textColor = .tertiaryLabelColor
        command.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(command)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.topAnchor),
            title.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            body.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            command.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 8),
            command.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            command.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            command.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    private func makeSettingsSection() -> NSView {
        let cards = NSStackView()
        cards.orientation = .horizontal
        cards.alignment = .top
        cards.spacing = 16
        cards.translatesAutoresizingMaskIntoConstraints = false

        let general = GeneralTabView()
        general.appearance = HarnessAppearance.light.nsAppearance
        general.layoutSubtreeIfNeeded()

        let promptPreview = PromptPreviewView()
        promptPreview.refresh()
        promptPreview.appearance = HarnessAppearance.dark.nsAppearance
        promptPreview.layoutSubtreeIfNeeded()

        cards.addArrangedSubview(HarnessCardView(
            title: "Settings — General",
            subtitle: "Real General tab content, pinned to light mode for first-open appearance checks.",
            appearanceName: HarnessAppearance.light.label,
            contentView: general,
            contentSize: NSSize(width: 500, height: 430)
        ))
        cards.addArrangedSubview(HarnessCardView(
            title: "Settings — Prompt preview",
            subtitle: "Real prompt-preview surface using the same generator path as copy/export/prompt.txt.",
            appearanceName: HarnessAppearance.dark.label,
            contentView: promptPreview,
            contentSize: NSSize(width: 500, height: 430)
        ))

        return makeSection(
            title: "Settings surfaces",
            subtitle: "Representative live settings surfaces instead of screenshots or detached docs.",
            content: cards
        )
    }

    private func makeSetupAndPopoverSection() -> NSView {
        let cards = NSStackView()
        cards.orientation = .horizontal
        cards.alignment = .top
        cards.spacing = 16
        cards.translatesAutoresizingMaskIntoConstraints = false

        let step2Preview = SetupHarnessSurfaceView(variant: .step2Active)
        step2Preview.appearance = HarnessAppearance.light.nsAppearance

        let step3Preview = SetupHarnessSurfaceView(variant: .step3Active)
        step3Preview.appearance = HarnessAppearance.dark.nsAppearance

        let popoverLight = PopoverContentView()
        popoverLight.appearance = HarnessAppearance.light.nsAppearance

        let popoverDark = PopoverContentView()
        popoverDark.appearance = HarnessAppearance.dark.nsAppearance

        cards.addArrangedSubview(HarnessCardView(
            title: "Setup — step 2 active",
            subtitle: "Harness-only setup adapter using the same tokens and geometry contract as the runtime setup flow.",
            appearanceName: HarnessAppearance.light.label,
            contentView: step2Preview,
            contentSize: step2Preview.intrinsicContentSize
        ))
        cards.addArrangedSubview(HarnessCardView(
            title: "Setup — step 3 active",
            subtitle: "Shows the screen-recording action row and helper note in the same setup contract.",
            appearanceName: HarnessAppearance.dark.label,
            contentView: step3Preview,
            contentSize: step3Preview.intrinsicContentSize
        ))
        cards.addArrangedSubview(HarnessCardView(
            title: "Popover menu",
            subtitle: "Real popover content surface for hover, divider, and first-attach appearance checks.",
            appearanceName: HarnessAppearance.light.label,
            contentView: popoverLight,
            contentSize: popoverLight.frame.size
        ))
        cards.addArrangedSubview(HarnessCardView(
            title: "Popover menu",
            subtitle: "Same runtime popover in dark mode to compare chrome without re-running the app flow.",
            appearanceName: HarnessAppearance.dark.label,
            contentView: popoverDark,
            contentSize: popoverDark.frame.size
        ))

        return makeSection(
            title: "Setup + popover probes",
            subtitle: "These probes keep appearance-sensitive surfaces easy to compare in light and dark mode.",
            content: cards
        )
    }

    private func makeEditorSection() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let calm = EditorHarnessSurfaceView(style: .calmSingleImage)
        calm.appearance = HarnessAppearance.light.nsAppearance
        let denseSingle = EditorHarnessSurfaceView(style: .denseHoverSelection)
        denseSingle.appearance = HarnessAppearance.dark.nsAppearance
        let denseFilmstrip = EditorHarnessSurfaceView(style: .denseFilmstrip)
        denseFilmstrip.appearance = HarnessAppearance.light.nsAppearance

        stack.addArrangedSubview(HarnessCardView(
            title: "Editor — calm canvas",
            subtitle: "Single-image runtime chrome with a modest annotation load for baseline visual review.",
            appearanceName: HarnessAppearance.light.label,
            contentView: calm,
            contentSize: calm.intrinsicContentSize
        ))
        stack.addArrangedSubview(HarnessCardView(
            title: "Editor — dense hover/select",
            subtitle: "Real canvas, note pills, and select-tool wiring for hover, selection, and drag checks under load.",
            appearanceName: HarnessAppearance.dark.label,
            contentView: denseSingle,
            contentSize: denseSingle.intrinsicContentSize
        ))
        stack.addArrangedSubview(HarnessCardView(
            title: "Editor — dense filmstrip",
            subtitle: "Real filmstrip grid, title pills, and cross-image annotations for multi-image regression checks.",
            appearanceName: HarnessAppearance.light.label,
            contentView: denseFilmstrip,
            contentSize: denseFilmstrip.intrinsicContentSize
        ))

        return makeSection(
            title: "Editor scenarios",
            subtitle: "These are the scenarios reused by the manual dense-annotation baseline and regression checklist.",
            content: stack
        )
    }

    private func makeSection(title: String, subtitle: String, content: NSView) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let subtitleLabel = NSTextField(wrappingLabelWithString: subtitle)
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(subtitleLabel)

        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            content.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }
}

private final class HarnessCardView: AppearanceAwareSurfaceView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(wrappingLabelWithString: "")
    private let appearanceLabel = NSTextField(labelWithString: "")
    private let contentHost = NSView()

    init(title: String, subtitle: String, appearanceName: String, contentView: NSView, contentSize: NSSize) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.stringValue = title
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        subtitleLabel.stringValue = subtitle
        subtitleLabel.font = NSFont.systemFont(ofSize: 11)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)

        appearanceLabel.stringValue = appearanceName
        appearanceLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        appearanceLabel.textColor = .tertiaryLabelColor
        appearanceLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(appearanceLabel)

        contentHost.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentHost)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.appearance = contentView.appearance ?? (appearanceName == HarnessAppearance.dark.label ? HarnessAppearance.dark.nsAppearance : HarnessAppearance.light.nsAppearance)
        contentHost.appearance = contentView.appearance
        contentHost.addSubview(contentView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: contentSize.width + 28),

            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            appearanceLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            appearanceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            appearanceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            contentHost.topAnchor.constraint(equalTo: appearanceLabel.bottomAnchor, constant: 10),
            contentHost.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            contentHost.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            contentHost.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            contentHost.widthAnchor.constraint(equalToConstant: contentSize.width),
            contentHost.heightAnchor.constraint(equalToConstant: contentSize.height),

            contentView.topAnchor.constraint(equalTo: contentHost.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentHost.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentHost.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentHost.bottomAnchor),
        ])

        refreshSurfaceAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func refreshSurfaceAppearance() {
        SettingsUI.stylePreviewSurface(self)
    }
}

private enum SetupPreviewVariant {
    case step2Active
    case step3Active
}

private final class SetupHarnessSurfaceView: NSView {
    private let variant: SetupPreviewVariant

    init(variant: SetupPreviewVariant) {
        self.variant = variant
        super.init(frame: NSRect(x: 0, y: 0, width: 520, height: 240))
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }
    override var intrinsicContentSize: NSSize { frame.size }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        DesignTokens.setupWindowBg.setFill()
        bounds.fill()

        let footerHeight: CGFloat = 52
        let panelHeight = bounds.height - footerHeight
        let panelWidth = floor((bounds.width - 2) / 3)

        let footerRect = CGRect(x: 0, y: panelHeight, width: bounds.width, height: footerHeight)
        DesignTokens.setupFooterBg.setFill()
        footerRect.fill()

        DesignTokens.setupBorder.setFill()
        CGRect(x: panelWidth, y: 0, width: 1, height: panelHeight).fill()
        CGRect(x: panelWidth * 2 + 1, y: 0, width: 1, height: panelHeight).fill()
        CGRect(x: 0, y: panelHeight, width: bounds.width, height: 1).fill()

        drawPanel(
            index: 1,
            title: "Captures folder",
            description: "Choose where Vibeliner saves screenshots and prompts.",
            panelRect: CGRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            state: .done,
            showsAction: false,
            actionLabel: "",
            helperText: nil,
            statusText: "Folder ready"
        )
        drawPanel(
            index: 2,
            title: "Accessibility",
            description: "Vibeliner needs accessibility permission so the capture hotkey works from any app.",
            panelRect: CGRect(x: panelWidth + 1, y: 0, width: panelWidth, height: panelHeight),
            state: variant == .step2Active ? .active : .done,
            showsAction: variant == .step2Active,
            actionLabel: "Open Accessibility Settings",
            helperText: nil,
            statusText: variant == .step2Active ? nil : "Permission granted"
        )
        drawPanel(
            index: 3,
            title: "Screen recording",
            description: "Vibeliner needs screen recording permission to capture screenshots of your running app.",
            panelRect: CGRect(x: panelWidth * 2 + 2, y: 0, width: panelWidth, height: panelHeight),
            state: variant == .step3Active ? .active : .locked,
            showsAction: variant == .step3Active,
            actionLabel: "Open Screen Recording Settings",
            helperText: variant == .step3Active ? "You may need to restart the app after granting." : nil,
            statusText: variant == .step3Active ? nil : "Complete step 2 first"
        )

        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: DesignTokens.setupDescFont,
            .foregroundColor: DesignTokens.setupGrayText,
        ]
        let footerText = NSAttributedString(string: "Complete all steps to continue", attributes: footerAttrs)
        let footerSize = footerText.size()
        footerText.draw(at: CGPoint(x: bounds.width - footerSize.width - 18, y: panelHeight + (footerHeight - footerSize.height) / 2))
    }

    private enum PanelState { case done, active, locked }

    private func drawPanel(
        index: Int,
        title: String,
        description: String,
        panelRect: CGRect,
        state: PanelState,
        showsAction: Bool,
        actionLabel: String,
        helperText: String?,
        statusText: String?
    ) {
        let pad = DesignTokens.setupPanelPad
        let contentWidth = panelRect.width - pad * 2
        let badgeRect = CGRect(x: panelRect.minX + pad, y: pad, width: DesignTokens.setupBadgeSize, height: DesignTokens.setupBadgeSize)
        drawBadge(in: badgeRect, index: index, state: state)

        let titleRect = CGRect(x: badgeRect.maxX + 12, y: pad + 2, width: contentWidth - 44, height: 22)
        drawText(title, rect: titleRect, font: DesignTokens.setupPanelTitleFont, color: DesignTokens.setupTextPrimary)

        let descriptionRect = CGRect(x: panelRect.minX + pad, y: badgeRect.maxY + 18, width: contentWidth, height: 72)
        drawText(description, rect: descriptionRect, font: DesignTokens.setupDescFont, color: DesignTokens.setupTextSecondary)

        if let helperText {
            let helperRect = CGRect(x: panelRect.minX + pad, y: panelRect.maxY - 86, width: contentWidth, height: 30)
            drawText(helperText, rect: helperRect, font: DesignTokens.setupHelperFont, color: DesignTokens.setupTextDim, alignment: .center)
        }

        if showsAction {
            let labelRect = CGRect(x: panelRect.minX + pad, y: panelRect.maxY - 64, width: contentWidth, height: 18)
            drawText(actionLabel, rect: labelRect, font: DesignTokens.setupActionLabelFont, color: DesignTokens.setupButtonText, alignment: .center)
            drawCircleArrow(in: CGRect(
                x: panelRect.midX - DesignTokens.setupArrowSize / 2,
                y: panelRect.maxY - 64 + 26,
                width: DesignTokens.setupArrowSize,
                height: DesignTokens.setupArrowSize
            ))
        } else if let statusText {
            let statusColor: NSColor = state == .done ? DesignTokens.setupGreenText : DesignTokens.setupGrayText
            let statusRect = CGRect(x: panelRect.minX + pad, y: panelRect.maxY - 42, width: contentWidth, height: 20)
            drawText(statusText, rect: statusRect, font: DesignTokens.setupStatusFont, color: statusColor, alignment: .center)
        }
    }

    private func drawBadge(in rect: CGRect, index: Int, state: PanelState) {
        let path = NSBezierPath(ovalIn: rect)
        path.lineWidth = 2
        switch state {
        case .done:
            DesignTokens.setupGreenBadgeBg.setFill()
            DesignTokens.setupGreen.setStroke()
            path.fill()
            path.stroke()
            drawText("✓", rect: rect, font: DesignTokens.setupBadgeCheckFont, color: DesignTokens.setupGreen, alignment: .center)
        case .active:
            DesignTokens.setupButtonFill.setFill()
            DesignTokens.setupButtonBorder.setStroke()
            path.fill()
            path.stroke()
            drawText("\(index)", rect: rect, font: DesignTokens.setupBadgeFont, color: DesignTokens.setupButtonText, alignment: .center)
        case .locked:
            DesignTokens.setupGrayBg.setFill()
            DesignTokens.setupGrayText.setStroke()
            path.fill()
            path.stroke()
            drawText("\(index)", rect: rect, font: DesignTokens.setupBadgeFont, color: DesignTokens.setupGrayText, alignment: .center)
        }
    }

    private func drawCircleArrow(in rect: CGRect) {
        let path = NSBezierPath(ovalIn: rect)
        SettingsUI.styleSurface(
            self,
            background: .clear,
            borderWidth: 0
        )
        DesignTokens.setupButtonFill.setFill()
        DesignTokens.setupButtonBorder.setStroke()
        path.lineWidth = 1
        path.fill()
        path.stroke()

        let arrow = NSAttributedString(
            string: "→",
            attributes: [
                .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: DesignTokens.setupButtonText,
            ]
        )
        let size = arrow.size()
        arrow.draw(at: CGPoint(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2))
    }

    private func drawText(_ text: String, rect: CGRect, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]
        NSString(string: text).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs)
    }
}

private enum EditorHarnessStyle {
    case calmSingleImage
    case denseHoverSelection
    case denseFilmstrip

    var size: NSSize {
        switch self {
        case .denseFilmstrip:
            return NSSize(width: 920, height: 440)
        case .calmSingleImage, .denseHoverSelection:
            return NSSize(width: 760, height: 430)
        }
    }
}

private final class EditorHarnessSurfaceView: NSView {
    private let style: EditorHarnessStyle
    private let toolbar = ToolbarView()
    private let statusPill = StatusPillView()
    private var screenshotView: ScreenshotCanvasView?
    private var filmstripView: FilmstripGridView?
    private var canvas: CanvasView?
    private var store: AnnotationStore?
    private var session: CaptureSession?

    init(style: EditorHarnessStyle) {
        self.style = style
        super.init(frame: NSRect(origin: .zero, size: style.size))
        wantsLayer = false
        buildScene()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { frame.size }

    private func buildScene() {
        switch style {
        case .calmSingleImage:
            buildSingleImageScene(dense: false)
        case .denseHoverSelection:
            buildSingleImageScene(dense: true)
        case .denseFilmstrip:
            buildFilmstripScene()
        }
    }

    private func buildSingleImageScene(dense: Bool) {
        let canvasFrame = NSRect(x: 48, y: 74, width: bounds.width - 96, height: 250)
        let sampleImage = Self.generateSampleImage(width: canvasFrame.width, height: canvasFrame.height, accent: dense ? DesignTokens.red : DesignTokens.purpleLight)
        let screenshot = ScreenshotCanvasView(image: sampleImage)
        screenshot.frame = canvasFrame
        addSubview(screenshot)
        screenshotView = screenshot

        let annotationStore = AnnotationStore()
        if dense {
            Self.addDenseAnnotations(to: annotationStore, canvasSize: canvasFrame.size)
        } else {
            Self.addCalmAnnotations(to: annotationStore, canvasSize: canvasFrame.size)
        }

        let canvas = makeCanvas(frame: CGRect(origin: .zero, size: canvasFrame.size), store: annotationStore)
        screenshot.addSubview(canvas)
        configureHighlightState(for: canvas, store: annotationStore, dense: dense)

        self.store = annotationStore
        self.canvas = canvas

        toolbar.updateAnnotationCount(annotationStore.count)
        let toolbarFrame = CGRect(
            x: (bounds.width - toolbar.frame.width) / 2,
            y: 22,
            width: toolbar.frame.width,
            height: toolbar.frame.height
        )
        toolbar.frame = toolbarFrame
        addSubview(toolbar)

        statusPill.updateDimensions(width: Int(canvasFrame.width), height: Int(canvasFrame.height))
        statusPill.updateNoteCount(annotationStore.annotations.filter { !$0.noteText.isEmpty }.count)
        statusPill.frame.origin = CGPoint(x: (bounds.width - statusPill.frame.width) / 2, y: canvasFrame.maxY + 12)
        addSubview(statusPill)
    }

    private func buildFilmstripScene() {
        let images = [
            Self.makeCaptureImage(width: 320, height: 200, title: "Current", role: .observed, accent: DesignTokens.purpleLight, index: 0),
            Self.makeCaptureImage(width: 280, height: 200, title: "Target", role: .expected, accent: DesignTokens.setupGreen, index: 1),
            Self.makeCaptureImage(width: 300, height: 200, title: "Reference", role: .reference, accent: NSColor.systemBlue, index: 2),
        ]
        let session = CaptureSession(images: images)
        self.session = session

        let filmstrip = FilmstripGridView(frame: NSRect(x: 28, y: 74, width: bounds.width - 56, height: 252))
        addSubview(filmstrip)
        filmstrip.setImages(session.images, selectedIndex: 1)
        filmstripView = filmstrip

        let annotationStore = AnnotationStore()
        let overlay = makeCanvas(frame: filmstrip.imageAreaRect, store: annotationStore)
        overlay.frame.origin = filmstrip.imageAreaRect.origin
        overlay.imageIndexAtPoint = { [weak filmstrip] point in
            filmstrip?.imageIndexAtPoint(point) ?? 0
        }
        overlay.imageIDAtPoint = { [weak filmstrip, weak session] point in
            guard let filmstrip, let session else { return nil }
            return session.imageID(at: filmstrip.imageIndexAtPoint(point))
        }
        filmstrip.scrollableContentView.addSubview(overlay)

        Self.addFilmstripAnnotations(to: annotationStore, filmstrip: filmstrip, session: session)
        configureHighlightState(for: overlay, store: annotationStore, dense: true)

        self.store = annotationStore
        self.canvas = overlay

        toolbar.updateAnnotationCount(annotationStore.count)
        toolbar.frame.origin = CGPoint(x: (bounds.width - toolbar.frame.width) / 2, y: 18)
        addSubview(toolbar)

        statusPill.updateDimensions(width: Int(bounds.width - 56), height: Int(filmstrip.imageAreaRect.height))
        statusPill.updateNoteCount(annotationStore.annotations.filter { !$0.noteText.isEmpty }.count)
        statusPill.frame.origin = CGPoint(x: (bounds.width - statusPill.frame.width) / 2, y: filmstrip.frame.maxY + 10)
        addSubview(statusPill)
    }

    private func makeCanvas(frame: CGRect, store: AnnotationStore) -> CanvasView {
        let canvas = CanvasView(frame: frame, store: store)
        let selectTool = SelectTool()
        canvas.selectTool = selectTool
        canvas.activeTool = selectTool
        canvas.undoManager_ = UndoRedoManager(store: store)
        return canvas
    }

    private func configureHighlightState(for canvas: CanvasView, store: AnnotationStore, dense: Bool) {
        guard let hovered = store.annotations.dropFirst().first?.id else { return }
        let selected = store.annotations.last?.id ?? hovered
        canvas.marksLayer.hoveredId = hovered
        canvas.marksLayer.selectedId = selected
        store.select(id: selected)
        canvas.marksLayer.needsDisplay = true
        canvas.refreshNotePills()
        if dense {
            canvas.needsDisplay = true
        }
    }

    private static func generateSampleImage(width: CGFloat, height: CGFloat, accent: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()

        let gradient = NSGradient(
            starting: accent.withAlphaComponent(0.10),
            ending: NSColor.windowBackgroundColor.blended(withFraction: 0.12, of: accent) ?? accent.withAlphaComponent(0.16)
        )
        gradient?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 140)

        NSColor.controlBackgroundColor.setFill()
        NSRect(x: 0, y: height - 28, width: width, height: 28).fill()
        NSColor.separatorColor.setFill()
        NSRect(x: 0, y: height - 29, width: width, height: 1).fill()

        let dots: [(NSColor, CGFloat)] = [
            (NSColor.systemRed, 14),
            (NSColor.systemYellow, 28),
            (NSColor.systemGreen, 42),
        ]
        for (color, xOff) in dots {
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: xOff, y: height - 20, width: 8, height: 8)).fill()
        }

        let cardColor = accent.withAlphaComponent(0.12)
        for index in 0..<4 {
            let cardRect = NSRect(x: 22 + CGFloat(index % 2) * ((width - 66) / 2), y: height - 110 - CGFloat(index / 2) * 92, width: (width - 66) / 2, height: 72)
            cardColor.setFill()
            NSBezierPath(roundedRect: cardRect, xRadius: 10, yRadius: 10).fill()
            NSColor.separatorColor.setStroke()
            NSBezierPath(roundedRect: cardRect, xRadius: 10, yRadius: 10).stroke()
        }

        image.unlockFocus()
        return image
    }

    private static func makeCaptureImage(width: CGFloat, height: CGFloat, title: String, role: ImageRole, accent: NSColor, index: Int) -> CaptureImage {
        let image = generateSampleImage(width: width, height: height, accent: accent)
        return CaptureImage(sourceImage: image, title: title, role: role, originalSize: image.size, index: index)
    }

    private static func addCalmAnnotations(to store: AnnotationStore, canvasSize: CGSize) {
        let pin = Annotation(
            type: .pin,
            number: 0,
            noteText: "give this card more breathing room",
            position: .pin(tip: CGPoint(x: 130, y: 90)),
            badgePosition: CGPoint(x: 130, y: 90 - DesignTokens.stakeLength - DesignTokens.badgeDiameter / 2)
        )
        _ = store.add(pin)

        let arrow = Annotation(
            type: .arrow,
            number: 0,
            noteText: "align this action with the field above",
            position: .arrow(start: CGPoint(x: canvasSize.width * 0.55, y: 90), end: CGPoint(x: canvasSize.width * 0.73, y: 150)),
            badgePosition: CGPoint(x: canvasSize.width * 0.55, y: 90)
        )
        _ = store.add(arrow)

        let rectOrigin = CGPoint(x: 84, y: canvasSize.height * 0.56)
        let rectSize = CGSize(width: 180, height: 72)
        let rect = Annotation(
            type: .rectangle,
            number: 0,
            noteText: "match this section frame to the rest of settings",
            position: .rectangle(origin: rectOrigin, size: rectSize),
            badgePosition: CGPoint(x: rectOrigin.x, y: rectOrigin.y + rectSize.height)
        )
        _ = store.add(rect)
    }

    private static func addDenseAnnotations(to store: AnnotationStore, canvasSize: CGSize) {
        let columns = 4
        let rows = 5
        let cellWidth = (canvasSize.width - 160) / CGFloat(columns)
        let cellHeight = (canvasSize.height - 120) / CGFloat(rows)
        var noteNumber = 0

        for row in 0..<rows {
            for column in 0..<columns {
                let origin = CGPoint(
                    x: 44 + CGFloat(column) * cellWidth,
                    y: 38 + CGFloat(row) * cellHeight
                )
                switch (row + column) % 4 {
                case 0:
                    let size = CGSize(width: 52 + CGFloat((row * 7) % 24), height: 34 + CGFloat((column * 5) % 18))
                    var annotation = Annotation(
                        type: .rectangle,
                        number: 0,
                        noteText: "tighten spacing in cluster \(noteNumber + 1)",
                        position: .rectangle(origin: origin, size: size),
                        badgePosition: CGPoint(x: origin.x, y: origin.y + size.height)
                    )
                    annotation.parentImageIndex = 0
                    _ = store.add(annotation)
                case 1:
                    let center = CGPoint(x: origin.x + 38, y: origin.y + 26)
                    var annotation = Annotation(
                        type: .circle,
                        number: 0,
                        noteText: "icon weight mismatch in row \(row + 1)",
                        position: .circle(center: center, radius: 24),
                        badgePosition: CGPoint(x: center.x + 24, y: center.y)
                    )
                    annotation.parentImageIndex = 0
                    _ = store.add(annotation)
                case 2:
                    let start = CGPoint(x: origin.x, y: origin.y + 8)
                    let end = CGPoint(x: origin.x + 52, y: origin.y + 34)
                    var annotation = Annotation(
                        type: .arrow,
                        number: 0,
                        noteText: "line this up with the active state",
                        position: .arrow(start: start, end: end),
                        badgePosition: start
                    )
                    annotation.parentImageIndex = 0
                    _ = store.add(annotation)
                default:
                    let points = FreehandTool.smoothPoints([
                        CGPoint(x: origin.x, y: origin.y + 10),
                        CGPoint(x: origin.x + 16, y: origin.y + 18),
                        CGPoint(x: origin.x + 24, y: origin.y + 8),
                        CGPoint(x: origin.x + 38, y: origin.y + 22),
                        CGPoint(x: origin.x + 52, y: origin.y + 16),
                    ], passes: 2)
                    var annotation = Annotation(
                        type: .freehand,
                        number: 0,
                        noteText: "shape contrast breaks under hover",
                        position: .freehand(points: points),
                        badgePosition: points.first ?? origin
                    )
                    annotation.parentImageIndex = 0
                    _ = store.add(annotation)
                }
                noteNumber += 1
            }
        }
    }

    private static func addFilmstripAnnotations(to store: AnnotationStore, filmstrip: FilmstripGridView, session: CaptureSession) {
        guard session.images.count >= 3 else { return }
        for index in 0..<session.images.count {
            let cell = filmstrip.imageCellFrameInCanvas(at: index)
            let image = session.images[index]

            var pin = Annotation(
                type: .pin,
                number: 0,
                noteText: "title pill and preview should stay aligned",
                position: .pin(tip: CGPoint(x: cell.minX + 30, y: cell.minY + 38)),
                badgePosition: CGPoint(x: cell.minX + 30, y: cell.minY + 38 - DesignTokens.stakeLength - DesignTokens.badgeDiameter / 2)
            )
            pin.parentImageIndex = image.index
            pin.parentImageID = image.id
            _ = store.add(pin)

            var rect = Annotation(
                type: .rectangle,
                number: 0,
                noteText: "keep this filmstrip card visually stable during hover",
                position: .rectangle(origin: CGPoint(x: cell.minX + 56, y: cell.minY + 52), size: CGSize(width: cell.width * 0.42, height: cell.height * 0.28)),
                badgePosition: CGPoint(x: cell.minX + 56, y: cell.minY + 52 + cell.height * 0.28)
            )
            rect.parentImageIndex = image.index
            rect.parentImageID = image.id
            _ = store.add(rect)

            var circle = Annotation(
                type: .circle,
                number: 0,
                noteText: "role color and selected border should remain readable",
                position: .circle(center: CGPoint(x: cell.maxX - 42, y: cell.minY + 64), radius: 20),
                badgePosition: CGPoint(x: cell.maxX - 22, y: cell.minY + 64)
            )
            circle.parentImageIndex = image.index
            circle.parentImageID = image.id
            _ = store.add(circle)
        }

        let first = session.images[0]
        let second = session.images[1]
        let firstCell = filmstrip.imageCellFrameInCanvas(at: 0)
        let secondCell = filmstrip.imageCellFrameInCanvas(at: 1)

        var crossImageArrow = Annotation(
            type: .arrow,
            number: 0,
            noteText: "cross-image callouts should survive filmstrip selection changes",
            position: .arrow(
                start: CGPoint(x: firstCell.midX, y: firstCell.midY),
                end: CGPoint(x: secondCell.minX + 54, y: secondCell.midY - 16)
            ),
            badgePosition: CGPoint(x: firstCell.midX, y: firstCell.midY)
        )
        crossImageArrow.parentImageIndex = first.index
        crossImageArrow.parentImageID = first.id
        crossImageArrow.endImageIndex = second.index
        crossImageArrow.endImageID = second.id
        _ = store.add(crossImageArrow)
    }
}
#endif
