import AppKit

/// Manages an ordered list of images in a capture session.
/// Single-image captures are represented as a list of one.
final class CaptureSession {

    static let annotatedImageFilename = "screenshot.png"
    static let legacyAnnotatedImageFilename = "composite.png"
    static let promptFilename = "prompt.txt"

    private(set) var images: [CaptureImage] = []

    var isSingleImage: Bool { images.count == 1 }
    var isMultiImage: Bool { images.count >= 2 }
    var isComposite: Bool { isMultiImage }
    var primaryImage: CaptureImage? { images.first }

    /// Initialize with a single screenshot (backward-compatible path).
    init(image: NSImage, title: String = "Image 1", role: ImageRole = .observed) {
        let entry = CaptureImage(
            sourceImage: image,
            title: title,
            role: role,
            originalSize: image.size,
            index: 0
        )
        images = [entry]
    }

    /// Initialize with multiple images.
    init(images: [CaptureImage]) {
        self.images = images
        reindexImages()
    }

    func snapshot() -> CaptureSession {
        CaptureSession(images: images)
    }

    /// Append a new image and assign the next index.
    func addImage(_ image: NSImage, title: String, role: ImageRole) {
        let entry = CaptureImage(
            sourceImage: image,
            title: title,
            role: role,
            originalSize: image.size,
            index: images.count
        )
        images.append(entry)
    }

    /// Remove the image at the given index and reindex remaining entries.
    @discardableResult
    func removeImage(at index: Int) -> CaptureImage? {
        guard index >= 0, index < images.count else { return nil }
        let removed = images.remove(at: index)
        reindexImages()
        return removed
    }

    /// Update the title of an image at the given index.
    func updateTitle(at index: Int, title: String) {
        guard index >= 0, index < images.count else { return }
        images[index].title = title
    }

    /// Update the role of an image at the given index.
    func updateRole(at index: Int, role: ImageRole) {
        guard index >= 0, index < images.count else { return }
        images[index].role = role
    }

    /// Default role for any new image — uses the first configured role, or .observed.
    /// User changes roles manually via the dropdown.
    static func defaultRole(forIndex index: Int) -> ImageRole {
        let roles = ConfigManager.shared.roles
        if index < roles.count {
            return ImageRole(name: roles[index].name)
        }
        return roles.first.map { ImageRole(name: $0.name) } ?? .observed
    }

    func image(at index: Int) -> CaptureImage? {
        guard index >= 0, index < images.count else { return nil }
        return images[index]
    }

    func imageID(at index: Int) -> UUID? {
        image(at: index)?.id
    }

    func index(forImageID id: UUID) -> Int? {
        images.firstIndex { $0.id == id }
    }

    func title(forImageID id: UUID?, fallbackIndex: Int?) -> String {
        if let id, let image = images.first(where: { $0.id == id }) {
            return image.title
        }
        if let fallbackIndex, let image = image(at: fallbackIndex) {
            return image.title
        }
        if let fallbackIndex {
            return "Image \(fallbackIndex + 1)"
        }
        return "Image 1"
    }

    /// Update indices to match array positions (call after add/remove).
    func reindexImages() {
        for i in images.indices {
            images[i].index = i
        }
    }

    static func annotatedImageURL(in folder: URL) -> URL {
        folder.appendingPathComponent(annotatedImageFilename)
    }

    static func resolvedAnnotatedImageURL(in folder: URL, fileManager: FileManager = .default) -> URL {
        let canonicalURL = annotatedImageURL(in: folder)
        if fileManager.fileExists(atPath: canonicalURL.path) {
            return canonicalURL
        }

        let legacyURL = folder.appendingPathComponent(legacyAnnotatedImageFilename)
        if fileManager.fileExists(atPath: legacyURL.path) {
            return legacyURL
        }

        return canonicalURL
    }

    static func saveAnnotatedImage(_ image: NSImage, to folder: URL) {
        BookmarkManager.shared.withBookmarkAccess { _ in
            let fileURL = annotatedImageURL(in: folder)
            let tempURL = folder.appendingPathComponent(".\(annotatedImageFilename).tmp")
            _ = image.savePNG(to: tempURL)
            try? FileManager.default.removeItem(at: fileURL)
            try? FileManager.default.moveItem(at: tempURL, to: fileURL)

            let legacyURL = folder.appendingPathComponent(legacyAnnotatedImageFilename)
            try? FileManager.default.removeItem(at: legacyURL)
        }
    }

    // MARK: - Disk persistence

    /// Save all source images to the capture folder.
    /// - Single image: `screenshot.png` (unchanged behavior)
    /// - Multi-image: `image_1.png`, `image_2.png`, ... plus canonical `screenshot.png`
    func saveImages(to folder: URL) {
        if isSingleImage {
            guard let image = images.first?.sourceImage else { return }
            Self.saveAnnotatedImage(image, to: folder)
        } else {
            // Save individual source images
            for entry in images {
                let filename = "image_\(entry.index + 1).png"
                let fileURL = folder.appendingPathComponent(filename)
                let tempURL = folder.appendingPathComponent(".\(filename).tmp")
                _ = entry.sourceImage.savePNG(to: tempURL)
                try? FileManager.default.removeItem(at: fileURL)
                try? FileManager.default.moveItem(at: tempURL, to: fileURL)
            }

            // Canonical saved image placeholder — copy first image for now (stitching is VIB-264)
            if let firstImage = images.first?.sourceImage {
                Self.saveAnnotatedImage(firstImage, to: folder)
            }
        }
    }

    /// Load images from a capture folder on disk.
    /// Handles both old single-image folders (`screenshot.png`) and
    /// new multi-image folders (`image_1.png`, `image_2.png`, ...).
    static func load(from folder: URL) -> CaptureSession? {
        let fm = FileManager.default

        // Check for multi-image folder first
        var multiImages: [CaptureImage] = []
        var idx = 1
        while true {
            let fileURL = folder.appendingPathComponent("image_\(idx).png")
            guard fm.fileExists(atPath: fileURL.path),
                  let image = NSImage(contentsOf: fileURL) else { break }
            let entry = CaptureImage(
                sourceImage: image,
                title: "Image \(idx)",
                role: .observed,
                originalSize: image.size,
                index: idx - 1
            )
            multiImages.append(entry)
            idx += 1
        }

        if !multiImages.isEmpty {
            return CaptureSession(images: multiImages)
        }

        // Fall back to the canonical annotated image with a legacy composite fallback.
        let screenshotURL = resolvedAnnotatedImageURL(in: folder, fileManager: fm)
        guard let image = NSImage(contentsOf: screenshotURL) else { return nil }

        return CaptureSession(image: image)
    }
}

typealias CaptureStore = CaptureSession
