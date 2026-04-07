import Foundation

enum PromptMode {
    case savedFile
    case clipboardIDE(absolutePath: String)
    case clipboardApp
}

final class PromptGenerator {

    static func generatePrompt(
        annotations: [Annotation],
        screenshotPath: String,
        mode: PromptMode,
        preambleOverride: String? = nil,
        footerOverride: String? = nil,
        toolDescriptionsOverride: [String: String]? = nil
    ) -> String {
        var preamble = preambleOverride ?? ConfigManager.shared.preamble

        // Replace [Screenshot Path]
        switch mode {
        case .savedFile:
            preamble = preamble.replacingOccurrences(of: "[Screenshot Path]", with: "./screenshot.png")
        case .clipboardIDE(let absolutePath):
            preamble = preamble.replacingOccurrences(of: "[Screenshot Path]", with: absolutePath)
        case .clipboardApp:
            // Remove the entire sentence containing the token
            let lines = preamble.components(separatedBy: "\n")
            let filtered = lines.filter { !$0.contains("[Screenshot Path]") }
            preamble = filtered.joined(separator: "\n")
        }

        // Replace [Tool Description]
        let toolDescription = generateToolDescription(from: annotations, toolDescriptions: toolDescriptionsOverride)
        preamble = preamble.replacingOccurrences(of: "[Tool Description]", with: toolDescription)

        // Annotation list
        let sorted = annotations.sorted { $0.number < $1.number }
        var annotationLines: [String] = []
        for a in sorted {
            if a.noteText.isEmpty {
                annotationLines.append("\(a.number)  [\(a.type.label)]")
            } else {
                annotationLines.append("\(a.number)  [\(a.type.label)] \(a.noteText)")
            }
        }
        let annotationList = annotationLines.joined(separator: "\n")

        // Footer
        let footer = footerOverride ?? ConfigManager.shared.footer

        // Assemble
        var parts: [String] = [preamble]
        if !annotationList.isEmpty {
            parts.append(annotationList)
        }
        if !footer.isEmpty {
            parts.append(footer)
        }

        return parts.joined(separator: "\n\n")
    }

    static func savePromptFile(to folderURL: URL, annotations: [Annotation]) {
        let prompt = generatePrompt(annotations: annotations, screenshotPath: "./screenshot.png", mode: .savedFile)
        let fileURL = folderURL.appendingPathComponent("prompt.txt")
        let tempURL = folderURL.appendingPathComponent(".prompt.txt.tmp")
        try? prompt.write(to: tempURL, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.moveItem(at: tempURL, to: fileURL)
    }

    static func clipboardPrompt(annotations: [Annotation], captureFolder: URL) -> String {
        let mode = ConfigManager.shared.copyMode
        if mode == "ide" {
            let absolutePath = captureFolder.appendingPathComponent("screenshot.png").path
            return generatePrompt(annotations: annotations, screenshotPath: absolutePath, mode: .clipboardIDE(absolutePath: absolutePath))
        } else {
            return generatePrompt(annotations: annotations, screenshotPath: "", mode: .clipboardApp)
        }
    }

    // MARK: - Tool description

    private static func generateToolDescription(from annotations: [Annotation], toolDescriptions: [String: String]? = nil) -> String {
        let toolTypes = Set(annotations.map { $0.type })
        guard !toolTypes.isEmpty else { return "" }

        let descriptions = toolDescriptions ?? ConfigManager.shared.toolDescriptions
        let ordered: [AnnotationToolType] = [.pin, .arrow, .rectangle, .circle, .freehand]
        let used = ordered.filter { toolTypes.contains($0) }

        if used.count == 1, let tool = used.first {
            let desc = descriptions[tool.label] ?? ""
            return "Numbered \(tool.label)s \(desc)."
        } else if used.count == 2 {
            let first = used[0]
            let second = used[1]
            let desc1 = descriptions[first.label] ?? ""
            let desc2 = descriptions[second.label] ?? ""
            return "Numbered \(first.label)s \(desc1) and \(second.label)s \(desc2)."
        } else {
            let parts = used.map { tool -> String in
                let desc = descriptions[tool.label] ?? ""
                return "\(tool.label)s (\(desc))"
            }
            let allButLast = parts.dropLast().joined(separator: ", ")
            let last = parts.last ?? ""
            return "Annotations use \(allButLast), and \(last)."
        }
    }
}
