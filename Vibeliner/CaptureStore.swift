import AppKit
import Foundation

struct CaptureRecord: Codable {
    let id: String
    let created: Date
    let count: Int
    let slug: String
    let folderURL: URL
    var sent: Bool

    enum CodingKeys: String, CodingKey {
        case created, count, slug, sent
    }

    init(id: String, created: Date, count: Int, slug: String, folderURL: URL, sent: Bool = false) {
        self.id = id
        self.created = created
        self.count = count
        self.slug = slug
        self.folderURL = folderURL
        self.sent = sent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        created = try container.decode(Date.self, forKey: .created)
        count = try container.decode(Int.self, forKey: .count)
        slug = try container.decode(String.self, forKey: .slug)
        sent = (try? container.decode(Bool.self, forKey: .sent)) ?? false
        // These are set after decoding from context
        id = ""
        folderURL = URL(fileURLWithPath: "/")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(created, forKey: .created)
        try container.encode(count, forKey: .count)
        try container.encode(slug, forKey: .slug)
        try container.encode(sent, forKey: .sent)
    }
}

class CaptureStore {
    struct StorageStatus {
        enum State {
            case ready
            case repaired
            case error
        }

        let url: URL
        let state: State
        let detail: String
        let remediation: String?

        var isReady: Bool {
            state != .error
        }
    }

    static let shared = CaptureStore()

    private let fm = FileManager.default

    private var baseDirURL: URL {
        Config.shared.saveDirectoryURL
    }

    private let screenshotFilename = "screenshot.png"
    private let promptFilename = "prompt.md"
    private let metaFilename = "meta.json"

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HHmmss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    private init() {}

    // MARK: - Storage Preparation

    func prepareSaveDirectory(autoRepair: Bool = true) -> StorageStatus {
        let url = baseDirURL
        var isDirectory: ObjCBool = false
        var createdDirectory = false

        if fm.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                return StorageStatus(
                    url: url,
                    state: .error,
                    detail: "The save directory path points to a file, not a folder.",
                    remediation: "Edit save_dir in \(Config.shared.configFilePath) or remove it to use the default captures folder."
                )
            }
        } else if autoRepair {
            do {
                try fm.createDirectory(at: url, withIntermediateDirectories: true)
                createdDirectory = true
            } catch {
                return StorageStatus(
                    url: url,
                    state: .error,
                    detail: "Vibeliner could not create the captures folder at \(url.path).",
                    remediation: "Check that the parent folder is writable, or update save_dir in \(Config.shared.configFilePath)."
                )
            }
        } else {
            return StorageStatus(
                url: url,
                state: .error,
                detail: "The captures folder does not exist yet.",
                remediation: "Use Open captures folder or save a capture to create it."
            )
        }

        do {
            try validateWritableDirectory(at: url)
        } catch {
            return StorageStatus(
                url: url,
                state: .error,
                detail: "Vibeliner cannot write to the captures folder at \(url.path).",
                remediation: "Choose a writable save_dir in \(Config.shared.configFilePath), then relaunch Vibeliner."
            )
        }

        return StorageStatus(
            url: url,
            state: createdDirectory ? .repaired : .ready,
            detail: createdDirectory ? "Created captures folder at \(url.path)." : "Ready at \(url.path).",
            remediation: nil
        )
    }

    @discardableResult
    func openCapturesFolder() throws -> URL {
        let storageStatus = prepareSaveDirectory(autoRepair: true)
        guard storageStatus.isReady else {
            throw CaptureStoreError.saveDirectoryUnavailable(storageStatus.detail, storageStatus.remediation)
        }

        NSWorkspace.shared.activateFileViewerSelecting([storageStatus.url])
        return storageStatus.url
    }

    // MARK: - Save

    func save(image: NSImage, annotations: [(number: Int, note: String)], preamble: String) throws -> CaptureRecord {
        let storageStatus = prepareSaveDirectory(autoRepair: true)
        guard storageStatus.isReady else {
            throw CaptureStoreError.saveDirectoryUnavailable(storageStatus.detail, storageStatus.remediation)
        }

        let now = Date()
        let slug = deriveSlug(from: annotations)
        let timestamp = dateFormatter.string(from: now)
        let folderName = findAvailableFolderName(timestamp: timestamp, slug: slug, baseDirectoryURL: storageStatus.url)
        let folderURL = storageStatus.url.appendingPathComponent(folderName, isDirectory: true)

        try ensureDirectoryExists(at: folderURL)

        // Write screenshot.png
        let imageURL = folderURL.appendingPathComponent(screenshotFilename)
        guard let pngData = pngRepresentation(of: image) else {
            throw CaptureStoreError.imageConversionFailed
        }
        try pngData.write(to: imageURL)

        // Write prompt.md
        let promptURL = folderURL.appendingPathComponent(promptFilename)
        let promptText = PromptBuilder.buildPrompt(
            preambleTemplate: preamble,
            annotations: annotations,
            screenshotReference: PromptBuilder.savedScreenshotReference
        )
        try promptText.write(to: promptURL, atomically: true, encoding: .utf8)

        // Write meta.json
        let record = CaptureRecord(
            id: folderName,
            created: now,
            count: annotations.count,
            slug: slug,
            folderURL: folderURL
        )
        let metaURL = folderURL.appendingPathComponent(metaFilename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let metaData = try encoder.encode(record)
        try metaData.write(to: metaURL)

        return record
    }

    // MARK: - Update (re-save to existing folder)

    func update(record: CaptureRecord, image: NSImage, annotations: [(number: Int, note: String)], preamble: String) throws -> CaptureRecord {
        let storageStatus = prepareSaveDirectory(autoRepair: true)
        guard storageStatus.isReady else {
            throw CaptureStoreError.saveDirectoryUnavailable(storageStatus.detail, storageStatus.remediation)
        }

        let folderURL = record.folderURL

        // Overwrite screenshot.png
        let imageURL = folderURL.appendingPathComponent(screenshotFilename)
        guard let pngData = pngRepresentation(of: image) else {
            throw CaptureStoreError.imageConversionFailed
        }
        try pngData.write(to: imageURL)

        // Overwrite prompt.md
        let promptURL = folderURL.appendingPathComponent(promptFilename)
        let promptText = PromptBuilder.buildPrompt(
            preambleTemplate: preamble,
            annotations: annotations,
            screenshotReference: PromptBuilder.savedScreenshotReference
        )
        try promptText.write(to: promptURL, atomically: true, encoding: .utf8)

        // Overwrite meta.json
        let updated = CaptureRecord(
            id: record.id,
            created: record.created,
            count: annotations.count,
            slug: deriveSlug(from: annotations),
            folderURL: folderURL,
            sent: record.sent
        )
        let metaURL = folderURL.appendingPathComponent(metaFilename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let metaData = try encoder.encode(updated)
        try metaData.write(to: metaURL)

        return updated
    }

    // MARK: - Delete

    func delete(record: CaptureRecord) {
        do {
            try fm.removeItem(at: record.folderURL)
        } catch {
            print("[Vibeliner] Warning: Could not delete \(record.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Mark Sent

    func markSent(_ record: CaptureRecord) {
        var updated = record
        updated.sent = true
        let metaURL = record.folderURL.appendingPathComponent(metaFilename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(updated) {
            try? data.write(to: metaURL)
        }
    }

    // MARK: - List

    func list() -> [CaptureRecord] {
        guard fm.fileExists(atPath: baseDirURL.path) else { return [] }

        var records: [CaptureRecord] = []

        guard let contents = try? fm.contentsOfDirectory(
            at: baseDirURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        for folderURL in contents {
            guard folderURL.hasDirectoryPath else { continue }
            let metaURL = folderURL.appendingPathComponent(metaFilename)
            guard fm.fileExists(atPath: metaURL.path) else { continue }

            do {
                let data = try Data(contentsOf: metaURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decoded = try decoder.decode(CaptureRecord.self, from: data)
                let record = CaptureRecord(
                    id: folderURL.lastPathComponent,
                    created: decoded.created,
                    count: decoded.count,
                    slug: decoded.slug,
                    folderURL: folderURL,
                    sent: decoded.sent
                )
                records.append(record)
            } catch {
                print("[Vibeliner] Warning: Could not read meta.json in \(folderURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        return records.sorted { $0.created > $1.created }
    }

    // MARK: - Clean

    func clean(retainDays: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -retainDays, to: Date()) ?? Date()
        let records = list()

        for record in records where record.created < cutoff {
            do {
                try fm.removeItem(at: record.folderURL)
            } catch {
                print("[Vibeliner] Warning: Could not delete \(record.id): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helpers

    func captureDir(for record: CaptureRecord) -> URL {
        record.folderURL
    }

    func clipboardPrompt(for record: CaptureRecord) throws -> String {
        let promptURL = record.folderURL.appendingPathComponent(promptFilename)
        let savedPrompt = try String(contentsOf: promptURL, encoding: .utf8)
        let screenshotURL = record.folderURL.appendingPathComponent(screenshotFilename)

        return PromptBuilder.clipboardPrompt(from: savedPrompt, screenshotURL: screenshotURL)
    }

    private func deriveSlug(from annotations: [(number: Int, note: String)]) -> String {
        guard let first = annotations.first, !first.note.isEmpty else {
            return "untitled"
        }

        let slug = first.note
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")

        let filtered = slug.unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == "-"
        }

        let cleaned = String(String.UnicodeScalarView(filtered))
        if cleaned.count > 30 {
            return String(cleaned.prefix(30))
        }
        return cleaned.isEmpty ? "untitled" : cleaned
    }

    private func findAvailableFolderName(timestamp: String, slug: String, baseDirectoryURL: URL) -> String {
        let base = "\(timestamp)_\(slug)"
        if !fm.fileExists(atPath: baseDirectoryURL.appendingPathComponent(base).path) {
            return base
        }
        var counter = 2
        while true {
            let candidate = "\(base)-\(counter)"
            if !fm.fileExists(atPath: baseDirectoryURL.appendingPathComponent(candidate).path) {
                return candidate
            }
            counter += 1
        }
    }

    private func ensureDirectoryExists(at url: URL) throws {
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func validateWritableDirectory(at url: URL) throws {
        let probeURL = url.appendingPathComponent(".write-test-\(UUID().uuidString)")
        let probeData = Data("ok".utf8)
        do {
            try probeData.write(to: probeURL, options: .atomic)
            try fm.removeItem(at: probeURL)
        } catch {
            throw CaptureStoreError.directoryNotWritable(url.path)
        }
    }

    private func pngRepresentation(of image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}

enum CaptureStoreError: Error, LocalizedError {
    case imageConversionFailed
    case directoryNotWritable(String)
    case saveDirectoryUnavailable(String, String?)

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to PNG"
        case .directoryNotWritable(let path):
            return "The captures folder at \(path) is not writable."
        case .saveDirectoryUnavailable(let detail, let remediation):
            if let remediation, !remediation.isEmpty {
                return "\(detail) \(remediation)"
            }
            return detail
        }
    }
}
