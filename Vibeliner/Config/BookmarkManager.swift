import Foundation

/// Manages security-scoped bookmarks for the user's captures folder.
/// Under App Sandbox, folder access requires persisting a bookmark
/// from the NSOpenPanel grant. Thread-safe: start/stop access calls
/// are balanced per Apple documentation.
final class BookmarkManager {
    static let shared = BookmarkManager()

    private let bookmarkKey = "capturesFolderBookmark"

    private init() {}

    /// Store a security-scoped bookmark for a URL.
    /// Must be called while the sandbox extension is active (e.g., inside
    /// an NSOpenPanel completion handler).
    @discardableResult
    func saveBookmark(for url: URL) -> Bool {
        do {
            let data = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(data, forKey: bookmarkKey)
            return true
        } catch {
            #if DEBUG
            print("Vibeliner: Failed to create bookmark: \(error)")
            #endif
            return false
        }
    }

    /// Resolve the stored bookmark to a URL.
    /// Returns nil if no bookmark is stored or if it cannot be resolved.
    /// If the bookmark is stale but resolvable, re-saves it automatically.
    func resolveBookmark() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Attempt to re-save the bookmark from the resolved URL
                saveBookmark(for: url)
            }

            return url
        } catch {
            #if DEBUG
            print("Vibeliner: Failed to resolve bookmark: \(error)")
            #endif
            return nil
        }
    }

    /// Check if a stored bookmark exists and can be resolved.
    func isBookmarkValid() -> Bool {
        return resolveBookmark() != nil
    }

    /// Execute a block with security-scoped access to the bookmarked folder.
    /// Returns nil if the bookmark can't be resolved or access can't be started.
    /// The resolved URL is passed to the block so callers know the path.
    func withBookmarkAccess<T>(_ block: (URL) throws -> T) rethrows -> T? {
        guard let url = resolveBookmark() else {
            return nil
        }

        guard url.startAccessingSecurityScopedResource() else {
            #if DEBUG
            print("Vibeliner: startAccessingSecurityScopedResource returned false")
            #endif
            return nil
        }

        defer { url.stopAccessingSecurityScopedResource() }
        return try block(url)
    }
}
