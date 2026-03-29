import Foundation
import CoreGraphics

enum AnnotationType {
    case freehand
    case arrow
    case circle
}

struct Annotation: Identifiable {
    let id: UUID
    var number: Int
    var type: AnnotationType
    var points: [CGPoint]
    var note: String
    var startPoint: CGPoint

    init(number: Int, type: AnnotationType, points: [CGPoint], note: String = "") {
        self.id = UUID()
        self.number = number
        self.type = type
        self.points = points
        self.note = note
        self.startPoint = points.first ?? .zero
    }
}
