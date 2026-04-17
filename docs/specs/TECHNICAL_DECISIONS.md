# Vibeliner — Technical Decisions

This document records architectural decisions and failed approaches. Claude Code reads this before writing code. Claude.ai updates it when tickets fail.

---

## Architectural decisions

### Custom capture overlay vs. native screencapture
**Decision:** Custom overlay using borderless NSWindow + CGWindowListCreateImage.
**Why:** The PRD specifies a branded capture experience (purple crosshair, bright cutout, dimension label) that is impossible with `screencapture -i`.
**Fallback:** If the custom overlay is unreliable on certain macOS versions or display configurations, fall back to `screencapture -R x,y,w,h` for the actual pixel capture while keeping the custom overlay for region selection.
**Risk:** High. This is the #1 risk area.

### AppKit for annotation canvas, not SwiftUI Canvas
**Decision:** Use NSView + Core Graphics for all annotation rendering.
**Why:** The annotation tools require precise mouse event handling (hover detection on individual strokes, drag handles, inline text editing on NSTextField). SwiftUI Canvas doesn't support hit testing on individual drawn elements. NSView gives us full control over `mouseDown`, `mouseMoved`, `mouseUp`, `mouseDragged` events and direct Core Graphics drawing.
**Fallback:** None — this is the only viable approach for the interaction model in the PRD.

### Config as TOML, not JSON or plist
**Decision:** Use a simple `config.toml` file with a hand-written key=value parser.
**Why:** Human-readable and editable in any text editor. No third-party TOML library needed — the config is flat key-value pairs, not nested structures. JSON requires careful quoting. Plist is XML noise.
**Trade-off:** The hand-written parser won't handle complex TOML features (nested tables, arrays of tables). Fine for v1 where all config values are flat.

### No third-party dependencies
**Decision:** Zero external dependencies for v1.
**Why:** Reduces build complexity, avoids license issues, keeps the binary small. Everything Vibeliner needs is in the macOS SDK (AppKit, Core Graphics, CGWindowListCreateImage).
**Exception:** If hotkey registration via NSEvent proves unreliable for global shortcuts across all Spaces and full-screen apps, KeyboardShortcuts (MIT licensed) may be added as a single dependency.

### Sequential annotation numbering renumbers after deletion
**Decision:** When an annotation is deleted, the remaining annotations are renumbered sequentially.
**Why:** This matches the current `AnnotationStore` implementation and keeps the exported prompt list contiguous while editing.

### Two rendering layers: marks (clips) and notes (overflows)
**Decision:** The annotation canvas has two overlapping NSViews — MarksLayer with `clipsToBounds = true` and NotesLayer with `clipsToBounds = false`.
**Why:** Annotation marks (shapes, lines, badges) should clip at the screenshot edge for a clean look. But note pills should be readable even when placed near the edge — they overflow beyond the canvas. Two layers with different clipping behavior solve this cleanly.

### Backspace/Delete structural fix (VIB-460)
**Decision:** Move the Delete/Backspace handler in `handleKeyEvent` above the `KeyEventGuard.shouldHandleShortcut` gate, rather than patching individual call sites to clear stale first responders.
**Why:** Backspace/Delete failing to delete selected annotations has recurred 5 times (VIB-102, VIB-311, VIB-435, VIB-449, VIB-454). The root cause is always the same: a stale NSTextView field editor (from note pill editing, title pill editing, etc.) is left as first responder, and `KeyEventGuard.shouldHandleShortcut` returns false because it detects a text responder. Previous fixes patched individual code paths to resign the field editor, but each new text field or interaction path reintroduces the bug. The structural fix is safe because: (1) the `isEditingNote` early-return at the top of `handleKeyEvent` already handles the case where a note is actively being edited, and (2) when a title pill field editor is actively focused, AppKit routes Backspace to the field editor directly via the key monitor's `routeTextOwnedKeyEvent` — it never reaches the delete branch. The `KeyEventGuard` gate still protects all other shortcuts (tool switching, undo/redo, etc.).

---

## Failed approaches

*This section is updated when tickets fail. Each entry explains what was tried, why it failed, and what to do instead.*

### DMG Applications folder shortcut (VIB-347, attempts 2-4)
**Tried:** `ln -s /Applications` (symlink), Finder alias via `osascript` in staging dir, Finder alias inside mounted RW DMG volume.
**Failed:** All three approaches rendered the Applications folder as a black square in the DMG Finder window. The symlink lacks Finder icon metadata. The Finder alias created in staging lost its metadata when copied by `hdiutil create -srcfolder`. The alias created inside the mounted volume still showed a black square — likely a macOS Finder rendering limitation with HFS+ DMG volumes on modern macOS (14+).
**Decision:** Removed the Applications shortcut entirely. The DMG now contains only Vibeliner.app centered on the branded background. Users drag the app to /Applications manually or via Finder sidebar.
