import AppKit

/// A single annotation line rendered in the prompt sheet.
struct TourPromptLine {
    let index: Int
    let tool: String
    let note: String
}

/// Monospace text block for tour illustrations.
/// Renders a formatted prompt preview with preamble, annotation lines, and footer.
final class TourPromptSheet: TourSurfaceView {

    private let preamble: String?
    private let annotations: [TourPromptLine]
    private let footer: String?

    override var isFlipped: Bool { true }

    init(preamble: String? = nil, annotations: [TourPromptLine], footer: String? = nil) {
        self.preamble = preamble
        self.annotations = annotations
        self.footer = footer
        super.init(role: .promptSheet)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let padH = DesignTokens.tourPromptSheetPaddingH
        let padV = DesignTokens.tourPromptSheetPaddingV
        let textRect = bounds.insetBy(dx: padH, dy: padV)
        makeAttributedText().draw(
            with: textRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
    }

    private func makeAttributedText() -> NSAttributedString {
        let output = NSMutableAttributedString()
        let monoFont = DesignTokens.tourPromptSheetFont
        let monoBoldFont = NSFont.monospacedSystemFont(
            ofSize: monoFont.pointSize,
            weight: .bold
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = DesignTokens.tourPromptSheetLineHeight
        paragraphStyle.maximumLineHeight = DesignTokens.tourPromptSheetLineHeight
        paragraphStyle.lineBreakMode = .byWordWrapping

        let dimAttrs: [NSAttributedString.Key: Any] = [
            .font: monoFont,
            .foregroundColor: DesignTokens.tourPromptSheetDim,
            .paragraphStyle: paragraphStyle,
        ]
        let regularAttrs: [NSAttributedString.Key: Any] = [
            .font: monoFont,
            .foregroundColor: DesignTokens.tourPromptSheetColor,
            .paragraphStyle: paragraphStyle,
        ]
        let numberAttrs: [NSAttributedString.Key: Any] = [
            .font: monoBoldFont,
            .foregroundColor: DesignTokens.red,
            .paragraphStyle: paragraphStyle,
        ]

        if let preamble, !preamble.isEmpty {
            appendLines(
                preamble.components(separatedBy: "\n"),
                attributes: dimAttrs,
                to: output
            )
        }

        if !annotations.isEmpty {
            if output.length > 0 {
                output.append(NSAttributedString(string: "\n", attributes: regularAttrs))
            }

            for (index, annotation) in annotations.enumerated() {
                output.append(NSAttributedString(string: "\(annotation.index)", attributes: numberAttrs))
                output.append(NSAttributedString(
                    string: "  [\(annotation.tool)] \(annotation.note)",
                    attributes: regularAttrs
                ))

                if index < annotations.count - 1 {
                    output.append(NSAttributedString(string: "\n", attributes: regularAttrs))
                }
            }
        }

        if let footer, !footer.isEmpty {
            if output.length > 0 {
                output.append(NSAttributedString(string: "\n\n", attributes: dimAttrs))
            }

            appendLines(
                footer.components(separatedBy: "\n"),
                attributes: dimAttrs,
                to: output
            )
        }

        return output
    }

    private func appendLines(
        _ lines: [String],
        attributes: [NSAttributedString.Key: Any],
        to output: NSMutableAttributedString
    ) {
        for (index, line) in lines.enumerated() {
            output.append(NSAttributedString(string: line, attributes: attributes))
            if index < lines.count - 1 {
                output.append(NSAttributedString(string: "\n", attributes: attributes))
            }
        }
    }
}
