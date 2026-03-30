import AppKit
import CoreGraphics

enum ScreenRecordingPermissionState {
    case authorized
    case notGranted

    var isAuthorized: Bool {
        self == .authorized
    }

    var issue: UserFacingIssue {
        switch self {
        case .authorized:
            return UserFacingIssue(
                title: "Screen Recording ready",
                message: "vibeliner can use Screen Recording.",
                recoverySuggestion: nil,
                technicalDetails: nil
            )
        case .notGranted:
            return UserFacingIssue(
                title: "Screen Recording permission needed",
                message: "vibeliner cannot start a region capture until macOS allows it to record the screen.",
                recoverySuggestion: "Enable vibeliner in System Settings > Privacy & Security > Screen & System Audio Recording, then quit and reopen vibeliner.",
                technicalDetails: nil,
                showsScreenRecordingSettingsAction: true
            )
        }
    }

    var offersOpenSettingsShortcut: Bool {
        self != .authorized
    }

    static func current() -> Self {
        CGPreflightScreenCaptureAccess() ? .authorized : .notGranted
    }
}

@MainActor
enum PermissionCoordinator {
    static func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    static func requestScreenRecordingAccess() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func screenRecordingRelaunchIssue() -> UserFacingIssue {
        let runtimeIdentity = AppRuntimeIdentity.current()
        return UserFacingIssue(
            title: "Relaunch required before capture",
            message: "Screen Recording permission changed, but this running process cannot safely resume capture until it restarts.",
            recoverySuggestion: "Relaunch into the canonical app copy before trying capture again. \(runtimeIdentity.canonicalLaunchGuidance)",
            technicalDetails: "category=relaunchRequired; runCopy=\(runtimeIdentity.runCopyLabel); appPath=\(runtimeIdentity.appBundlePath); expectedDistPath=\(runtimeIdentity.expectedDistAppPath ?? "nil")"
        )
    }

    static func unsupportedRuntimeIssue(_ runtimeIdentity: AppRuntimeIdentity) -> UserFacingIssue {
        let message = "This app copy is not the supported screenshot-capture runtime."
        let recoverySuggestion = "\(runtimeIdentity.canonicalLaunchGuidance) Current app path: \(runtimeIdentity.appBundlePath)"

        return UserFacingIssue(
            title: "Launch the canonical app copy",
            message: message,
            recoverySuggestion: recoverySuggestion,
            technicalDetails: "runCopy=\(runtimeIdentity.runCopyLabel); appPath=\(runtimeIdentity.appBundlePath); expectedDistPath=\(runtimeIdentity.expectedDistAppPath ?? "nil")"
        )
    }

    @discardableResult
    static func relaunchIntoCanonicalAppIfPossible() -> Bool {
        let runtimeIdentity = AppRuntimeIdentity.current()
        guard let canonicalAppURL = runtimeIdentity.canonicalAppURL else {
            return false
        }

        guard FileManager.default.fileExists(atPath: canonicalAppURL.path) else {
            return false
        }

        guard NSWorkspace.shared.open(canonicalAppURL) else {
            return false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.terminate(nil)
        }

        return true
    }
}
