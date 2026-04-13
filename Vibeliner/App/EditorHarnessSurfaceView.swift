import AppKit

#if DEBUG
enum EditorHarnessStyle {
    case calmSingleImage
    case denseHoverSelection
    case denseFilmstrip

    var size: NSSize {
        switch self {
        case .denseFilmstrip:
            return NSSize(width: 920, height: 440)
        case .calmSingleImage, .denseHoverSelection:
            return NSSize(width: 760, height: 430)
        }
    }
}

final class EditorHarnessSurfaceView: NSView {
    private let style: EditorHarnessStyle
    private let toolbar = ToolbarView()
    private let statusPill = StatusPillView()
    private var screenshotView: ScreenshotCanvasView?
    private var filmstripView: FilmstripGridView?
    private var canvas: CanvasView?
    private var store: AnnotationStore?
    private var session: CaptureSession?

    init(style: EditorHarnessStyle) {
        self.style = style
        super.init(frame: NSRect(origin: .zero, size: style.size))
        wantsLayer = false
        buildScene()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { frame.size }

    private func buildScene() {
        switch style {
        case .calmSingleImage:
            buildSingleImageScene(dense: false)
        case .denseHoverSelection:
            buildSingleImageScene(dense: true)
        case .denseFilmstrip:
            buildFilmstripScene()
        }
    }

    private func buildSingleImageScene(dense: Bool) {
        let canvasFrame = NSRect(x: 48, y: 74, width: bounds.width - 96, height: 250)
        let sampleImage = Self.generateSampleImage(width: canvasFrame.width, height: canvasFrame.height, accent: dense ? DesignTokens.red : DesignTokens.purpleLight)
        let screenshot = ScreenshotCanvasView(image: sampleImage)
        screenshot.frame = canvasFrame
        addSubview(screenshot)
        screenshotView = screenshot

        let annotationStore = AnnotationStore()
        if dense {
            Self.addDenseAnnotations(to: annotationStore, canvasSize: canvasFrame.size)
        } else {
            Self.addCalmAnnotations(to: annotationStore, canvasSize: canvasFrame.size)
        }

        let canvas = makeCanvas(frame: CGRect(origin: .zero, size: canvasFrame.size), store: annotationStore)
        screenshot.addSubview(canvas)
        configureHighlightState(for: canvas, store: annotationStore, dense: dense)

        self.store = annotationStore
        self.canvas = canvas

        toolbar.updateAnnotationCount(annotationStore.count)
        let toolbarFrame = CGRect(
            x: (bounds.width - toolbar.frame.width) / 2,
            y: 22,
            width: toolbar.frame.width,
            height: toolbar.frame.height
        )
        toolbar.frame = toolbarFrame
        addSubview(toolbar)

        statusPill.updateDimensions(width: Int(canvasFrame.width), height: Int(canvasFrame.height))
        statusPill.updateNoteCount(annotationStore.annotations.filter { !$0.noteText.isEmpty }.count)
        statusPill.frame.origin = CGPoint(x: (bounds.width - statusPill.frame.width) / 2, y: canvasFrame.maxY + 12)
        addSubview(statusPill)
    }

    private func buildFilmstripScene() {
        let images = [
            Self.makeCaptureImage(width: 320, height: 200, title: "Current", role: .observed, accent: DesignTokens.purpleLight, index: 0),
            Self.makeCaptureImage(width: 280, height: 200, title: "Target", role: .expected, accent: DesignTokens.setupGreen, index: 1),
            Self.makeCaptureImage(width: 300, height: 200, title: "Reference", role: .reference, accent: NSColor.systemBlue, index: 2),
        ]
        let session = CaptureSession(images: images)
        self.session = session

        let filmstrip = FilmstripGridView(frame: NSRect(x: 28, y: 74, width: bounds.width - 56, height: 252))
        addSubview(filmstrip)
        filmstrip.setImages(session.images, selectedIndex: 1)
        filmstripView = filmstrip

        let annotationStore = AnnotationStore()
        let overlay = makeCanvas(frame: filmstrip.imageAreaRect, store: annotationStore)
        overlay.frame.origin = filmstrip.imageAreaRect.origin
        overlay.imageIndexAtPoint = { [weak filmstrip] point in
            filmstrip?.imageIndexAtPoint(point) ?? 0
        }
        overlay.imageIDAtPoint = { [weak filmstrip, weak session] point in
            guard let filmstrip, let session else { return nil }
            return session.imageID(at: filmstrip.imageIndexAtPoint(point))
        }
        filmstrip.scrollableContentView.addSubview(overlay)

        Self.addFilmstripAnnotations(to: annotationStore, filmstrip: filmstrip, session: session)
        configureHighlightState(for: overlay, store: annotationStore, dense: true)

        self.store = annotationStore
        self.canvas = overlay

        toolbar.updateAnnotationCount(annotationStore.count)
        toolbar.frame.origin = CGPoint(x: (bounds.width - toolbar.frame.width) / 2, y: 18)
        addSubview(toolbar)

        statusPill.updateDimensions(width: Int(bounds.width - 56), height: Int(filmstrip.imageAreaRect.height))
        statusPill.updateNoteCount(annotationStore.annotations.filter { !$0.noteText.isEmpty }.count)
        statusPill.frame.origin = CGPoint(x: (bounds.width - statusPill.frame.width) / 2, y: filmstrip.frame.maxY + 10)
        addSubview(statusPill)
    }

    private func makeCanvas(frame: CGRect, store: AnnotationStore) -> CanvasView {
        let canvas = CanvasView(frame: frame, store: store)
        let selectTool = SelectTool()
        canvas.selectTool = selectTool
        canvas.activeTool = selectTool
        canvas.undoManager_ = UndoRedoManager(store: store)
        return canvas
    }

    private func configureHighlightState(for canvas: CanvasView, store: AnnotationStore, dense: Bool) {
        guard let hovered = store.annotations.dropFirst().first?.id else { return }
        let selected = store.annotations.last?.id ?? hovered
        canvas.marksLayer.hoveredId = hovered
        canvas.marksLayer.selectedId = selected
        store.select(id: selected)
        canvas.marksLayer.needsDisplay = true
        canvas.refreshNotePills()
        if dense {
            canvas.needsDisplay = true
        }
    }

    static func generateSampleImage(width: CGFloat, height: CGFloat, accent: NSColor) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()

        let gradient = NSGradient(
            starting: accent.withAlphaComponent(0.10),
            ending: NSColor.windowBackgroundColor.blended(withFraction: 0.12, of: accent) ?? accent.withAlphaComponent(0.16)
        )
        gradient?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 140)

        NSColor.controlBackgroundColor.setFill()
        NSRect(x: 0, y: height - 28, width: width, height: 28).fill()
        NSColor.separatorColor.setFill()
        NSRect(x: 0, y: height - 29, width: width, height: 1).fill()

        let dots: [(NSColor, CGFloat)] = [
            (NSColor.systemRed, 14),
            (NSColor.systemYellow, 28),
            (NSColor.systemGreen, 42),
        ]
        for (color, xOff) in dots {
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: xOff, y: height - 20, width: 8, height: 8)).fill()
        }

        let cardColor = accent.withAlphaComponent(0.12)
        for index in 0..<4 {
            let cardRect = NSRect(x: 22 + CGFloat(index % 2) * ((width - 66) / 2), y: height - 110 - CGFloat(index / 2) * 92, width: (width - 66) / 2, height: 72)
            cardColor.setFill()
            NSBezierPath(roundedRect: cardRect, xRadius: 10, yRadius: 10).fill()
            NSColor.separatorColor.setStroke()
            NSBezierPath(roundedRect: cardRect, xRadius: 10, yRadius: 10).stroke()
        }

        image.unlockFocus()
        return image
    }

    static func makeCaptureImage(width: CGFloat, height: CGFloat, title: String, role: ImageRole, accent: NSColor, index: Int) -> CaptureImage {
        let image = generateSampleImage(width: width, height: height, accent: accent)
        return CaptureImage(sourceImage: image, title: title, role: role, originalSize: image.size, index: index)
    }

}
#endif
