import AppKit
import CoreGraphics
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureScreen = Self("captureScreen")
}

@MainActor
final class AppState {
    var isCaptureInProgress = false
    var lastIssue: UserFacingIssue?

    func refresh(autoRepairStorage: Bool) {
        _ = CaptureStore.shared.prepareSaveDirectory(autoRepair: autoRepairStorage)
    }

    func presentIssue(_ issue: UserFacingIssue) {
        lastIssue = issue
    }

    func clearIssue() {
        lastIssue = nil
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let dynamicItemTag = 9000

    private var statusItem: NSStatusItem!
    private let appState = AppState()
    private var editorController: EditorWindowController?
    private var activeInteractiveSessions = 0
    private var pendingScreenRecordingRemediationRefresh = false
    private var requiresScreenRecordingRelaunch = false
    private var recentCaptureRecords: [CaptureRecord] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        configureStatusItem()
        configureDefaultHotkeyIfNeeded()
        registerHotkeyHandler()

        appState.refresh(autoRepairStorage: true)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if pendingScreenRecordingRemediationRefresh {
            pendingScreenRecordingRemediationRefresh = false
            let refreshedState = ScreenRecordingPermissionState.current()
            appState.refresh(autoRepairStorage: true)
            if refreshedState.isAuthorized {
                handleAuthorizedScreenRecordingGrant()
            }
            return
        }

        appState.refresh(autoRepairStorage: true)
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        appState.refresh(autoRepairStorage: true)

        menu.items
            .filter { $0.tag == Self.dynamicItemTag }
            .forEach { menu.removeItem($0) }

        guard let firstSeparatorIndex = menu.items.firstIndex(where: { $0.isSeparatorItem }) else {
            return
        }

        var insertIndex = firstSeparatorIndex

        if !CGPreflightScreenCaptureAccess() {
            let statusItem = NSMenuItem(title: "Screen Recording: Not Granted", action: nil, keyEquivalent: "")
            statusItem.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Warning")
            statusItem.isEnabled = false
            statusItem.tag = Self.dynamicItemTag
            menu.insertItem(statusItem, at: insertIndex)
            insertIndex += 1

            let openSettingsItem = NSMenuItem(title: "Open System Settings...", action: #selector(openScreenRecordingSettingsAction), keyEquivalent: "")
            openSettingsItem.target = self
            openSettingsItem.tag = Self.dynamicItemTag
            menu.insertItem(openSettingsItem, at: insertIndex)
            insertIndex += 1

            let sep = NSMenuItem.separator()
            sep.tag = Self.dynamicItemTag
            menu.insertItem(sep, at: insertIndex)
            insertIndex += 1
        }

        let recentCapturesIndex = insertIndex + 1
        let recentItem = NSMenuItem(title: "Recent Captures", action: nil, keyEquivalent: "")
        recentItem.image = NSImage(systemSymbolName: "clock.arrow.circlepath", accessibilityDescription: "Recent")
        recentItem.tag = Self.dynamicItemTag

        let submenu = NSMenu()
        recentCaptureRecords = Array(CaptureStore.shared.list().prefix(5))

        if recentCaptureRecords.isEmpty {
            let emptyItem = NSMenuItem(title: "No recent captures", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            submenu.addItem(emptyItem)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            for (index, record) in recentCaptureRecords.enumerated() {
                let displaySlug = record.slug.count > 30 ? String(record.slug.prefix(30)) + "..." : record.slug
                let dateStr = formatter.string(from: record.created)
                let title = displaySlug.isEmpty ? dateStr : "\(displaySlug) — \(dateStr)"
                let captureItem = NSMenuItem(title: title, action: #selector(copyRecentCapture(_:)), keyEquivalent: "")
                captureItem.target = self
                captureItem.tag = index
                submenu.addItem(captureItem)
            }
        }

        recentItem.submenu = submenu
        menu.insertItem(recentItem, at: recentCapturesIndex)

        let recentSep = NSMenuItem.separator()
        recentSep.tag = Self.dynamicItemTag
        menu.insertItem(recentSep, at: recentCapturesIndex + 1)
    }

    @objc private func copyRecentCapture(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index >= 0, index < recentCaptureRecords.count else { return }
        copyCapturePrompt(for: recentCaptureRecords[index])
    }

    @objc private func openScreenRecordingSettingsAction() {
        activateInteractiveApp()
        pendingScreenRecordingRemediationRefresh = true
        PermissionCoordinator.openScreenRecordingSettings()
    }

    // MARK: - Status Item & Menu

    @objc func startCapture() {
        if let existingWindow = editorController?.window, existingWindow.isVisible {
            activateInteractiveApp()
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        guard !appState.isCaptureInProgress else { return }

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

        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let captureItem = NSMenuItem(title: "Capture Now", action: #selector(startCapture), keyEquivalent: "")
        captureItem.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Capture")
        captureItem.target = self
        menu.addItem(captureItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Preferences")
        prefsItem.target = self
        prefsItem.keyEquivalentModifierMask = .command
        menu.addItem(prefsItem)

        let aboutItem = NSMenuItem(title: "About Vibeliner", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Vibeliner", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)

        return menu
    }

    @objc private func openPreferences() {
        showSettings(for: .general)
    }

    @objc private func openAbout() {
        showSettings(for: .about)
    }

    // MARK: - Hotkey

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

    // MARK: - Capture

    private func ensureReadyForCapture() -> Bool {
        let storageStatus = CaptureStore.shared.prepareSaveDirectory(autoRepair: true)
        if !storageStatus.isReady {
            presentIssue(UserFacingIssue(
                title: "Captures folder unavailable",
                message: storageStatus.detail,
                recoverySuggestion: storageStatus.remediation,
                technicalDetails: nil
            ))
            return false
        }

        let runtimeIdentity = AppRuntimeIdentity.current()
        if !runtimeIdentity.isSupportedRuntimeCopy {
            appState.refresh(autoRepairStorage: true)
            presentIssue(PermissionCoordinator.unsupportedRuntimeIssue(runtimeIdentity))
            return false
        }

        appState.refresh(autoRepairStorage: true)

        guard !requiresScreenRecordingRelaunch else {
            presentIssue(PermissionCoordinator.screenRecordingRelaunchIssue())
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
            appState.refresh(autoRepairStorage: true)
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

    // MARK: - Editor

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

    // MARK: - Settings

    private func showSettings(for tab: SettingsTab) {
        beginInteractiveSession()

        SettingsPanelPresenter.show(
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
            presentIssue(UserFacingIssue(
                title: "Could not open captures folder",
                message: error.localizedDescription,
                recoverySuggestion: "Fix the save_dir setting in \(Config.shared.configFilePath), then try again.",
                technicalDetails: nil
            ))
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
            presentIssue(UserFacingIssue(
                title: "Could not use capture folder",
                message: storageStatus.detail,
                recoverySuggestion: storageStatus.remediation,
                technicalDetails: nil
            ))
            return false
        }

        Config.shared.updateSaveDirectory(to: selectedURL.path)
        appState.clearIssue()
        appState.refresh(autoRepairStorage: true)
        return true
    }

    func copyCapturePrompt(for record: CaptureRecord) -> Bool {
        do {
            let promptText = try CaptureStore.shared.clipboardPrompt(for: record)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(promptText, forType: .string)
            appState.clearIssue()
            appState.refresh(autoRepairStorage: true)
            return true
        } catch {
            presentIssue(UserFacingIssue(
                title: "Could not copy capture",
                message: "Vibeliner could not load the saved prompt for \(record.id).",
                recoverySuggestion: "Open the capture folder and confirm prompt.md and screenshot.png still exist.",
                technicalDetails: error.localizedDescription
            ))
            return false
        }
    }

    // MARK: - Activation Policy

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

    // MARK: - Issue Handling

    private func handleAuthorizedScreenRecordingGrant() {
        requiresScreenRecordingRelaunch = true

        if PermissionCoordinator.relaunchIntoCanonicalAppIfPossible() {
            return
        }

        presentIssue(PermissionCoordinator.screenRecordingRelaunchIssue())
    }

    private func presentIssue(_ issue: UserFacingIssue, offersScreenRecordingShortcut: Bool = false) {
        appState.presentIssue(issue)
        guard !offersScreenRecordingShortcut else {
            return
        }

        let shouldRestoreAccessoryMode = activeInteractiveSessions == 0
        activateInteractiveApp()

        let userWantsSettings = AlertPresenter.showAlert(for: issue, offersScreenRecordingShortcut: offersScreenRecordingShortcut)
        if userWantsSettings {
            pendingScreenRecordingRemediationRefresh = true
            PermissionCoordinator.openScreenRecordingSettings()
        }

        if shouldRestoreAccessoryMode {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
