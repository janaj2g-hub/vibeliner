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

    static func activeTextResponder(in window: NSWindow?) -> NSTextView? {
        guard let window else { return nil }

        if let textView = window.firstResponder as? NSTextView {
            return textView
        }

        if let firstResponderView = window.firstResponder as? NSView,
           let fieldEditor = window.fieldEditor(false, for: firstResponderView) as? NSTextView {
            return fieldEditor
        }

        return nil
    }

    /// Returns true if the keyboard shortcut should be handled by the app.
    /// Returns false if a text field is editing and the key event should pass through
    /// to the text field's field editor.
    static func shouldHandleShortcut(in window: NSWindow?) -> Bool {
        activeTextResponder(in: window) == nil
    }
}
