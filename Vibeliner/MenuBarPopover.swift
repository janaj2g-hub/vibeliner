import AppKit
import KeyboardShortcuts
import SwiftUI

struct MenuBarPopover: View {
    @ObservedObject var appState: AppState

    let startCapture: () -> Void
    let onCopyCapturePrompt: (CaptureRecord) -> Bool
    let openPromptSettings: () -> Void
    let openCapturesFolder: () -> Void
    let openScreenRecordingSettings: () -> Void
    let dismissIssue: () -> Void

    @State private var copiedCaptureID: String?

    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private var showsSetupSection: Bool {
        !appState.setupSummary.screenRecordingAuthorized || !appState.setupSummary.storageStatus.isReady
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if showsSetupSection {
                readinessSection
            }

            if let issue = appState.lastIssue {
                issueSection(issue)
            }

            recentCapturesSection
            utilitySection
            hotkeySection

            Button("Quit Vibeliner") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
        }
        .padding(14)
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Vibeliner")
                    .font(.system(size: 14, weight: .bold))
                Text(appState.setupSummary.readinessTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(appState.setupSummary.isReadyToCapture ? .green : .orange)
            }

            Spacer()
        }
    }

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("SETUP")

            readinessRow(
                title: "Screen Recording",
                isReady: appState.setupSummary.screenRecordingAuthorized,
                detail: appState.setupSummary.screenRecordingDetail,
                actionTitle: appState.setupSummary.screenRecordingAuthorized ? nil : "Open Settings",
                action: openScreenRecordingSettings
            )

            readinessRow(
                title: "Captures folder",
                isReady: appState.setupSummary.storageStatus.isReady,
                detail: appState.setupSummary.storageStatus.detail,
                actionTitle: "Open Folder",
                action: openCapturesFolder
            )

            readinessRow(
                title: "Ready to capture",
                isReady: appState.setupSummary.isReadyToCapture,
                detail: appState.setupSummary.isReadyToCapture
                    ? "The hotkey can open the native region capture UI."
                    : "Finish the setup items above before capturing.",
                actionTitle: nil,
                action: {}
            )
        }
    }

    private func issueSection(_ issue: UserFacingIssue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Label(issue.title, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                Spacer()
                Button("Dismiss") {
                    dismissIssue()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
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
                .fill(Color(nsColor: NSColor.windowBackgroundColor))
        )
    }

    private var recentCapturesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("RECENT CAPTURES")

            if appState.recentCaptures.isEmpty {
                Text("No captures yet. Use the hotkey or Capture now to create your first packaged screenshot.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(appState.recentCaptures, id: \.id) { record in
                    Button {
                        copyCapturePrompt(for: record)
                    } label: {
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
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var utilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("ACTIONS")

            Button {
                startCapture()
            } label: {
                Label(appState.isCaptureInProgress ? "Capturing..." : "Capture now", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.plain)
            .disabled(appState.isCaptureInProgress)

            Button {
                openPromptSettings()
            } label: {
                Label("Prompt settings", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.plain)

            Button {
                openCapturesFolder()
            } label: {
                Label("Open captures folder", systemImage: "folder")
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 12))
    }

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("HOTKEY")

            HStack {
                Text("Change hotkey")
                    .font(.system(size: 12))
                Spacer()
                KeyboardShortcuts.Recorder(for: .captureScreen)
            }

            Text("The hotkey uses macOS’s native region selection UI.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
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
        title: String,
        isReady: Bool,
        detail: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: isReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isReady ? .green : .orange)

                Spacer()

                if let actionTitle {
                    Button(actionTitle) {
                        action()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                }
            }

            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: NSColor.windowBackgroundColor))
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private func displaySlug(for slug: String) -> String {
        guard slug.count > 25 else { return slug }
        return String(slug.prefix(25)) + "..."
    }
}
