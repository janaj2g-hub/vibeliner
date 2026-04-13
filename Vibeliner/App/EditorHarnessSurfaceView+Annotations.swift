import AppKit

#if DEBUG
extension EditorHarnessSurfaceView {

    static func addCalmAnnotations(to store: AnnotationStore, canvasSize: CGSize) {
        let pin = Annotation(
            type: .pin,
            number: 0,
            noteText: "give this card more breathing room",
            position: .pin(tip: CGPoint(x: 130, y: 90)),
            badgePosition: CGPoint(x: 130, y: 90 - DesignTokens.stakeLength - DesignTokens.badgeDiameter / 2)
        )
        _ = store.add(pin)

        let arrow = Annotation(
            type: .arrow,
            number: 0,
            noteText: "align this action with the field above",
            position: .arrow(start: CGPoint(x: canvasSize.width * 0.55, y: 90), end: CGPoint(x: canvasSize.width * 0.73, y: 150)),
            badgePosition: CGPoint(x: canvasSize.width * 0.55, y: 90)
        )
        _ = store.add(arrow)

        let rectOrigin = CGPoint(x: 84, y: canvasSize.height * 0.56)
        let rectSize = CGSize(width: 180, height: 72)
        let rect = Annotation(
            type: .rectangle,
            number: 0,
            noteText: "match this section frame to the rest of settings",
            position: .rectangle(origin: rectOrigin, size: rectSize),
            badgePosition: CGPoint(x: rectOrigin.x, y: rectOrigin.y + rectSize.height)
        )
        _ = store.add(rect)
    }

    static func addDenseAnnotations(to store: AnnotationStore, canvasSize: CGSize) {
        let columns = 4
        let rows = 5
        let cellWidth = (canvasSize.width - 160) / CGFloat(columns)
        let cellHeight = (canvasSize.height - 120) / CGFloat(rows)
        var noteNumber = 0

        for row in 0..<rows {
            for column in 0..<columns {
                let origin = CGPoint(
                    x: 44 + CGFloat(column) * cellWidth,
                    y: 38 + CGFloat(row) * cellHeight
                )
                switch (row + column) % 4 {
                case 0:
                    let size = CGSize(width: 52 + CGFloat((row * 7) % 24), height: 34 + CGFloat((column * 5) % 18))
                    var annotation = Annotation(
                        type: .rectangle,
                        number: 0,
                        noteText: "tighten spacing in cluster \(noteNumber + 1)",
                        position: .rectangle(origin: origin, size: size),
                        badgePosition: CGPoint(x: origin.x, y: origin.y + size.height)
                    )
                    annotation.parentImageIndex = 0
                    _ = store.add(annotation)
                case 1:
                    let center = CGPoint(x: origin.x + 38, y: origin.y + 26)
                    var annotation = Annotation(
                        type: .circle,
                        number: 0,
                        noteText: "icon weight mismatch in row \(row + 1)",
                        position: .circle(center: center, radius: 24),
                        badgePosition: CGPoint(x: center.x + 24, y: center.y)
                    )
                    annotation.parentImageIndex = 0
                    _ = store.add(annotation)
                case 2:
                    let start = CGPoint(x: origin.x, y: origin.y + 8)
                    let end = CGPoint(x: origin.x + 52, y: origin.y + 34)
                    var annotation = Annotation(
                        type: .arrow,
                        number: 0,
                        noteText: "line this up with the active state",
                        position: .arrow(start: start, end: end),
                        badgePosition: start
                    )
                    annotation.parentImageIndex = 0
                    _ = store.add(annotation)
                default:
                    let points = FreehandTool.smoothPoints([
                        CGPoint(x: origin.x, y: origin.y + 10),
                        CGPoint(x: origin.x + 16, y: origin.y + 18),
                        CGPoint(x: origin.x + 24, y: origin.y + 8),
                        CGPoint(x: origin.x + 38, y: origin.y + 22),
                        CGPoint(x: origin.x + 52, y: origin.y + 16),
                    ], passes: 2)
                    var annotation = Annotation(
                        type: .freehand,
                        number: 0,
                        noteText: "shape contrast breaks under hover",
                        position: .freehand(points: points),
                        badgePosition: points.first ?? origin
                    )
                    annotation.parentImageIndex = 0
                    _ = store.add(annotation)
                }
                noteNumber += 1
            }
        }
    }

    static func addFilmstripAnnotations(to store: AnnotationStore, filmstrip: FilmstripGridView, session: CaptureSession) {
        guard session.images.count >= 3 else { return }
        for index in 0..<session.images.count {
            let cell = filmstrip.imageCellFrameInCanvas(at: index)
            let image = session.images[index]

            var pin = Annotation(
                type: .pin,
                number: 0,
                noteText: "title pill and preview should stay aligned",
                position: .pin(tip: CGPoint(x: cell.minX + 30, y: cell.minY + 38)),
                badgePosition: CGPoint(x: cell.minX + 30, y: cell.minY + 38 - DesignTokens.stakeLength - DesignTokens.badgeDiameter / 2)
            )
            pin.parentImageIndex = image.index
            pin.parentImageID = image.id
            _ = store.add(pin)

            var rect = Annotation(
                type: .rectangle,
                number: 0,
                noteText: "keep this filmstrip card visually stable during hover",
                position: .rectangle(origin: CGPoint(x: cell.minX + 56, y: cell.minY + 52), size: CGSize(width: cell.width * 0.42, height: cell.height * 0.28)),
                badgePosition: CGPoint(x: cell.minX + 56, y: cell.minY + 52 + cell.height * 0.28)
            )
            rect.parentImageIndex = image.index
            rect.parentImageID = image.id
            _ = store.add(rect)

            var circle = Annotation(
                type: .circle,
                number: 0,
                noteText: "role color and selected border should remain readable",
                position: .circle(center: CGPoint(x: cell.maxX - 42, y: cell.minY + 64), radius: 20),
                badgePosition: CGPoint(x: cell.maxX - 22, y: cell.minY + 64)
            )
            circle.parentImageIndex = image.index
            circle.parentImageID = image.id
            _ = store.add(circle)
        }

        let first = session.images[0]
        let second = session.images[1]
        let firstCell = filmstrip.imageCellFrameInCanvas(at: 0)
        let secondCell = filmstrip.imageCellFrameInCanvas(at: 1)

        var crossImageArrow = Annotation(
            type: .arrow,
            number: 0,
            noteText: "cross-image callouts should survive filmstrip selection changes",
            position: .arrow(
                start: CGPoint(x: firstCell.midX, y: firstCell.midY),
                end: CGPoint(x: secondCell.minX + 54, y: secondCell.midY - 16)
            ),
            badgePosition: CGPoint(x: firstCell.midX, y: firstCell.midY)
        )
        crossImageArrow.parentImageIndex = first.index
        crossImageArrow.parentImageID = first.id
        crossImageArrow.endImageIndex = second.index
        crossImageArrow.endImageID = second.id
        _ = store.add(crossImageArrow)
    }
}
#endif
