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

enum HarnessAppearance {
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
#endif

