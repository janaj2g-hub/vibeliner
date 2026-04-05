import AppKit

final class HotkeyManager {
    static let shared = HotkeyManager()

    struct HotkeySpec {
        let keyCode: UInt16
        let modifiers: NSEvent.ModifierFlags
        let keyToken: String

        var configValue: String {
            var parts: [String] = []
            if modifiers.contains(.command) { parts.append("cmd") }
            if modifiers.contains(.shift) { parts.append("shift") }
            if modifiers.contains(.option) { parts.append("option") }
            if modifiers.contains(.control) { parts.append("ctrl") }
            parts.append(keyToken)
            return parts.joined(separator: "+")
        }

        var displayParts: [String] {
            var parts: [String] = []
            if modifiers.contains(.command) { parts.append("⌘") }
            if modifiers.contains(.shift) { parts.append("⇧") }
            if modifiers.contains(.option) { parts.append("⌥") }
            if modifiers.contains(.control) { parts.append("⌃") }
            parts.append(Self.displayToken(for: keyToken))
            return parts
        }

        private static func displayToken(for keyToken: String) -> String {
            if keyToken.count == 1 {
                return keyToken.uppercased()
            }
            switch keyToken {
            case "space": return "Space"
            case "return": return "↩"
            case "tab": return "⇥"
            case "delete": return "⌫"
            case "escape": return "⎋"
            default: return keyToken.uppercased()
            }
        }
    }

    var onHotkeyPressed: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var registeredHotkey = HotkeySpec(keyCode: 22, modifiers: [.command, .shift], keyToken: "6")

    private init() {}

    func register() {
        registeredHotkey = hotkeySpec(from: ConfigManager.shared.hotkey) ?? Self.defaultHotkey

        NSLog(
            "Vibeliner: Registering hotkey %@ (keyCode %d)",
            registeredHotkey.displayParts.joined(),
            registeredHotkey.keyCode
        )

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isHotkeyMatch(event) == true {
                NSLog("Vibeliner: Global hotkey %@ triggered", self?.registeredHotkey.displayParts.joined() ?? "")
                DispatchQueue.main.async {
                    self?.onHotkeyPressed?()
                }
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.isHotkeyMatch(event) == true {
                NSLog("Vibeliner: Local hotkey %@ triggered", self?.registeredHotkey.displayParts.joined() ?? "")
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
        return flags.contains(registeredHotkey.modifiers) && event.keyCode == registeredHotkey.keyCode
    }

    func updateHotkey(to configValue: String) {
        guard let newHotkey = hotkeySpec(from: configValue) else { return }
        ConfigManager.shared.hotkey = newHotkey.configValue
        ConfigManager.shared.save()
        unregister()
        register()
    }

    func displayParts(for configValue: String) -> [String] {
        let spec = hotkeySpec(from: configValue) ?? Self.defaultHotkey
        return spec.displayParts
    }

    func hotkeySpec(for event: NSEvent) -> HotkeySpec? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let allowedModifiers = flags.intersection([.command, .shift, .option, .control])
        guard !allowedModifiers.isEmpty else { return nil }
        guard let keyToken = Self.keyToken(for: event.keyCode) else { return nil }
        return HotkeySpec(keyCode: event.keyCode, modifiers: allowedModifiers, keyToken: keyToken)
    }

    private func hotkeySpec(from configValue: String) -> HotkeySpec? {
        let parts = configValue
            .lowercased()
            .split(separator: "+")
            .map(String.init)

        guard let keyToken = parts.last, let keyCode = Self.keyCode(for: keyToken) else {
            return nil
        }

        var modifiers: NSEvent.ModifierFlags = []
        for part in parts.dropLast() {
            switch part {
            case "cmd", "command":
                modifiers.insert(.command)
            case "shift":
                modifiers.insert(.shift)
            case "option", "opt", "alt":
                modifiers.insert(.option)
            case "ctrl", "control":
                modifiers.insert(.control)
            default:
                break
            }
        }

        guard !modifiers.isEmpty else { return nil }
        return HotkeySpec(keyCode: keyCode, modifiers: modifiers, keyToken: keyToken)
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

    private static let defaultHotkey = HotkeySpec(keyCode: 22, modifiers: [.command, .shift], keyToken: "6")

    private static let keyTokenToKeyCode: [String: UInt16] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
        "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
        "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23,
        "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29, "]": 30, "o": 31, "u": 32, "[": 33,
        "i": 34, "p": 35, "return": 36, "l": 37, "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42,
        ",": 43, "/": 44, "n": 45, "m": 46, ".": 47, "tab": 48, "space": 49, "`": 50,
        "delete": 51, "escape": 53
    ]

    private static let keyCodeToKeyToken = Dictionary(uniqueKeysWithValues: keyTokenToKeyCode.map { ($1, $0) })

    private static func keyCode(for keyToken: String) -> UInt16? {
        keyTokenToKeyCode[keyToken]
    }

    private static func keyToken(for keyCode: UInt16) -> String? {
        keyCodeToKeyToken[keyCode]
    }
}
