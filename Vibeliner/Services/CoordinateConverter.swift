import Foundation
import CoreGraphics

/// VIB-268: Converts between absolute canvas coordinates and image-relative
/// percentages (0.0–1.0). Annotations store relative positions so they
/// survive filmstrip layout changes (image added/removed, window resize).
enum CoordinateConverter {

    // MARK: - Point conversion

    /// Convert an absolute canvas point to image-relative (0.0–1.0) coordinates.
    static func absoluteToRelative(point: CGPoint, imageFrame: CGRect) -> CGPoint {
        guard imageFrame.width > 0, imageFrame.height > 0 else { return .zero }
        return CGPoint(
            x: (point.x - imageFrame.origin.x) / imageFrame.width,
            y: (point.y - imageFrame.origin.y) / imageFrame.height
        )
    }

    /// Convert image-relative (0.0–1.0) coordinates to an absolute canvas point.
    static func relativeToAbsolute(point: CGPoint, imageFrame: CGRect) -> CGPoint {
        return CGPoint(
            x: imageFrame.origin.x + point.x * imageFrame.width,
            y: imageFrame.origin.y + point.y * imageFrame.height
        )
    }

    // MARK: - Image index detection

    /// Determine which image a point belongs to. Returns the containing image
    /// index, or the nearest image if the point is in a gap.
    static func imageIndex(for point: CGPoint, imageFrames: [CGRect]) -> Int {
        guard !imageFrames.isEmpty else { return 0 }

        // Check direct containment first
        for (i, frame) in imageFrames.enumerated() {
            if frame.contains(point) { return i }
        }

        // Point is in a gap — assign to nearest image by center distance
        var minDist: CGFloat = .greatestFiniteMagnitude
        var nearestIndex = 0
        for (i, frame) in imageFrames.enumerated() {
            let dx = point.x - frame.midX
            let dy = point.y - frame.midY
            let dist = hypot(dx, dy)
            if dist < minDist {
                minDist = dist
                nearestIndex = i
            }
        }
        return nearestIndex
    }

    // MARK: - Full position conversion

    /// Convert an AnnotationPosition from absolute canvas coords to image-relative (0.0–1.0).
    /// For arrows, `endFrame` may differ from `parentFrame` (cross-image arrows).
    static func positionToRelative(
        _ position: AnnotationPosition,
        parentFrame: CGRect,
        endFrame: CGRect? = nil
    ) -> AnnotationPosition {
        switch position {
        case .pin(let tip):
            return .pin(tip: absoluteToRelative(point: tip, imageFrame: parentFrame))

        case .arrow(let start, let end):
            let ef = endFrame ?? parentFrame
            return .arrow(
                start: absoluteToRelative(point: start, imageFrame: parentFrame),
                end: absoluteToRelative(point: end, imageFrame: ef)
            )

        case .rectangle(let origin, let size):
            let relOrigin = absoluteToRelative(point: origin, imageFrame: parentFrame)
            let relSize = CGSize(
                width: parentFrame.width > 0 ? size.width / parentFrame.width : 0,
                height: parentFrame.height > 0 ? size.height / parentFrame.height : 0
            )
            return .rectangle(origin: relOrigin, size: relSize)

        case .circle(let center, let radius):
            let relCenter = absoluteToRelative(point: center, imageFrame: parentFrame)
            // Normalize radius by image width for consistent scaling
            let relRadius = parentFrame.width > 0 ? radius / parentFrame.width : 0
            return .circle(center: relCenter, radius: relRadius)

        case .freehand(let points):
            let relPoints = points.map { absoluteToRelative(point: $0, imageFrame: parentFrame) }
            return .freehand(points: relPoints)
        }
    }

    /// Convert an AnnotationPosition from image-relative (0.0–1.0) to absolute canvas coords.
    /// For arrows, `endFrame` may differ from `parentFrame` (cross-image arrows).
    static func positionToAbsolute(
        _ position: AnnotationPosition,
        parentFrame: CGRect,
        endFrame: CGRect? = nil
    ) -> AnnotationPosition {
        switch position {
        case .pin(let tip):
            return .pin(tip: relativeToAbsolute(point: tip, imageFrame: parentFrame))

        case .arrow(let start, let end):
            let ef = endFrame ?? parentFrame
            return .arrow(
                start: relativeToAbsolute(point: start, imageFrame: parentFrame),
                end: relativeToAbsolute(point: end, imageFrame: ef)
            )

        case .rectangle(let origin, let size):
            let absOrigin = relativeToAbsolute(point: origin, imageFrame: parentFrame)
            let absSize = CGSize(
                width: size.width * parentFrame.width,
                height: size.height * parentFrame.height
            )
            return .rectangle(origin: absOrigin, size: absSize)

        case .circle(let center, let radius):
            let absCenter = relativeToAbsolute(point: center, imageFrame: parentFrame)
            let absRadius = radius * parentFrame.width
            return .circle(center: absCenter, radius: absRadius)

        case .freehand(let points):
            let absPoints = points.map { relativeToAbsolute(point: $0, imageFrame: parentFrame) }
            return .freehand(points: absPoints)
        }
    }
}
