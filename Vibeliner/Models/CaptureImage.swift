import AppKit

/// A single image entry in a multi-image capture.
struct CaptureImage: Identifiable {
    let id: UUID
    var sourceImage: NSImage
    var title: String
    var role: ImageRole
    var originalSize: CGSize
    var index: Int

    init(id: UUID = UUID(), sourceImage: NSImage, title: String, role: ImageRole, originalSize: CGSize, index: Int) {
        self.id = id
        self.sourceImage = sourceImage
        self.title = title
        self.role = role
        self.originalSize = originalSize
        self.index = index
    }
}
