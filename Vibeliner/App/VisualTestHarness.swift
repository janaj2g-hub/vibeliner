import AppKit

/// Debug facility that opens a test window with sample annotations, toolbar, and note pill states.
/// Launch with: open Vibeliner.app --args --visual-test
final class VisualTestHarness {

    private var window: NSWindow?

    func show() {
        let canvasW: CGFloat = 640
        let canvasH: CGFloat = 360
        let toolbarGap: CGFloat = 56  // gap between canvas top and toolbar
        let bottomGap: CGFloat = 80   // room for status pill + note state row
        let noteStateRowH: CGFloat = 60
        let topPadding: CGFloat = 20  // room above toolbar
        let totalW: CGFloat = max(canvasW + 40, 760)
        let totalH: CGFloat = canvasH + toolbarGap + bottomGap + noteStateRowH + topPadding

        let win = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: totalW, height: totalH),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Vibeliner Visual Test"
        win.isReleasedWhenClosed = false
        win.backgroundColor = NSColor(red: 30/255, green: 30/255, blue: 35/255, alpha: 1)

        let container = NSView(frame: NSRect(origin: .zero, size: win.contentView!.frame.size))
        win.contentView = container

        // --- Generate sample screenshot image (gradient) ---
        let sampleImage = generateSampleImage(width: canvasW, height: canvasH)

        // --- Screenshot canvas (same as production) ---
        let canvasView = ScreenshotCanvasView(image: sampleImage)
        let canvasX = (totalW - canvasW) / 2
        let canvasY = noteStateRowH + bottomGap
        canvasView.frame = NSRect(x: canvasX, y: canvasY, width: canvasW, height: canvasH)
        container.addSubview(canvasView)

        // --- Annotation store with sample annotations ---
        let store = AnnotationStore()
        addSampleAnnotations(to: store)

        // --- Canvas overlay (marks + notes layers, same as production) ---
        let canvas = CanvasView(frame: NSRect(x: 0, y: 0, width: canvasW, height: canvasH), store: store)
        canvasView.addSubview(canvas)

        // Force render a hovered annotation (annotation 2 = arrow)
        let arrowId = store.annotations[1].id
        canvas.marksLayer.hoveredId = arrowId

        // Force render selected state on rectangle (annotation 3)
        let rectId = store.annotations[2].id
        canvas.marksLayer.selectedId = rectId
        store.select(id: rectId)

        canvas.marksLayer.needsDisplay = true
        canvas.refreshNotePills()

        // --- Production toolbar ---
        let toolbar = ToolbarView()
        toolbar.updateAnnotationCount(store.count)
        let toolbarX = (totalW - toolbar.frame.width) / 2
        let toolbarY = canvasY + canvasH + (toolbarGap - DesignTokens.toolbarHeight) / 2
        toolbar.setFrameOrigin(NSPoint(x: toolbarX, y: toolbarY))
        container.addSubview(toolbar)

        // --- Status pill (same as production) ---
        let statusPill = StatusPillView()
        statusPill.updateDimensions(width: Int(canvasW), height: Int(canvasH))
        statusPill.updateNoteCount(store.count)
        let pillX = (totalW - statusPill.frame.width) / 2
        let pillY = canvasY - 32
        statusPill.setFrameOrigin(NSPoint(x: pillX, y: pillY))
        container.addSubview(statusPill)

        // --- Note pill state demo row ---
        let stateRowY: CGFloat = 14
        let states: [(String, NotePillRenderer.NotePillState)] = [
            ("default state", .default),
            ("hover state", .hover),
            ("selected state", .selected),
            ("editing state", .editing),
        ]
        var sx: CGFloat = 20
        for (text, state) in states {
            let pill = NotePillRenderer.createNotePillForTest(number: 1, text: text, state: state)
            pill.frame.origin = NSPoint(x: sx, y: stateRowY)
            container.addSubview(pill)
            sx += pill.frame.width + 16
        }

        // Label for the row
        let stateLabel = NSTextField(labelWithString: "Note pill states:")
        stateLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        stateLabel.textColor = NSColor(white: 1, alpha: 0.4)
        stateLabel.frame = NSRect(x: 20, y: stateRowY + 34, width: 200, height: 16)
        container.addSubview(stateLabel)

        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = win

        // Auto-save screenshot after a short delay for layout to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.saveScreenshot()
        }
    }

    /// Renders the window content view to a PNG file at /tmp/vibeliner_test.png
    func saveScreenshot() {
        guard let win = window, let contentView = win.contentView else { return }

        let size = contentView.bounds.size
        guard let bitmapRep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) else {
            NSLog("Failed to create bitmap rep")
            return
        }
        contentView.cacheDisplay(in: contentView.bounds, to: bitmapRep)

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            NSLog("Failed to create PNG data")
            return
        }

        let outputPath = "/tmp/vibeliner_test.png"
        do {
            try pngData.write(to: URL(fileURLWithPath: outputPath))
            NSLog("Visual test screenshot saved to \(outputPath) (\(Int(size.width))×\(Int(size.height)))")
        } catch {
            NSLog("Failed to save screenshot: \(error)")
        }
    }

    // MARK: - Sample data

    private func generateSampleImage(width: CGFloat, height: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()

        // Light gray gradient background mimicking an app screenshot
        let gradient = NSGradient(starting: NSColor(white: 0.96, alpha: 1), ending: NSColor(white: 0.92, alpha: 1))
        gradient?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 135)

        // Fake title bar
        NSColor(white: 0.94, alpha: 1).setFill()
        NSRect(x: 0, y: height - 28, width: width, height: 28).fill()
        NSColor(white: 0.88, alpha: 1).setFill()
        NSRect(x: 0, y: height - 29, width: width, height: 1).fill()

        // Traffic lights
        let dots: [(NSColor, CGFloat)] = [
            (NSColor(red: 1, green: 0.373, blue: 0.341, alpha: 1), 14),
            (NSColor(red: 0.996, green: 0.737, blue: 0.18, alpha: 1), 28),
            (NSColor(red: 0.157, green: 0.784, blue: 0.251, alpha: 1), 42),
        ]
        for (color, xOff) in dots {
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: xOff, y: height - 20, width: 8, height: 8)).fill()
        }

        // Placeholder content lines
        NSColor(white: 0.85, alpha: 1).setFill()
        for (i, w) in [220.0, 180.0, 280.0, 160.0, 240.0].enumerated() {
            NSRect(x: 20, y: height - 60 - CGFloat(i) * 18, width: w, height: 7).fill()
        }

        // Placeholder cards
        for i in 0..<3 {
            let cardX = 20 + CGFloat(i) * 194
            let cardRect = NSRect(x: cardX, y: height - 250, width: 180, height: 80)
            NSColor.white.setFill()
            NSBezierPath(roundedRect: cardRect, xRadius: 8, yRadius: 8).fill()
            NSColor(white: 0.9, alpha: 1).setStroke()
            NSBezierPath(roundedRect: cardRect, xRadius: 8, yRadius: 8).stroke()
        }

        image.unlockFocus()
        return image
    }

    private func smoothPoints(_ pts: [CGPoint], passes: Int) -> [CGPoint] {
        var result = pts
        for _ in 0..<passes {
            var smoothed = [result[0]]
            for i in 1..<result.count - 1 {
                smoothed.append(CGPoint(
                    x: result[i - 1].x * 0.25 + result[i].x * 0.5 + result[i + 1].x * 0.25,
                    y: result[i - 1].y * 0.25 + result[i].y * 0.5 + result[i + 1].y * 0.25
                ))
            }
            smoothed.append(result[result.count - 1])
            result = smoothed
        }
        return result
    }

    private func addSampleAnnotations(to store: AnnotationStore) {
        // Pin at (150, 120) — in flipped coordinates for the canvas, y increases downward in our model
        let pin = Annotation(
            type: .pin,
            number: 0,
            noteText: "padding too tight",
            position: .pin(tip: CGPoint(x: 150, y: 120)),
            badgePosition: CGPoint(x: 150, y: 120 - DesignTokens.stakeLength - DesignTokens.badgeDiameter / 2)
        )
        _ = store.add(pin)

        // Arrow from (300, 80) to (450, 180)
        let arrow = Annotation(
            type: .arrow,
            number: 0,
            noteText: "align to grid",
            position: .arrow(start: CGPoint(x: 300, y: 80), end: CGPoint(x: 450, y: 180)),
            badgePosition: CGPoint(x: 300, y: 80)
        )
        _ = store.add(arrow)

        // Rectangle from (80, 220) to (250, 310)
        let rectOrigin = CGPoint(x: 80, y: 220)
        let rectSize = CGSize(width: 170, height: 90)
        let rect = Annotation(
            type: .rectangle,
            number: 0,
            noteText: "increase height",
            position: .rectangle(origin: rectOrigin, size: rectSize),
            badgePosition: rectOrigin
        )
        _ = store.add(rect)

        // Circle centered at (450, 280) radius 50
        let circCenter = CGPoint(x: 450, y: 280)
        let circRadius: CGFloat = 50
        // Badge on perimeter (right side)
        let circleBadge = CGPoint(x: circCenter.x + circRadius, y: circCenter.y)
        let circle = Annotation(
            type: .circle,
            number: 0,
            noteText: "wrong icon",
            position: .circle(center: circCenter, radius: circRadius),
            badgePosition: circleBadge
        )
        _ = store.add(circle)

        // Freehand stroke — more points for realistic smooth curve
        let rawFreehandPoints: [CGPoint] = [
            CGPoint(x: 500, y: 100),
            CGPoint(x: 505, y: 108),
            CGPoint(x: 512, y: 118),
            CGPoint(x: 520, y: 130),
            CGPoint(x: 528, y: 126),
            CGPoint(x: 535, y: 118),
            CGPoint(x: 542, y: 112),
            CGPoint(x: 550, y: 110),
            CGPoint(x: 558, y: 115),
            CGPoint(x: 565, y: 125),
            CGPoint(x: 572, y: 133),
            CGPoint(x: 580, y: 140),
            CGPoint(x: 588, y: 136),
            CGPoint(x: 595, y: 128),
            CGPoint(x: 600, y: 120)
        ]
        // Smooth them like the production FreehandTool does
        let freehandPoints = smoothPoints(rawFreehandPoints, passes: 3)
        let freehand = Annotation(
            type: .freehand,
            number: 0,
            noteText: "this area is off",
            position: .freehand(points: freehandPoints),
            badgePosition: freehandPoints.first!
        )
        _ = store.add(freehand)
    }
}
