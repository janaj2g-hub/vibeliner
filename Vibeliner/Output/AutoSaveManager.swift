import AppKit

final class AutoSaveManager {

    private let store: AnnotationStore
    private let captureFolder: URL
    private let originalImage: NSImage
    private let canvasSize: CGSize
    private var storeObserver: Any?
    private var debounceTimer: Timer?
    private var isDirty = false

    init(store: AnnotationStore, captureFolder: URL, originalImage: NSImage, canvasSize: CGSize) {
        self.store = store
        self.captureFolder = captureFolder
        self.originalImage = originalImage
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

    func saveNow() {
        debounceTimer?.invalidate()
        performSave()
    }

    func saveIfNeeded() {
        guard isDirty else { return }
        saveNow()
    }

    private func scheduleSave() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.performSave()
        }
    }

    private func performSave() {
        let annotations = store.annotations
        ScreenshotExporter.saveExportedScreenshot(
            to: captureFolder,
            original: originalImage,
            annotations: annotations,
            canvasSize: canvasSize
        )
        PromptGenerator.savePromptFile(to: captureFolder, annotations: annotations)
        isDirty = false
    }
}
