import AppKit

final class HotkeyManager {
    static let shared = HotkeyManager()

    var onHotkeyPressed: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {}

    func register() {
        let keyCode: UInt16 = 22 // "6" key

        NSLog("Vibeliner: Registering hotkey ⌘⇧6 (keyCode %d)", keyCode)

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isHotkeyMatch(event) == true {
                NSLog("Vibeliner: Global hotkey ⌘⇧6 triggered")
                DispatchQueue.main.async {
                    self?.onHotkeyPressed?()
                }
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isHotkeyMatch(event) == true {
                NSLog("Vibeliner: Local hotkey ⌘⇧6 triggered")
                DispatchQueue.main.async {
                    self?.onHotkeyPressed?()
                }
                return nil
            }
            return event
        }

        let trusted = isTrusted()
        NSLog("Vibeliner: Accessibility trusted = %@", trusted ? "YES" : "NO")
        if !trusted {
            // Prompt for accessibility access
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }

    /// Check if the event matches ⌘⇧6. Uses .contains instead of == to tolerate
    /// extra modifier bits (capsLock, numericPad, function keys, etc.)
    private func isHotkeyMatch(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return flags.contains([.command, .shift]) && event.keyCode == 22
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
