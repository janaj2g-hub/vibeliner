import AppKit

class AnnotationCanvas: NSView, NSTextFieldDelegate {
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

    var onToolChanged: ((AnnotationType) -> Void)?
    var onAnnotationsChanged: (() -> Void)?

    // Inline text field state
    private var activeTextField: NSTextField?
    private var activeAnnotationIndex: Int?
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

    override var acceptsFirstResponder: Bool { true }

    var isEditingInlineText: Bool {
        activeTextField != nil
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
            drawBadge(number: annotation.number, at: annotation.startPoint)
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
        Constants.annotationRed.setFill()

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
    }

    private func drawArrowhead(at tip: CGPoint, from origin: CGPoint) {
        let headLength: CGFloat = 10
        let headWidth: CGFloat = 8
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
        head.move(to: tip)
        head.line(to: p1)
        head.line(to: p2)
        head.close()
        head.fill()
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

        Constants.badgeOutlineColor.setStroke()
        circle.lineWidth = 1
        circle.stroke()

        // White number text, smaller font for 2+ digits
        let fontSize: CGFloat = number >= 10 ? 12 : 14
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        let text = "\(number)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: Constants.badgeTextColor
        ]
        let textSize = text.size(withAttributes: attrs)
        let textPoint = CGPoint(
            x: point.x - textSize.width / 2,
            y: point.y - textSize.height / 2
        )
        text.draw(at: textPoint, withAttributes: attrs)
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
        if let index = annotationIndex(near: clamped) {
            if activeAnnotationIndex == index, let activeTextField {
                window?.makeFirstResponder(activeTextField)
                return
            }

            finalizeActiveTextField()
            selectedAnnotationIndex = index
            showTextField(for: index)
            return
        }

        // Finalize any open text field first before starting a new annotation.
        finalizeActiveTextField()
        selectedAnnotationIndex = nil

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
        needsDisplay = true

        // Show inline text field for the new annotation
        let newAnnotationIndex = annotations.count - 1
        DispatchQueue.main.async { [weak self] in
            self?.showTextField(for: newAnnotationIndex)
        }
    }

    private func handleDoubleClick(at point: CGPoint) {
        if let index = annotationIndex(near: point) {
            selectedAnnotationIndex = index
            finalizeActiveTextField()
            showTextField(for: index)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        hoveredBadgeIndex = annotationIndex(near: point)
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
        let badgeCenter = annotation.startPoint

        let fieldWidth: CGFloat = 250
        let fieldHeight: CGFloat = 24
        let offset: CGFloat = 30

        // Position: right of badge, or left if near right edge
        let xPos: CGFloat
        if badgeCenter.x + offset + fieldWidth > bounds.width - 10 {
            xPos = badgeCenter.x - offset - fieldWidth
        } else {
            xPos = badgeCenter.x + offset
        }
        let yPos = badgeCenter.y - fieldHeight / 2

        let textField = NSTextField(frame: NSRect(x: xPos, y: yPos, width: fieldWidth, height: fieldHeight))
        textField.font = NSFont.systemFont(ofSize: 12)
        textField.textColor = Constants.inlineNoteTextColor
        textField.backgroundColor = Constants.inlineNoteBackgroundColor
        textField.isBordered = false
        textField.isBezeled = false
        textField.focusRingType = .none
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 5
        textField.layer?.masksToBounds = true
        textField.placeholderString = "Describe issue..."
        textField.delegate = self
        textField.stringValue = annotation.note

        // Remove any existing text field
        activeTextField?.removeFromSuperview()

        activeTextField = textField
        activeAnnotationIndex = annotationIndex

        addSubview(textField)

        DispatchQueue.main.async { [weak self, weak textField] in
            guard let self, let textField, self.activeTextField === textField else { return }
            self.window?.makeFirstResponder(textField)
        }
    }

    func finalizeActiveTextField() {
        finalizeActiveTextField(matching: activeTextField)
    }

    private func finalizeActiveTextField(matching matchingField: NSTextField?) {
        guard let textField = activeTextField, let index = activeAnnotationIndex else { return }
        if let matchingField, matchingField !== textField {
            return
        }
        if index < annotations.count {
            annotations[index].note = textField.stringValue
        }
        textField.removeFromSuperview()
        activeTextField = nil
        activeAnnotationIndex = nil
        needsDisplay = true
    }

    private func cancelActiveTextField() {
        cancelActiveTextField(matching: activeTextField)
    }

    private func cancelActiveTextField(matching matchingField: NSTextField?) {
        guard let textField = activeTextField, let index = activeAnnotationIndex else { return }
        if let matchingField, matchingField !== textField {
            return
        }
        if index < annotations.count {
            annotations[index].note = ""
        }
        textField.removeFromSuperview()
        activeTextField = nil
        activeAnnotationIndex = nil
        needsDisplay = true
    }

    // MARK: - NSTextFieldDelegate

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
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

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let endedField = obj.object as? NSTextField else { return }
        guard endedField === activeTextField else { return }
        // Loss of focus — finalize
        DispatchQueue.main.async { [weak self] in
            self?.finalizeActiveTextField()
        }
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

        if let index = annotationIndex(near: point) {
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
            super.keyDown(with: event)
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let characters = event.charactersIgnoringModifiers?.lowercased() ?? ""

        if modifiers == [] {
            switch characters {
            case "1":
                currentTool = .freehand
                return
            case "2":
                currentTool = .arrow
                return
            case "3":
                currentTool = .circle
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

    // MARK: - Helpers

    private func annotationIndex(near point: CGPoint) -> Int? {
        for (index, annotation) in annotations.enumerated() {
            let distance = hypot(annotation.startPoint.x - point.x, annotation.startPoint.y - point.y)
            if distance <= Constants.badgeHitRadius {
                return index
            }
        }
        return nil
    }

    private func cursorForCurrentLocation() -> NSCursor {
        if hoveredBadgeIndex != nil {
            return .pointingHand
        }
        return .crosshair
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
