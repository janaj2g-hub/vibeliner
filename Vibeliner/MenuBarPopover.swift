import AppKit
import KeyboardShortcuts
import SwiftUI

private struct InteractiveMenuRow<Content: View>: View {
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isHovered ? Color.white.opacity(0.09) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovering in
            isHovered = isEnabled && hovering
        }
    }
}

struct MenuBarPopover: View {
    @ObservedObject var appState: AppState

    let startCapture: () -> Void
    let onCopyCapturePrompt: (CaptureRecord) -> Bool
    let openGeneralSettings: () -> Void
    let openHotkeySettings: () -> Void
    let openPromptSettings: () -> Void
    let openAboutSettings: () -> Void
    let openCapturesFolder: () -> Void
    let requestScreenRecordingAccess: () -> Void
    let openScreenRecordingSettings: () -> Void
    let dismissIssue: () -> Void

    @State private var copiedCaptureID: String?

    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private var shortcutSummary: String {
        guard let shortcut = KeyboardShortcuts.getShortcut(for: .captureScreen) else {
            return "Not set"
        }

        return String(describing: shortcut)
    }

    private var showsSetupSection: Bool {
        let setupNeedsScreenRecording = !appState.setupSummary.screenRecordingAuthorized
        let setupNeedsStorage = !appState.setupSummary.storageStatus.isReady

        if setupNeedsStorage {
            return true
        }

        guard setupNeedsScreenRecording else {
            return false
        }

        return !(appState.lastIssue?.isScreenRecordingRelated ?? false)
    }

    private var needsStorageSetup: Bool {
        !appState.setupSummary.storageStatus.isReady
    }

    private var recentCapturesSummary: String {
        let count = appState.recentCaptures.count
        guard count > 0 else {
            return "None"
        }

        if count == 1 {
            return "1 item"
        }

        return "\(count) items"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsSetupSection || needsStorageSetup {
                setupActionsSection
                sectionDivider
            }

            if let issue = appState.lastIssue {
                issueSection(issue)
                sectionDivider
            }

            primaryActionsSection
            sectionDivider
            settingsSection

            InteractiveMenuRow(isEnabled: true, action: openAboutSettings) {
                menuRowLabel("About vibeliner", systemImage: "info.circle")
            }

            sectionDivider

            InteractiveMenuRow(isEnabled: true, action: { NSApp.terminate(nil) }) {
                menuRowLabel("Quit vibeliner", systemImage: "power")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(width: 286)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var setupActionsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            if showsSetupSection {
                InteractiveMenuRow(isEnabled: true, action: requestScreenRecordingAccess) {
                    menuRowLabel(
                        "Grant Screen Recording Access",
                        systemImage: "display",
                        trailingText: nil,
                        showsChevron: true,
                        accentColor: .orange
                    )
                }
            }

            if needsStorageSetup {
                InteractiveMenuRow(isEnabled: true, action: openCapturesFolder) {
                    menuRowLabel(
                        "Open captures folder",
                        systemImage: "folder",
                        trailingText: nil,
                        showsChevron: true,
                        accentColor: .orange
                    )
                }
            }
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.11))
            .frame(height: 1)
            .padding(.vertical, 8)
    }

    private func menuRowLabel(
        _ title: String,
        systemImage: String,
        trailingText: String? = nil,
        showsChevron: Bool = false,
        accentColor: Color? = nil
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(accentColor ?? .primary)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accentColor ?? .primary)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
        .contentShape(Rectangle())
    }

    private func issueSection(_ issue: UserFacingIssue) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(issue.title, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                Spacer()
                HStack(spacing: 10) {
                    if issue.showsScreenRecordingSettingsAction {
                        Button("Open Settings") {
                            openScreenRecordingSettings()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                    }

                    Button("Dismiss") {
                        dismissIssue()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                }
            }

            Text(issue.message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            if let recoverySuggestion = issue.recoverySuggestion, !recoverySuggestion.isEmpty {
                Text(recoverySuggestion)
                .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var primaryActionsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            InteractiveMenuRow(isEnabled: !appState.isCaptureInProgress, action: startCapture) {
                menuRowLabel(appState.isCaptureInProgress ? "Capturing..." : "Capture now", systemImage: "camera.viewfinder")
            }

            if let latestCapture = appState.recentCaptures.first {
                InteractiveMenuRow(isEnabled: true, action: { copyCapturePrompt(for: latestCapture) }) {
                    menuRowLabel(
                        "Copy latest capture",
                        systemImage: "clock.arrow.circlepath",
                        trailingText: copiedCaptureID == latestCapture.id
                            ? "Copied"
                            : relativeFormatter.localizedString(for: latestCapture.created, relativeTo: Date())
                    )
                }
            }

            InteractiveMenuRow(isEnabled: true, action: openCapturesFolder) {
                menuRowLabel("Recent captures", systemImage: "tray.full", trailingText: recentCapturesSummary, showsChevron: true)
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            InteractiveMenuRow(isEnabled: true, action: openPromptSettings) {
                menuRowLabel("Prompt settings", systemImage: "slider.horizontal.3", showsChevron: true)
            }

            InteractiveMenuRow(isEnabled: true, action: openGeneralSettings) {
                menuRowLabel("General settings", systemImage: "gearshape", showsChevron: true)
            }

            InteractiveMenuRow(isEnabled: true, action: openHotkeySettings) {
                menuRowLabel("Hotkey", systemImage: "command", trailingText: shortcutSummary, showsChevron: true)
            }
        }
    }

    private func copyCapturePrompt(for record: CaptureRecord) {
        guard onCopyCapturePrompt(record) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            copiedCaptureID = record.id
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard copiedCaptureID == record.id else { return }

            withAnimation(.easeInOut(duration: 0.2)) {
                copiedCaptureID = nil
            }
        }
    }

    private func displaySlug(for slug: String) -> String {
        guard slug.count > 25 else { return slug }
        return String(slug.prefix(25)) + "..."
    }

    private func compactReadinessDetail(for detail: String) -> String {
        if detail.hasPrefix("Ready at ") || detail.hasPrefix("Created captures folder at ") {
            return detail
                .replacingOccurrences(of: "Created captures folder at ", with: "")
                .replacingOccurrences(of: "Ready at ", with: "")
        }

        return detail
            .replacingOccurrences(of: "The captures folder does not exist yet.", with: "Missing.")
            .replacingOccurrences(of: "The save directory path points to a file, not a folder.", with: "Path points to a file.")
            .replacingOccurrences(of: "Vibeliner could not create the captures folder at ", with: "Could not create ")
            .replacingOccurrences(of: "Vibeliner cannot write to the captures folder at ", with: "Cannot write to ")
    }
}
