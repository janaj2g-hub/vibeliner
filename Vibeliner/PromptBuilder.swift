import Foundation

enum PromptBuilder {
    static let screenshotPathToken = "{{SCREENSHOT_PATH}}"
    static let savedScreenshotReference = "./screenshot.png"
    static let automaticScreenshotLinePrefix = "Screenshot: "
    static let annotationSemanticsSummary = "Red overlays are intentional annotations: numbered badges mark issues or discussion points, note text explains them when present, arrows point to exact targets, and circles mark regions to inspect."
    static let noAnnotationSummary = "No explicit overlays are present in this screenshot; use the screenshot itself as the source of truth."
    static let defaultSinglePreamble = "Review the screenshot at `\(screenshotPathToken)`. \(annotationSemanticsSummary)"
    static let defaultBatchPreamble = "Review the screenshots referenced below. \(annotationSemanticsSummary)"
    static let pathGuidance = "Saved prompt.md files keep a relative screenshot path (\(savedScreenshotReference)). Copy for LLM resolves that path to an absolute screenshot path so pasting works from any Claude Code or Cursor working directory."
    static let singlePreambleGuidance = "Use \(screenshotPathToken) to place the screenshot path yourself. If you omit it, Vibeliner appends a separate screenshot line automatically. Default prompt text keeps the screenshot first and explains badges, note text, arrows, and circles in one concise block."
    static let batchPreambleGuidance = "Reserved for multi-capture exports. The same screenshot-path and annotation-semantics rules apply when this template is used."

    static func formattedScreenshotReference(_ reference: String) -> String {
        "`\(reference)`"
    }

    static func normalizedTemplate(_ template: String) -> String {
        template.replacingOccurrences(of: savedScreenshotReference, with: screenshotPathToken)
    }

    static func buildPrompt(
        preambleTemplate: String,
        annotations: [(number: Int, note: String)],
        screenshotReference: String
    ) -> String {
        let resolvedTemplate = normalizedTemplate(preambleTemplate).trimmingCharacters(in: .whitespacesAndNewlines)
        var lines: [String] = []

        if resolvedTemplate.isEmpty {
            lines.append("\(automaticScreenshotLinePrefix)\(formattedScreenshotReference(screenshotReference))")
        } else if resolvedTemplate.contains(screenshotPathToken) {
            lines.append(resolvedTemplate.replacingOccurrences(of: screenshotPathToken, with: screenshotReference))
        } else {
            lines.append(resolvedTemplate)
            lines.append("")
            lines.append("\(automaticScreenshotLinePrefix)\(formattedScreenshotReference(screenshotReference))")
        }

        lines.append("")
        lines.append(contentsOf: annotationSummaryLines(for: annotations))

        lines.append("")
        return lines.joined(separator: "\n")
    }

    static func buildSavedPrompt(
        preambleTemplate: String,
        annotations: [(number: Int, note: String)]
    ) -> String {
        buildPrompt(
            preambleTemplate: preambleTemplate,
            annotations: annotations,
            screenshotReference: savedScreenshotReference
        )
    }

    static func clipboardPrompt(from savedPrompt: String, screenshotURL: URL) -> String {
        let screenshotPath = screenshotURL.path

        return savedPrompt
            .replacingOccurrences(of: savedScreenshotReference, with: screenshotPath)
            .replacingOccurrences(of: screenshotPathToken, with: screenshotPath)
    }

    private static func annotationSummaryLines(for annotations: [(number: Int, note: String)]) -> [String] {
        guard !annotations.isEmpty else {
            return [noAnnotationSummary]
        }

        return annotations
            .sorted(by: { $0.number < $1.number })
            .map { annotation in
                let noteText = annotation.note.isEmpty ? "[no description]" : annotation.note
                return "\(annotation.number). \(noteText)"
            }
    }
}
