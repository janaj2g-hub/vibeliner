import Foundation
import CoreGraphics

enum AnnotationToolType: Int, CaseIterable {
    case select = 0, pin, arrow, rectangle, circle, freehand

    var label: String {
        switch self {
        case .select: return "select"
        case .pin: return "pin"
        case .arrow: return "arrow"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .freehand: return "freehand"
        }
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

    init(id: UUID = UUID(), type: AnnotationToolType, number: Int, noteText: String = "", position: AnnotationPosition, badgePosition: CGPoint) {
        self.id = id
        self.type = type
        self.number = number
        self.noteText = noteText
        self.position = position
        self.badgePosition = badgePosition
    }
}
