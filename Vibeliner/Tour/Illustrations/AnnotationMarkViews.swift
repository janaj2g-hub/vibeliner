import AppKit

// MARK: - Badge (18px red circle with white number)

final class TourAnnotationBadge: NSView {
    private let number: Int

    init(number: Int) {
        self.number = number
        super.init(frame: NSRect(x: 0, y: 0, width: 18, height: 18))
        wantsLayer = true
        layer?.cornerRadius = 9
        layer?.backgroundColor = DesignTokens.red.cgColor
        layer?.shadowColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.35).cgColor
        layer?.shadowOffset = CGSize(width: 0, height: -4)
        layer?.shadowRadius = 12
        layer?.shadowOpacity = 1

        let label = NSTextField(labelWithString: "\(number)")
        label.font = NSFont.systemFont(ofSize: 9, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.sizeToFit()
        label.frame.origin = NSPoint(
            x: (18 - label.frame.width) / 2,
            y: (18 - label.frame.height) / 2
        )
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: 18, height: 18) }
}

// MARK: - Note pill (26px height, red-tinted)

final class TourAnnotationNote: NSView {
    init(text: String) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 13
        layer?.backgroundColor = NSColor(red: 255/255, green: 248/255, blue: 248/255, alpha: 0.92).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = DesignTokens.redNoteBorder.cgColor
        layer?.shadowColor = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.08).cgColor
        layer?.shadowOffset = CGSize(width: 0, height: -6)
        layer?.shadowRadius = 20
        layer?.shadowOpacity = 1

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = DesignTokens.noteTextColor
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.sizeToFit()

        let hPad: CGFloat = 10
        let w = label.frame.width + hPad * 2
        setFrameSize(NSSize(width: w, height: 26))

        label.frame.origin = NSPoint(x: hPad, y: (26 - label.frame.height) / 2)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Arrow (red line with chevron)

final class TourAnnotationArrow: NSView {
    private let length: CGFloat
    private let angle: CGFloat  // radians

    init(length: CGFloat, angle: CGFloat = 0) {
        self.length = length
        self.angle = angle
        super.init(frame: NSRect(x: 0, y: 0, width: length + 14, height: length + 14))
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()

        let start = CGPoint(x: 7, y: bounds.height - 7)
        let end = CGPoint(x: start.x + length * cos(angle), y: start.y - length * sin(angle))

        ctx.setStrokeColor(DesignTokens.red.cgColor)
        ctx.setLineWidth(2.5)
        ctx.setLineCap(.round)

        // Main line
        ctx.move(to: start)
        ctx.addLine(to: end)
        ctx.strokePath()

        // Chevron
        let chevLen: CGFloat = 10
        let chevAngle: CGFloat = .pi / 4
        let lineAngle = atan2(start.y - end.y, end.x - start.x) + .pi

        let chev1 = CGPoint(
            x: end.x + chevLen * cos(lineAngle + chevAngle),
            y: end.y - chevLen * sin(lineAngle + chevAngle)
        )
        let chev2 = CGPoint(
            x: end.x + chevLen * cos(lineAngle - chevAngle),
            y: end.y - chevLen * sin(lineAngle - chevAngle)
        )

        ctx.move(to: chev1)
        ctx.addLine(to: end)
        ctx.addLine(to: chev2)
        ctx.strokePath()

        ctx.restoreGState()
    }
}

// MARK: - Rectangle highlight

final class TourAnnotationRect: NSView {
    init(size: CGSize) {
        super.init(frame: NSRect(origin: .zero, size: size))
        wantsLayer = true
        layer?.cornerRadius = 3
        layer?.borderWidth = 2.5
        layer?.borderColor = DesignTokens.red.cgColor
        layer?.backgroundColor = DesignTokens.redFill.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Circle highlight

final class TourAnnotationCircle: NSView {
    init(diameter: CGFloat) {
        super.init(frame: NSRect(x: 0, y: 0, width: diameter, height: diameter))
        wantsLayer = true
        layer?.cornerRadius = diameter / 2
        layer?.borderWidth = 2.5
        layer?.borderColor = DesignTokens.red.cgColor
        layer?.backgroundColor = DesignTokens.redFill.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Stake (2×10px red rect)

final class TourAnnotationStake: NSView {
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 2, height: 10))
        wantsLayer = true
        layer?.backgroundColor = DesignTokens.red.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: 2, height: 10) }
}

// MARK: - Flow arrow (vertical, purple, pointing down)

final class TourFlowArrow: NSView {
    private let arrowHeight: CGFloat

    init(height: CGFloat = 28) {
        self.arrowHeight = height
        super.init(frame: NSRect(x: 0, y: 0, width: 14, height: height))
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: 14, height: arrowHeight) }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let midX = bounds.midX
        ctx.setStrokeColor(DesignTokens.purpleLight.cgColor)
        ctx.setLineWidth(2)
        ctx.setLineCap(.round)

        // Vertical line (top to bottom, AppKit y is flipped for drawing)
        ctx.move(to: CGPoint(x: midX, y: bounds.maxY))
        ctx.addLine(to: CGPoint(x: midX, y: 0))
        ctx.strokePath()

        // Chevron at bottom
        let chevLen: CGFloat = 6
        ctx.move(to: CGPoint(x: midX - chevLen, y: chevLen))
        ctx.addLine(to: CGPoint(x: midX, y: 0))
        ctx.addLine(to: CGPoint(x: midX + chevLen, y: chevLen))
        ctx.strokePath()
    }
}
