import AppKit

struct UserFacingIssue: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoverySuggestion: String?
    let technicalDetails: String?
    let showsScreenRecordingSettingsAction: Bool

    init(
        title: String,
        message: String,
        recoverySuggestion: String?,
        technicalDetails: String?,
        showsScreenRecordingSettingsAction: Bool = false
    ) {
        self.title = title
        self.message = message
        self.recoverySuggestion = recoverySuggestion
        self.technicalDetails = technicalDetails
        self.showsScreenRecordingSettingsAction = showsScreenRecordingSettingsAction
    }

    var isScreenRecordingRelated: Bool {
        showsScreenRecordingSettingsAction || title.localizedCaseInsensitiveContains("screen recording")
    }
}

enum AlertPresenter {
    /// Shows a warning alert for a user-facing issue. Returns true if the user clicked
    /// "Open Screen Recording Settings" (the second button), false otherwise.
    @MainActor
    static func showAlert(for issue: UserFacingIssue, offersScreenRecordingShortcut: Bool) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = issue.title

        var details: [String] = [issue.message]
        if let recoverySuggestion = issue.recoverySuggestion, !recoverySuggestion.isEmpty {
            details.append(recoverySuggestion)
        }
        if let technicalDetails = issue.technicalDetails,
           !technicalDetails.isEmpty,
           issue.title.contains("Could not") {
            details.append("Details: \(technicalDetails)")
        }
        alert.informativeText = details.joined(separator: "\n\n")

        alert.addButton(withTitle: "OK")
        if offersScreenRecordingShortcut {
            alert.addButton(withTitle: "Open Screen Recording Settings")
        }

        let response = alert.runModal()
        return offersScreenRecordingShortcut && response == .alertSecondButtonReturn
    }
}
