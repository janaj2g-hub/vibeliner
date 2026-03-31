import AppKit

final class CanvasView: NSView {

    let marksLayer: NSView
    let notesLayer: NSView
    private var storeObserver: Any?

    init(frame: NSRect, store: AnnotationStore) {
        marksLayer = NSView(frame: NSRect(origin: .zero, size: frame.size))
        marksLayer.wantsLayer = true
        marksLayer.layer?.masksToBounds = true

        notesLayer = NSView(frame: NSRect(origin: .zero, size: frame.size))
        notesLayer.wantsLayer = true
        notesLayer.layer?.masksToBounds = false

        super.init(frame: NSRect(origin: .zero, size: frame.size))

        addSubview(marksLayer)
        addSubview(notesLayer)

        storeObserver = NotificationCenter.default.addObserver(
            forName: .annotationsDidChange, object: store, queue: .main
        ) { [weak self] _ in
            self?.marksLayer.needsDisplay = true
            self?.notesLayer.needsDisplay = true
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let observer = storeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
