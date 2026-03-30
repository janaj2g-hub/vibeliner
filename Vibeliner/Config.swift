import Foundation

struct VibelinerConfig: Equatable {
    static let defaultSaveDir = "~/.vibeliner/captures"

    var hotkey: String = "cmd+shift+6"
    var saveDir: String = VibelinerConfig.defaultSaveDir
    var retainDays: Int = 30
    var preambleSingle: String = PromptBuilder.defaultSinglePreamble
    var preambleBatch: String = PromptBuilder.defaultBatchPreamble

    var resolvedSaveDir: String {
        let normalizedSaveDir = saveDir.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? VibelinerConfig.defaultSaveDir
            : saveDir

        if normalizedSaveDir.hasPrefix("~") {
            return (normalizedSaveDir as NSString).expandingTildeInPath
        }

        return normalizedSaveDir
    }
}

class Config {
    static let shared = Config()

    private(set) var config: VibelinerConfig

    var preambleSingle: String {
        get { config.preambleSingle }
        set { config.preambleSingle = newValue }
    }

    var preambleBatch: String {
        get { config.preambleBatch }
        set { config.preambleBatch = newValue }
    }

    var configFilePath: String {
        configFileURL.path
    }

    var saveDirectoryURL: URL {
        URL(fileURLWithPath: config.resolvedSaveDir, isDirectory: true).standardizedFileURL
    }

    private let configDirURL: URL
    private let configFileURL: URL

    private init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configDirURL = home.appendingPathComponent(".vibeliner")
        configFileURL = configDirURL.appendingPathComponent("config.toml")
        config = VibelinerConfig()
        load()
    }

    func reload() {
        load()
    }

    private func load() {
        let fm = FileManager.default

        // Ensure directory exists
        if !fm.fileExists(atPath: configDirURL.path) {
            do {
                try fm.createDirectory(at: configDirURL, withIntermediateDirectories: true)
            } catch {
                print("[Vibeliner] Warning: Could not create config directory: \(error.localizedDescription)")
                return
            }
        }

        // If config file doesn't exist, write defaults
        if !fm.fileExists(atPath: configFileURL.path) {
            save()
            return
        }

        // Read and parse
        do {
            let contents = try String(contentsOf: configFileURL, encoding: .utf8)
            let parsedConfig = parse(contents)
            let migratedConfig = migrate(parsedConfig)
            config = migratedConfig

            if migratedConfig != parsedConfig {
                save()
            }
        } catch {
            print("[Vibeliner] Warning: Could not read config file: \(error.localizedDescription)")
        }
    }

    func save() {
        let fm = FileManager.default

        // Ensure directory exists
        if !fm.fileExists(atPath: configDirURL.path) {
            do {
                try fm.createDirectory(at: configDirURL, withIntermediateDirectories: true)
            } catch {
                print("[Vibeliner] Warning: Could not create config directory: \(error.localizedDescription)")
                return
            }
        }

        let toml = serialize(config)
        do {
            try toml.write(to: configFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("[Vibeliner] Warning: Could not write config file: \(error.localizedDescription)")
        }
    }

    func updateSaveDirectory(to path: String) {
        config.saveDir = path
        save()
    }

    // MARK: - TOML Parser (simple key = value)

    private func parse(_ contents: String) -> VibelinerConfig {
        var result = VibelinerConfig()
        let lines = contents.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Split on first '='
            guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[trimmed.startIndex..<equalsIndex].trimmingCharacters(in: .whitespaces)
            let rawValue = trimmed[trimmed.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)

            switch key {
            case "hotkey":
                result.hotkey = unquote(rawValue)
            case "save_dir":
                result.saveDir = unquote(rawValue)
            case "retain_days":
                if let intVal = Int(rawValue) {
                    result.retainDays = intVal
                }
            case "preamble_single":
                result.preambleSingle = unquote(rawValue)
            case "preamble_batch":
                result.preambleBatch = unquote(rawValue)
            default:
                // Unknown keys are ignored
                break
            }
        }

        return result
    }

    private func migrate(_ config: VibelinerConfig) -> VibelinerConfig {
        var migrated = config

        if migrated.saveDir.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            migrated.saveDir = VibelinerConfig.defaultSaveDir
        }

        migrated.preambleSingle = PromptBuilder.normalizedTemplate(migrated.preambleSingle)
        migrated.preambleBatch = PromptBuilder.normalizedTemplate(migrated.preambleBatch)

        return migrated
    }

    private func unquote(_ value: String) -> String {
        if value.count >= 2 && value.hasPrefix("\"") && value.hasSuffix("\"") {
            let inner = value.dropFirst().dropLast()
            return String(inner)
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
                .replacingOccurrences(of: "\\n", with: "\n")
        }
        return value
    }

    private func quote(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    private func serialize(_ config: VibelinerConfig) -> String {
        var lines: [String] = []
        lines.append("# Vibeliner configuration")
        lines.append("")
        lines.append("hotkey = \(quote(config.hotkey))")
        lines.append("save_dir = \(quote(config.saveDir))")
        lines.append("retain_days = \(config.retainDays)")
        lines.append("preamble_single = \(quote(config.preambleSingle))")
        lines.append("preamble_batch = \(quote(config.preambleBatch))")
        lines.append("")
        return lines.joined(separator: "\n")
    }
}
