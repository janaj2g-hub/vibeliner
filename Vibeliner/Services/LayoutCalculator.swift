import Foundation

/// Output frame for a single image cell in the filmstrip.
struct LayoutFrame {
    let origin: CGPoint
    let size: CGSize
}

/// Pure computation class — no views. Takes image sizes and returns layout frames.
/// Shared between FilmstripGridView (display) and CompositeStitcher (export).
///
/// VIB-297: Simplified to single horizontal row only. All images same height,
/// widths proportional to aspect ratio. No multi-row chunking.
final class LayoutCalculator {

    /// Maximum row height — prevents rows from being taller than the screen.
    static let maxRowHeight: CGFloat = 500

    /// Compute single-row layout frames for the given image sizes.
    ///
    /// - Parameters:
    ///   - imageSizes: Original image dimensions (width × height).
    ///   - rowHeight: Fixed height for all cells in the row.
    ///   - gap: Space between cells horizontally.
    ///   - titlePillTotalHeight: Extra height per cell for title pill + gap (0 for single image).
    /// - Returns: Tuple of layout frames and the total content width.
    static func computeFrames(
        imageSizes: [CGSize],
        rowHeight: CGFloat,
        gap: CGFloat,
        titlePillTotalHeight: CGFloat = 0
    ) -> (frames: [LayoutFrame], totalWidth: CGFloat) {
        guard !imageSizes.isEmpty else { return ([], 0) }

        let cellHeight = rowHeight + titlePillTotalHeight
        var frames: [LayoutFrame] = []
        var xOffset: CGFloat = 0

        for size in imageSizes {
            let ar: CGFloat = size.height > 0 ? size.width / size.height : 1
            let cellWidth = rowHeight * ar

            let frame = LayoutFrame(
                origin: CGPoint(x: xOffset, y: 0),
                size: CGSize(width: cellWidth, height: cellHeight)
            )
            frames.append(frame)
            xOffset += cellWidth + gap
        }

        // Remove trailing gap
        let totalWidth = max(0, xOffset - gap)
        return (frames, totalWidth)
    }

    /// Total height of the computed layout (all cells are the same height).
    static func totalHeight(frames: [LayoutFrame]) -> CGFloat {
        return frames.first?.size.height ?? 0
    }

    /// Total width of the computed layout.
    static func totalWidth(frames: [LayoutFrame], gap: CGFloat) -> CGFloat {
        guard let last = frames.last else { return 0 }
        return last.origin.x + last.size.width
    }
}
