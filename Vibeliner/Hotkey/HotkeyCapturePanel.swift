import AppKit

/// Reusable hotkey capture sheet that presents a modal panel for recording a new keyboard shortcut.
/// Used by both the Settings window and the Setup window.
///
/// Usage:
///   HotkeyCapturePanel.present(from: parentWindow) { newKeys in
///       // newKeys is the display parts like ["⌘", "⇧", "6"]
///       // HotkeyManager and ConfigManager are already updated
///   }
final class HotkeyCapturePanel {

    private var panel: NSPanel?
    private var monitor: Any?
    private weak var parentWindow: NSWindow?
    private var onComplete: (([String]) -> Void)?

    /// Present the hotkey capture sheet attached to the given parent window.
    /// `onComplete` is called with the new display parts after a successful capture.
    static func present(from parentWindow: NSWindow, onComplete: (([String]) -> Void)? = nil) {
        let instance = HotkeyCapturePanel()
        instance.show(from: parentWindow, onComplete: onComplete)
    }

    private func show(from parentWindow: NSWindow, onComplete: (([String]) -> Void)?) {
        self.parentWindow = parentWindow
        self.onComplete = onComplete

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 150),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        panel.title = "Record Hotkey"
        panel.isReleasedWhenClosed = false

        let content = NSView(frame: panel.contentRect(forFrameRect: panel.frame))

        let title = NSTextField(labelWithString: "Press your new capture shortcut")
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        title.alignment = .center
        title.frame = NSRect(x: 20, y: 86, width: 320, height: 22)
        content.addSubview(title)

        let helper = NSTextField(labelWithString: "Use at least one modifier key. Press Escape to cancel.")
        helper.font = NSFont.systemFont(ofSize: 12)
        helper.textColor = .secondaryLabelColor
        helper.alignment = .center
        helper.frame = NSRect(x: 20, y: 58, width: 320, height: 18)
        content.addSubview(helper)

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.frame = NSRect(x: 140, y: 16, width: 80, height: 28)
        content.addSubview(cancelButton)

        panel.contentView = content
        self.panel = panel

        // Retain self while sheet is open
        objc_setAssociatedObject(parentWindow, &HotkeyCapturePanel.associatedKey, self, .OBJC_ASSOCIATION_RETAIN)

        parentWindow.beginSheet(panel)

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel != nil else { return event }

            // Escape → cancel
            if event.keyCode == 53 {
                self.cancel()
                return nil
            }

            guard let spec = HotkeyManager.shared.hotkeySpec(for: event) else {
                NSSound.beep()
                return nil
            }

            HotkeyManager.shared.updateHotkey(to: spec.configValue)
            let keys = spec.displayParts
            self.close()
            self.onComplete?(keys)
            return nil
        }
    }

    @objc private func cancel() {
        close()
    }

    private func close() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        if let panel, let parentWindow {
            parentWindow.endSheet(panel)
            panel.orderOut(nil)
        }
        self.panel = nil
        // Release self
        if let parentWindow {
            objc_setAssociatedObject(parentWindow, &HotkeyCapturePanel.associatedKey, nil, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private static var associatedKey: UInt8 = 0
}
