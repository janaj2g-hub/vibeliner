import AppKit

enum CaptureOutcome {
    case success(NSImage)
    case cancelled
    case failure(CaptureFailure)
}

struct CaptureFailure: LocalizedError {
    let title: String
    let message: String
    let recoverySuggestion: String
    let technicalDetails: String?

    var errorDescription: String? {
        "\(message) \(recoverySuggestion)"
    }
}

class CaptureManager {
    static let shared = CaptureManager()

    private init() {}

    func captureRegion() async -> CaptureOutcome {
        let captureURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        defer {
            try? FileManager.default.removeItem(at: captureURL)
        }

        let result = await runScreenCapture(to: captureURL)
        let trimmedError = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
        let fileExists = FileManager.default.fileExists(atPath: captureURL.path)

        guard result.exitCode == 0 else {
            if !fileExists && trimmedError.isEmpty {
                return .cancelled
            }

            return .failure(classifyFailure(stderr: trimmedError, outputURL: captureURL))
        }

        guard fileExists else {
            return .failure(
                CaptureFailure(
                    title: "Capture failed",
                    message: "macOS finished the capture flow, but Vibeliner did not receive a screenshot file.",
                    recoverySuggestion: "Try the capture again. If it keeps failing, relaunch Vibeliner and confirm Screen Recording is enabled for Vibeliner in System Settings.",
                    technicalDetails: trimmedError.isEmpty ? nil : trimmedError
                )
            )
        }

        guard let image = NSImage(contentsOf: captureURL) else {
            return .failure(
                CaptureFailure(
                    title: "Capture failed",
                    message: "Vibeliner captured a file, but macOS could not load it as an image.",
                    recoverySuggestion: "Try the capture again. If the problem continues, relaunch Vibeliner and retry from the menu bar.",
                    technicalDetails: trimmedError.isEmpty ? nil : trimmedError
                )
            )
        }

        return .success(image)
    }

    private func runScreenCapture(to outputURL: URL) async -> (exitCode: Int32, standardError: String) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let stderrPipe = Pipe()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                process.arguments = ["-i", "-x", outputURL.path]
                process.standardError = stderrPipe

                do {
                    try process.run()
                    process.waitUntilExit()
                    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                    continuation.resume(returning: (process.terminationStatus, stderr))
                } catch {
                    continuation.resume(returning: (-1, error.localizedDescription))
                }
            }
        }
    }

    private func classifyFailure(stderr: String, outputURL: URL) -> CaptureFailure {
        if stderr.contains("could not create image from rect") {
            return CaptureFailure(
                title: "Capture blocked by macOS",
                message: "macOS could not turn the selected region into an image.",
                recoverySuggestion: "Make sure Screen Recording is enabled for Vibeliner, then fully quit and reopen the app before trying again.",
                technicalDetails: stderr
            )
        }

        if stderr.localizedCaseInsensitiveContains("permission") {
            return CaptureFailure(
                title: "Screen Recording permission needed",
                message: "Vibeliner does not currently have the macOS permission needed to capture the screen.",
                recoverySuggestion: "Enable Vibeliner under System Settings > Privacy & Security > Screen Recording, then quit and reopen Vibeliner.",
                technicalDetails: stderr
            )
        }

        if stderr.isEmpty {
            return CaptureFailure(
                title: "Capture failed",
                message: "macOS did not complete the region capture.",
                recoverySuggestion: "Try again. If it keeps failing, relaunch Vibeliner and retry the capture from the menu bar.",
                technicalDetails: "No screenshot was written to \(outputURL.path)."
            )
        }

        return CaptureFailure(
            title: "Capture failed",
            message: "macOS returned an error while capturing the selected region.",
            recoverySuggestion: "Try again. If it keeps failing, relaunch Vibeliner and confirm Screen Recording is enabled for Vibeliner.",
            technicalDetails: stderr
        )
    }
}
