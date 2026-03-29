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
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsSetupSection {
                readinessSection
                sectionDivider
            }

            if let issue = appState.lastIssue {
                issueSection(issue)
                sectionDivider
            }

            recentCapturesSection
            sectionDivider
            utilitySection
            sectionDivider
            hotkeySection
            sectionDivider

            InteractiveMenuRow(isEnabled: true, action: openAboutSettings) {
                menuRowLabel("About vibeliner", systemImage: "info.circle")
            }

            InteractiveMenuRow(isEnabled: true, action: { NSApp.terminate(nil) }) {
                Text("Quit vibeliner")
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Setup")

            VStack(alignment: .leading, spacing: 0) {
                Text(appState.setupSummary.setupHeading)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange)
                    .padding(.bottom, 8)

                if !appState.setupSummary.screenRecordingAuthorized {
                    readinessRow(
                        symbol: "1",
                        title: "Screen Recording permission",
                        isReady: false,
                        detail: compactReadinessDetail(for: appState.setupSummary.screenRecordingDetail),
                        actionTitle: "Grant Access",
                        action: requestScreenRecordingAccess
                    )
                }

                if !appState.setupSummary.screenRecordingAuthorized && !appState.setupSummary.storageStatus.isReady {
                    sectionDivider
                        .padding(.vertical, 10)
                }

                readinessRow(
                    symbol: appState.setupSummary.storageStatus.isReady ? "checkmark" : (!appState.setupSummary.screenRecordingAuthorized ? "2" : "1"),
                    title: "Captures folder",
                    isReady: appState.setupSummary.storageStatus.isReady,
                    detail: compactReadinessDetail(for: appState.setupSummary.storageStatus.detail),
                    actionTitle: "Open Folder",
                    action: openCapturesFolder
                )
            }
            .padding(12)
            .background(sectionCardBackground)
            .overlay(sectionCardBorder)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var sectionCardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.05))
    }

    private var sectionCardBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.35))
            .frame(height: 1)
            .padding(.vertical, 10)
    }

    private func menuRowLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 13))

            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func iconBadge(symbol: String, isReady: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isReady ? Color.green.opacity(0.2) : Color.white.opacity(0.08))
                .frame(width: 28, height: 28)

            if symbol == "checkmark" {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.green)
            } else {
                Text(symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange)
            }
        }
    }

    private func issueSection(_ issue: UserFacingIssue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
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
                .foregroundStyle(.primary)

            if let recoverySuggestion = issue.recoverySuggestion, !recoverySuggestion.isEmpty {
                Text(recoverySuggestion)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.18), lineWidth: 1)
        )
    }

    private var recentCapturesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Recent Captures")

            if appState.recentCaptures.isEmpty {
                Text("no captures yet")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(appState.recentCaptures, id: \.id) { record in
                    InteractiveMenuRow(isEnabled: true, action: { copyCapturePrompt(for: record) }) {
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(displaySlug(for: record.slug))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text("\(record.count) \(record.count == 1 ? "note" : "notes") · \(relativeFormatter.localizedString(for: record.created, relativeTo: Date()))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if copiedCaptureID == record.id {
                                Text("Copied")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.blue)
                                    .transition(.opacity)
                            }
                        }
                    }
                }
            }
        }
    }

    private var utilitySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Actions")

            InteractiveMenuRow(isEnabled: !appState.isCaptureInProgress, action: startCapture) {
                menuRowLabel(appState.isCaptureInProgress ? "Capturing..." : "Capture now", systemImage: "camera.viewfinder")
            }

            InteractiveMenuRow(isEnabled: true, action: openPromptSettings) {
                menuRowLabel("Prompt settings", systemImage: "slider.horizontal.3")
            }

            InteractiveMenuRow(isEnabled: true, action: openGeneralSettings) {
                menuRowLabel("General settings", systemImage: "gearshape")
            }

            InteractiveMenuRow(isEnabled: true, action: openCapturesFolder) {
                menuRowLabel("Open captures folder", systemImage: "folder")
            }
        }
    }

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle("Hotkey")

            HStack {
                Text("Change hotkey")
                    .font(.system(size: 12))
                Spacer()
                KeyboardShortcuts.Recorder(for: .captureScreen)
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

    private func readinessRow(
        symbol: String,
        title: String,
        isReady: Bool,
        detail: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconBadge(symbol: symbol, isReady: isReady)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))

                    Spacer()

                    if let actionTitle {
                        Button(actionTitle) {
                            action()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
                    }
                }

                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
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
