import AppKit

private struct AnnotationDragState {
    let index: Int
    let initialPoint: CGPoint
    var lastPoint: CGPoint
    var hasExceededThreshold: Bool
}

private final class ActiveBadgeView: NSView {
    var number: Int = 1 {
        didSet { needsDisplay = true }
    }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        Constants.annotationRed.setFill()
        NSBezierPath(ovalIn: rect).fill()

        let fontSize: CGFloat = number >= 10 ? 12 : 15
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .bold)
        let text = NSAttributedString(string: "\(number)", attributes: [
            .font: font,
            .foregroundColor: Constants.badgeTextColor
        ])
        let size = text.size()
        let x = floor(bounds.midX - (size.width / 2))
        let y = floor(bounds.midY - (size.height / 2) + (number >= 10 ? -0.5 : 0))
        text.draw(in: NSRect(x: x, y: y, width: ceil(size.width), height: ceil(size.height)))
    }
}

private final class FlippedContainerView: NSView {
    override var isFlipped: Bool { true }
}

private final class FlippedTextView: NSTextView {
    override var isFlipped: Bool { true }
}

class AnnotationCanvas: NSView, NSTextViewDelegate {
    private let noteHorizontalPadding: CGFloat = 12
    private let noteVerticalPadding: CGFloat = 10
    private let noteCornerRadius: CGFloat = 8
    private let noteMaxTextWidth: CGFloat = 176
    private let noteMinHeight: CGFloat = 30
    private let notePlaceholder = "Describe issue..."
    private let noteBadgeInset: CGFloat = 10

    var backgroundImage: NSImage? {
        didSet { needsDisplay = true }
    }
    var annotations: [Annotation] = [] {
        didSet {
            needsDisplay = true
            onAnnotationsChanged?()
        }
    }
    var currentStroke: [CGPoint]?
    var currentTool: AnnotationType = .freehand {
        didSet {
            needsDisplay = true
            window?.invalidateCursorRects(for: self)
            onToolChanged?(currentTool)
        }
    }
    var isToolArmed = false {
        didSet {
            guard isToolArmed != oldValue else { return }
            window?.invalidateCursorRects(for: self)
            onToolChanged?(currentTool)
        }
    }

    var onToolChanged: ((AnnotationType) -> Void)?
    var onAnnotationsChanged: (() -> Void)?

    // Inline text field state
    private var activeEditorContainer: NSView?
    private var activeTextView: NSTextView?
    private var activePlaceholderLabel: NSTextField?
    private var activeBadgeView: ActiveBadgeView?
    private var activeAnnotationIndex: Int?
    private var isActivatingTextField = false
    private var selectedAnnotationIndex: Int?
    private var hoveredBadgeIndex: Int? {
        didSet {
            guard hoveredBadgeIndex != oldValue else { return }
            needsDisplay = true
            window?.invalidateCursorRects(for: self)
            updateCursor()
        }
    }

    // In-progress shape preview
    private var shapeStartPoint: CGPoint?
    private var activeShapeTool: AnnotationType?
    private var trackingArea: NSTrackingArea?
    private var annotationDragState: AnnotationDragState?

    private let annotationDragThreshold: CGFloat = 4
    private let shapeHitTolerance: CGFloat = 12

    override var acceptsFirstResponder: Bool { true }

    var isEditingInlineText: Bool {
        activeTextView != nil
    }

    var activeEditingTextView: NSTextView? {
        activeTextView
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw background image scaled to fill
        if let image = backgroundImage {
            image.draw(in: bounds)
        }

        // Draw completed annotations
        for annotation in annotations {
            drawAnnotation(annotation)
        }

        // Draw in-progress stroke (freehand)
        if let stroke = currentStroke {
            drawFreehandStroke(points: stroke)
        }

        // Draw in-progress shape preview
        if let start = shapeStartPoint, let stroke = currentStroke, let end = stroke.last {
            switch activeShapeTool ?? currentTool {
            case .arrow:
                drawArrowPreview(from: start, to: end)
            case .circle:
                drawCirclePreview(center: start, edge: end)
            case .freehand:
                break
            }
        }

        // Draw badges on top of strokes
        for (index, annotation) in annotations.enumerated() {
            if index == hoveredBadgeIndex {
                drawBadgeHoverRing(at: annotation.startPoint)
            }
            if activeAnnotationIndex != index {
                drawNoteOverlay(for: annotation)
                drawBadge(number: annotation.number, at: annotation.startPoint)
            }
        }
    }

    private func drawAnnotation(_ annotation: Annotation) {
        switch annotation.type {
        case .freehand:
            drawFreehandStroke(points: annotation.points)
        case .arrow:
            guard annotation.points.count >= 2 else { return }
            drawArrow(from: annotation.points[0], to: annotation.points[1])
        case .circle:
            guard annotation.points.count >= 2 else { return }
            drawCircle(center: annotation.points[0], edge: annotation.points[1])
        }
    }

    private func drawFreehandStroke(points: [CGPoint]) {
        guard !points.isEmpty else { return }

        Constants.annotationRed.setStroke()
        let path = NSBezierPath()
        path.lineWidth = Constants.strokeWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        if points.count == 1 {
            // Pin drop — draw a small dot
            let dotRect = NSRect(
                x: points[0].x - Constants.strokeWidth,
                y: points[0].y - Constants.strokeWidth,
                width: Constants.strokeWidth * 2,
                height: Constants.strokeWidth * 2
            )
            let dot = NSBezierPath(ovalIn: dotRect)
            Constants.annotationRed.setFill()
            dot.fill()
            return
        }

        path.move(to: points[0])
        for point in points.dropFirst() {
            path.line(to: point)
        }
        path.stroke()
    }

    // MARK: - Arrow Drawing

    private func drawArrow(from start: CGPoint, to end: CGPoint) {
        Constants.annotationRed.setStroke()

        // Line
        let linePath = NSBezierPath()
        linePath.lineWidth = Constants.strokeWidth
        linePath.lineCapStyle = .round
        linePath.move(to: start)
        linePath.line(to: end)
        linePath.stroke()

        // Arrowhead
        drawArrowhead(at: end, from: start)
    }

    private func drawArrowPreview(from start: CGPoint, to end: CGPoint) {
        Constants.annotationRed.setStroke()

        let linePath = NSBezierPath()
        linePath.lineWidth = Constants.strokeWidth
        linePath.lineCapStyle = .round
        let pattern: [CGFloat] = [6, 4]
        linePath.setLineDash(pattern, count: 2, phase: 0)
        linePath.move(to: start)
        linePath.line(to: end)
        linePath.stroke()
        drawArrowhead(at: end, from: start, dashed: true)
    }

    private func drawArrowhead(at tip: CGPoint, from origin: CGPoint, dashed: Bool = false) {
        let headLength: CGFloat = 14
        let headWidth: CGFloat = 11
        let angle = atan2(tip.y - origin.y, tip.x - origin.x)

        let p1 = CGPoint(
            x: tip.x - headLength * cos(angle) + headWidth / 2 * sin(angle),
            y: tip.y - headLength * sin(angle) - headWidth / 2 * cos(angle)
        )
        let p2 = CGPoint(
            x: tip.x - headLength * cos(angle) - headWidth / 2 * sin(angle),
            y: tip.y - headLength * sin(angle) + headWidth / 2 * cos(angle)
        )

        let head = NSBezierPath()
        head.lineWidth = Constants.strokeWidth
        head.lineCapStyle = .round
        head.lineJoinStyle = .round
        if dashed {
            let pattern: [CGFloat] = [6, 4]
            head.setLineDash(pattern, count: 2, phase: 0)
        }
        head.move(to: p1)
        head.line(to: tip)
        head.line(to: p2)
        head.stroke()
    }

    // MARK: - Circle Drawing

    private func drawCircle(center: CGPoint, edge: CGPoint) {
        let radius = max(5, hypot(edge.x - center.x, edge.y - center.y))
        let rect = NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        Constants.annotationRed.setStroke()
        let path = NSBezierPath(ovalIn: rect)
        path.lineWidth = Constants.strokeWidth
        path.stroke()
    }

    private func drawCirclePreview(center: CGPoint, edge: CGPoint) {
        let radius = max(5, hypot(edge.x - center.x, edge.y - center.y))
        let rect = NSRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        Constants.annotationRed.setStroke()
        let path = NSBezierPath(ovalIn: rect)
        path.lineWidth = Constants.strokeWidth
        let pattern: [CGFloat] = [6, 4]
        path.setLineDash(pattern, count: 2, phase: 0)
        path.stroke()
    }

    // MARK: - Badge Drawing

    private func drawBadge(number: Int, at point: CGPoint) {
        let radius = Constants.badgeRadius
        let badgeRect = NSRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        // Red filled circle
        Constants.annotationRed.setFill()
        let circle = NSBezierPath(ovalIn: badgeRect)
        circle.fill()

        // White number text, smaller font for 2+ digits
        let isDoubleDigit = number >= 10
        let fontSize: CGFloat = isDoubleDigit ? 12 : 15
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .bold)
        let text = NSAttributedString(string: "\(number)", attributes: [
            .font: font,
            .foregroundColor: Constants.badgeTextColor
        ])
        let textSize = text.size()
        let descender = abs(font.descender)
        let baseY = badgeRect.midY - ((font.ascender - descender) / 2)
        let textOriginY = floor(baseY - descender)
        let textOriginX = floor(badgeRect.midX - (textSize.width / 2) + badgeOpticalOffsetX(for: number))
        let textRect = NSRect(
            x: textOriginX,
            y: textOriginY,
            width: ceil(textSize.width),
            height: ceil(textSize.height)
        )
        text.draw(in: textRect)
    }

    private func drawBadgeHoverRing(at point: CGPoint) {
        let radius = Constants.badgeHoverRingRadius
        let rect = NSRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        let ring = NSBezierPath(ovalIn: rect)
        ring.lineWidth = 2
        Constants.badgeHoverRingColor.setStroke()
        ring.stroke()
    }

    private func drawNoteOverlay(for annotation: Annotation) {
        let note = annotation.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }

        let rect = noteRect(for: annotation)
        let path = NSBezierPath(roundedRect: rect, xRadius: noteCornerRadius, yRadius: noteCornerRadius)
        Constants.inlineNoteBackgroundColor.withAlphaComponent(0.5).setFill()
        path.fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: Constants.inlineNoteTextColor.withAlphaComponent(0.5),
            .paragraphStyle: paragraphStyle
        ]

        let textRect = noteContentRect(for: rect)
        (note as NSString).draw(in: textRect, withAttributes: attributes)
    }

    // MARK: - Render Annotated Image

    func renderAnnotatedImage() -> NSImage {
        guard let bgImage = backgroundImage else {
            return NSImage(size: bounds.size)
        }

        // Zero annotations → return original unchanged
        guard !annotations.isEmpty else { return bgImage }

        let imageSize = bgImage.size

        // Create image at original resolution
        let result = NSImage(size: imageSize)
        result.lockFocus()

        // Draw background
        bgImage.draw(in: NSRect(origin: .zero, size: imageSize))

        // Scale factor: image-space / view-space
        let scaleX = imageSize.width / bounds.width
        let scaleY = imageSize.height / bounds.height

        // Apply scale transform so all drawing happens in image coordinates
        let transform = NSAffineTransform()
        transform.scaleX(by: scaleX, yBy: scaleY)
        transform.concat()

        // Draw annotations (uses view-space coordinates, scaled by transform)
        for annotation in annotations {
            drawAnnotation(annotation)
        }

        // Draw badges (need manual scale for font/circle sizing)
        for annotation in annotations {
            drawBadge(number: annotation.number, at: annotation.startPoint)
        }

        // Restore transform
        let inverse = NSAffineTransform()
        inverse.scaleX(by: 1.0 / scaleX, yBy: 1.0 / scaleY)
        inverse.concat()

        result.unlockFocus()
        return result
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        // Double-click on badge opens text field for editing
        if event.clickCount == 2 {
            handleDoubleClick(at: point)
            return
        }

        let clamped = clamp(point)
        if let noteIndex = noteAnnotationIndex(at: clamped) {
            selectedAnnotationIndex = noteIndex
            finalizeActiveTextField()
            showTextField(for: noteIndex)
            return
        }

        if let badgeIndex = badgeAnnotationIndex(near: clamped) {
            if activeAnnotationIndex == badgeIndex, let activeTextView {
                selectedAnnotationIndex = badgeIndex
                window?.makeFirstResponder(activeTextView)
                return
            }

            finalizeActiveTextField()
            selectedAnnotationIndex = badgeIndex
            annotationDragState = AnnotationDragState(
                index: badgeIndex,
                initialPoint: clamped,
                lastPoint: clamped,
                hasExceededThreshold: false
            )
            needsDisplay = true
            return
        }

        if let index = annotationIndex(at: clamped) {
            finalizeActiveTextField()
            selectedAnnotationIndex = index
            needsDisplay = true
            return
        }

        // Finalize any open text field first before starting a new annotation.
        finalizeActiveTextField()
        selectedAnnotationIndex = nil
        annotationDragState = nil

        guard isToolArmed else {
            needsDisplay = true
            return
        }

        activeShapeTool = currentTool
        let tool = activeShapeTool ?? currentTool
        switch tool {
        case .freehand:
            currentStroke = [clamped]
        case .arrow, .circle:
            shapeStartPoint = clamped
            currentStroke = [clamped]
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let clamped = clamp(point)

        if var dragState = annotationDragState {
            let movementFromStart = hypot(
                clamped.x - dragState.initialPoint.x,
                clamped.y - dragState.initialPoint.y
            )
            if !dragState.hasExceededThreshold {
                guard movementFromStart >= annotationDragThreshold else {
                    return
                }
                dragState.hasExceededThreshold = true
            }

            let delta = CGPoint(
                x: clamped.x - dragState.lastPoint.x,
                y: clamped.y - dragState.lastPoint.y
            )
            if dragState.index < annotations.count {
                annotations[dragState.index].translate(by: delta)
            }
            dragState.lastPoint = clamped
            annotationDragState = dragState
            needsDisplay = true
            return
        }

        let tool = activeShapeTool ?? currentTool

        switch tool {
        case .freehand:
            currentStroke?.append(clamped)
        case .arrow, .circle:
            // Update the last point for preview
            if currentStroke != nil {
                currentStroke = [shapeStartPoint ?? clamped, clamped]
            }
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let clamped = clamp(point)

        if let dragState = annotationDragState {
            selectedAnnotationIndex = dragState.index
            annotationDragState = nil
            if !dragState.hasExceededThreshold {
                DispatchQueue.main.async { [weak self] in
                    self?.showTextField(for: dragState.index)
                }
            }
            needsDisplay = true
            return
        }

        let tool = activeShapeTool ?? currentTool

        let annotation: Annotation
        switch tool {
        case .freehand:
            guard let stroke = currentStroke else { return }
            let finalPoints: [CGPoint]
            if stroke.count == 1 {
                finalPoints = stroke
            } else {
                finalPoints = stroke + [clamped]
            }
            annotation = Annotation(
                number: annotations.count + 1,
                type: .freehand,
                points: finalPoints
            )
        case .arrow:
            guard let start = shapeStartPoint else { return }
            guard isMeaningfulShape(from: start, to: clamped) else {
                resetInProgressShapeState()
                return
            }
            annotation = Annotation(
                number: annotations.count + 1,
                type: .arrow,
                points: [start, clamped]
            )
        case .circle:
            guard let center = shapeStartPoint else { return }
            guard isMeaningfulShape(from: center, to: clamped) else {
                resetInProgressShapeState()
                return
            }
            annotation = Annotation(
                number: annotations.count + 1,
                type: .circle,
                points: [center, clamped]
            )
        }

        annotations.append(annotation)
        resetInProgressShapeState()
        isToolArmed = false
        needsDisplay = true

        // Show inline text field for the new annotation
        let newAnnotationIndex = annotations.count - 1
        DispatchQueue.main.async { [weak self] in
            self?.showTextField(for: newAnnotationIndex)
        }
    }

    private func handleDoubleClick(at point: CGPoint) {
        if let index = annotationIndex(at: point) {
            selectedAnnotationIndex = index
            finalizeActiveTextField()
            showTextField(for: index)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        hoveredBadgeIndex = badgeAnnotationIndex(near: point)
    }

    override func mouseExited(with event: NSEvent) {
        hoveredBadgeIndex = nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: cursorForCurrentLocation())
    }

    // MARK: - Inline Text Field

    private func showTextField(for annotationIndex: Int) {
        guard annotationIndex >= 0 && annotationIndex < annotations.count else { return }
        let annotation = annotations[annotationIndex]
        let fieldRect = noteRect(for: annotation)
        let paragraphStyle = noteParagraphStyle()
        let container = FlippedContainerView(frame: fieldRect)
        container.wantsLayer = true
        container.layer?.backgroundColor = Constants.inlineNoteBackgroundColor.cgColor
        container.layer?.cornerRadius = noteCornerRadius
        container.layer?.masksToBounds = true

        let scrollView = NSScrollView(frame: container.bounds)
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.autoresizingMask = [.width, .height]

        let textRect = noteContentRect(for: container.bounds)
        let textView = FlippedTextView(frame: textRect)
        textView.drawsBackground = false
        textView.delegate = self
        textView.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        textView.textColor = Constants.inlineNoteTextColor
        textView.insertionPointColor = Constants.inlineNoteTextColor
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: textRect.width,
            height: .greatestFiniteMagnitude
        )
        textView.textContainer?.lineFragmentPadding = 0
        textView.maxSize = NSSize(width: textRect.width, height: .greatestFiniteMagnitude)
        textView.minSize = NSSize(width: textRect.width, height: 0)
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: Constants.inlineNoteTextColor,
            .paragraphStyle: paragraphStyle
        ]

        let placeholderLabel = NSTextField(labelWithString: notePlaceholder)
        placeholderLabel.frame = textRect
        placeholderLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        placeholderLabel.textColor = Constants.inlineNoteTextColor.withAlphaComponent(0.55)
        placeholderLabel.alignment = .left
        placeholderLabel.lineBreakMode = .byWordWrapping
        placeholderLabel.maximumNumberOfLines = 0
        placeholderLabel.autoresizingMask = [.width, .height]

        let badgeSize = Constants.badgeRadius * 2
        let badgeView = ActiveBadgeView(frame: NSRect(
            x: 0,
            y: 0,
            width: badgeSize,
            height: badgeSize
        ))
        badgeView.number = annotation.number
        badgeView.autoresizingMask = [.maxXMargin, .maxYMargin]

        let trimmedNote = annotation.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedNote.isEmpty {
            textView.string = ""
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
            textView.textStorage?.setAttributedString(NSAttributedString(
                string: annotation.note,
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: Constants.inlineNoteTextColor,
                    .paragraphStyle: paragraphStyle
                ]
            ))
        }

        scrollView.documentView = textView
        container.addSubview(scrollView)
        container.addSubview(placeholderLabel)
        container.addSubview(badgeView)

        // Remove any existing text field
        activeEditorContainer?.removeFromSuperview()

        activeEditorContainer = container
        activeTextView = textView
        activePlaceholderLabel = placeholderLabel
        activeBadgeView = badgeView
        activeAnnotationIndex = annotationIndex
        isActivatingTextField = true
        isToolArmed = false

        addSubview(container)

        DispatchQueue.main.async { [weak self, weak textView] in
            guard let self, let textView, self.activeTextView === textView else { return }
            self.window?.makeKeyAndOrderFront(nil)
            let becameFirstResponder = self.window?.makeFirstResponder(textView) ?? false
            if becameFirstResponder, !textView.string.isEmpty {
                textView.setSelectedRange(NSRange(location: 0, length: textView.string.count))
            }
            self.resizeActiveEditor()
            self.isActivatingTextField = false
        }
    }

    func finalizeActiveTextField() {
        finalizeActiveTextField(matching: activeTextView)
    }

    private func finalizeActiveTextField(matching matchingView: NSTextView?) {
        guard let textView = activeTextView, let container = activeEditorContainer, let index = activeAnnotationIndex else { return }
        if let matchingView, matchingView !== textView {
            return
        }
        if index < annotations.count {
            annotations[index].note = textView.string
        }
        container.removeFromSuperview()
        activeEditorContainer = nil
        activeTextView = nil
        activePlaceholderLabel = nil
        activeBadgeView = nil
        activeAnnotationIndex = nil
        needsDisplay = true
    }

    private func cancelActiveTextField() {
        cancelActiveTextField(matching: activeTextView)
    }

    private func cancelActiveTextField(matching matchingView: NSTextView?) {
        guard let textView = activeTextView, let container = activeEditorContainer, let index = activeAnnotationIndex else { return }
        if let matchingView, matchingView !== textView {
            return
        }
        if index < annotations.count {
            annotations[index].note = ""
        }
        container.removeFromSuperview()
        activeEditorContainer = nil
        activeTextView = nil
        activePlaceholderLabel = nil
        activeBadgeView = nil
        activeAnnotationIndex = nil
        needsDisplay = true
    }

    // MARK: - NSTextViewDelegate

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            // Enter key — finalize
            finalizeActiveTextField()
            window?.makeFirstResponder(self)
            return true
        }
        if commandSelector == #selector(cancelOperation(_:)) {
            // Escape key — cancel
            cancelActiveTextField()
            window?.makeFirstResponder(self)
            return true
        }
        return false
    }

    func textDidEndEditing(_ notification: Notification) {
        guard let endedView = notification.object as? NSTextView else { return }
        guard endedView === activeTextView else { return }
        guard !isActivatingTextField else { return }
        DispatchQueue.main.async { [weak self] in
            self?.finalizeActiveTextField()
        }
    }

    func textDidChange(_ notification: Notification) {
        guard let changedView = notification.object as? NSTextView else { return }
        guard changedView === activeTextView else { return }
        changedView.textStorage?.addAttributes(
            [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: Constants.inlineNoteTextColor,
                .paragraphStyle: noteParagraphStyle()
            ],
            range: NSRange(location: 0, length: changedView.string.utf16.count)
        )
        updatePlaceholderVisibility()
        resizeActiveEditor()
    }

    // MARK: - Undo

    func undoLastAnnotation() {
        guard !annotations.isEmpty else { return }
        finalizeActiveTextField()
        annotations.removeLast()
        for i in annotations.indices {
            annotations[i].number = i + 1
        }
        selectedAnnotationIndex = nil
        needsDisplay = true
    }

    // MARK: - Delete

    func deleteAnnotation(at index: Int) {
        guard index >= 0 && index < annotations.count else { return }
        finalizeActiveTextField()
        annotations.remove(at: index)
        for i in annotations.indices {
            annotations[i].number = i + 1
        }
        selectedAnnotationIndex = nil
        needsDisplay = true
    }

    // MARK: - Right-click context menu

    override func rightMouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if let index = annotationIndex(at: point) {
            selectedAnnotationIndex = index
            let annotation = annotations[index]
                let menu = NSMenu()
                let item = NSMenuItem(
                    title: "Delete annotation #\(annotation.number)",
                    action: #selector(deleteAnnotationFromMenu(_:)),
                    keyEquivalent: ""
                )
                item.tag = index
                item.target = self
                menu.addItem(item)
                NSMenu.popUpContextMenu(menu, with: event, for: self)
                return
        }

        super.rightMouseDown(with: event)
    }

    @objc private func deleteAnnotationFromMenu(_ sender: NSMenuItem) {
        deleteAnnotation(at: sender.tag)
    }

    // MARK: - Keyboard

    override func keyDown(with event: NSEvent) {
        if isEditingInlineText {
            if handleInlineEditorKeyEvent(event) {
                return
            }
            super.keyDown(with: event)
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""

        if modifiers == [] {
            switch characters {
            case "1":
                currentTool = .freehand
                isToolArmed = true
                return
            case "2":
                currentTool = .arrow
                isToolArmed = true
                return
            case "3":
                currentTool = .circle
                isToolArmed = true
                return
            default:
                break
            }
        }

        if modifiers == [.command], characters == "z" {
            undoLastAnnotation()
            return
        }

        if modifiers == [], event.keyCode == 51 || event.keyCode == 117 {
            guard let selectedAnnotationIndex else {
                NSSound.beep()
                return
            }
            deleteAnnotation(at: selectedAnnotationIndex)
            return
        }

        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if isEditingInlineText, handleInlineEditorKeyEvent(event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    // MARK: - Helpers

    private func badgeAnnotationIndex(near point: CGPoint) -> Int? {
        for (index, annotation) in annotations.enumerated().reversed() {
            let distance = hypot(annotation.startPoint.x - point.x, annotation.startPoint.y - point.y)
            if distance <= Constants.badgeHitRadius {
                return index
            }
        }
        return nil
    }

    private func annotationIndex(at point: CGPoint) -> Int? {
        for (index, annotation) in annotations.enumerated().reversed() {
            if annotationContainsPoint(annotation, point: point) {
                return index
            }
        }
        return nil
    }

    private func noteAnnotationIndex(at point: CGPoint) -> Int? {
        for (index, annotation) in annotations.enumerated().reversed() {
            let note = annotation.note.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !note.isEmpty else { continue }
            if noteRect(for: annotation).contains(point) {
                return index
            }
        }
        return nil
    }

    private func annotationContainsPoint(_ annotation: Annotation, point: CGPoint) -> Bool {
        if badgeContainsPoint(annotation.startPoint, point: point) {
            return true
        }

        let note = annotation.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty && noteRect(for: annotation).contains(point) {
            return true
        }

        switch annotation.type {
        case .freehand:
            return polylineContainsPoint(annotation.points, point: point, tolerance: shapeHitTolerance)
        case .arrow:
            guard annotation.points.count >= 2 else { return false }
            return lineSegmentContainsPoint(
                start: annotation.points[0],
                end: annotation.points[1],
                point: point,
                tolerance: shapeHitTolerance
            )
        case .circle:
            guard annotation.points.count >= 2 else { return false }
            let center = annotation.points[0]
            let edge = annotation.points[1]
            let radius = max(5, hypot(edge.x - center.x, edge.y - center.y))
            let distance = hypot(point.x - center.x, point.y - center.y)
            return abs(distance - radius) <= shapeHitTolerance
        }
    }

    private func badgeContainsPoint(_ badgeCenter: CGPoint, point: CGPoint) -> Bool {
        hypot(badgeCenter.x - point.x, badgeCenter.y - point.y) <= Constants.badgeHitRadius
    }

    private func noteRect(for annotation: Annotation) -> NSRect {
        let note = annotation.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? notePlaceholder
            : annotation.note
        let paragraphStyle = noteParagraphStyle()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .paragraphStyle: paragraphStyle
        ]

        let minTextWidth = ceil((notePlaceholder as NSString).size(withAttributes: attributes).width)
        let measuredSingleLineWidth = ceil((note as NSString).size(withAttributes: attributes).width)
        let textWidth = min(max(minTextWidth, measuredSingleLineWidth), noteMaxTextWidth)
        let constraintRect = NSRect(
            x: 0,
            y: 0,
            width: textWidth,
            height: .greatestFiniteMagnitude
        )
        let measuredRect = (note as NSString).boundingRect(
            with: constraintRect.size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )
        let leftInset = noteHorizontalPadding + Constants.badgeRadius + noteBadgeInset
        let width = textWidth + leftInset + noteHorizontalPadding
        let height = max(noteMinHeight, ceil(measuredRect.height) + (noteVerticalPadding * 2) + Constants.badgeRadius)
        let x = annotation.startPoint.x - Constants.badgeRadius
        let y = annotation.startPoint.y - height + Constants.badgeRadius

        return NSRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
    }

    private func resizeActiveEditor() {
        guard
            let activeEditorContainer,
            let activeTextView,
            let activeAnnotationIndex,
            activeAnnotationIndex < annotations.count
        else {
            return
        }
        var annotation = annotations[activeAnnotationIndex]
        annotation.note = activeTextView.string
        let frame = noteRect(for: annotation)
        activeEditorContainer.frame = frame
        if let scrollView = activeEditorContainer.subviews.first as? NSScrollView {
            scrollView.frame = activeEditorContainer.bounds
            let textRect = noteContentRect(for: activeEditorContainer.bounds)
            activeTextView.frame = textRect
            activeTextView.textContainer?.containerSize = NSSize(width: textRect.width, height: .greatestFiniteMagnitude)
            activeTextView.maxSize = NSSize(width: textRect.width, height: .greatestFiniteMagnitude)
            activeTextView.minSize = NSSize(width: textRect.width, height: 0)
        }
        activePlaceholderLabel?.frame = noteContentRect(for: activeEditorContainer.bounds)
        if let activeBadgeView {
            let badgeSize = Constants.badgeRadius * 2
            activeBadgeView.frame = NSRect(
                x: 0,
                y: 0,
                width: badgeSize,
                height: badgeSize
            )
        }
        updatePlaceholderVisibility()
    }

    private func noteParagraphStyle() -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        return paragraphStyle
    }

    private func noteContentRect(for rect: NSRect) -> NSRect {
        let leftInset = noteHorizontalPadding + (Constants.badgeRadius * 2) + noteBadgeInset + 4
        let topInset = noteVerticalPadding + Constants.badgeRadius + 6
        return NSRect(
            x: leftInset,
            y: topInset,
            width: rect.width - leftInset - noteHorizontalPadding,
            height: rect.height - topInset - noteVerticalPadding
        )
    }

    private func badgeOpticalOffsetX(for number: Int) -> CGFloat {
        if number == 3 {
            return -0.8
        }
        if number >= 10 {
            return -0.45
        }
        return 0
    }

    private func updatePlaceholderVisibility() {
        activePlaceholderLabel?.isHidden = !(activeTextView?.string.isEmpty ?? true)
    }

    private func handleInlineEditorKeyEvent(_ event: NSEvent) -> Bool {
        guard let activeTextView else { return false }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""

        if modifiers == [.command], characters == "z" {
            activeTextView.undoManager?.undo()
            return true
        }

        if modifiers == [], event.keyCode == 51 {
            activeTextView.deleteBackward(nil)
            return true
        }

        if modifiers == [], event.keyCode == 117 {
            activeTextView.deleteForward(nil)
            return true
        }

        return false
    }

    private func polylineContainsPoint(_ points: [CGPoint], point: CGPoint, tolerance: CGFloat) -> Bool {
        guard !points.isEmpty else { return false }
        if points.count == 1 {
            return hypot(points[0].x - point.x, points[0].y - point.y) <= tolerance
        }

        for segmentStartIndex in 0..<(points.count - 1) {
            if lineSegmentContainsPoint(
                start: points[segmentStartIndex],
                end: points[segmentStartIndex + 1],
                point: point,
                tolerance: tolerance
            ) {
                return true
            }
        }

        return false
    }

    private func lineSegmentContainsPoint(start: CGPoint, end: CGPoint, point: CGPoint, tolerance: CGFloat) -> Bool {
        distanceFromPoint(point, toLineSegmentFrom: start, to: end) <= tolerance
    }

    private func distanceFromPoint(_ point: CGPoint, toLineSegmentFrom start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y

        if dx == 0 && dy == 0 {
            return hypot(point.x - start.x, point.y - start.y)
        }

        let t = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / (dx * dx + dy * dy)))
        let projection = CGPoint(x: start.x + t * dx, y: start.y + t * dy)
        return hypot(point.x - projection.x, point.y - projection.y)
    }

    private func cursorForCurrentLocation() -> NSCursor {
        if isEditingInlineText {
            return .iBeam
        }
        if hoveredBadgeIndex != nil {
            return .pointingHand
        }
        return isToolArmed ? .crosshair : .arrow
    }

    private func updateCursor() {
        cursorForCurrentLocation().set()
    }

    private func clamp(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: max(0, min(point.x, bounds.width)),
            y: max(0, min(point.y, bounds.height))
        )
    }

    private func isMeaningfulShape(from start: CGPoint, to end: CGPoint) -> Bool {
        hypot(end.x - start.x, end.y - start.y) >= 4
    }

    private func resetInProgressShapeState() {
        currentStroke = nil
        shapeStartPoint = nil
        activeShapeTool = nil
    }
}
