import Foundation

struct CaptureInfo {
    let folderURL: URL
    let timestamp: Date
    let screenshotURL: URL
    let promptURL: URL
    let noteCount: Int
}

final class CapturesManager {
    static let shared = CapturesManager()

    private let fileManager = FileManager.default
    private static let folderDateFormat = "yyyy-MM-dd_HHmmss"

    private init() {}

    var baseFolderURL: URL {
        let path = ConfigManager.shared.expandedCapturesFolder
        return URL(fileURLWithPath: path)
    }

    func ensureBaseFolder() {
        let path = baseFolderURL.path
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }

    func createCaptureFolder() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = Self.folderDateFormat
        let folderName = formatter.string(from: Date())
        let folderURL = baseFolderURL.appendingPathComponent(folderName)
        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL
    }

    // VIB-183: Cached results for async usage
    private var cachedCaptures: [CaptureInfo]?
    private var cacheTimestamp: Date?

    /// VIB-183: Async version — scans on background thread, calls completion on main
    func listRecentCapturesAsync(limit: Int = 5, completion: @escaping ([CaptureInfo]) -> Void) {
        // Return cache if fresh (< 5 seconds old)
        if let cached = cachedCaptures, let ts = cacheTimestamp, Date().timeIntervalSince(ts) < 5 {
            completion(Array(cached.prefix(limit)))
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let captures = self.listRecentCaptures(limit: limit)
            self.cachedCaptures = captures
            self.cacheTimestamp = Date()
            DispatchQueue.main.async {
                completion(captures)
            }
        }
    }

    /// Invalidate cache (call after saving a new capture)
    func invalidateCache() {
        cachedCaptures = nil
        cacheTimestamp = nil
    }

    func listRecentCaptures(limit: Int = 10) -> [CaptureInfo] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: baseFolderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = Self.folderDateFormat

        var captures: [CaptureInfo] = []

        for url in contents {
            guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  resourceValues.isDirectory == true else {
                continue
            }

            let folderName = url.lastPathComponent
            guard let date = formatter.date(from: folderName) else {
                continue
            }

            let screenshotURL = url.appendingPathComponent("screenshot.png")
            let promptURL = url.appendingPathComponent("prompt.txt")
            let noteCount = countNotes(in: promptURL)

            captures.append(CaptureInfo(
                folderURL: url,
                timestamp: date,
                screenshotURL: screenshotURL,
                promptURL: promptURL,
                noteCount: noteCount
            ))
        }

        captures.sort { $0.timestamp > $1.timestamp }

        if captures.count > limit {
            return Array(captures.prefix(limit))
        }
        return captures
    }

    private func countNotes(in promptURL: URL) -> Int {
        guard let contents = try? String(contentsOf: promptURL, encoding: .utf8) else {
            return 0
        }

        var count = 0
        for line in contents.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let first = trimmed.first, first.isNumber {
                count += 1
            }
        }
        return count
    }
}
