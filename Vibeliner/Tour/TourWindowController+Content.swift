import AppKit

extension TourWindowController {

    // MARK: - Illustration factory

    func buildIllustration(for index: Int, in container: NSView) {
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

    func buildDoneContent(in container: NSView) {
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

    func makeKbdPill(_ text: String) -> NSView {
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

    func makePillButton(title: String, isPrimary: Bool) -> HoverButton {
        let button = HoverButton(title: title, target: nil, action: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.cornerRadius = DesignTokens.tourNextButtonHeight / 2
        button.layer?.borderWidth = 1
        if isPrimary {
            updateButtonTitle(button, title: title, color: DesignTokens.pillButtonPrimaryText)
            button.layer?.backgroundColor = DesignTokens.pillButtonPrimaryBg.cgColor
            button.layer?.borderColor = DesignTokens.pillButtonPrimaryBorder.cgColor
        } else {
            updateButtonTitle(button, title: title, color: DesignTokens.tourTextDim)
            button.layer?.backgroundColor = NSColor.clear.cgColor
            button.layer?.borderColor = DesignTokens.tourGhostButtonBorder.cgColor
        }

        // Horizontal padding
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true

        return button
    }

    func setNextButtonHover(_ hovered: Bool) {
        updateNextButtonAppearance(hovered: hovered, isDone: steps[currentStep].buttonLabel == "Got it")
    }

    func setBackButtonHover(_ hovered: Bool) {
        updateBackButtonAppearance(hovered: hovered)
    }

    func updateExitButtonAppearance(hovered: Bool) {
        exitButton.isHovered = hovered
    }

    func updateBackButtonAppearance(hovered: Bool) {
        let border = hovered ? DesignTokens.tourGhostButtonHoverBorder : DesignTokens.tourGhostButtonBorder
        let text = hovered ? DesignTokens.tourTextSecondary : DesignTokens.tourTextDim
        backButton.layer?.borderColor = border.cgColor
        updateButtonTitle(backButton, title: "Back", color: text)
    }

    func updateNextButtonAppearance(hovered: Bool, isDone: Bool) {
        let title = nextButton.title
        if isDone {
            nextButton.layer?.backgroundColor = (hovered ? DesignTokens.tourDoneButtonHoverBg : DesignTokens.tourDoneButtonBg).cgColor
            nextButton.layer?.borderColor = DesignTokens.tourDoneButtonBorder.cgColor
            updateButtonTitle(nextButton, title: title, color: DesignTokens.tourDoneButtonText)
            return
        }

        let bg = hovered ? DesignTokens.pillButtonPrimaryHoverBg : DesignTokens.pillButtonPrimaryBg
        let border = hovered ? DesignTokens.pillButtonPrimaryHoverBorder : DesignTokens.pillButtonPrimaryBorder
        nextButton.layer?.backgroundColor = bg.cgColor
        nextButton.layer?.borderColor = border.cgColor
        updateButtonTitle(nextButton, title: title, color: DesignTokens.pillButtonPrimaryText)
    }

    func updateButtonTitle(_ button: NSButton, title: String, color: NSColor, font: NSFont = DesignTokens.tourButtonFont) {
        button.title = title
        button.attributedTitle = NSAttributedString(string: title, attributes: [
            .font: font,
            .foregroundColor: color,
        ])
    }

    // MARK: - Actions

    @objc func nextStep() {
        if currentStep >= steps.count - 1 {
            exitTour()
        } else {
            currentStep += 1
            renderStep(currentStep)
        }
    }

    @objc func prevStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
        renderStep(currentStep)
    }

    @objc func exitTour() {
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
    func refreshAppearanceColors() {
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

