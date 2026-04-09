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
    private let sheetPadding: CGFloat = 10
    private let lineSpacing: CGFloat = 3

    init(preamble: String? = nil, annotations: [TourPromptLine], footer: String? = nil) {
        self.preamble = preamble
        self.annotations = annotations
        self.footer = footer
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor(white: 1.0, alpha: 0.03).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(white: 1.0, alpha: 0.06).cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let h = bounds.height
        var y = h - sheetPadding

        let monoFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let monoBoldFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .bold)

        let dimAttrs: [NSAttributedString.Key: Any] = [
            .font: monoFont,
            .foregroundColor: DesignTokens.tourTextDim,
        ]

        // Preamble
        if let preamble, !preamble.isEmpty {
            let lines = preamble.components(separatedBy: "\n")
            for line in lines {
                let str = NSAttributedString(string: line, attributes: dimAttrs)
                let size = str.size()
                y -= size.height
                str.draw(at: NSPoint(x: sheetPadding, y: y))
                y -= lineSpacing
            }
            y -= lineSpacing * 2
        }

        // Annotation lines
        for annotation in annotations {
            let attributed = NSMutableAttributedString()

            // Red bold index number
            let indexStr = NSAttributedString(string: "\(annotation.index). ", attributes: [
                .font: monoBoldFont,
                .foregroundColor: DesignTokens.red,
            ])
            attributed.append(indexStr)

            // Tool name in dim
            let toolStr = NSAttributedString(string: "[\(annotation.tool)] ", attributes: dimAttrs)
            attributed.append(toolStr)

            // Note text in secondary
            let noteStr = NSAttributedString(string: annotation.note, attributes: [
                .font: monoFont,
                .foregroundColor: DesignTokens.tourTextSecondary,
            ])
            attributed.append(noteStr)

            let size = attributed.size()
            y -= size.height
            attributed.draw(at: NSPoint(x: sheetPadding, y: y))
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
                str.draw(at: NSPoint(x: sheetPadding, y: y))
                y -= lineSpacing
            }
        }
    }
}
