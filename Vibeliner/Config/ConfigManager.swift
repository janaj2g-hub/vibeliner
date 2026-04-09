import Foundation

final class ConfigManager {
    static let shared = ConfigManager()

    private let queue = DispatchQueue(label: "com.vibeliner.config")

    var capturesFolder: String = "~/Documents/vibeliner"
    var hotkey: String = "cmd+shift+6"
    var copyMode: String = "app"
    var setupComplete: Bool = false
    var tooltipDismissed: Bool = false
    var launchAtLogin: Bool = false
    /// Appearance mode: "system", "dark", or "light"
    var appearance: String = "system"
    var preamble: String = "This is a screenshot of my running app. View it at [Screenshot Path]\n\n[Tool Description] Each annotation has a number and a description.\n\nFix each issue:"
    var footer: String = "Make the changes and verify they match the design."
    var toolDescriptions: [String: String] = [
        "pin": "points to a specific issue",
        "arrow": "points at or between elements",
        "rectangle": "highlights a region or container",
        "circle": "calls out a specific element",
        "freehand": "marks an irregular area"
    ]
    var roleDescriptions: [String: String] = [
        "observed": "shows the current state of the app",
        "expected": "shows the desired or correct state",
        "reference": "provides supplementary context or a design spec"
    ]

    var expandedCapturesFolder: String {
        return (capturesFolder as NSString).expandingTildeInPath
    }

    /// Whether the captures folder exists on disk as a directory
    var capturesFolderExists: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: expandedCapturesFolder, isDirectory: &isDir) && isDir.boolValue
    }

    /// Whether config.toml exists (distinguishes first-time from returning user)
    var configFileExists: Bool {
        return FileManager.default.fileExists(atPath: configFileURL.path)
    }

    /// Stable config location — survives captures folder changes and clean builds.
    /// ~/Library/Application Support/Vibeliner/config.toml
    private var configFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Vibeliner").appendingPathComponent("config.toml")
    }

    /// Legacy config path inside the captures folder (pre-VIB-301).
    /// Used only for one-time migration.
    private var legacyConfigFileURL: URL {
        let path = (capturesFolder as NSString).expandingTildeInPath
        return URL(fileURLWithPath: path).appendingPathComponent("config.toml")
    }

    private init() {}

    func load() {
        queue.sync {
            loadInternal()
        }
    }

    func save() {
        queue.sync {
            saveInternal()
        }
    }

    func reset() {
        queue.sync {
            capturesFolder = "~/Documents/vibeliner"
            hotkey = "cmd+shift+6"
            copyMode = "app"
            setupComplete = false
            tooltipDismissed = false
            launchAtLogin = false
            appearance = "system"
            preamble = "This is a screenshot of my running app. View it at [Screenshot Path]\n\n[Tool Description] Each annotation has a number and a description.\n\nFix each issue:"
            footer = "Make the changes and verify they match the design."
            toolDescriptions = [
                "pin": "points to a specific issue",
                "arrow": "points at or between elements",
                "rectangle": "highlights a region or container",
                "circle": "calls out a specific element",
                "freehand": "marks an irregular area"
            ]
            roleDescriptions = [
                "observed": "shows the current state of the app",
                "expected": "shows the desired or correct state",
                "reference": "provides supplementary context or a design spec"
            ]
            saveInternal()
        }
    }

    // MARK: - Internal (must be called within queue.sync)

    private func loadInternal() {
        let fileManager = FileManager.default
        let configPath = configFileURL.path

        // If stable config exists, load it directly.
        if fileManager.fileExists(atPath: configPath) {
            if let contents = try? String(contentsOfFile: configPath, encoding: .utf8) {
                parseToml(contents)
            }
            return
        }

        // Migration: check for legacy config inside the default captures folder.
        let legacyPath = legacyConfigFileURL.path
        if fileManager.fileExists(atPath: legacyPath),
           let legacyContents = try? String(contentsOfFile: legacyPath, encoding: .utf8) {
            parseToml(legacyContents)
            // Save to new stable location so future launches use it.
            saveInternal()
            // Remove legacy file to avoid stale copies.
            try? fileManager.removeItem(atPath: legacyPath)
            return
        }

        // First launch — write defaults to the new stable location.
        saveInternal()
    }

    private func saveInternal() {
        let fileManager = FileManager.default

        // Ensure the Application Support/Vibeliner directory exists.
        let configDir = configFileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: configDir.path) {
            try? fileManager.createDirectory(at: configDir, withIntermediateDirectories: true)
        }

        let toml = generateToml()
        try? toml.write(to: configFileURL, atomically: true, encoding: .utf8)
    }

    // MARK: - TOML Parsing

    private func parseToml(_ contents: String) {
        var currentSection = ""

        for line in contents.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                currentSection = String(trimmed.dropFirst().dropLast())
                continue
            }

            guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }

            let key = trimmed[trimmed.startIndex..<equalsIndex].trimmingCharacters(in: .whitespaces)
            let rawValue = trimmed[trimmed.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)

            if currentSection == "tool_descriptions" {
                toolDescriptions[key] = unquoteString(rawValue)
                continue
            }
            if currentSection == "role_descriptions" {
                roleDescriptions[key] = unquoteString(rawValue)
                continue
            }

            switch key {
            case "captures_folder":
                capturesFolder = unquoteString(rawValue)
            case "hotkey":
                hotkey = unquoteString(rawValue)
            case "copy_mode":
                copyMode = unquoteString(rawValue)
            case "setup_complete":
                setupComplete = rawValue == "true"
            case "tooltip_dismissed":
                tooltipDismissed = rawValue == "true"
            case "launch_at_login":
                launchAtLogin = rawValue == "true"
            case "appearance":
                appearance = unquoteString(rawValue)
            case "preamble":
                preamble = unquoteMultilineString(rawValue)
            case "footer":
                footer = unquoteMultilineString(rawValue)
            default:
                break
            }
        }
    }

    private func generateToml() -> String {
        var lines: [String] = []
        lines.append("captures_folder = \"\(capturesFolder)\"")
        lines.append("hotkey = \"\(hotkey)\"")
        lines.append("copy_mode = \"\(copyMode)\"")
        lines.append("setup_complete = \(setupComplete)")
        lines.append("tooltip_dismissed = \(tooltipDismissed)")
        lines.append("launch_at_login = \(launchAtLogin)")
        lines.append("appearance = \"\(appearance)\"")
        lines.append("preamble = \"\(escapeString(preamble))\"")
        lines.append("footer = \"\(escapeString(footer))\"")
        lines.append("")
        lines.append("[tool_descriptions]")

        let sortedKeys = toolDescriptions.keys.sorted()
        for key in sortedKeys {
            if let value = toolDescriptions[key] {
                lines.append("\(key) = \"\(escapeString(value))\"")
            }
        }

        lines.append("")
        lines.append("[role_descriptions]")

        let sortedRoleKeys = roleDescriptions.keys.sorted()
        for key in sortedRoleKeys {
            if let value = roleDescriptions[key] {
                lines.append("\(key) = \"\(escapeString(value))\"")
            }
        }

        lines.append("")
        return lines.joined(separator: "\n")
    }

    private func unquoteString(_ value: String) -> String {
        var s = value
        if s.hasPrefix("\"") && s.hasSuffix("\"") && s.count >= 2 {
            s = String(s.dropFirst().dropLast())
        }
        return s.replacingOccurrences(of: "\\n", with: "\n")
              .replacingOccurrences(of: "\\\"", with: "\"")
    }

    private func unquoteMultilineString(_ value: String) -> String {
        return unquoteString(value)
    }

    private func escapeString(_ value: String) -> String {
        return value.replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
    }
}
