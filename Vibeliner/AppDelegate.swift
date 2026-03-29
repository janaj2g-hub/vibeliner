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
}

extension UserFacingIssue {
    var isScreenRecordingRelated: Bool {
        showsScreenRecordingSettingsAction || title.localizedCaseInsensitiveContains("screen recording")
    }
}

enum ScreenRecordingPermissionState {
    case authorized
    case notGranted

    var isAuthorized: Bool {
        self == .authorized
    }

    var setupDetail: String {
        switch self {
        case .authorized:
            return "Appears enabled."
        case .notGranted:
            return "Grant access, or enable it in System Settings."
        }
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

struct AppSetupSummary {
    let screenRecordingState: ScreenRecordingPermissionState
    let storageStatus: CaptureStore.StorageStatus

    var screenRecordingAuthorized: Bool {
        screenRecordingState.isAuthorized
    }

    var screenRecordingDetail: String {
        screenRecordingState.setupDetail
    }

    var isReadyToCapture: Bool {
        storageStatus.isReady
    }

    var setupHeading: String {
        storageStatus.isReady ? "Finish setup" : "Setup required"
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

    func refresh(autoRepairStorage: Bool, screenRecordingState: ScreenRecordingPermissionState? = nil) {
        let storageStatus = CaptureStore.shared.prepareSaveDirectory(autoRepair: autoRepairStorage)
        setupSummary = AppState.makeSetupSummary(
            storageStatus: storageStatus,
            screenRecordingState: screenRecordingState
        )
        recentCaptures = Array(CaptureStore.shared.list().prefix(5))
    }

    func presentIssue(_ issue: UserFacingIssue) {
        lastIssue = issue
    }

    func clearIssue() {
        lastIssue = nil
    }

    private static func makeSetupSummary(
        storageStatus: CaptureStore.StorageStatus,
        screenRecordingState: ScreenRecordingPermissionState? = nil
    ) -> AppSetupSummary {
        return AppSetupSummary(
            screenRecordingState: screenRecordingState ?? ScreenRecordingPermissionState.current(),
            storageStatus: storageStatus
        )
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private final class MenuPanel: NSPanel {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { false }
    }

    private var statusItem: NSStatusItem!
    private let appState = AppState()
    private var editorController: EditorWindowController?
    private var activeInteractiveSessions = 0
    private var menuPanel: MenuPanel?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var pendingScreenRecordingRemediationRefresh = false
    private var requiresScreenRecordingRelaunch = false

    private lazy var popoverController = NSHostingController(
        rootView: MenuBarPopover(
            appState: appState,
            startCapture: { [weak self] in
                self?.startCapture()
            },
            onCopyCapturePrompt: { [weak self] record in
                self?.copyCapturePrompt(for: record) ?? false
            },
            openGeneralSettings: { [weak self] in
                self?.showSettings(for: .general)
            },
            openHotkeySettings: { [weak self] in
                self?.showSettings(for: .hotkey)
            },
            openPromptSettings: { [weak self] in
                self?.showSettings(for: .promptSettings)
            },
            openAboutSettings: { [weak self] in
                self?.showSettings(for: .about)
            },
            openCapturesFolder: { [weak self] in
                self?.openCapturesFolder()
            },
            requestScreenRecordingAccess: { [weak self] in
                self?.requestScreenRecordingAccess()
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

    func applicationDidResignActive(_ notification: Notification) {
        closeMenuPanel()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if pendingScreenRecordingRemediationRefresh {
            pendingScreenRecordingRemediationRefresh = false
            let refreshedState = ScreenRecordingPermissionState.current()
            appState.refresh(
                autoRepairStorage: true,
                screenRecordingState: refreshedState
            )
            if refreshedState.isAuthorized {
                handleAuthorizedScreenRecordingGrant()
            }
            return
        }

        appState.refresh(autoRepairStorage: true)
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }

        appState.refresh(autoRepairStorage: true)

        if isMenuVisible {
            closeMenuPanel()
            return
        }

        showMenuPanel(relativeTo: button)
    }

    func startCapture() {
        if let existingWindow = editorController?.window, existingWindow.isVisible {
            activateInteractiveApp()
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        guard !appState.isCaptureInProgress else { return }

        closeMenuPanel()

        guard ensureReadyForCapture() else {
            return
        }

        restoreAccessoryModeIfIdle()
        appState.isCaptureInProgress = true

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
        if #available(macOS 13.0, *) {
            popoverController.sizingOptions = [.preferredContentSize]
        }
        _ = ensureMenuPanel()
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

        let runtimeIdentity = AppRuntimeIdentity.current()
        if !runtimeIdentity.isSupportedRuntimeCopy {
            appState.refresh(autoRepairStorage: true)
            presentIssue(unsupportedRuntimeIssue(runtimeIdentity))
            return false
        }

        let liveScreenRecordingState = ScreenRecordingPermissionState.current()
        appState.refresh(
            autoRepairStorage: true,
            screenRecordingState: liveScreenRecordingState
        )

        guard liveScreenRecordingState.isAuthorized else {
            presentIssue(ScreenRecordingPermissionState.notGranted.issue, offersScreenRecordingShortcut: true)
            return false
        }

        guard !requiresScreenRecordingRelaunch else {
            presentIssue(screenRecordingRelaunchIssue())
            return false
        }

        appState.clearIssue()
        return true
    }

    private func performCapture() async {
        let outcome = await CaptureManager.shared.captureRegion()

        appState.isCaptureInProgress = false

        switch outcome {
        case .success(let image):
            appState.clearIssue()
            appState.refresh(
                autoRepairStorage: true,
                screenRecordingState: .authorized
            )
            beginInteractiveSession()
            presentEditor(with: image)
        case .cancelled:
            appState.refresh(autoRepairStorage: true)
            restoreAccessoryModeIfIdle()
        case .failure(let failure):
            let issue: UserFacingIssue
            let offersScreenRecordingShortcut: Bool
            if let permissionState = failure.screenRecordingState {
                let baseIssue = permissionState.issue
                issue = UserFacingIssue(
                    title: baseIssue.title,
                    message: baseIssue.message,
                    recoverySuggestion: baseIssue.recoverySuggestion,
                    technicalDetails: failure.technicalDetails,
                    showsScreenRecordingSettingsAction: baseIssue.showsScreenRecordingSettingsAction
                )
                offersScreenRecordingShortcut = permissionState.offersOpenSettingsShortcut
            } else {
                issue = UserFacingIssue(
                    title: failure.title,
                    message: failure.message,
                    recoverySuggestion: failure.recoverySuggestion,
                    technicalDetails: failure.technicalDetails
                )
                offersScreenRecordingShortcut = failure.title.contains("Screen Recording") || failure.title.contains("macOS")
            }
            presentIssue(issue, offersScreenRecordingShortcut: offersScreenRecordingShortcut)
            appState.refresh(autoRepairStorage: true)
            restoreAccessoryModeIfIdle()
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

    private func showSettings(for tab: SettingsTab) {
        closeMenuPanel()
        beginInteractiveSession()

        PromptSettingsPanelPresenter.show(
            initialTab: tab,
            openCapturesFolder: { [weak self] in self?.openCapturesFolder() },
            pickCapturesFolder: { [weak self] in self?.pickCapturesFolder() ?? false }
        ) { [weak self] in
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

    private func pickCapturesFolder() -> Bool {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = Config.shared.saveDirectoryURL
        panel.prompt = "Choose Folder"
        panel.message = "Choose where new vibeliner captures should be saved."

        guard panel.runModal() == .OK, let selectedURL = panel.url?.standardizedFileURL else {
            return false
        }

        let storageStatus = CaptureStore.shared.prepareSaveDirectory(at: selectedURL, autoRepair: true)
        guard storageStatus.isReady else {
            let issue = UserFacingIssue(
                title: "Could not use capture folder",
                message: storageStatus.detail,
                recoverySuggestion: storageStatus.remediation,
                technicalDetails: nil
            )
            presentIssue(issue)
            return false
        }

        Config.shared.updateSaveDirectory(to: selectedURL.path)
        appState.clearIssue()
        appState.refresh(autoRepairStorage: true)
        return true
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
        activateInteractiveApp()

        appState.refresh(autoRepairStorage: true)
        pendingScreenRecordingRemediationRefresh = true

        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            pendingScreenRecordingRemediationRefresh = false
            return
        }

        guard NSWorkspace.shared.open(url) else {
            pendingScreenRecordingRemediationRefresh = false
            return
        }
    }

    private func requestScreenRecordingAccess() {
        activateInteractiveApp()

        let isAuthorized = CGRequestScreenCaptureAccess()
        let refreshedState: ScreenRecordingPermissionState = isAuthorized ? .authorized : .notGranted
        appState.refresh(
            autoRepairStorage: true,
            screenRecordingState: refreshedState
        )

        if isAuthorized {
            handleAuthorizedScreenRecordingGrant()
            return
        }

        presentIssue(
            ScreenRecordingPermissionState.notGranted.issue,
            offersScreenRecordingShortcut: true
        )
    }

    private var isMenuVisible: Bool {
        menuPanel?.isVisible == true
    }

    private func ensureMenuPanel() -> MenuPanel {
        if let menuPanel {
            return menuPanel
        }

        let panel = MenuPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.transient, .moveToActiveSpace, .ignoresCycle]
        panel.animationBehavior = .utilityWindow
        panel.delegate = self

        let rootView = NSView()
        rootView.translatesAutoresizingMaskIntoConstraints = false

        let effectView = NSVisualEffectView()
        effectView.material = .menu
        effectView.blendingMode = .withinWindow
        effectView.state = .active
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 16
        effectView.layer?.cornerCurve = .continuous
        effectView.layer?.masksToBounds = true

        let hostedView = popoverController.view
        hostedView.translatesAutoresizingMaskIntoConstraints = false

        panel.contentView = rootView
        rootView.addSubview(effectView)
        effectView.addSubview(hostedView)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: rootView.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),

            hostedView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: effectView.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
        ])

        menuPanel = panel
        return panel
    }

    private func showMenuPanel(relativeTo button: NSStatusBarButton) {
        let panel = ensureMenuPanel()
        updateMenuPanelSize(panel)
        positionMenuPanel(panel, relativeTo: button)
        installMenuDismissMonitors()
        panel.orderFrontRegardless()
        panel.makeFirstResponder(nil)
    }

    private func closeMenuPanel() {
        menuPanel?.orderOut(nil)
        removeMenuDismissMonitors()
    }

    private func updateMenuPanelSize(_ panel: MenuPanel) {
        let preferredSize = popoverController.preferredContentSize
        let measuredSize: NSSize

        if preferredSize.width > 0, preferredSize.height > 0 {
            measuredSize = preferredSize
        } else {
            measuredSize = popoverController.view.fittingSize
        }

        panel.setContentSize(NSSize(width: measuredSize.width, height: measuredSize.height))
    }

    private func positionMenuPanel(_ panel: MenuPanel, relativeTo button: NSStatusBarButton) {
        guard
            let window = button.window,
            let screen = window.screen ?? NSScreen.main
        else {
            return
        }

        let buttonFrameInWindow = button.convert(button.bounds, to: nil)
        let buttonFrameOnScreen = window.convertToScreen(buttonFrameInWindow)
        let panelSize = panel.frame.size
        let visibleFrame = screen.visibleFrame.insetBy(dx: 8, dy: 8)

        var origin = NSPoint(
            x: buttonFrameOnScreen.minX,
            y: buttonFrameOnScreen.minY - panelSize.height - 6
        )

        origin.x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - panelSize.width)
        origin.y = max(visibleFrame.minY, origin.y)

        panel.setFrameOrigin(origin)
    }

    private func installMenuDismissMonitors() {
        guard localEventMonitor == nil, globalEventMonitor == nil else {
            return
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown]) { [weak self] event in
            self?.handleMenuEvent(event)
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleGlobalMenuEvent(event)
            }
        }
    }

    private func removeMenuDismissMonitors() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }

    private func handleMenuEvent(_ event: NSEvent) {
        guard isMenuVisible else {
            return
        }

        if event.type == .keyDown, event.keyCode == 53 {
            closeMenuPanel()
            return
        }

        guard event.type == .leftMouseDown || event.type == .rightMouseDown || event.type == .otherMouseDown else {
            return
        }

        if shouldDismissMenu(forScreenLocation: currentScreenLocation(for: event)) {
            closeMenuPanel()
        }
    }

    private func handleGlobalMenuEvent(_ event: NSEvent) {
        guard isMenuVisible else {
            return
        }

        if shouldDismissMenu(forScreenLocation: currentScreenLocation(for: event)) {
            closeMenuPanel()
        }
    }

    private func currentScreenLocation(for event: NSEvent) -> NSPoint {
        if event.window == nil {
            return event.locationInWindow
        }

        return NSEvent.mouseLocation
    }

    private func shouldDismissMenu(forScreenLocation screenLocation: NSPoint) -> Bool {
        guard let panel = menuPanel else {
            return false
        }

        return !panel.frame.contains(screenLocation)
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

        restoreAccessoryModeIfIdle()
    }

    private func activateInteractiveApp() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    private func restoreAccessoryModeIfIdle() {
        guard activeInteractiveSessions == 0 else {
            return
        }

        if NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func screenRecordingRelaunchIssue() -> UserFacingIssue {
        let runtimeIdentity = AppRuntimeIdentity.current()
        return UserFacingIssue(
            title: "Relaunch required before capture",
            message: "Screen Recording permission changed, but this running process cannot safely resume capture until it restarts.",
            recoverySuggestion: "Relaunch into the canonical app copy before trying capture again. \(runtimeIdentity.canonicalLaunchGuidance)",
            technicalDetails: nil
        )
    }

    private func unsupportedRuntimeIssue(_ runtimeIdentity: AppRuntimeIdentity) -> UserFacingIssue {
        let message = "This app copy is not the supported screenshot-capture runtime."
        let recoverySuggestion = "\(runtimeIdentity.canonicalLaunchGuidance) Current app path: \(runtimeIdentity.appBundlePath)"

        return UserFacingIssue(
            title: "Launch the canonical app copy",
            message: message,
            recoverySuggestion: recoverySuggestion,
            technicalDetails: "runCopy=\(runtimeIdentity.runCopyLabel); appPath=\(runtimeIdentity.appBundlePath); expectedDistPath=\(runtimeIdentity.expectedDistAppPath ?? "nil")"
        )
    }

    private func handleAuthorizedScreenRecordingGrant() {
        requiresScreenRecordingRelaunch = true

        if relaunchIntoCanonicalAppIfPossible() {
            return
        }

        presentIssue(screenRecordingRelaunchIssue())
    }

    @discardableResult
    private func relaunchIntoCanonicalAppIfPossible() -> Bool {
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

    private func presentIssue(_ issue: UserFacingIssue, offersScreenRecordingShortcut: Bool = false) {
        appState.presentIssue(issue)
        guard !offersScreenRecordingShortcut else {
            return
        }
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
        if offersScreenRecordingShortcut, response == .alertSecondButtonReturn {
            openScreenRecordingSettings()
        }

        if shouldRestoreAccessoryMode {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
