import AppKit

/// VIB-297: Renders a filmstrip of images into a single stitched horizontal strip PNG.
/// Reuses LayoutCalculator for layout computation. Title pills baked in for 2+ images.
final class CompositeStitcher {

    private static let maxExportWidth: CGFloat = 4800  // Wider limit for horizontal strips
    private static let exportRowHeight: CGFloat = 400   // Fixed row height for export
    private static let exportScale: CGFloat = 2         // Retina

    private static let pinRenderer = PinRenderer()
    private static let arrowRenderer = ArrowRenderer()
    private static let rectangleRenderer = RectangleRenderer()
    private static let circleRenderer = CircleRenderer()
    private static let freehandRenderer = FreehandRenderer()

    /// Stitch multiple images into a single horizontal strip composite.
    /// - Parameters:
    ///   - images: Ordered list of capture images with titles and roles.
    ///   - annotations: All annotations to bake into the export.
    ///   - canvasSize: The editor canvas size (for scaling annotations).
    ///   - exportWidth: Ignored for horizontal strip — width is computed from content.
    /// - Returns: The stitched NSImage, or nil if images is empty.
    static func stitch(
        images: [CaptureImage],
        annotations: [Annotation],
        canvasSize: CGSize,
        exportWidth: CGFloat? = nil
    ) -> NSImage? {
        guard !images.isEmpty else { return nil }

        // For single image, delegate to existing exporter behavior
        if images.count == 1, let single = images.first {
            return ScreenshotExporter.exportAnnotatedScreenshot(
                original: single.sourceImage,
                annotations: annotations,
                canvasSize: canvasSize
            )
        }

        // Multi-image horizontal strip
        let gap = DesignTokens.filmstripGap
        let padding = DesignTokens.filmstripPadding
        let pillH = FilmCellView.pillAreaHeight
        let rowHeight = exportRowHeight

        let sizes = images.map { $0.originalSize }
        let (frames, totalContentWidth) = LayoutCalculator.computeFrames(
            imageSizes: sizes,
            rowHeight: rowHeight,
            gap: gap,
            titlePillTotalHeight: pillH
        )

        let compositeWidth = totalContentWidth + padding * 2
        let compositeHeight = rowHeight + pillH + padding * 2
        let compositeSize = NSSize(width: compositeWidth, height: compositeHeight)

        let image = NSImage(size: compositeSize)
        image.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        // Clear background (transparent)
        ctx.clear(CGRect(origin: .zero, size: compositeSize))

        // Draw each cell — horizontal strip layout
        for (i, layoutFrame) in frames.enumerated() where i < images.count {
            let captureImage = images[i]
            let cellX = padding + layoutFrame.origin.x
            // NSImage coordinate system: Y=0 at bottom
            let cellY = padding

            // Image area is below the title pill area
            let imageRect = NSRect(
                x: cellX,
                y: cellY,
                width: layoutFrame.size.width,
                height: rowHeight
            )

            // Draw screenshot
            captureImage.sourceImage.draw(in: imageRect)

            // Draw title pill (baked in above the image)
            drawExportPill(
                ctx: ctx,
                title: captureImage.title,
                role: captureImage.role,
                cellX: cellX,
                cellWidth: layoutFrame.size.width,
                pillY: cellY + rowHeight,
                pillHeight: DesignTokens.titlePillHeight
            )
        }

        image.unlockFocus()
        return image
    }

    /// Save the composite to disk as `composite.png`.
    static func saveComposite(
        to folder: URL,
        images: [CaptureImage],
        annotations: [Annotation],
        canvasSize: CGSize
    ) {
        guard images.count >= 2,
              let composite = stitch(images: images, annotations: annotations, canvasSize: canvasSize) else {
            return
        }

        let fileURL = folder.appendingPathComponent("composite.png")
        let tempURL = folder.appendingPathComponent(".composite.png.tmp")
        _ = composite.savePNG(to: tempURL)
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.moveItem(at: tempURL, to: fileURL)
    }

    // MARK: - Title pill rendering

    private static func drawExportPill(
        ctx: CGContext,
        title: String,
        role: ImageRole,
        cellX: CGFloat,
        cellWidth: CGFloat,
        pillY: CGFloat,
        pillHeight: CGFloat
    ) {
        let pillW = min(cellWidth - 8, max(100, cellWidth * 0.85))
        let pillX = cellX + (cellWidth - pillW) / 2
        let pillRect = NSRect(x: pillX, y: pillY, width: pillW, height: pillHeight)
        let cornerRadius = pillHeight / 2

        // Shadow
        ctx.saveGState()
        let shadow = DesignTokens.titlePillExportShadow
        ctx.setShadow(
            offset: shadow.shadowOffset,
            blur: shadow.shadowBlurRadius,
            color: (shadow.shadowColor as? NSColor)?.cgColor ?? NSColor(red: 0, green: 0, blue: 0, alpha: 0.3).cgColor
        )

        // Background
        let bgColor: NSColor
        let borderColor: NSColor
        switch role {
        case .observed:
            bgColor = DesignTokens.roleObservedBg
            borderColor = DesignTokens.roleObservedBorder
        case .expected:
            bgColor = DesignTokens.roleExpectedBg
            borderColor = DesignTokens.roleExpectedBorder
        case .reference:
            bgColor = DesignTokens.roleReferenceBg
            borderColor = DesignTokens.roleReferenceBorder
        }

        let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: cornerRadius, yRadius: cornerRadius)
        bgColor.setFill()
        pillPath.fill()
        ctx.restoreGState()

        // Border (no shadow)
        borderColor.setStroke()
        pillPath.lineWidth = 1
        pillPath.stroke()

        // Title text
        let titleFont = NSFont.systemFont(ofSize: 10, weight: .semibold)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.white,
        ]
        let titleStr = title as NSString
        let titleSize = titleStr.size(withAttributes: titleAttrs)
        let titleX = pillRect.minX + 12
        let titleY = pillRect.midY - titleSize.height / 2
        titleStr.draw(at: NSPoint(x: titleX, y: titleY), withAttributes: titleAttrs)

        // Role label
        let roleFont = NSFont.systemFont(ofSize: 9, weight: .semibold)
        let roleAttrs: [NSAttributedString.Key: Any] = [
            .font: roleFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.6),
        ]
        let roleStr = role.displayName as NSString
        let roleSize = roleStr.size(withAttributes: roleAttrs)
        let roleX = pillRect.maxX - roleSize.width - 10
        let roleY = pillRect.midY - roleSize.height / 2
        roleStr.draw(at: NSPoint(x: roleX, y: roleY), withAttributes: roleAttrs)
    }
}
