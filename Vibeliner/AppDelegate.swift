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
        closeMenuPanel()
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

    private var isMenuVisible: Bool {
        menuPanel?.isVisible == true
    }

    private func ensureMenuPanel() -> MenuPanel {
        if let menuPanel {
            return menuPanel
        }

        let panel = MenuPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 420),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.transient, .moveToActiveSpace, .ignoresCycle]
        panel.animationBehavior = .utilityWindow

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
    }

    private func closeMenuPanel() {
        menuPanel?.orderOut(nil)
        removeMenuDismissMonitors()
    }

    private func updateMenuPanelSize(_ panel: MenuPanel) {
        popoverController.view.layoutSubtreeIfNeeded()
        let fittingSize = popoverController.view.fittingSize
        panel.setContentSize(NSSize(width: fittingSize.width, height: fittingSize.height))
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
            x: buttonFrameOnScreen.maxX - panelSize.width,
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

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.closeMenuPanel()
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

        guard
            event.type == .leftMouseDown || event.type == .rightMouseDown || event.type == .otherMouseDown,
            let eventWindow = event.window,
            eventWindow !== menuPanel
        else {
            return
        }

        closeMenuPanel()
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
