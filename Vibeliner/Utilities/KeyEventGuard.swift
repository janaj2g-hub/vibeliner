import AppKit

// CRITICAL: Do not bypass this guard. See VIB-287, VIB-311 for the history
// of this recurring regression. Every keyDown/performKeyEquivalent override
// in the project MUST call KeyEventGuard.shouldHandleShortcut(in:) before
// handling Delete, Backspace, number keys 1-5, or any other shortcut.

/// Centralized guard for keyboard shortcuts.
/// Returns false when a text field or field editor is the first responder,
/// preventing the app from swallowing keystrokes intended for text editing.
///
/// Usage:
///   guard KeyEventGuard.shouldHandleShortcut(in: window) else { return }
enum KeyEventGuard {

    /// Returns true if the keyboard shortcut should be handled by the app.
    /// Returns false if a text field is editing and the key event should pass through
    /// to the text field's field editor.
    static func shouldHandleShortcut(in window: NSWindow?) -> Bool {
        guard let firstResponder = window?.firstResponder else { return true }

        // If a text view is the first responder (includes field editors for
        // NSTextField, note text fields, title pill text fields, etc.), pass through.
        if firstResponder is NSTextView { return false }
        if firstResponder is NSTextField { return false }

        // Double-check: if the window has an active field editor, pass through.
        if let window = window, window.fieldEditor(false, for: nil) != nil {
            if window.firstResponder is NSTextView { return false }
        }

        return true
    }
}
