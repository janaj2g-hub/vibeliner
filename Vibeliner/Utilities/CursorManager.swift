import AppKit

/// Centralized cursor visibility management. All cursor hide/show in the app
/// goes through this singleton to prevent unbalanced NSCursor.hide()/unhide() calls.
/// VIB-334: Added isCursorHidden public getter and forceShow safety nets.
final class CursorManager {
    static let shared = CursorManager()

    /// VIB-334: Public read access for safety net checks.
    private(set) var isCursorHidden = false

    private init() {}

    func hideCursor() {
        guard !isCursorHidden else { return }
        NSCursor.hide()
        isCursorHidden = true
    }

    func showCursor() {
        guard isCursorHidden else { return }
        NSCursor.unhide()
        isCursorHidden = false
    }

    /// Emergency reset — call on window deactivation / close to guarantee cursor is visible.
    func forceShow() {
        if isCursorHidden {
            NSCursor.unhide()
            isCursorHidden = false
        }
    }
}
