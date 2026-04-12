import AppKit

final class AutoSaveManager {

    private let store: AnnotationStore
    private let captureFolder: URL
    private let session: CaptureSession
    /// VIB-372: Mutable so filmstrip mode can update it to the actual canvas bounds.
    var canvasSize: CGSize
    private var storeObserver: Any?
    private var debounceTimer: Timer?
    private var isDirty = false

    init(store: AnnotationStore, captureFolder: URL, session: CaptureSession, canvasSize: CGSize) {
        self.store = store
        self.captureFolder = captureFolder
        self.session = session
        self.canvasSize = canvasSize

        storeObserver = NotificationCenter.default.addObserver(
            forName: .annotationsDidChange, object: store, queue: .main
        ) { [weak self] _ in
            self?.isDirty = true
            self?.scheduleSave()
        }
    }

    deinit {
        if let observer = storeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        debounceTimer?.invalidate()
    }

    /// VIB-169: Save immediately but non-blocking. File I/O goes to background queue.
    func saveNow() {
        debounceTimer?.invalidate()
        performSave()
    }

private func scheduleSave() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.performSave()
        }
    }

    private func performSave() {
        // VIB-169: Capture data on main thread, dispatch file I/O to background
        let annotations = store.annotations
        let folder = captureFolder
        let sessionSnapshot = session.snapshot()
        let size = canvasSize
        isDirty = false
        DispatchQueue.global(qos: .userInitiated).async {
            if sessionSnapshot.isMultiImage {
                if let composite = CompositeStitcher.stitch(images: sessionSnapshot.images, annotations: annotations, canvasSize: size) {
                    CaptureSession.saveAnnotatedImage(composite, to: folder)
                }
            } else if let image = sessionSnapshot.primaryImage?.sourceImage {
                ScreenshotExporter.saveExportedScreenshot(to: folder, original: image, annotations: annotations, canvasSize: size)
            }
            PromptGenerator.savePromptFile(to: folder, annotations: annotations, captureSession: sessionSnapshot)
            // VIB-183: Invalidate captures cache so next submenu open shows the new capture
            CapturesManager.shared.invalidateCache()
        }
    }
}
