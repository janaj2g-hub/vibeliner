import AppKit

enum TourSurfaceRole {
    case outputCard
    case promptSheet
}

enum TourSurfaceContract {
    static func apply(to view: NSView, role: TourSurfaceRole) {
        switch role {
        case .outputCard:
            SettingsUI.styleSurface(
                view,
                background: DesignTokens.tourOutputCardBg,
                border: DesignTokens.tourOutputCardBorder,
                cornerRadius: DesignTokens.tourOutputCardRadius
            )
        case .promptSheet:
            SettingsUI.styleSurface(
                view,
                background: DesignTokens.tourPromptSheetBg,
                border: DesignTokens.tourPromptSheetBorder,
                cornerRadius: DesignTokens.tourPromptSheetRadius
            )
        }
    }
}

class TourSurfaceView: AppearanceAwareSurfaceView {
    private let role: TourSurfaceRole

    init(role: TourSurfaceRole) {
        self.role = role
        super.init(frame: .zero)
        wantsLayer = true
        refreshSurfaceAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func refreshSurfaceAppearance() {
        TourSurfaceContract.apply(to: self, role: role)
        layer?.masksToBounds = true
    }
}

final class TourFilenamePillView: AppearanceAwareSurfaceView {
    private let label = NSTextField(labelWithString: "")

    init(text: String) {
        super.init(frame: .zero)
        wantsLayer = true
        label.stringValue = text
        label.font = DesignTokens.tourOutputLabelFont
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.tourOutputLabelPaddingH),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.tourOutputLabelPaddingH),
            label.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.tourOutputLabelPaddingV),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.tourOutputLabelPaddingV),
        ])

        refreshSurfaceAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize {
        let labelSize = label.intrinsicContentSize
        return NSSize(
            width: labelSize.width + DesignTokens.tourOutputLabelPaddingH * 2,
            height: ceil(DesignTokens.tourOutputLabelFont.pointSize) + DesignTokens.tourOutputLabelPaddingV * 2
        )
    }

    override func refreshSurfaceAppearance() {
        SettingsUI.styleSurface(
            self,
            background: DesignTokens.tourOutputLabelBg,
            border: DesignTokens.tourOutputLabelBorder,
            cornerRadius: intrinsicContentSize.height / 2
        )
        label.textColor = DesignTokens.tourTextSecondary
    }
}

/// Rounded rect container for tour illustrations.
/// Shows a label pill at top (e.g. "screenshot.png") and a public content area below.
final class TourOutputCard: TourSurfaceView {

    private let labelPill: TourFilenamePillView
    /// Public content area for callers to add child views.
    let contentArea: NSView

    init(label: String) {
        self.labelPill = TourFilenamePillView(text: label)
        self.contentArea = NSView()
        super.init(role: .outputCard)

        contentArea.wantsLayer = true
        addSubview(labelPill)
        addSubview(contentArea)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        let pad = DesignTokens.tourOutputCardPadding
        let labelSize = labelPill.intrinsicContentSize
        let labelY = h - pad - labelSize.height

        // Content area fills below the label pill
        let contentY: CGFloat = pad
        let contentH = h - pad - labelSize.height - DesignTokens.tourOutputLabelGap - pad
        contentArea.frame = CGRect(
            x: pad,
            y: contentY,
            width: w - pad * 2,
            height: max(0, contentH)
        )
        labelPill.frame = CGRect(x: pad, y: labelY, width: labelSize.width, height: labelSize.height)
    }
}
