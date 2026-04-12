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
        captureSession: CaptureSession? = nil,
        preambleOverride: String? = nil,
        footerOverride: String? = nil,
        toolDescriptionsOverride: [String: String]? = nil
    ) -> String {
        var preamble = preambleOverride ?? ConfigManager.shared.preamble

        // Replace [Screenshot Path]
        switch mode {
        case .savedFile:
            preamble = preamble.replacingOccurrences(
                of: "[Screenshot Path]",
                with: "./\(CaptureSession.annotatedImageFilename)"
            )
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
        if let session = captureSession, session.isMultiImage {
            let count = session.images.count
            var lines: [String] = []
            lines.append("This screenshot contains \(count) framed images in one stitched composite.")
            lines.append("")
            lines.append("Images:")
            for img in session.images {
                let roleDesc = ConfigManager.shared.roles.first(where: { $0.name.lowercased() == img.role.name.lowercased() })?.description ?? ""
                if roleDesc.isEmpty {
                    lines.append("- \(img.title) (\(img.role.displayName))")
                } else {
                    lines.append("- \(img.title) (\(img.role.displayName)) — \(roleDesc)")
                }
            }
            lines.append("")
            lines.append("Use the visible frame title bars to determine which image each annotation belongs to.")
            let roleNames = Array(Set(session.images.map { $0.role.displayName })).sorted()
            if !roleNames.isEmpty {
                lines.append("Use the visible role pills to identify each image's role (\(roleNames.joined(separator: ", "))).")
            }
            multiImageBlock = lines.joined(separator: "\n")
        }

        // Annotation list
        let sorted = annotations.sorted { $0.number < $1.number }
        var annotationLines: [String] = []
        for a in sorted {
            let text = a.noteText.isEmpty ? "(no description)" : a.noteText
            // VIB-269: Prepend image title prefix in composite mode
            let imagePrefix: String
            if let session = captureSession, session.isMultiImage {
                let parentTitle = session.title(forImageID: a.parentImageID, fallbackIndex: a.parentImageIndex)
                if case .arrow = a.position,
                   let endTitleIndex = a.endImageIndex,
                   endTitleIndex != a.parentImageIndex {
                    let endTitle = session.title(forImageID: a.endImageID, fallbackIndex: endTitleIndex)
                    imagePrefix = "\(parentTitle) → \(endTitle) — "
                } else {
                    imagePrefix = "\(parentTitle) — "
                }
            } else {
                imagePrefix = ""
            }
            annotationLines.append("\(a.number)  [\(a.type.label)] \(imagePrefix)\(text)")
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

    static func savePromptFile(to folderURL: URL, annotations: [Annotation], captureSession: CaptureSession? = nil) {
        let prompt = generatePrompt(
            annotations: annotations,
            screenshotPath: "./\(CaptureSession.annotatedImageFilename)",
            mode: .savedFile,
            captureSession: captureSession
        )
        let fileURL = folderURL.appendingPathComponent(CaptureSession.promptFilename)
        let tempURL = folderURL.appendingPathComponent(".\(CaptureSession.promptFilename).tmp")
        try? prompt.write(to: tempURL, atomically: true, encoding: .utf8)
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.moveItem(at: tempURL, to: fileURL)
    }

    static func clipboardPrompt(annotations: [Annotation], captureFolder: URL, captureSession: CaptureSession? = nil) -> String {
        let mode = ConfigManager.shared.copyMode
        if mode == "ide" {
            let absolutePath = CaptureSession.resolvedAnnotatedImageURL(in: captureFolder).path
            return generatePrompt(
                annotations: annotations,
                screenshotPath: absolutePath,
                mode: .clipboardIDE(absolutePath: absolutePath),
                captureSession: captureSession
            )
        } else {
            return generatePrompt(
                annotations: annotations,
                screenshotPath: "",
                mode: .clipboardApp,
                captureSession: captureSession
            )
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
