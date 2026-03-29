import AppKit
import OSLog

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
    let screenRecordingState: ScreenRecordingPermissionState?

    var errorDescription: String? {
        "\(message) \(recoverySuggestion)"
    }
}

class CaptureManager {
    static let shared = CaptureManager()
    private let filePollInterval: UInt64 = 50_000_000
    private let fileMaterializationDeadline: UInt64 = 1_000_000_000
    private let logger = Logger(subsystem: "com.jongrossman.vibeliner", category: "Capture")

    private init() {}

    func captureRegion() async -> CaptureOutcome {
        let runtimeIdentity = AppRuntimeIdentity.current()
        let captureURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        defer {
            try? FileManager.default.removeItem(at: captureURL)
        }

        let result = await runScreenCapture(to: captureURL)
        let fileStatus = await waitForCaptureFile(at: captureURL)

        guard result.exitCode == 0 else {
            if isUserCancelled(result: result, fileStatus: fileStatus) {
                return .cancelled
            }

            return .failure(classifyFailure(result: result, fileStatus: fileStatus, outputURL: captureURL))
        }

        guard fileStatus.isMaterialized else {
            return .failure(
                CaptureFailure(
                    title: "Capture failed",
                    message: "macOS finished the capture flow, but vibeliner did not receive a screenshot file.",
                    recoverySuggestion: "Try the capture again. If it keeps failing, reopen vibeliner and try once more.",
                    technicalDetails: diagnosticSummary(
                        result: result,
                        fileStatus: fileStatus,
                        outputURL: captureURL,
                        runtimeIdentity: runtimeIdentity
                    ),
                    screenRecordingState: nil
                )
            )
        }

        guard let image = NSImage(contentsOf: captureURL) else {
            return .failure(
                CaptureFailure(
                    title: "Capture failed",
                    message: "vibeliner received a screenshot file, but macOS could not load it as an image.",
                    recoverySuggestion: "Try the capture again. If the problem continues, relaunch Vibeliner and retry from the menu bar.",
                    technicalDetails: diagnosticSummary(
                        result: result,
                        fileStatus: fileStatus,
                        outputURL: captureURL,
                        runtimeIdentity: runtimeIdentity
                    ),
                    screenRecordingState: nil
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

    private func waitForCaptureFile(at outputURL: URL) async -> CaptureFileStatus {
        let deadline = DispatchTime.now().uptimeNanoseconds + fileMaterializationDeadline

        while DispatchTime.now().uptimeNanoseconds < deadline {
            let status = CaptureFileStatus(url: outputURL)
            if status.isMaterialized {
                return status
            }

            try? await Task.sleep(nanoseconds: filePollInterval)
        }

        return CaptureFileStatus(url: outputURL)
    }

    private func isUserCancelled(
        result: (exitCode: Int32, standardError: String),
        fileStatus: CaptureFileStatus
    ) -> Bool {
        result.exitCode == 1 &&
            result.standardError.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !fileStatus.exists
    }

    private func classifyFailure(
        result: (exitCode: Int32, standardError: String),
        fileStatus: CaptureFileStatus,
        outputURL: URL
    ) -> CaptureFailure {
        let stderr = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
        let runtimeIdentity = AppRuntimeIdentity.current()
        let diagnostics = diagnosticSummary(
            result: result,
            fileStatus: fileStatus,
            outputURL: outputURL,
            runtimeIdentity: runtimeIdentity
        )
        let loweredError = stderr.lowercased()

        if loweredError.contains("declined tcc") || loweredError.contains("permission") || loweredError.contains("not authorized") {
            let livePermissionState = ScreenRecordingPermissionState.current()
            logger.error("Capture permission-like failure: \(diagnostics, privacy: .public)")

            if livePermissionState.isAuthorized && !runtimeIdentity.isLikelyRunningWrongAppCopy {
                return CaptureFailure(
                    title: "Screen Recording mismatch",
                    message: "macOS denied the capture even though Vibeliner appears enabled in Screen Recording settings.",
                    recoverySuggestion: "Turn Vibeliner off and back on in System Settings > Privacy & Security > Screen & System Audio Recording, then quit and reopen Vibeliner before retrying.",
                    technicalDetails: diagnostics,
                    screenRecordingState: nil
                )
            }

            let issue = runtimeIdentity.isLikelyRunningWrongAppCopy
                ? UserFacingIssue(
                    title: "Screen Recording blocked for this app copy",
                    message: "macOS blocked Screen Recording for the Vibeliner bundle that is currently running.",
                    recoverySuggestion: runtimeIdentity.runCopyRecoverySuggestion,
                    technicalDetails: nil,
                    showsScreenRecordingSettingsAction: true
                )
                : ScreenRecordingPermissionState.notGranted.issue
            return CaptureFailure(
                title: issue.title,
                message: issue.message,
                recoverySuggestion: issue.recoverySuggestion ?? "Enable Screen Recording for vibeliner, then quit and reopen it.",
                technicalDetails: diagnostics,
                screenRecordingState: .notGranted
            )
        }

        if stderr.contains("could not create image from rect") {
            logger.error("Capture rect failure: \(diagnostics, privacy: .public)")
            let recoverySuggestion = runtimeIdentity.isLikelyRunningWrongAppCopy
                ? runtimeIdentity.runCopyRecoverySuggestion
                : "Try the capture again. If it keeps failing, quit and reopen vibeliner, then retry from the menu bar."
            return CaptureFailure(
                title: "Capture failed",
                message: runtimeIdentity.isLikelyRunningWrongAppCopy
                    ? "macOS started the region capture UI, but the running Vibeliner app copy may not match the bundle Screen Recording was approved for."
                    : "macOS started the region capture UI, but it did not produce an image for the selected area.",
                recoverySuggestion: recoverySuggestion,
                technicalDetails: diagnostics,
                screenRecordingState: nil
            )
        }

        if result.exitCode != 0 && stderr.isEmpty {
            logger.error("Capture empty-stderr failure: \(diagnostics, privacy: .public)")
            return CaptureFailure(
                title: "Capture failed",
                message: "macOS ended the capture flow without returning a screenshot.",
                recoverySuggestion: "Try the capture again. If it keeps failing, reopen vibeliner and retry from the menu bar.",
                technicalDetails: diagnostics,
                screenRecordingState: nil
            )
        }

        if stderr.isEmpty {
            logger.error("Capture generic empty-error failure: \(diagnostics, privacy: .public)")
            return CaptureFailure(
                title: "Capture failed",
                message: "macOS did not complete the region capture.",
                recoverySuggestion: "Try again. If it keeps failing, relaunch Vibeliner and retry the capture from the menu bar.",
                technicalDetails: diagnostics,
                screenRecordingState: nil
            )
        }

        logger.error("Capture stderr failure: \(diagnostics, privacy: .public)")
        return CaptureFailure(
            title: "Capture failed",
            message: "macOS returned an error while capturing the selected region.",
            recoverySuggestion: "Try again. If it keeps failing, relaunch vibeliner and retry the capture from the menu bar.",
            technicalDetails: diagnostics,
            screenRecordingState: nil
        )
    }

    private func diagnosticSummary(
        result: (exitCode: Int32, standardError: String),
        fileStatus: CaptureFileStatus,
        outputURL: URL,
        runtimeIdentity: AppRuntimeIdentity
    ) -> String {
        let stderr = result.standardError.trimmingCharacters(in: .whitespacesAndNewlines)
        let stderrSummary = stderr.isEmpty ? "<empty>" : stderr
        let fileSizeSummary = fileStatus.size.map(String.init) ?? "nil"
        let expectedDistPath = runtimeIdentity.expectedDistAppPath ?? "nil"
        return "exitCode=\(result.exitCode); fileExists=\(fileStatus.exists); fileSize=\(fileSizeSummary); outputURL=\(outputURL.path); stderr=\(stderrSummary); bundleID=\(runtimeIdentity.bundleIdentifier); appPath=\(runtimeIdentity.appBundlePath); expectedDistPath=\(expectedDistPath); runCopy=\(runtimeIdentity.runCopyLabel)"
    }
}

private struct CaptureFileStatus {
    let exists: Bool
    let size: UInt64?

    var isMaterialized: Bool {
        exists && (size ?? 0) > 0
    }

    init(url: URL) {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? NSNumber {
            exists = true
            size = fileSize.uint64Value
        } else {
            exists = false
            size = nil
        }
    }
}
