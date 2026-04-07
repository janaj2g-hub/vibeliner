import AppKit

/// Centralized cursor visibility management. All cursor hide/show in the app
/// goes through this singleton to prevent unbalanced NSCursor.hide()/unhide() calls.
final class CursorManager {
    static let shared = CursorManager()

    private var isHidden = false

    private init() {}

    func hideCursor() {
        guard !isHidden else { return }
        NSCursor.hide()
        isHidden = true
    }

    func showCursor() {
        guard isHidden else { return }
        NSCursor.unhide()
        isHidden = false
    }

    /// Emergency reset — call on window deactivation / close to guarantee cursor is visible.
    func forceShow() {
        if isHidden {
            NSCursor.unhide()
            isHidden = false
        }
    }
}
