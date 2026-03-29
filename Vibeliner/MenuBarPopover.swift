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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            setupSection

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
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Vibeliner")
                    .font(.system(size: 14, weight: .bold))
            }

            Spacer()

            Button(appState.isCaptureInProgress ? "Capturing..." : "Capture now") {
                startCapture()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(appState.isCaptureInProgress)
        }
    }

    private var setupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("SETUP")

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(appState.setupSummary.isReadyToCapture ? "Setup complete" : "Setup required")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(appState.setupSummary.isReadyToCapture ? .green : .orange)
                    Spacer()
                }

                setupStep(
                    number: 1,
                    title: "Screen Recording permission",
                    isComplete: appState.setupSummary.screenRecordingAuthorized,
                    detail: appState.setupSummary.screenRecordingDetail,
                    actionTitle: appState.setupSummary.screenRecordingAuthorized ? nil : "Open Settings",
                    action: openScreenRecordingSettings
                )

                setupStep(
                    number: 2,
                    title: "Captures folder",
                    isComplete: appState.setupSummary.storageStatus.isReady,
                    detail: appState.setupSummary.storageStatus.detail,
                    actionTitle: "Open Folder",
                    action: openCapturesFolder
                )
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: NSColor.windowBackgroundColor))
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

    private func setupStep(
        number: Int,
        title: String,
        isComplete: Bool,
        detail: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green.opacity(0.18) : Color.orange.opacity(0.22))
                    .frame(width: 24, height: 24)
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.green)
                } else {
                    Text("\(number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.orange)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    if let actionTitle, !isComplete {
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
        }
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
