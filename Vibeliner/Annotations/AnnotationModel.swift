import Foundation
import CoreGraphics

struct AnnotationToolDefinition {
    let type: AnnotationToolType
    let displayName: String
    let shortcutDigit: String?
    let shortcutKeyCode: UInt16?
    let supportsPromptExport: Bool
    let defaultPromptDescription: String?

    var label: String {
        switch type {
        case .select: return "select"
        case .pin: return "pin"
        case .arrow: return "arrow"
        case .line: return "line"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .freehand: return "freehand"
        }
    }

    var toolbarTooltip: String {
        guard let shortcutDigit else { return displayName }
        return "\(displayName) (\(shortcutDigit))"
    }
}

enum AnnotationToolType: Int, CaseIterable {
    case select = 0, pin, arrow, line, rectangle, circle, freehand

    static let allDefinitions: [AnnotationToolDefinition] = [
        AnnotationToolDefinition(
            type: .select,
            displayName: "Select",
            shortcutDigit: "1",
            shortcutKeyCode: 18,
            supportsPromptExport: false,
            defaultPromptDescription: nil
        ),
        AnnotationToolDefinition(
            type: .pin,
            displayName: "Pin",
            shortcutDigit: "2",
            shortcutKeyCode: 19,
            supportsPromptExport: true,
            defaultPromptDescription: "points to a specific issue"
        ),
        AnnotationToolDefinition(
            type: .arrow,
            displayName: "Arrow",
            shortcutDigit: "3",
            shortcutKeyCode: 20,
            supportsPromptExport: true,
            defaultPromptDescription: "points at or between elements"
        ),
        AnnotationToolDefinition(
            type: .line,
            displayName: "Line",
            shortcutDigit: "7",
            shortcutKeyCode: 26,
            supportsPromptExport: true,
            defaultPromptDescription: "marks a connection or alignment"
        ),
        AnnotationToolDefinition(
            type: .rectangle,
            displayName: "Rectangle",
            shortcutDigit: "4",
            shortcutKeyCode: 21,
            supportsPromptExport: true,
            defaultPromptDescription: "highlights a region or container"
        ),
        AnnotationToolDefinition(
            type: .circle,
            displayName: "Circle",
            shortcutDigit: "5",
            shortcutKeyCode: 22,
            supportsPromptExport: true,
            defaultPromptDescription: "calls out a specific element"
        ),
        AnnotationToolDefinition(
            type: .freehand,
            displayName: "Freehand",
            shortcutDigit: "6",
            shortcutKeyCode: 23,
            supportsPromptExport: true,
            defaultPromptDescription: "marks an irregular area"
        ),
    ]

    static var toolbarDefinitions: [AnnotationToolDefinition] {
        allDefinitions
    }

    static var promptExportDefinitions: [AnnotationToolDefinition] {
        allDefinitions.filter(\.supportsPromptExport)
    }

    static var defaultPromptDescriptions: [String: String] {
        Dictionary(
            uniqueKeysWithValues: promptExportDefinitions.compactMap { definition in
                guard let description = definition.defaultPromptDescription else { return nil }
                return (definition.label, description)
            }
        )
    }

    static func tool(forShortcutKeyCode keyCode: UInt16) -> AnnotationToolType? {
        allDefinitions.first(where: { $0.shortcutKeyCode == keyCode })?.type
    }

    var definition: AnnotationToolDefinition {
        Self.allDefinitions.first(where: { $0.type == self }) ?? Self.allDefinitions[0]
    }

    var label: String {
        definition.label
    }

    var displayName: String {
        definition.displayName
    }

    var shortcutKeyCode: UInt16? {
        definition.shortcutKeyCode
    }

    /// Whether this is an annotation-creating tool (vs select)
    var isDrawingTool: Bool { self != .select }
}

enum AnnotationPosition {
    case pin(tip: CGPoint)
    case arrow(start: CGPoint, end: CGPoint)
    case rectangle(origin: CGPoint, size: CGSize)
    case circle(center: CGPoint, radius: CGFloat)
    case freehand(points: [CGPoint])

    /// VIB-355: Bounding rect for hit-test quick-reject pre-filter.
    var boundingRect: NSRect {
        let pad: CGFloat = 15
        switch self {
        case .pin(let tip):
            return NSRect(x: tip.x - pad, y: tip.y - pad, width: pad * 2, height: pad * 2)
        case .arrow(let start, let end):
            let minX = min(start.x, end.x) - pad
            let minY = min(start.y, end.y) - pad
            let maxX = max(start.x, end.x) + pad
            let maxY = max(start.y, end.y) + pad
            return NSRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        case .rectangle(let origin, let size):
            return NSRect(x: origin.x - pad, y: origin.y - pad, width: size.width + pad * 2, height: size.height + pad * 2)
        case .circle(let center, let radius):
            let r = radius + pad
            return NSRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        case .freehand(let points):
            guard let first = points.first else { return .zero }
            var minX = first.x, minY = first.y, maxX = first.x, maxY = first.y
            for p in points {
                minX = min(minX, p.x); minY = min(minY, p.y)
                maxX = max(maxX, p.x); maxY = max(maxY, p.y)
            }
            return NSRect(x: minX - pad, y: minY - pad, width: maxX - minX + pad * 2, height: maxY - minY + pad * 2)
        }
    }
}

struct Annotation: Identifiable {
    let id: UUID
    let type: AnnotationToolType
    var number: Int
    var noteText: String
    var position: AnnotationPosition
    var badgePosition: CGPoint
    var noteOffset: CGPoint = .zero
    var isSelected: Bool = false

    // VIB-268: Image-relative coordinate system.
    // Positions stored as 0.0–1.0 fractions within the parent image's frame.
    // Prevents annotation drift when the filmstrip layout changes.
    var parentImageIndex: Int = 0
    /// Stable image ownership used across deletes and reindex operations.
    var parentImageID: UUID?
    /// Relative position (0.0–1.0) within parent image.
    var relativePosition: AnnotationPosition?
    /// Badge position as 0.0–1.0 fractions within the parent image's frame.
    var relativeBadgePosition: CGPoint?
    /// For cross-image arrows only: the image index of the arrow's end point.
    var endImageIndex: Int?
    /// Stable end-image ownership for cross-image arrows.
    var endImageID: UUID?

    init(id: UUID = UUID(), type: AnnotationToolType, number: Int, noteText: String = "", position: AnnotationPosition, badgePosition: CGPoint) {
        self.id = id
        self.type = type
        self.number = number
        self.noteText = noteText
        self.position = position
        self.badgePosition = badgePosition
    }
}
