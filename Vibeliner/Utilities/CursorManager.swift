import AppKit

/// Centralized cursor visibility management. All cursor hide/show in the app
/// goes through this singleton to prevent unbalanced NSCursor.hide()/unhide() calls.
/// VIB-334 attempt 3: Counter-based tracking replaces boolean flag to handle
/// desync between our state and the AppKit cursor stack.
final class CursorManager {
    static let shared = CursorManager()

    private var hideCount = 0

    /// Public read access for safety net checks.
    var isCursorHidden: Bool { hideCount > 0 }

    private init() {}

    func hideCursor() {
        guard hideCount == 0 else { return }
        NSCursor.hide()
        hideCount = 1
    }

    func showCursor() {
        guard hideCount > 0 else { return }
        NSCursor.unhide()
        hideCount = 0
    }

    /// Emergency reset — unconditionally ensures cursor is visible.
    /// Calls unhide() regardless of tracked state to fix any desync,
    /// then resets the arrow cursor to clear custom cursors.
    func forceShow() {
        NSCursor.unhide()
        if hideCount > 0 {
            NSCursor.unhide()
        }
        NSCursor.arrow.set()
        hideCount = 0
    }
}
