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
        captureStore: CaptureStore? = nil,
        preambleOverride: String? = nil,
        footerOverride: String? = nil,
        toolDescriptionsOverride: [String: String]? = nil
    ) -> String {
        var preamble = preambleOverride ?? ConfigManager.shared.preamble

        // Replace [Screenshot Path]
        switch mode {
        case .savedFile:
            let filename = (captureStore?.isComposite == true) ? "./composite.png" : "./screenshot.png"
            preamble = preamble.replacingOccurrences(of: "[Screenshot Path]", with: filename)
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

        // VIB-265: Multi-image block
        var multiImageBlock = ""
        if let store = captureStore, store.isComposite {
            let count = store.images.count
            var lines: [String] = []
            lines.append("This screenshot contains \(count) framed images in one stitched composite.")
            lines.append("")
            lines.append("Images:")
            for img in store.images {
                lines.append("- \(img.title) (\(img.role.displayName))")
            }
            lines.append("")
            lines.append("Use the visible frame title bars to determine which image each note belongs to.")
            lines.append("Use the visible role pills to determine whether an image is Observed, Reference, or Expected.")
            multiImageBlock = lines.joined(separator: "\n")
        }

        // Annotation list
        let sorted = annotations.sorted { $0.number < $1.number }
        var annotationLines: [String] = []
        for a in sorted {
            let text = a.noteText.isEmpty ? "(no description)" : a.noteText
            annotationLines.append("\(a.number)  [\(a.type.label)] \(text)")
        }
        let annotationList = annotationLines.joined(separator: "\n")

        // Footer
        let footer = footerOverride ?? ConfigManager.shared.footer

        // Assemble
        var parts: [String] = [preamble]
        if !multiImageBlock.isEmpty {
            parts.append(multiImageBlock)
        }
        if !annotationList.isEmpty {
            parts.append(annotationList)
        }
        if !footer.isEmpty {
            parts.append(footer)
        }

        return parts.joined(separator: "\n\n")
    }

    static func savePromptFile(to folderURL: URL, annotations: [Annotation], captureStore: CaptureStore? = nil) {
        let prompt = generatePrompt(annotations: annotations, screenshotPath: "./screenshot.png", mode: .savedFile, captureStore: captureStore)
        let fileURL = folderURL.appendingPathComponent("prompt.txt")
        let tempURL = folderURL.appendingPathComponent(".prompt.txt.tmp")
        try? prompt.write(to: tempURL, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.moveItem(at: tempURL, to: fileURL)
    }

    static func clipboardPrompt(annotations: [Annotation], captureFolder: URL, captureStore: CaptureStore? = nil) -> String {
        let mode = ConfigManager.shared.copyMode
        if mode == "ide" {
            let filename = (captureStore?.isComposite == true) ? "composite.png" : "screenshot.png"
            let absolutePath = captureFolder.appendingPathComponent(filename).path
            return generatePrompt(annotations: annotations, screenshotPath: absolutePath, mode: .clipboardIDE(absolutePath: absolutePath), captureStore: captureStore)
        } else {
            return generatePrompt(annotations: annotations, screenshotPath: "", mode: .clipboardApp, captureStore: captureStore)
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
