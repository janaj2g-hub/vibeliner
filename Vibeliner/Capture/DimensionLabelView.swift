import AppKit

final class DimensionLabelView: NSView {

    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = DesignTokens.purpleDark.cgColor
        layer?.cornerRadius = DesignTokens.dimensionLabelCornerRadius

        label.font = DesignTokens.fontMonoSm
        label.textColor = .white
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: DesignTokens.dimensionLabelPaddingH),
            trailingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: DesignTokens.dimensionLabelPaddingH),
        ])
    }

    func updateDuringDrag(width: Int, height: Int) {
        label.stringValue = "w \(width)  h \(height)"
        sizeToFitContent()
    }

    func updateAfterRelease(width: Int, height: Int) {
        label.stringValue = "\(width) × \(height)"
        sizeToFitContent()
    }

    func positionRelativeTo(selectionRect: NSRect, in screenFrame: NSRect) {
        sizeToFitContent()

        let labelWidth = frame.width
        let centerX = selectionRect.midX - labelWidth / 2

        let gap = DesignTokens.dimensionLabelGap
        var labelY = selectionRect.minY - gap - DesignTokens.dimensionLabelHeight

        // If near bottom of screen, position above the selection
        if labelY < screenFrame.minY + 10 {
            labelY = selectionRect.maxY + gap
        }

        setFrameOrigin(NSPoint(x: centerX, y: labelY))
    }

    private func sizeToFitContent() {
        label.sizeToFit()
        let contentWidth = label.frame.width + DesignTokens.dimensionLabelPaddingH * 2
        setFrameSize(NSSize(width: contentWidth, height: DesignTokens.dimensionLabelHeight))
    }
}
