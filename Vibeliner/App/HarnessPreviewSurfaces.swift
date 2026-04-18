import AppKit

#if DEBUG
final class HarnessCardView: AppearanceAwareSurfaceView {
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

enum SetupPreviewVariant {
    case step2Active
    case step3Active
}

final class SetupHarnessSurfaceView: NSView {
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

        NSColor.windowBackgroundColor.setFill()
        bounds.fill()

        let footerHeight: CGFloat = 52
        let panelHeight = bounds.height - footerHeight
        let panelWidth = floor((bounds.width - 2) / 3)

        let footerRect = CGRect(x: 0, y: panelHeight, width: bounds.width, height: footerHeight)
        DesignTokens.setupFooterBg.setFill()
        footerRect.fill()

        NSColor.separatorColor.setFill()
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
            .font: DesignTokens.fontBody,
            .foregroundColor: NSColor.tertiaryLabelColor,
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
        drawText(title, rect: titleRect, font: DesignTokens.fontTitle, color: NSColor.labelColor)

        let descriptionRect = CGRect(x: panelRect.minX + pad, y: badgeRect.maxY + 18, width: contentWidth, height: 72)
        drawText(description, rect: descriptionRect, font: DesignTokens.fontBody, color: NSColor.secondaryLabelColor)

        if let helperText {
            let helperRect = CGRect(x: panelRect.minX + pad, y: panelRect.maxY - 86, width: contentWidth, height: 30)
            drawText(helperText, rect: helperRect, font: DesignTokens.fontCaption, color: NSColor.tertiaryLabelColor, alignment: .center)
        }

        if showsAction {
            let labelRect = CGRect(x: panelRect.minX + pad, y: panelRect.maxY - 64, width: contentWidth, height: 18)
            drawText(actionLabel, rect: labelRect, font: DesignTokens.fontLabel, color: DesignTokens.pillButtonText, alignment: .center)
            drawCircleArrow(in: CGRect(
                x: panelRect.midX - DesignTokens.setupArrowSize / 2,
                y: panelRect.maxY - 64 + 26,
                width: DesignTokens.setupArrowSize,
                height: DesignTokens.setupArrowSize
            ))
        } else if let statusText {
            let statusColor: NSColor = state == .done ? DesignTokens.setupGreenText : NSColor.tertiaryLabelColor
            let statusRect = CGRect(x: panelRect.minX + pad, y: panelRect.maxY - 42, width: contentWidth, height: 20)
            drawText(statusText, rect: statusRect, font: DesignTokens.fontLabel, color: statusColor, alignment: .center)
        }
    }

    private func drawBadge(in rect: CGRect, index: Int, state: PanelState) {
        let path = NSBezierPath(ovalIn: rect)
        path.lineWidth = 1
        switch state {
        case .done:
            DesignTokens.setupGreenBadgeBg.setFill()
            DesignTokens.setupGreen.setStroke()
            path.fill()
            path.stroke()
            drawText("✓", rect: rect, font: DesignTokens.fontTitle, color: DesignTokens.setupGreen, alignment: .center)
        case .active:
            DesignTokens.pillButtonBg.setFill()
            DesignTokens.pillButtonBorder.setStroke()
            path.fill()
            path.stroke()
            drawText("\(index)", rect: rect, font: DesignTokens.fontNumberLg, color: DesignTokens.pillButtonText, alignment: .center)
        case .locked:
            DesignTokens.setupFieldBg.setFill()
            NSColor.tertiaryLabelColor.setStroke()
            path.fill()
            path.stroke()
            drawText("\(index)", rect: rect, font: DesignTokens.fontNumberLg, color: NSColor.tertiaryLabelColor, alignment: .center)
        }
    }

    private func drawCircleArrow(in rect: CGRect) {
        let path = NSBezierPath(ovalIn: rect)
        SettingsUI.styleSurface(
            self,
            background: .clear,
            borderWidth: 0
        )
        DesignTokens.pillButtonBg.setFill()
        DesignTokens.pillButtonBorder.setStroke()
        path.lineWidth = 1
        path.fill()
        path.stroke()

        let arrow = NSAttributedString(
            string: "→",
            attributes: [
                .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: DesignTokens.pillButtonText,
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
#endif
