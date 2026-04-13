import AppKit

extension TourWindowController {

    // MARK: - Body

    func buildBody(in parent: NSView) {
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

    func renderStep(_ index: Int) {
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

    func updateTitle(_ text: String) {
        let attrStr = NSMutableAttributedString(string: text, attributes: [
            .font: DesignTokens.tourTitleFont,
            .foregroundColor: DesignTokens.tourTextPrimary,
            .kern: -0.55,  // -0.025em at 22px
        ])
        titleLabel.attributedStringValue = attrStr
    }

    func updateBody(_ text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.65
        let attrStr = NSMutableAttributedString(string: text, attributes: [
            .font: DesignTokens.tourBodyFont,
            .foregroundColor: DesignTokens.tourTextSecondary,
            .paragraphStyle: paragraphStyle,
        ])
        bodyLabel.attributedStringValue = attrStr
    }

    func updateNextButton(for step: TourStep) {
        nextButton.title = step.buttonLabel
        updateNextButtonAppearance(hovered: false, isDone: step.buttonLabel == "Got it")
    }

    func updateLayout(for step: TourStep) {
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

    func updateIllustration(for index: Int, step: TourStep) {
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

}
