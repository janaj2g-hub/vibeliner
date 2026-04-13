import AppKit

extension TourWindowController {

    // MARK: - Build UI

    func buildUI() {
        guard let panel = window else { return }
        guard let baseContentView = panel.contentView else { return }

        let contentView = TourContentView(frame: baseContentView.bounds)
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

    func buildHeader(in parent: NSView) {
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

        // VIB-382 attempt 5: custom NSView pill — avoids NSButton rendering quirks
        exitButton = ExitTourPillView()
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.onClicked = { [weak self] in self?.exitTour() }
        headerView.addSubview(exitButton)
        NSLayoutConstraint.activate([
            exitButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            exitButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            exitButton.heightAnchor.constraint(equalToConstant: 26),
        ])
    }

    func setExitButtonHover(_ hovered: Bool) {
        exitButton.isHovered = hovered
    }

    // MARK: - Footer

    func buildFooter(in parent: NSView) {
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

}
