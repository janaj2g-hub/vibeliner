import AppKit
import KeyboardShortcuts
import SwiftUI

struct MenuBarPopover: View {
    @ObservedObject var appState: AppState

    let startCapture: () -> Void
    let onCopyCapturePrompt: (CaptureRecord) -> Bool
    let openPromptSettings: () -> Void
    let openAboutSettings: () -> Void
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

            Button {
                openAboutSettings()
            } label: {
                menuRowLabel("About vibeliner", systemImage: "info.circle")
            }
            .buttonStyle(.plain)
            .padding(.bottom, 10)

            Button("Quit vibeliner") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .padding(.top, 10)
        }
        .padding(16)
        .frame(width: 352)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Setup")

            VStack(alignment: .leading, spacing: 0) {
                Text("Setup required")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                    .padding(.bottom, 12)

                readinessRow(
                    symbol: appState.setupSummary.screenRecordingAuthorized ? "checkmark" : "1",
                    title: "Screen Recording permission",
                    isReady: appState.setupSummary.screenRecordingAuthorized,
                    detail: appState.setupSummary.screenRecordingDetail,
                    actionTitle: appState.setupSummary.screenRecordingAuthorized ? nil : "Open Settings",
                    action: openScreenRecordingSettings
                )

                sectionDivider
                    .padding(.vertical, 10)

                readinessRow(
                    symbol: appState.setupSummary.storageStatus.isReady ? "checkmark" : "2",
                    title: "Captures folder",
                    isReady: appState.setupSummary.storageStatus.isReady,
                    detail: appState.setupSummary.storageStatus.detail,
                    actionTitle: "Open Folder",
                    action: openCapturesFolder
                )
            }
            .padding(14)
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
            .padding(.vertical, 14)
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
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.18), lineWidth: 1)
        )
    }

    private var recentCapturesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Recent Captures")

            if appState.recentCaptures.isEmpty {
                Text("no captures yet")
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
            sectionTitle("Actions")

            Button {
                startCapture()
            } label: {
                menuRowLabel(appState.isCaptureInProgress ? "Capturing..." : "Capture now", systemImage: "camera.viewfinder")
            }
            .buttonStyle(.plain)
            .disabled(appState.isCaptureInProgress)

            Button {
                openPromptSettings()
            } label: {
                menuRowLabel("Prompt settings", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.plain)

            Button {
                openCapturesFolder()
            } label: {
                menuRowLabel("Open captures folder", systemImage: "folder")
            }
            .buttonStyle(.plain)
        }
    }

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Hotkey")

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
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private func displaySlug(for slug: String) -> String {
        guard slug.count > 25 else { return slug }
        return String(slug.prefix(25)) + "..."
    }
}
