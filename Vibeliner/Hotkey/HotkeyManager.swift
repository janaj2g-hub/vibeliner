import AppKit

final class HotkeyManager {
    static let shared = HotkeyManager()

    var onHotkeyPressed: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {}

    func register() {
        let modifiers: NSEvent.ModifierFlags = [.command, .shift]
        let keyCode: UInt16 = 22 // "6" key

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers &&
               event.keyCode == keyCode {
                self?.onHotkeyPressed?()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers &&
               event.keyCode == keyCode {
                self?.onHotkeyPressed?()
                return nil
            }
            return event
        }

        if !isTrusted() {
            print("Vibeliner: Accessibility permission not granted. Global hotkey will not work from other apps. Please grant access in System Settings > Privacy & Security > Accessibility.")
        }
    }

    func unregister() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    private func isTrusted() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
