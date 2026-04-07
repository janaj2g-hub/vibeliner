import Foundation

/// Output frame for a single image cell in the filmstrip grid.
struct LayoutFrame {
    let origin: CGPoint
    let size: CGSize
    let rowIndex: Int
}

/// Pure computation class — no views. Takes image sizes and returns layout frames.
/// Shared between FilmstripGridView (display) and composite stitcher (export).
final class LayoutCalculator {

    /// Minimum cell width before reducing images per row.
    static let minimumCellWidth: CGFloat = 120

    /// Compute layout frames for the given image sizes.
    ///
    /// - Parameters:
    ///   - imageSizes: Original image dimensions (width × height).
    ///   - availableWidth: Total width the grid can occupy (excluding external padding).
    ///   - gap: Space between cells horizontally and between rows vertically.
    ///   - maxPerRow: Maximum images per row (default 3).
    ///   - titlePillTotalHeight: Extra height per cell for title pill + gap (0 for single image).
    /// - Returns: Array of `LayoutFrame` for each image, in input order.
    static func computeFrames(
        imageSizes: [CGSize],
        availableWidth: CGFloat,
        gap: CGFloat,
        maxPerRow: Int = 3,
        titlePillTotalHeight: CGFloat = 0
    ) -> [LayoutFrame] {
        guard !imageSizes.isEmpty else { return [] }

        // Chunk into rows
        let rows = chunk(imageSizes, maxPerRow: maxPerRow)

        var frames: [LayoutFrame] = []
        var currentY: CGFloat = 0
        var globalIndex = 0

        let pillH = titlePillTotalHeight

        for (rowIndex, rowSizes) in rows.enumerated() {
            let rowFrames = layoutRow(
                sizes: rowSizes,
                availableWidth: availableWidth,
                gap: gap,
                originY: currentY,
                rowIndex: rowIndex,
                startIndex: globalIndex,
                titlePillTotalHeight: pillH
            )

            // Check minimum cell width — reduce per-row count if needed
            let tooNarrow = rowFrames.contains { $0.size.width < minimumCellWidth }
            if tooNarrow && rowSizes.count > 1 {
                // Re-chunk this row's images with fewer per row
                let reduced = chunk(rowSizes, maxPerRow: rowSizes.count - 1)
                var subY = currentY
                for subRow in reduced {
                    let subFrames = layoutRow(
                        sizes: subRow,
                        availableWidth: availableWidth,
                        gap: gap,
                        originY: subY,
                        rowIndex: rowIndex,
                        startIndex: globalIndex,
                        titlePillTotalHeight: pillH
                    )
                    frames.append(contentsOf: subFrames)
                    globalIndex += subRow.count
                    if let last = subFrames.last {
                        subY = last.origin.y + last.size.height + gap
                    }
                }
                currentY = subY
            } else {
                frames.append(contentsOf: rowFrames)
                globalIndex += rowSizes.count
                if let last = rowFrames.last {
                    currentY = last.origin.y + last.size.height + gap
                }
            }
        }

        return frames
    }

    /// Total height of the computed layout (last frame bottom + removes trailing gap).
    static func totalHeight(frames: [LayoutFrame]) -> CGFloat {
        guard let last = frames.last else { return 0 }
        return last.origin.y + last.size.height
    }

    // MARK: - Private

    /// Split array into chunks of `maxPerRow`.
    private static func chunk(_ sizes: [CGSize], maxPerRow: Int) -> [[CGSize]] {
        let clamped = max(maxPerRow, 1)
        var result: [[CGSize]] = []
        var i = 0
        while i < sizes.count {
            let end = min(i + clamped, sizes.count)
            result.append(Array(sizes[i..<end]))
            i = end
        }
        return result
    }

    /// Layout a single row of images with proportional widths.
    private static func layoutRow(
        sizes: [CGSize],
        availableWidth: CGFloat,
        gap: CGFloat,
        originY: CGFloat,
        rowIndex: Int,
        startIndex: Int,
        titlePillTotalHeight: CGFloat = 0
    ) -> [LayoutFrame] {
        let count = sizes.count
        guard count > 0 else { return [] }

        // Aspect ratios (width / height), clamped to avoid division by zero
        let aspectRatios = sizes.map { size -> CGFloat in
            guard size.height > 0 else { return 1 }
            return size.width / size.height
        }

        let sumAR = aspectRatios.reduce(0, +)
        guard sumAR > 0 else { return [] }

        let gapSpace = gap * CGFloat(count - 1)
        let usableWidth = availableWidth - gapSpace

        // Each cell width = (AR / sumAR) * usableWidth
        // Row height = any cell width / its AR (all equal)
        let imageRowHeight = usableWidth / sumAR
        let cellHeight = imageRowHeight + titlePillTotalHeight

        var frames: [LayoutFrame] = []
        var x: CGFloat = 0

        for (_, ar) in aspectRatios.enumerated() {
            let cellWidth = ar * imageRowHeight
            let frame = LayoutFrame(
                origin: CGPoint(x: x, y: originY),
                size: CGSize(width: cellWidth, height: cellHeight),
                rowIndex: rowIndex
            )
            frames.append(frame)
            x += cellWidth + gap
        }

        return frames
    }
}
