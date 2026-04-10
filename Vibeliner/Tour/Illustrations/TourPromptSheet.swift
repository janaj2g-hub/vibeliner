import AppKit

/// A single annotation line rendered in the prompt sheet.
struct TourPromptLine {
    let index: Int
    let tool: String
    let note: String
}

/// Monospace text block for tour illustrations.
/// Renders a formatted prompt preview with preamble, annotation lines, and footer.
final class TourPromptSheet: NSView {

    private let preamble: String?
    private let annotations: [TourPromptLine]
    private let footer: String?
    private let lineSpacing: CGFloat = 3

    init(preamble: String? = nil, annotations: [TourPromptLine], footer: String? = nil) {
        self.preamble = preamble
        self.annotations = annotations
        self.footer = footer
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = DesignTokens.tourPromptSheetRadius
        layer?.masksToBounds = true
        layer?.backgroundColor = DesignTokens.tourPromptSheetBg.cgColor
        layer?.borderWidth = 1
        layer?.borderColor = DesignTokens.tourPromptSheetBorder.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let h = bounds.height
        let padH = DesignTokens.tourPromptSheetPaddingH
        let padV = DesignTokens.tourPromptSheetPaddingV
        var y = h - padV

        let monoFont = DesignTokens.tourPromptSheetFont
        let monoBoldFont = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .bold)

        let dimAttrs: [NSAttributedString.Key: Any] = [
            .font: monoFont,
            .foregroundColor: DesignTokens.tourPromptSheetDim,
        ]

        // Preamble
        if let preamble, !preamble.isEmpty {
            let lines = preamble.components(separatedBy: "\n")
            for line in lines {
                let str = NSAttributedString(string: line, attributes: dimAttrs)
                let size = str.size()
                y -= size.height
                str.draw(at: NSPoint(x: padH, y: y))
                y -= lineSpacing
            }
            y -= lineSpacing * 2
        }

        // Annotation lines
        for annotation in annotations {
            let attributed = NSMutableAttributedString()

            // Red bold index number
            let indexStr = NSAttributedString(string: "\(annotation.index)", attributes: [
                .font: monoBoldFont,
                .foregroundColor: DesignTokens.tourPromptSheetNumber,
            ])
            attributed.append(indexStr)

            // Tool + note in default color (HTML: "1  [pin] padding too tight")
            let restStr = NSAttributedString(string: "  [\(annotation.tool)] \(annotation.note)", attributes: [
                .font: monoFont,
                .foregroundColor: DesignTokens.tourPromptSheetColor,
            ])
            attributed.append(restStr)

            let size = attributed.size()
            y -= size.height
            attributed.draw(at: NSPoint(x: padH, y: y))
            y -= lineSpacing
        }

        // Footer
        if let footer, !footer.isEmpty {
            y -= lineSpacing * 2
            let lines = footer.components(separatedBy: "\n")
            for line in lines {
                let str = NSAttributedString(string: line, attributes: dimAttrs)
                let size = str.size()
                y -= size.height
                str.draw(at: NSPoint(x: padH, y: y))
                y -= lineSpacing
            }
        }
    }
}
