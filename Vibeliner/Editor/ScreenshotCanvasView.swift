import AppKit

final class ScreenshotCanvasView: NSView {

    private let imageView: NSImageView

    init(image: NSImage) {
        self.imageView = NSImageView()
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.masksToBounds = true

        // Shadow on a wrapper approach: set shadow on superview layer
        layer?.shadowColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.12).cgColor
        layer?.shadowOffset = NSSize(width: 0, height: -4)
        layer?.shadowRadius = 24
        layer?.shadowOpacity = 1.0
        layer?.masksToBounds = false

        // Use a sublayer for clipping content while keeping shadow visible
        let clipView = NSView()
        clipView.wantsLayer = true
        clipView.layer?.cornerRadius = 6
        clipView.layer?.masksToBounds = true
        clipView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(clipView)

        imageView.image = image
        imageView.imageScaling = .scaleAxesIndependently
        imageView.translatesAutoresizingMaskIntoConstraints = false
        clipView.addSubview(imageView)

        NSLayoutConstraint.activate([
            clipView.topAnchor.constraint(equalTo: topAnchor),
            clipView.bottomAnchor.constraint(equalTo: bottomAnchor),
            clipView.leadingAnchor.constraint(equalTo: leadingAnchor),
            clipView.trailingAnchor.constraint(equalTo: trailingAnchor),

            imageView.topAnchor.constraint(equalTo: clipView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: clipView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: clipView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: clipView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
