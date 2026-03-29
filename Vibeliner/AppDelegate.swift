import AppKit
import CoreGraphics
import KeyboardShortcuts
import SwiftUI

extension KeyboardShortcuts.Name {
    static let captureScreen = Self("captureScreen")
}

struct UserFacingIssue: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoverySuggestion: String?
    let technicalDetails: String?
}

struct AppSetupSummary {
    let screenRecordingAuthorized: Bool
    let screenRecordingDetail: String
    let storageStatus: CaptureStore.StorageStatus

    var isReadyToCapture: Bool {
        screenRecordingAuthorized && storageStatus.isReady
    }

    var readinessTitle: String {
        isReadyToCapture ? "Ready to capture" : "Setup required"
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var setupSummary: AppSetupSummary
    @Published private(set) var recentCaptures: [CaptureRecord] = []
    @Published var isCaptureInProgress = false
    @Published var lastIssue: UserFacingIssue?

    init() {
        let storageStatus = CaptureStore.shared.prepareSaveDirectory(autoRepair: true)
        setupSummary = AppState.makeSetupSummary(storageStatus: storageStatus)
        refresh(autoRepairStorage: true)
    }

    func refresh(autoRepairStorage: Bool) {
        let storageStatus = CaptureStore.shared.prepareSaveDirectory(autoRepair: autoRepairStorage)
        setupSummary = AppState.makeSetupSummary(storageStatus: storageStatus)
        recentCaptures = Array(CaptureStore.shared.list().prefix(5))
    }

    func presentIssue(_ issue: UserFacingIssue) {
        lastIssue = issue
    }

    func clearIssue() {
        lastIssue = nil
    }

    private static func makeSetupSummary(storageStatus: CaptureStore.StorageStatus) -> AppSetupSummary {
        let screenRecordingAuthorized = CGPreflightScreenCaptureAccess()
        let screenRecordingDetail = screenRecordingAuthorized
            ? "macOS Screen Recording access is enabled."
            : "Enable Screen Recording for Vibeliner in System Settings, then quit and reopen the app."

        return AppSetupSummary(
            screenRecordingAuthorized: screenRecordingAuthorized,
            screenRecordingDetail: screenRecordingDetail,
            storageStatus: storageStatus
        )
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let appState = AppState()
    private var editorController: EditorWindowController?
    private var activeInteractiveSessions = 0

    private lazy var popoverController = NSHostingController(
        rootView: MenuBarPopover(
            appState: appState,
            startCapture: { [weak self] in
                self?.startCapture()
            },
            onCopyCapturePrompt: { [weak self] record in
                self?.copyCapturePrompt(for: record) ?? false
            },
            openPromptSettings: { [weak self] in
                self?.showPromptSettings()
            },
            openCapturesFolder: { [weak self] in
                self?.openCapturesFolder()
            },
            openScreenRecordingSettings: { [weak self] in
                self?.openScreenRecordingSettings()
            },
            dismissIssue: { [weak self] in
                self?.appState.clearIssue()
            }
        )
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        configureStatusItem()
        configurePopover()
        configureDefaultHotkeyIfNeeded()
        registerHotkeyHandler()

        appState.refresh(autoRepairStorage: true)
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        appState.refresh(autoRepairStorage: true)

        if popover.isShown {
            popover.performClose(nil)
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func startCapture() {
        if let existingWindow = editorController?.window, existingWindow.isVisible {
            activateInteractiveApp()
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        guard !appState.isCaptureInProgress else { return }

        popover.performClose(nil)
        appState.refresh(autoRepairStorage: true)

        guard ensureReadyForCapture() else {
            return
        }

        appState.isCaptureInProgress = true
        beginInteractiveSession()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }

            Task { @MainActor [weak self] in
                await self?.performCapture()
            }
        }
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(systemSymbolName: "circle.dashed", accessibilityDescription: "Vibeliner")
        button.image?.isTemplate = true
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func configurePopover() {
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.behavior = .transient
        popover.contentViewController = popoverController
    }

    private func configureDefaultHotkeyIfNeeded() {
        guard KeyboardShortcuts.getShortcut(for: .captureScreen) == nil else {
            return
        }

        KeyboardShortcuts.setShortcut(.init(.six, modifiers: [.command, .shift]), for: .captureScreen)
    }

    private func registerHotkeyHandler() {
        KeyboardShortcuts.onKeyUp(for: .captureScreen) { [weak self] in
            Task { @MainActor [weak self] in
                self?.startCapture()
            }
        }
    }

    private func ensureReadyForCapture() -> Bool {
        let storageStatus = CaptureStore.shared.prepareSaveDirectory(autoRepair: true)
        if !storageStatus.isReady {
            let issue = UserFacingIssue(
                title: "Captures folder unavailable",
                message: storageStatus.detail,
                recoverySuggestion: storageStatus.remediation,
                technicalDetails: nil
            )
            presentIssue(issue)
            return false
        }

        if CGPreflightScreenCaptureAccess() {
            return true
        }

        activateInteractiveApp()
        _ = CGRequestScreenCaptureAccess()
        appState.refresh(autoRepairStorage: true)

        guard CGPreflightScreenCaptureAccess() else {
            let issue = UserFacingIssue(
                title: "Screen Recording permission needed",
                message: "Vibeliner cannot start a region capture until macOS allows it to record the screen.",
                recoverySuggestion: "Enable Vibeliner in System Settings > Privacy & Security > Screen Recording, then quit and reopen Vibeliner.",
                technicalDetails: nil
            )
            presentIssue(issue, offersScreenRecordingShortcut: true)
            return false
        }

        return true
    }

    private func performCapture() async {
        let outcome = await CaptureManager.shared.captureRegion()

        appState.isCaptureInProgress = false

        switch outcome {
        case .success(let image):
            appState.clearIssue()
            presentEditor(with: image)
        case .cancelled:
            endInteractiveSession()
            appState.refresh(autoRepairStorage: true)
        case .failure(let failure):
            endInteractiveSession()

            let issue = UserFacingIssue(
                title: failure.title,
                message: failure.message,
                recoverySuggestion: failure.recoverySuggestion,
                technicalDetails: failure.technicalDetails
            )
            let offersScreenRecordingShortcut = failure.title.contains("Screen Recording") || failure.title.contains("macOS")
            presentIssue(issue, offersScreenRecordingShortcut: offersScreenRecordingShortcut)
            appState.refresh(autoRepairStorage: true)
        }
    }

    private func presentEditor(with image: NSImage) {
        activateInteractiveApp()

        let controller = EditorWindowController(image: image)
        controller.onCaptureSaved = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.appState.refresh(autoRepairStorage: true)
                self?.appState.clearIssue()
            }
        }
        controller.onError = { [weak self] issue in
            Task { @MainActor [weak self] in
                self?.presentIssue(issue)
            }
        }
        controller.onClose = { [weak self] in
            Task { @MainActor [weak self] in
                self?.editorController = nil
                self?.appState.refresh(autoRepairStorage: true)
                self?.endInteractiveSession()
            }
        }

        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        editorController = controller
    }

    private func showPromptSettings() {
        popover.performClose(nil)
        beginInteractiveSession()

        PromptSettingsPanelPresenter.show { [weak self] in
            Task { @MainActor [weak self] in
                self?.appState.refresh(autoRepairStorage: true)
                self?.endInteractiveSession()
            }
        }
    }

    private func openCapturesFolder() {
        do {
            try CaptureStore.shared.openCapturesFolder()
            appState.clearIssue()
            appState.refresh(autoRepairStorage: true)
        } catch {
            let issue = UserFacingIssue(
                title: "Could not open captures folder",
                message: error.localizedDescription,
                recoverySuggestion: "Fix the save_dir setting in \(Config.shared.configFilePath), then try again.",
                technicalDetails: nil
            )
            presentIssue(issue)
        }
    }

    private func copyCapturePrompt(for record: CaptureRecord) -> Bool {
        do {
            let promptText = try CaptureStore.shared.clipboardPrompt(for: record)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(promptText, forType: .string)
            appState.clearIssue()
            appState.refresh(autoRepairStorage: true)
            return true
        } catch {
            let issue = UserFacingIssue(
                title: "Could not copy capture",
                message: "Vibeliner could not load the saved prompt for \(record.id).",
                recoverySuggestion: "Open the capture folder and confirm prompt.md and screenshot.png still exist.",
                technicalDetails: error.localizedDescription
            )
            presentIssue(issue)
            return false
        }
    }

    private func openScreenRecordingSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func beginInteractiveSession() {
        activeInteractiveSessions += 1
        if activeInteractiveSessions == 1 {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func endInteractiveSession() {
        activeInteractiveSessions = max(0, activeInteractiveSessions - 1)

        if activeInteractiveSessions == 0 {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func activateInteractiveApp() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    private func presentIssue(_ issue: UserFacingIssue, offersScreenRecordingShortcut: Bool = false) {
        appState.presentIssue(issue)
        showAlert(for: issue, offersScreenRecordingShortcut: offersScreenRecordingShortcut)
    }

    private func showAlert(for issue: UserFacingIssue, offersScreenRecordingShortcut: Bool) {
        let shouldRestoreAccessoryMode = activeInteractiveSessions == 0
        activateInteractiveApp()

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = issue.title

        var details: [String] = [issue.message]
        if let recoverySuggestion = issue.recoverySuggestion, !recoverySuggestion.isEmpty {
            details.append(recoverySuggestion)
        }
        if let technicalDetails = issue.technicalDetails, !technicalDetails.isEmpty {
            details.append("Details: \(technicalDetails)")
        }
        alert.informativeText = details.joined(separator: "\n\n")

        alert.addButton(withTitle: "OK")
        if offersScreenRecordingShortcut {
            alert.addButton(withTitle: "Open Screen Recording Settings")
        }

        let response = alert.runModal()
        if offersScreenRecordingShortcut, response == .alertSecondButtonReturn {
            openScreenRecordingSettings()
        }

        if shouldRestoreAccessoryMode {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
