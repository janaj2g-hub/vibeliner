import AppKit

enum Constants {
    static let annotationRed = NSColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1.0)
    static let toolbarAnnotationIconColor = annotationRed
    static let badgeRadius: CGFloat = 9
    static let strokeWidth: CGFloat = 2.5
    static let badgeOutlineColor = NSColor.white.withAlphaComponent(0.8)
    static let badgeHoverRingColor = annotationRed.withAlphaComponent(0.5)
    static let badgeTextColor = NSColor.white
    static let badgeHoverRingRadius: CGFloat = 13
    static let badgeHitRadius: CGFloat = 11
    static let inlineNoteTextColor = NSColor.white
    static let inlineNoteBackgroundColor = NSColor(
        red: 0.235,
        green: 0.055,
        blue: 0.078,
        alpha: 0.9
    )
}
