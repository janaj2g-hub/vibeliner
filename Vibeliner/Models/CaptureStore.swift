import AppKit

/// Manages an ordered list of images in a capture session.
/// Single-image captures are represented as a list of one.
final class CaptureStore {

    private(set) var images: [CaptureImage] = []

    var isSingleImage: Bool { images.count == 1 }
    var isComposite: Bool { images.count >= 2 }

    /// Initialize with a single screenshot (backward-compatible path).
    init(image: NSImage, title: String = "Screenshot", role: ImageRole = .observed) {
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
    func removeImage(at index: Int) {
        guard index >= 0, index < images.count else { return }
        images.remove(at: index)
        reindexImages()
    }

    /// Update indices to match array positions (call after add/remove).
    func reindexImages() {
        for i in images.indices {
            images[i].index = i
        }
    }

    // MARK: - Disk persistence

    /// Save all source images to the capture folder.
    /// - Single image: `screenshot.png` (unchanged behavior)
    /// - Multi-image: `image_1.png`, `image_2.png`, ..., `composite.png`
    func saveImages(to folder: URL) {
        if isSingleImage {
            guard let image = images.first?.sourceImage else { return }
            let fileURL = folder.appendingPathComponent("screenshot.png")
            let tempURL = folder.appendingPathComponent(".screenshot_src.png.tmp")
            _ = image.savePNG(to: tempURL)
            try? FileManager.default.removeItem(at: fileURL)
            try? FileManager.default.moveItem(at: tempURL, to: fileURL)
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

            // Composite placeholder — copy first image for now (stitching is VIB-264)
            if let firstImage = images.first?.sourceImage {
                let compositeURL = folder.appendingPathComponent("composite.png")
                let tempURL = folder.appendingPathComponent(".composite.png.tmp")
                _ = firstImage.savePNG(to: tempURL)
                try? FileManager.default.removeItem(at: compositeURL)
                try? FileManager.default.moveItem(at: tempURL, to: compositeURL)
            }

            // Clean up old screenshot.png if it exists (migrated to multi-image)
            let oldScreenshot = folder.appendingPathComponent("screenshot.png")
            try? FileManager.default.removeItem(at: oldScreenshot)
        }
    }

    /// Load images from a capture folder on disk.
    /// Handles both old single-image folders (`screenshot.png`) and
    /// new multi-image folders (`image_1.png`, `image_2.png`, ...).
    static func load(from folder: URL) -> CaptureStore? {
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
            return CaptureStore(images: multiImages)
        }

        // Fall back to single-image (auto-migrate)
        let screenshotURL = folder.appendingPathComponent("screenshot.png")
        guard fm.fileExists(atPath: screenshotURL.path),
              let image = NSImage(contentsOf: screenshotURL) else { return nil }

        return CaptureStore(image: image)
    }
}
