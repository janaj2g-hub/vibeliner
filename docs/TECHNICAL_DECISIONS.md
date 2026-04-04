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

### Sequential annotation numbering is permanent
**Decision:** When an annotation is deleted, its number is NOT reassigned. If annotation 2 is deleted, the next annotation is still 4 (not 3).
**Why:** The badge numbers are baked into the exported screenshot. If numbers were reassigned after deletion, the image and prompt would be out of sync during editing (user deletes 2, remaining badges still show the old numbers until re-rendered). Permanent numbers are simpler and match what the user sees.

### Two rendering layers: marks (clips) and notes (overflows)
**Decision:** The annotation canvas has two overlapping NSViews — MarksLayer with `clipsToBounds = true` and NotesLayer with `clipsToBounds = false`.
**Why:** Annotation marks (shapes, lines, badges) should clip at the screenshot edge for a clean look. But note pills should be readable even when placed near the edge — they overflow beyond the canvas. Two layers with different clipping behavior solve this cleanly.

---

## Failed approaches

*This section is updated when tickets fail. Each entry explains what was tried, why it failed, and what to do instead.*

### Cursor management: NSCursor.hide()/unhide() causes permanent cursor loss

**Ticket:** VIB-214 (attempts 1 and 2 both failed before settling on push/pop)

**What failed:** Using `NSCursor.hide()` to hide the system cursor when drawing tools are active. `NSCursor.hide()` and `NSCursor.unhide()` are globally reference-counted at the process level — every `hide()` increments a hidden counter, every `unhide()` decrements it. The cursor only reappears when the counter reaches zero. Any code path that calls `hide()` more times than `unhide()` (e.g., app switching, opening Settings, mouse exiting without triggering `mouseExited`) permanently hides the cursor system-wide across all apps until the app is quit.

**Attempt 1:** Added `NSCursor.unhide()` to `ToolbarView.mouseEntered`. Made things worse — the unhide/hide balance was still broken across app-switching paths.

**Correct fix:** Use the NSCursor stack API instead:
- `NSCursor.invisible.push()` — pushes a 1×1 transparent cursor; scoped to the calling context
- `NSCursor.pop()` — restores the previous cursor
- This never bleeds to other apps or windows

**Rule: Do not use `NSCursor.hide()` or `NSCursor.unhide()` anywhere in this codebase.** Use invisible cursor push/pop instead. The invisible cursor is defined in `DesignTokens.swift` as `NSCursor.invisible`.
