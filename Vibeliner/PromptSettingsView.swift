import AppKit
import KeyboardShortcuts
import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case about
    case hotkey
    case promptSettings
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .about:
            "About vibeliner"
        case .hotkey:
            "Hotkey"
        case .promptSettings:
            "Prompt Settings"
        case .general:
            "General"
        }
    }
}

struct PromptSettingsView: View {
    @State private var selectedTab: SettingsTab
    @State private var preambleSingle: String
    @State private var preambleBatch: String
    @State private var currentSaveDir: String

    private let defaults = VibelinerConfig()
    private let openCapturesFolder: () -> Void
    private let pickCapturesFolder: () -> Bool
    private let onClose: () -> Void

    init(
        initialTab: SettingsTab,
        openCapturesFolder: @escaping () -> Void,
        pickCapturesFolder: @escaping () -> Bool,
        onClose: @escaping () -> Void
    ) {
        let config = Config.shared
        _selectedTab = State(initialValue: initialTab)
        _preambleSingle = State(initialValue: config.preambleSingle)
        _preambleBatch = State(initialValue: config.preambleBatch)
        _currentSaveDir = State(initialValue: config.config.saveDir)
        self.openCapturesFolder = openCapturesFolder
        self.pickCapturesFolder = pickCapturesFolder
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Picker("Settings section", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Group {
                switch selectedTab {
                case .about:
                    aboutTab
                case .hotkey:
                    hotkeyTab
                case .promptSettings:
                    promptSettingsTab
                case .general:
                    generalTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
            .background(contentContainerBackground)
        }
        .padding(16)
        .frame(width: 560, height: 460)
        .background(Color(nsColor: NSColor(calibratedWhite: 0.13, alpha: 1.0)))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("vibeliner")
                .font(.system(size: 15, weight: .bold))

            Spacer()

            Button("Done") {
                onClose()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
    }

    private var contentContainerBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(nsColor: NSColor(calibratedWhite: 0.16, alpha: 1.0)))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("About vibeliner")
                .font(.system(size: 15, weight: .bold))

            Text("Capture, annotate, and package screenshots for AI coding tools.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            aboutRow(label: "Version", value: appVersion)
            aboutRow(label: "Bundle ID", value: bundleIdentifier)
            aboutRow(label: "Current run copy", value: runCopyStatus)
            aboutRow(label: "Current app path", value: appBundlePath)
            if let expectedDistAppPath {
                aboutRow(label: "Recommended TCC app path", value: expectedDistAppPath)
            }
            aboutRow(label: "Capture folder", value: currentSaveDir)
            aboutRow(label: "Workflow", value: "Native macOS region capture, lightweight annotations, prompt export")

            Spacer()
        }
    }

    private var hotkeyTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hotkey")
                .font(.system(size: 15, weight: .bold))

            Text("Choose the shortcut that starts a region capture from anywhere.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            HStack {
                Text("Capture shortcut")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                KeyboardShortcuts.Recorder(for: .captureScreen)
            }

            Spacer()
        }
    }

    private var promptSettingsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Prompt Settings")
                        .font(.system(size: 15, weight: .bold))

                    tokenGuidance
                    preambleSection(
                        title: "Single capture preamble",
                        helper: PromptBuilder.singlePreambleGuidance,
                        text: $preambleSingle,
                        resetAction: { preambleSingle = defaults.preambleSingle }
                    )
                    preambleSection(
                        title: "Batch preamble",
                        helper: PromptBuilder.batchPreambleGuidance,
                        text: $preambleBatch,
                        resetAction: { preambleBatch = defaults.preambleBatch }
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                Button("Save") {
                    Config.shared.preambleSingle = preambleSingle
                    Config.shared.preambleBatch = preambleBatch
                    Config.shared.save()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("General")
                .font(.system(size: 15, weight: .bold))

            Text("General settings is the home for broader app preferences such as capture-folder controls and other non-prompt configuration.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Capture folder")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(currentSaveDir)
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button("Open Folder") {
                        openCapturesFolder()
                    }
                    .buttonStyle(.bordered)

                    Button("Choose Folder") {
                        if pickCapturesFolder() {
                            refreshSaveDir()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: NSColor(calibratedWhite: 0.18, alpha: 1.0)))
            )

            Spacer()
        }
    }

    private var tokenGuidance: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Screenshot path token")
                .font(.system(size: 12, weight: .bold))

            Text(PromptBuilder.screenshotPathToken)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: NSColor(calibratedWhite: 0.2, alpha: 1.0)))
                )

            Text(PromptBuilder.pathGuidance)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func aboutRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func preambleSection(
        title: String,
        helper: String,
        text: Binding<String>,
        resetAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Button("Insert token") {
                    insertToken(into: text)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.blue)
                Button("Reset") {
                    resetAction()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.blue)
            }

            TextEditor(text: text)
                .font(.system(size: 11, design: .monospaced))
                .scrollContentBackground(.hidden)
                .foregroundStyle(.white)
                .frame(minHeight: 90)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: NSColor(calibratedWhite: 0.18, alpha: 1.0)))
                )

            Text(helper)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func insertToken(into text: Binding<String>) {
        if text.wrappedValue.contains(PromptBuilder.screenshotPathToken) {
            return
        }

        if text.wrappedValue.isEmpty {
            text.wrappedValue = PromptBuilder.screenshotPathToken
        } else {
            text.wrappedValue += " \(PromptBuilder.screenshotPathToken)"
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let shortVersion = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = info?["CFBundleVersion"] as? String ?? "1"
        return "\(shortVersion) (\(buildNumber))"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unknown"
    }

    private var appBundlePath: String {
        Bundle.main.bundleURL.standardizedFileURL.path
    }

    private var expectedDistAppPath: String? {
        guard
            let sourceRoot = Bundle.main.object(forInfoDictionaryKey: "VBLSourceRoot") as? String,
            !sourceRoot.isEmpty
        else {
            return nil
        }

        return URL(fileURLWithPath: sourceRoot)
            .appendingPathComponent("dist/Vibeliner.app")
            .standardizedFileURL
            .path
    }

    private var runCopyStatus: String {
        if let expectedDistAppPath, appBundlePath == expectedDistAppPath {
            return "Running the repo-local dist app. Use this copy for the most stable Screen Recording/TCC testing."
        }

        if appBundlePath.contains("/DerivedData/") {
            return "Running the Xcode DerivedData app. Screen Recording approval for dist/Vibeliner.app will not apply to this copy."
        }

        return "Running a non-dist app copy. Make sure macOS Screen Recording approval was granted to this exact path."
    }

    private func refreshSaveDir() {
        currentSaveDir = Config.shared.config.saveDir
    }
}

enum PromptSettingsPanelPresenter {
    private final class CloseObserver: NSObject, NSWindowDelegate {
        let onClose: () -> Void

        init(onClose: @escaping () -> Void) {
            self.onClose = onClose
        }

        func windowWillClose(_ notification: Notification) {
            onClose()
        }
    }

    private static var controller: NSWindowController?
    private static var closeObserver: CloseObserver?

    static func show(
        initialTab: SettingsTab,
        openCapturesFolder: @escaping () -> Void,
        pickCapturesFolder: @escaping () -> Bool,
        onClose: @escaping () -> Void
    ) {
        Config.shared.reload()
        controller?.close()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 460),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = initialTab.title
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.center()

        let closeObserver = CloseObserver {
            Self.controller = nil
            Self.closeObserver = nil
            onClose()
        }

        let controller = NSWindowController(window: panel)
        panel.delegate = closeObserver
        panel.contentView = NSHostingView(
            rootView: PromptSettingsView(
                initialTab: initialTab,
                openCapturesFolder: openCapturesFolder,
                pickCapturesFolder: pickCapturesFolder
            ) {
                controller.close()
            }
        )

        Self.closeObserver = closeObserver
        Self.controller = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
