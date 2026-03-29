import Foundation

struct AppRuntimeIdentity {
    let bundleIdentifier: String
    let appBundlePath: String
    let expectedDistAppPath: String?

    var isRunningDerivedDataCopy: Bool {
        appBundlePath.contains("/DerivedData/")
    }

    var isSupportedRuntimeCopy: Bool {
        guard let expectedDistAppPath else {
            return !isRunningDerivedDataCopy
        }

        return appBundlePath == expectedDistAppPath
    }

    var isLikelyRunningWrongAppCopy: Bool {
        !isSupportedRuntimeCopy
    }

    var runCopyLabel: String {
        if isSupportedRuntimeCopy {
            return "dist"
        }

        if isRunningDerivedDataCopy {
            return "derivedData"
        }

        return "other"
    }

    var canonicalLaunchGuidance: String {
        guard let expectedDistAppPath else {
            return "Launch the supported repo-local app copy before testing capture."
        }

        return "Launch \(expectedDistAppPath) before testing capture or authorizing Screen Recording."
    }

    var runCopyStatus: String {
        if isSupportedRuntimeCopy {
            return "Running the canonical repo-local dist app. Use this copy for Screen Recording authorization and capture testing."
        }

        if isRunningDerivedDataCopy {
            return "Running the Xcode DerivedData app. This copy is not the supported capture runtime; launch dist/Vibeliner.app instead."
        }

        return "Running a non-dist app copy. Launch dist/Vibeliner.app before testing capture so TCC approval and runtime behavior stay aligned."
    }

    var runCopyRecoverySuggestion: String {
        if let expectedDistAppPath {
            return "Authorize and relaunch the canonical app copy at \(expectedDistAppPath), then retry capture from that same bundle."
        }

        return "Authorize and relaunch the supported app copy, then retry capture from that same bundle."
    }

    static func current(bundle: Bundle = .main) -> Self {
        let sourceRoot = bundle.object(forInfoDictionaryKey: "VBLSourceRoot") as? String
        let expectedDistAppPath = sourceRoot.map {
            URL(fileURLWithPath: $0)
                .appendingPathComponent("dist/Vibeliner.app")
                .standardizedFileURL
                .path
        }

        return AppRuntimeIdentity(
            bundleIdentifier: bundle.bundleIdentifier ?? "unknown",
            appBundlePath: bundle.bundleURL.standardizedFileURL.path,
            expectedDistAppPath: expectedDistAppPath
        )
    }
}
