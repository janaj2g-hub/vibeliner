import AppKit

final class TourWindowController: NSWindowController {

    // MARK: - Singleton

    static let shared = TourWindowController()

    // MARK: - State

    private var currentStep = 0
    private let steps = TourStep.allSteps

    // MARK: - UI refs — header

    private var headerView: NSView!
    private var headerBorderView: NSView!
    private var exitButton: HoverButton!

    // MARK: - UI refs — body

    private var bodyView: NSView!
    private var illustrationPane: NSView!
    private var dividerView: NSView!
    private var textPane: NSView!
    private var stepBadgeLabel: NSTextField!
    private var titleLabel: NSTextField!
    private var bodyLabel: NSTextField!

    // MARK: - UI refs — footer

    private var footerView: NSView!
    private var footerBorderView: NSView!
    private var progressLabel: NSTextField!
    private var progressBars: [NSView] = []
    private var backButton: HoverButton!
    private var nextButton: HoverButton!

    // MARK: - UI refs — step 9 full-width done view

    private var doneView: NSView?

    // MARK: - Layout constraints for split mode

    private var illustrationWidthConstraint: NSLayoutConstraint!
    private var textPaneWidthConstraint: NSLayoutConstraint!

    // MARK: - Init

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0,
                                width: DesignTokens.tourWindowWidth,
                                height: DesignTokens.tourWindowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false  // Keep false for rounded corners to show through

        super.init(window: panel)

        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    // MARK: - Public API

    func showTour() {
        currentStep = 0
        refreshAppearanceColors()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Build UI

    private func buildUI() {
        guard let panel = window else { return }

        let contentView = TourContentView(frame: panel.contentView!.bounds)
        contentView.onAppearanceChange = { [weak self] in self?.refreshAppearanceColors() }
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = DesignTokens.tourWindowBg.cgColor
        contentView.layer?.cornerRadius = DesignTokens.tourWindowRadius
        contentView.layer?.masksToBounds = true
        contentView.layer?.borderWidth = 1
        contentView.layer?.borderColor = DesignTokens.tourWindowBorder.cgColor
        panel.contentView = contentView

        buildHeader(in: contentView)
        buildFooter(in: contentView)
        buildBody(in: contentView)

        refreshAppearanceColors()
    }

    // MARK: - Header

    private func buildHeader(in parent: NSView) {
        headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = DesignTokens.tourBarOverlay.cgColor
        parent.addSubview(headerView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: parent.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: DesignTokens.tourHeaderHeight),
        ])

        // Header border bottom
        headerBorderView = NSView()
        headerBorderView.translatesAutoresizingMaskIntoConstraints = false
        headerBorderView.wantsLayer = true
        headerBorderView.layer?.backgroundColor = DesignTokens.tourBarDivider.cgColor
        headerView.addSubview(headerBorderView)
        NSLayoutConstraint.activate([
            headerBorderView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerBorderView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerBorderView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerBorderView.heightAnchor.constraint(equalToConstant: 1),
        ])

        // Title label
        let titleLabel = NSTextField(labelWithString: "Vibeliner Overview")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DesignTokens.tourHeaderFont
        titleLabel.textColor = DesignTokens.tourTextPrimary
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        headerView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
        ])

        // Exit tour button — ghost pill with explicit attributed title for visibility
        exitButton = HoverButton(title: "", target: self, action: #selector(exitTour))
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.isBordered = false
        exitButton.wantsLayer = true
        exitButton.layer?.cornerRadius = 999
        exitButton.layer?.borderWidth = 1
        headerView.addSubview(exitButton)
        NSLayoutConstraint.activate([
            exitButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            exitButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            exitButton.heightAnchor.constraint(equalToConstant: 26),
            exitButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 72),
        ])
        exitButton.onMouseEntered = { [weak self] in self?.setExitButtonHover(true) }
        exitButton.onMouseExited = { [weak self] in self?.setExitButtonHover(false) }
        updateExitButtonAppearance(hovered: false)
    }

    private func setExitButtonHover(_ hovered: Bool) {
        updateExitButtonAppearance(hovered: hovered)
    }

    // MARK: - Footer

    private func buildFooter(in parent: NSView) {
        footerView = NSView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.wantsLayer = true
        footerView.layer?.backgroundColor = DesignTokens.tourBarOverlay.cgColor
        parent.addSubview(footerView)

        NSLayoutConstraint.activate([
            footerView.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            footerView.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            footerView.heightAnchor.constraint(equalToConstant: DesignTokens.tourFooterHeight),
        ])

        // Footer border top
        footerBorderView = NSView()
        footerBorderView.translatesAutoresizingMaskIntoConstraints = false
        footerBorderView.wantsLayer = true
        footerBorderView.layer?.backgroundColor = DesignTokens.tourBarDivider.cgColor
        footerView.addSubview(footerBorderView)
        NSLayoutConstraint.activate([
            footerBorderView.topAnchor.constraint(equalTo: footerView.topAnchor),
            footerBorderView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
            footerBorderView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
            footerBorderView.heightAnchor.constraint(equalToConstant: 1),
        ])

        // Progress label: "N / 9"
        progressLabel = NSTextField(labelWithString: "1 / 9")
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = DesignTokens.tourProgressFont
        progressLabel.textColor = DesignTokens.tourTextDim
        progressLabel.isBezeled = false
        progressLabel.drawsBackground = false
        progressLabel.isEditable = false
        footerView.addSubview(progressLabel)
        NSLayoutConstraint.activate([
            progressLabel.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            progressLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 20),
        ])

        // Progress bars
        let barsContainer = NSView()
        barsContainer.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(barsContainer)
        NSLayoutConstraint.activate([
            barsContainer.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            barsContainer.leadingAnchor.constraint(equalTo: progressLabel.trailingAnchor, constant: 10),
            barsContainer.heightAnchor.constraint(equalToConstant: DesignTokens.tourProgressBarHeight),
        ])

        let barSpacing: CGFloat = 3
        var previousBar: NSView? = nil
        for i in 0..<9 {
            let bar = NSView()
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.wantsLayer = true
            bar.layer?.cornerRadius = DesignTokens.tourProgressBarHeight / 2
            bar.layer?.backgroundColor = (i == 0 ? DesignTokens.tourProgressActive : DesignTokens.tourProgressInactive).cgColor
            barsContainer.addSubview(bar)
            progressBars.append(bar)

            NSLayoutConstraint.activate([
                bar.widthAnchor.constraint(equalToConstant: DesignTokens.tourProgressBarWidth),
                bar.heightAnchor.constraint(equalToConstant: DesignTokens.tourProgressBarHeight),
                bar.centerYAnchor.constraint(equalTo: barsContainer.centerYAnchor),
            ])

            if let prev = previousBar {
                bar.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: barSpacing).isActive = true
            } else {
                bar.leadingAnchor.constraint(equalTo: barsContainer.leadingAnchor).isActive = true
            }
            previousBar = bar
        }
        if let last = previousBar {
            last.trailingAnchor.constraint(equalTo: barsContainer.trailingAnchor).isActive = true
        }

        // Next button — primary purple pill
        nextButton = makePillButton(title: "Next", isPrimary: true)
        nextButton.target = self
        nextButton.action = #selector(nextStep)
        nextButton.onMouseEntered = { [weak self] in self?.setNextButtonHover(true) }
        nextButton.onMouseExited = { [weak self] in self?.setNextButtonHover(false) }
        footerView.addSubview(nextButton)
        NSLayoutConstraint.activate([
            nextButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            nextButton.heightAnchor.constraint(equalToConstant: DesignTokens.tourNextButtonHeight),
        ])

        // Back button — ghost pill
        backButton = makePillButton(title: "Back", isPrimary: false)
        backButton.target = self
        backButton.action = #selector(prevStep)
        backButton.onMouseEntered = { [weak self] in self?.setBackButtonHover(true) }
        backButton.onMouseExited = { [weak self] in self?.setBackButtonHover(false) }
        footerView.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            backButton.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -8),
            backButton.heightAnchor.constraint(equalToConstant: DesignTokens.tourNextButtonHeight),
        ])

        updateBackButtonAppearance(hovered: false)
    }

    // MARK: - Body

    private func buildBody(in parent: NSView) {
        bodyView = NSView()
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(bodyView)

        NSLayoutConstraint.activate([
            bodyView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            bodyView.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            bodyView.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            bodyView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
        ])

        // Illustration pane (left, 60%) — opaque background for illustrations
        illustrationPane = NSView()
        illustrationPane.translatesAutoresizingMaskIntoConstraints = false
        illustrationPane.wantsLayer = true
        illustrationPane.layer?.backgroundColor = DesignTokens.tourIllustrationPaneBg.cgColor
        bodyView.addSubview(illustrationPane)

        illustrationWidthConstraint = illustrationPane.widthAnchor.constraint(
            equalTo: bodyView.widthAnchor, multiplier: DesignTokens.tourIllustrationRatio)

        NSLayoutConstraint.activate([
            illustrationPane.topAnchor.constraint(equalTo: bodyView.topAnchor),
            illustrationPane.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor),
            illustrationPane.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor),
            illustrationWidthConstraint,
        ])

        // Divider
        dividerView = NSView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.wantsLayer = true
        dividerView.layer?.backgroundColor = DesignTokens.tourBarDivider.cgColor
        bodyView.addSubview(dividerView)

        NSLayoutConstraint.activate([
            dividerView.topAnchor.constraint(equalTo: bodyView.topAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor),
            dividerView.leadingAnchor.constraint(equalTo: illustrationPane.trailingAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
        ])

        // Text pane (right, 40%)
        textPane = NSView()
        textPane.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(textPane)

        textPaneWidthConstraint = textPane.widthAnchor.constraint(
            equalTo: bodyView.widthAnchor, multiplier: 1 - DesignTokens.tourIllustrationRatio)

        NSLayoutConstraint.activate([
            textPane.topAnchor.constraint(equalTo: bodyView.topAnchor),
            textPane.bottomAnchor.constraint(equalTo: bodyView.bottomAnchor),
            textPane.trailingAnchor.constraint(equalTo: bodyView.trailingAnchor),
            textPaneWidthConstraint,
        ])

        // Text pane content — vertically centered stack
        let textStack = NSView()
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textPane.addSubview(textStack)

        NSLayoutConstraint.activate([
            textStack.centerYAnchor.constraint(equalTo: textPane.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: textPane.leadingAnchor, constant: 28),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: textPane.trailingAnchor, constant: -20),
            textStack.widthAnchor.constraint(lessThanOrEqualToConstant: DesignTokens.tourTextMaxWidth),
        ])

        // Step badge: "Step N of 9"
        stepBadgeLabel = NSTextField(labelWithString: "Step 1 of 9")
        stepBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        stepBadgeLabel.font = DesignTokens.tourStepBadgeFont
        stepBadgeLabel.textColor = DesignTokens.tourProgressActive
        stepBadgeLabel.isBezeled = false
        stepBadgeLabel.drawsBackground = false
        stepBadgeLabel.isEditable = false
        textStack.addSubview(stepBadgeLabel)

        // Title
        titleLabel = NSTextField(labelWithString: "")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = DesignTokens.tourTitleFont
        titleLabel.textColor = DesignTokens.tourTextPrimary
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.maximumNumberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.preferredMaxLayoutWidth = DesignTokens.tourTextMaxWidth
        // Apply tracking (-0.025em ≈ -0.55pt at 22px)
        textStack.addSubview(titleLabel)

        // Body
        bodyLabel = NSTextField(labelWithString: "")
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = DesignTokens.tourBodyFont
        bodyLabel.textColor = DesignTokens.tourTextSecondary
        bodyLabel.isBezeled = false
        bodyLabel.drawsBackground = false
        bodyLabel.isEditable = false
        bodyLabel.maximumNumberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.preferredMaxLayoutWidth = DesignTokens.tourTextMaxWidth
        textStack.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            stepBadgeLabel.topAnchor.constraint(equalTo: textStack.topAnchor),
            stepBadgeLabel.leadingAnchor.constraint(equalTo: textStack.leadingAnchor),

            titleLabel.topAnchor.constraint(equalTo: stepBadgeLabel.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: textStack.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: textStack.trailingAnchor),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            bodyLabel.leadingAnchor.constraint(equalTo: textStack.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: textStack.trailingAnchor),
            bodyLabel.bottomAnchor.constraint(equalTo: textStack.bottomAnchor),
        ])
    }

    // MARK: - Render Step

    private func renderStep(_ index: Int) {
        let step = steps[index]

        // Update text pane
        stepBadgeLabel.stringValue = "Step \(index + 1) of \(steps.count)"
        updateTitle(step.title)
        updateBody(step.body)

        // Progress bars
        progressLabel.stringValue = "\(index + 1) / \(steps.count)"
        for (i, bar) in progressBars.enumerated() {
            bar.layer?.backgroundColor = (i <= index
                ? DesignTokens.tourProgressActive
                : DesignTokens.tourProgressInactive).cgColor
        }

        // Back button visibility
        backButton.isHidden = (index == 0)
        updateBackButtonAppearance(hovered: false)

        // Next button styling
        updateNextButton(for: step)

        // Full-width mode for step 9
        updateLayout(for: step)

        // Illustration content
        updateIllustration(for: index, step: step)
    }

    private func updateTitle(_ text: String) {
        let attrStr = NSMutableAttributedString(string: text, attributes: [
            .font: DesignTokens.tourTitleFont,
            .foregroundColor: DesignTokens.tourTextPrimary,
            .kern: -0.55,  // -0.025em at 22px
        ])
        titleLabel.attributedStringValue = attrStr
    }

    private func updateBody(_ text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.65
        let attrStr = NSMutableAttributedString(string: text, attributes: [
            .font: DesignTokens.tourBodyFont,
            .foregroundColor: DesignTokens.tourTextSecondary,
            .paragraphStyle: paragraphStyle,
        ])
        bodyLabel.attributedStringValue = attrStr
    }

    private func updateNextButton(for step: TourStep) {
        nextButton.title = step.buttonLabel
        updateNextButtonAppearance(hovered: false, isDone: step.buttonLabel == "Got it")
    }

    private func updateLayout(for step: TourStep) {
        // Remove done view if present
        doneView?.removeFromSuperview()
        doneView = nil

        if step.isFullWidth {
            // Full width — hide text pane and divider, expand illustration
            textPane.isHidden = true
            dividerView.isHidden = true
            illustrationWidthConstraint.isActive = false
            illustrationWidthConstraint = illustrationPane.widthAnchor.constraint(equalTo: bodyView.widthAnchor)
            illustrationWidthConstraint.isActive = true
        } else {
            // Split mode
            textPane.isHidden = false
            dividerView.isHidden = false
            illustrationWidthConstraint.isActive = false
            illustrationWidthConstraint = illustrationPane.widthAnchor.constraint(
                equalTo: bodyView.widthAnchor, multiplier: DesignTokens.tourIllustrationRatio)
            illustrationWidthConstraint.isActive = true
        }
        bodyView.layoutSubtreeIfNeeded()
    }

    private func updateIllustration(for index: Int, step: TourStep) {
        // Clear existing illustration content
        illustrationPane.subviews.forEach { $0.removeFromSuperview() }

        illustrationPane.effectiveAppearance.performAsCurrentDrawingAppearance {
            if step.isFullWidth {
                // Step 9: full-width "You're all set" content
                buildDoneContent(in: illustrationPane)
            } else {
                // Real illustrations for steps 0–7
                buildIllustration(for: index, in: illustrationPane)
            }
        }
    }

    // MARK: - Illustration factory

    private func buildIllustration(for index: Int, in container: NSView) {
        let view: NSView
        switch index {
        case 0: view = TourIllustration0()
        case 1: view = TourIllustration1()
        case 2: view = TourIllustration2()
        case 3: view = TourIllustration3()
        case 4: view = TourIllustration4()
        case 5: view = TourIllustration5()
        case 6: view = TourIllustration6()
        case 7: view = TourIllustration7()
        default: return
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
    }

    // MARK: - Step 9: Done content

    private func buildDoneContent(in container: NSView) {
        let doneContainer = NSView()
        doneContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(doneContainer)
        self.doneView = doneContainer

        NSLayoutConstraint.activate([
            doneContainer.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            doneContainer.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            doneContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
        ])

        // Green checkmark circle (56px, 2px green border)
        let checkCircle = NSView()
        checkCircle.translatesAutoresizingMaskIntoConstraints = false
        checkCircle.wantsLayer = true
        checkCircle.layer?.cornerRadius = 28
        checkCircle.layer?.borderWidth = 2
        checkCircle.layer?.borderColor = DesignTokens.copiedGreenBorder.cgColor
        checkCircle.layer?.backgroundColor = DesignTokens.copiedGreenBg.cgColor
        doneContainer.addSubview(checkCircle)

        let checkLabel = NSTextField(labelWithString: "\u{2713}")
        checkLabel.translatesAutoresizingMaskIntoConstraints = false
        checkLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        checkLabel.textColor = DesignTokens.copiedGreenText
        checkLabel.alignment = .center
        checkLabel.isBezeled = false
        checkLabel.drawsBackground = false
        checkLabel.isEditable = false
        checkCircle.addSubview(checkLabel)

        NSLayoutConstraint.activate([
            checkCircle.topAnchor.constraint(equalTo: doneContainer.topAnchor),
            checkCircle.centerXAnchor.constraint(equalTo: doneContainer.centerXAnchor),
            checkCircle.widthAnchor.constraint(equalToConstant: 56),
            checkCircle.heightAnchor.constraint(equalToConstant: 56),
            checkLabel.centerXAnchor.constraint(equalTo: checkCircle.centerXAnchor),
            checkLabel.centerYAnchor.constraint(equalTo: checkCircle.centerYAnchor),
        ])

        // "You're all set" heading
        let heading = NSTextField(labelWithString: steps[8].title)
        heading.translatesAutoresizingMaskIntoConstraints = false
        heading.font = DesignTokens.tourDoneTitleFont
        heading.textColor = DesignTokens.tourTextPrimary
        heading.alignment = .center
        heading.isBezeled = false
        heading.drawsBackground = false
        heading.isEditable = false
        doneContainer.addSubview(heading)

        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: checkCircle.bottomAnchor, constant: 20),
            heading.centerXAnchor.constraint(equalTo: doneContainer.centerXAnchor),
        ])

        // Body text
        let body = NSTextField(labelWithString: steps[8].body)
        body.translatesAutoresizingMaskIntoConstraints = false
        body.font = DesignTokens.tourBodyFont
        body.textColor = DesignTokens.tourTextSecondary
        body.alignment = .center
        body.isBezeled = false
        body.drawsBackground = false
        body.isEditable = false
        body.maximumNumberOfLines = 0
        body.lineBreakMode = .byWordWrapping
        body.preferredMaxLayoutWidth = 360
        doneContainer.addSubview(body)

        NSLayoutConstraint.activate([
            body.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 12),
            body.centerXAnchor.constraint(equalTo: doneContainer.centerXAnchor),
            body.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
        ])

        // Keyboard shortcut row: ⌘ ⇧ 6
        let kbdRow = NSStackView()
        kbdRow.translatesAutoresizingMaskIntoConstraints = false
        kbdRow.orientation = .horizontal
        kbdRow.spacing = 4
        doneContainer.addSubview(kbdRow)

        for key in ["\u{2318}", "\u{21E7}", "6"] {
            let pill = makeKbdPill(key)
            kbdRow.addArrangedSubview(pill)
        }

        // "to capture anytime" helper label
        let helperLabel = NSTextField(labelWithString: "to capture anytime")
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        helperLabel.font = DesignTokens.tourBodyFont
        helperLabel.textColor = DesignTokens.tourTextDim
        helperLabel.alignment = .center
        helperLabel.isBezeled = false
        helperLabel.drawsBackground = false
        helperLabel.isEditable = false
        doneContainer.addSubview(helperLabel)

        NSLayoutConstraint.activate([
            kbdRow.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 20),
            kbdRow.centerXAnchor.constraint(equalTo: doneContainer.centerXAnchor),
            helperLabel.topAnchor.constraint(equalTo: kbdRow.bottomAnchor, constant: 8),
            helperLabel.centerXAnchor.constraint(equalTo: doneContainer.centerXAnchor),
            helperLabel.bottomAnchor.constraint(equalTo: doneContainer.bottomAnchor),
        ])
    }

    private func makeKbdPill(_ text: String) -> NSView {
        let pill = NSView()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.wantsLayer = true
        pill.layer?.cornerRadius = 5
        pill.layer?.borderWidth = 1
        pill.layer?.borderColor = DesignTokens.setupKbdBorder.cgColor
        pill.layer?.backgroundColor = DesignTokens.setupKbdBg.cgColor

        let label = NSTextField(labelWithString: text)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = DesignTokens.setupKbdFont
        label.textColor = DesignTokens.setupKbdText
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        pill.addSubview(label)

        NSLayoutConstraint.activate([
            pill.widthAnchor.constraint(equalToConstant: 30),
            pill.heightAnchor.constraint(equalToConstant: 26),
            label.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
        ])

        return pill
    }

    // MARK: - Button Factories

    private func makePillButton(title: String, isPrimary: Bool) -> HoverButton {
        let button = HoverButton(title: title, target: nil, action: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = DesignTokens.tourNextButtonHeight / 2
        button.layer?.borderWidth = 1
        if isPrimary {
            updateButtonTitle(button, title: title, color: DesignTokens.tourPrimaryButtonText)
            button.layer?.backgroundColor = DesignTokens.tourPrimaryButtonBg.cgColor
            button.layer?.borderColor = DesignTokens.tourPrimaryButtonBorder.cgColor
        } else {
            updateButtonTitle(button, title: title, color: DesignTokens.tourGhostButtonText)
            button.layer?.backgroundColor = NSColor.clear.cgColor
            button.layer?.borderColor = DesignTokens.tourGhostButtonBorder.cgColor
        }

        // Horizontal padding
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true

        return button
    }

    private func setNextButtonHover(_ hovered: Bool) {
        updateNextButtonAppearance(hovered: hovered, isDone: steps[currentStep].buttonLabel == "Got it")
    }

    private func setBackButtonHover(_ hovered: Bool) {
        updateBackButtonAppearance(hovered: hovered)
    }

    private func updateExitButtonAppearance(hovered: Bool) {
        let border = hovered ? DesignTokens.tourGhostButtonHoverBorder : DesignTokens.tourGhostButtonBorder
        let text = hovered ? DesignTokens.tourGhostButtonHoverText : DesignTokens.tourGhostButtonText
        exitButton.layer?.borderColor = border.cgColor
        updateButtonTitle(exitButton, title: "Exit tour", color: text, font: DesignTokens.tourExitFont)
    }

    private func updateBackButtonAppearance(hovered: Bool) {
        let border = hovered ? DesignTokens.tourGhostButtonHoverBorder : DesignTokens.tourGhostButtonBorder
        let text = hovered ? DesignTokens.tourGhostButtonHoverText : DesignTokens.tourGhostButtonText
        backButton.layer?.borderColor = border.cgColor
        updateButtonTitle(backButton, title: "Back", color: text)
    }

    private func updateNextButtonAppearance(hovered: Bool, isDone: Bool) {
        let title = nextButton.title
        if isDone {
            nextButton.layer?.backgroundColor = (hovered ? DesignTokens.tourDoneButtonHoverBg : DesignTokens.tourDoneButtonBg).cgColor
            nextButton.layer?.borderColor = DesignTokens.tourDoneButtonBorder.cgColor
            updateButtonTitle(nextButton, title: title, color: DesignTokens.tourDoneButtonText)
            return
        }

        let bg = hovered ? DesignTokens.tourPrimaryButtonHoverBg : DesignTokens.tourPrimaryButtonBg
        let border = hovered ? DesignTokens.tourPrimaryButtonHoverBorder : DesignTokens.tourPrimaryButtonBorder
        nextButton.layer?.backgroundColor = bg.cgColor
        nextButton.layer?.borderColor = border.cgColor
        updateButtonTitle(nextButton, title: title, color: DesignTokens.tourPrimaryButtonText)
    }

    private func updateButtonTitle(_ button: NSButton, title: String, color: NSColor, font: NSFont = DesignTokens.tourButtonFont) {
        button.title = title
        button.attributedTitle = NSAttributedString(string: title, attributes: [
            .font: font,
            .foregroundColor: color,
        ])
    }

    // MARK: - Actions

    @objc private func nextStep() {
        if currentStep >= steps.count - 1 {
            exitTour()
        } else {
            currentStep += 1
            renderStep(currentStep)
        }
    }

    @objc private func prevStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
        renderStep(currentStep)
    }

    @objc private func exitTour() {
        UserDefaults.standard.set(true, forKey: "tourCompleted")
        window?.orderOut(nil)
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            exitTour()
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Appearance refresh

    /// VIB-373: Refresh all appearance-sensitive layer colors when system appearance changes.
    private func refreshAppearanceColors() {
        guard let contentView = window?.contentView else { return }
        let appearance = contentView.effectiveAppearance
        appearance.performAsCurrentDrawingAppearance {
            window?.backgroundColor = .clear
            contentView.layer?.backgroundColor = DesignTokens.tourWindowBg.cgColor
            contentView.layer?.borderColor = DesignTokens.tourWindowBorder.cgColor
            headerView?.layer?.backgroundColor = DesignTokens.tourBarOverlay.cgColor
            headerBorderView?.layer?.backgroundColor = DesignTokens.tourBarDivider.cgColor
            footerView?.layer?.backgroundColor = DesignTokens.tourBarOverlay.cgColor
            footerBorderView?.layer?.backgroundColor = DesignTokens.tourBarDivider.cgColor
            illustrationPane?.layer?.backgroundColor = DesignTokens.tourIllustrationPaneBg.cgColor
            dividerView?.layer?.backgroundColor = DesignTokens.tourBarDivider.cgColor
            guard bodyLabel != nil else { return }
            renderStep(currentStep)
        }
    }
}

// MARK: - Appearance-aware content view

private class TourContentView: NSView {
    var onAppearanceChange: (() -> Void)?
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        onAppearanceChange?()
    }
}

/// NSButton subclass that forwards mouse enter/exit for hover tracking.
private class HoverButton: NSButton {
    var onMouseEntered: (() -> Void)?
    var onMouseExited: (() -> Void)?
    private var hoverTrackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        if let hoverTrackingArea {
            removeTrackingArea(hoverTrackingArea)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        hoverTrackingArea = trackingArea
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEntered?()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExited?()
    }
}
