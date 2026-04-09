# VIB-334 Investigation: Cursor Randomly Disappears

**Date:** 2026-04-09
**Type:** Root-cause investigation (no code changes)
**Previous fix:** Safety net in `CanvasView.mouseMoved` + `forceShow()` on window events — cursor STILL disappears

---

## 1. CursorManager API Surface

**File:** `Utilities/CursorManager.swift` (33 LOC)

| Method | What it does | Guard |
|--------|-------------|-------|
| `hideCursor()` | Calls `NSCursor.hide()`, sets `isCursorHidden = true` | Skips if already hidden |
| `showCursor()` | Calls `NSCursor.unhide()`, sets `isCursorHidden = false` | Skips if already shown |
| `forceShow()` | Same as `showCursor()` but named for emergency use | Only unhides if hidden |

**Critical NSCursor behavior:** `NSCursor.hide()` and `NSCursor.unhide()` are **stack-based**. Two `hide()` calls require two `unhide()` calls. CursorManager's guard (`guard !isCursorHidden`) should prevent double-hides, but if **anything bypasses CursorManager** and calls `NSCursor.hide()` directly, the stack becomes corrupted.

---

## 2. All Call Sites

| File:Line | Call | Trigger | Matching Show |
|-----------|------|---------|---------------|
| `CaptureCoordinator.swift:37` | `hideCursor()` | `startCapture()` | `forceShow()` at :200 (cleanupAfterCapture) or :210 (dismissOverlays) |
| `CanvasView.swift:101` | `hideCursor()` | `mouseMoved` — drawing tool active, not hovering annotation | `showCursor()` at :98 (hovering annotation) or :104 (not drawing tool) or :263 (mouseExited) |
| `CanvasView.swift:98` | `showCursor()` | `mouseMoved` — drawing tool, hovering annotation (ghost suppressed) | — |
| `CanvasView.swift:104` | `showCursor()` | `mouseMoved` — not a drawing tool | — |
| `CanvasView.swift:263` | `showCursor()` | `mouseExited` | — |
| `CanvasView.swift:288` | `showCursor()` | `notePillHovered` — drawing tool + pill hovered | — |
| `CanvasView.swift:311` | `showCursor()` | `openNoteEditor` — editor opens | — |
| `CanvasView.swift:74` | `forceShow()` | `mouseMoved` safety net — non-drawing tool + cursor hidden | — |
| `EditorPanel.swift:191` | `forceShow()` | `resignKey()` | — |
| `EditorPanel.swift:201` | `forceShow()` | `close()` | — |
| `EditorPanel.swift:312` | `showCursor()` | Keyboard switch to select tool (key "1") | — |
| `ToolbarView.swift:332` | `showCursor()` | `mouseEntered` on toolbar | — |
| `CaptureCoordinator.swift:200` | `forceShow()` | `cleanupAfterCapture()` | — |
| `CaptureCoordinator.swift:210` | `forceShow()` | `dismissOverlays()` | — |

---

## 3. Round 1: Hypotheses

### H1: NSCursor stack corruption from CrosshairView's invisible cursor

**File:** `Capture/CrosshairView.swift:15-21`

CrosshairView creates a transparent 1x1 `invisibleCursor` and sets it via `NSCursor(image:hotSpot:)`. When the crosshair is active, this transparent cursor is `set()` on the tracking area. **This is a completely separate mechanism from `NSCursor.hide()`**. However, `CaptureCoordinator.startCapture()` at line 37 ALSO calls `CursorManager.shared.hideCursor()`.

So during capture: the cursor is hidden via `NSCursor.hide()` AND replaced with a transparent cursor. When capture completes, `forceShow()` calls `NSCursor.unhide()` — but the transparent cursor might still be the active cursor if AppKit's cursor rects haven't been recalculated yet.

**Trigger:** Complete a capture → the transparent cursor from CrosshairView is still the active cursor even though `unhide()` was called.

**Why safety nets miss this:** The cursor is technically "shown" (not hidden) — `isCursorHidden` is false — but the active cursor image is a 1x1 transparent pixel. `forceShow()` and `showCursor()` only call `NSCursor.unhide()`, they never call `NSCursor.arrow.set()`.

### H2: `mouseMoved` race between ToolbarView and CanvasView tracking areas

**File:** `CanvasView.swift:68-108`, `ToolbarView.swift:325-333`

When the mouse moves from canvas to toolbar:
1. `CanvasView.mouseExited` fires → `showCursor()` (line 263)
2. `ToolbarView.mouseEntered` fires → `showCursor()` (line 332)

But when the mouse moves from toolbar BACK to canvas:
1. `ToolbarView.mouseExited` fires → **nothing** (no cursor management)
2. `CanvasView.mouseEntered` fires → **nothing** (no `mouseEntered` override)
3. `CanvasView.mouseMoved` eventually fires → line 101 calls `hideCursor()`

**Gap:** Between `mouseEntered` on CanvasView and the first `mouseMoved`, the cursor state depends on the previous state. If the tool state changed while the cursor was over the toolbar (e.g., user clicked a drawing tool button), and then moves back to canvas — the first `mouseMoved` should handle it. **This path seems covered.**

### H3: Capture overlay dismiss + editor open race condition

**File:** `CaptureCoordinator.swift:72-108`

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
    // ... capture image ...
    cleanupAfterCapture()  // line 98: forceShow()
    self.editorPanel?.close()  // line 102
    let panel = EditorPanel(...)  // line 105: installs key monitor
    panel.makeKeyAndOrderFront(nil)  // line 106
    self.editorPanel = panel  // line 107
}
```

`cleanupAfterCapture()` calls `forceShow()` at line 200. Then the new EditorPanel is created. During `EditorPanel.init`, `CanvasView` is created with a tracking area. If the mouse is already over the canvas area when the panel appears, `mouseMoved` fires and — if a drawing tool is active (pin is default) — calls `hideCursor()`.

**This is normal behavior.** The cursor hides because a drawing tool is active. But what if there's a **brief window** where `resignKey()` fires on the old panel AFTER `hideCursor()` was already called by the new panel's canvas? That would call `forceShow()` and corrupt the new panel's expected cursor state. No — `forceShow()` shows the cursor, so this wouldn't cause disappearance.

### H4: `addImageCapture` flow — editor hidden, cursor state leaked

**File:** `EditorPanel.swift:423`, `CaptureCoordinator.swift:22-26`

When "Add image" is clicked:
1. `EditorPanel.toolbarDidRequestAddImage()` line 423: `orderOut(nil)` — hides editor
2. `CaptureCoordinator.startCapture()` line 37: `hideCursor()` — cursor hidden for capture
3. User completes capture → `cleanupAfterCapture()` line 200: `forceShow()` — cursor shown
4. Completion handler at EditorPanel line 437: `makeKeyAndOrderFront(nil)` — editor restored

**Key issue:** When the editor is ordered out at step 1, does `resignKey()` fire? Yes — `orderOut` causes the panel to resign key. So `resignKey()` at EditorPanel line 191 calls `forceShow()`. Then `startCapture()` at line 37 calls `hideCursor()`. Then `cleanupAfterCapture()` calls `forceShow()`. Then `makeKeyAndOrderFront()` makes the editor key again. If the mouse is over the canvas, `mouseMoved` fires and calls `hideCursor()` for the drawing tool.

**But what if the user CANCELS the add-image capture?** `cancelCapture()` line 53 calls `dismissOverlays()` which calls `forceShow()`, then the `onCancel` handler at EditorPanel line 456 calls `makeKeyAndOrderFront(nil)`. This seems balanced.

### H5: **NSCursor.hide() called outside CursorManager — CrosshairView's invisibleCursor bypass**

**File:** `Capture/CrosshairView.swift:15-21`

```swift
private static let invisibleCursor: NSCursor = {
    let image = NSImage(size: NSSize(width: 1, height: 1))
    return NSCursor(image: image, hotSpot: .zero)
}()
```

This cursor is set via `NSCursor` cursor rect or `set()` call somewhere (likely via tracking area `cursorUpdate`). But checking the code — CrosshairView does NOT override `cursorUpdate` or `resetCursorRects`. The invisible cursor is defined but **never actually used via `.set()`** in the current code. Instead, `CursorManager.hideCursor()` is used.

Wait — let me re-check. The invisible cursor is a static property that's allocated but... is it actually used anywhere? Searching for `invisibleCursor` in CrosshairView: it's defined at line 17 but never referenced elsewhere in the file. **This is dead code.** The capture overlay uses `CursorManager.hideCursor()` instead.

### H6: **ToolbarView.mouseEntered calls showCursor() but CanvasView.mouseEntered does NOT — cursor remains shown when re-entering canvas with drawing tool**

**File:** `CanvasView.swift` — no `mouseEntered` override

When the mouse re-enters the canvas from the toolbar, `mouseEntered` is not overridden. The tracking area options include `.mouseEnteredAndExited` (line 59), so `mouseEntered` WILL fire — but the default `NSView.mouseEntered` does nothing. The cursor stays visible until `mouseMoved` fires.

This is a tiny visual glitch (cursor flashes visible for one frame) but not a disappearance bug.

### H7: **Drawing tool active + mouse outside canvas + window move → tracking area not updated**

If the user moves the editor window while a drawing tool is active, the tracking areas may not immediately update. `updateTrackingAreas()` is called by AppKit when the view's position changes, but there could be a brief period where mouse events aren't routed correctly.

**Trigger:** Move the editor window by dragging the toolbar area → mouse ends up inside canvas without a proper `mouseEntered` event → `mouseMoved` fires but `hideCursor()` is called in a tracking area that's stale.

**Why safety nets miss this:** The safety net in `mouseMoved` only fires when the tool is NOT a drawing tool. If a drawing tool is active, `hideCursor()` is called normally.

### H8: **`CanvasView.mouseMoved` line 96-105 — the `else` branch always shows cursor, even for drawing tools when not over canvas content**

```swift
if isDrawingToolActive && !isEditingNote {
    if shouldSuppressGhost {
        CursorManager.shared.showCursor()   // line 98
        NSCursor.arrow.set()                 // line 99
    } else {
        CursorManager.shared.hideCursor()   // line 101
    }
} else {
    CursorManager.shared.showCursor()       // line 104
}
```

When `isEditingNote` is true AND a drawing tool is active, we fall to the `else` branch and `showCursor()` is called. When editing finishes (`confirmNoteEditing` or `cancelNoteEditing`), the code at CanvasView lines 458-460 and 487-489 sets `marksLayer.ghostTool = activeTool` and calls `needsDisplay = true`, but does NOT call `hideCursor()`. The cursor remains visible until the next `mouseMoved` event — which calls `hideCursor()` if conditions are met.

**This is correct behavior — not a bug.**

### H9: **The REAL issue: `mouseMoved` is NOT called when the cursor is already over the canvas and the panel becomes key**

**Trigger sequence:**
1. EditorPanel is open with a drawing tool active → cursor hidden (correct)
2. User Cmd+Tabs away → `resignKey()` fires → `forceShow()` → cursor shown
3. User Cmd+Tabs back → panel becomes key again
4. **Mouse is still over the canvas but `mouseMoved` does NOT fire** because the mouse didn't actually move
5. Cursor remains visible (shown by `forceShow()`) even though a drawing tool is active
6. This is NOT a disappearance — it's the opposite. The cursor is visible when it should be hidden.

This contradicts the bug report. Let me reconsider.

### H10: **The REAL issue: `NSCursor.hide()/unhide()` stack corruption from rapid tool switches during capture flow**

**Trigger sequence:**
1. User starts a capture → `CursorManager.hideCursor()` at CaptureCoordinator:37
2. `isCursorHidden = true`, `NSCursor.hide()` call count = 1
3. Capture completes → `cleanupAfterCapture()` → `forceShow()` → `NSCursor.unhide()`, `isCursorHidden = false`
4. New EditorPanel opens, mouse over canvas with pin tool → `mouseMoved` → `hideCursor()` at CanvasView:101
5. Everything balanced so far.

But what if:
1. User starts capture → `hideCursor()` — stack = 1, flag = true
2. AppKit internally calls `NSCursor.unhide()` for some reason (e.g., when overlay window closes or when screen changes) — stack = 0, but **flag still = true**
3. `forceShow()` at :200 checks flag → true → calls `NSCursor.unhide()` — **stack goes to -1** (extra unhide, but AppKit ignores it: unhide on already-visible cursor is a no-op)
4. Actually, this wouldn't cause disappearance. Extra unhides are safe.

The reverse is dangerous:
1. Something calls `NSCursor.hide()` bypassing CursorManager → stack = 1, flag = false
2. `hideCursor()` at CanvasView:101 checks flag → false → calls `NSCursor.hide()` — stack = 2, flag = true
3. `showCursor()` checks flag → true → calls `NSCursor.unhide()` — stack = 1, flag = false
4. **Cursor still hidden** because stack is 1, not 0.

**Question: does anything call NSCursor.hide() directly, bypassing CursorManager?**

Searching: no direct `NSCursor.hide()` or `NSCursor.unhide()` calls outside CursorManager in the codebase. **But** what about AppKit framework code? Some AppKit controls (NSPopUpButton, NSMenu, context menus) may internally call `NSCursor.hide()` during tracking.

---

## 4. Round 2: Critique

| # | Hypothesis | Rating | Evidence |
|---|-----------|--------|----------|
| H1 | CrosshairView invisible cursor bypasses CursorManager | **Unlikely** | `invisibleCursor` is defined but never used (`.set()` never called) — dead code |
| H2 | Toolbar ↔ Canvas tracking area race | **Unlikely** | Both paths converge to `mouseMoved` which handles state correctly |
| H3 | Capture dismiss + editor open race | **Unlikely** | `forceShow()` shows cursor; new editor's `mouseMoved` re-hides correctly |
| H4 | addImageCapture cursor leak | **Unlikely** | All paths call `forceShow()` before editor restores |
| H5 | Dead invisible cursor code | **Unlikely** | Never used — not the cause |
| H6 | CanvasView.mouseEntered missing | **Possible** | Brief cursor flash, but not a disappearance |
| H7 | Window move + stale tracking area | **Possible** | Could cause brief inconsistency, but `mouseMoved` self-corrects |
| H8 | Note editing + drawing tool | **Unlikely** | Correctly falls to showCursor path |
| H9 | resignKey/becomeKey without mouseMoved | **Possible** | But this shows cursor, not hides it — opposite of bug |
| H10 | NSCursor stack corruption via AppKit internals | **LIKELY** | If an NSPopUpButton (title pill role dropdown) or NSMenu internally calls hide/unhide, it corrupts CursorManager's flag |

**Additional hypothesis from code review:**

### H11: **NSPopUpButton in TitlePillView triggers AppKit cursor manipulation**

**File:** `Views/TitlePillView.swift` — contains an NSPopUpButton for role selection.

When the user clicks the role dropdown in a title pill, NSPopUpButton internally manages cursor visibility for its menu tracking. If the menu tracking calls `NSCursor.hide()` internally, it bypasses CursorManager. When the menu dismisses, AppKit calls `NSCursor.unhide()`, but CursorManager's `isCursorHidden` flag is now wrong.

**Rating: LIKELY** — This would explain the "random" nature: it happens when the user interacts with the role dropdown in filmstrip mode.

### H12: **Right-click context menus or tooltips from AppKit controls**

Any AppKit control that shows a tooltip or context menu may internally manipulate the cursor stack. CursorManager wouldn't know about these manipulations.

**Rating: POSSIBLE** — Could explain intermittent disappearance, but the app doesn't use right-click menus.

---

## 5. Round 3: Deep Dive on Top 3

### Deep Dive 1: H10/H11 — AppKit internal cursor manipulation (NSPopUpButton, NSMenu)

**The core problem:** CursorManager tracks a boolean `isCursorHidden` but NSCursor uses a **counter-based stack**. Any code — including AppKit internals — that calls `NSCursor.hide()` or `NSCursor.unhide()` without going through CursorManager will desynchronize the flag from the actual stack.

**Specific scenario with NSPopUpButton:**
1. Drawing tool active → `hideCursor()` at CanvasView:101 — stack=1, flag=true
2. User clicks role dropdown → NSPopUpButton menu tracking begins
3. AppKit internally calls `NSCursor.unhide()` to show cursor during menu — stack=0, flag=**still true**
4. User selects a role → menu dismisses
5. AppKit internally calls `NSCursor.hide()` to restore pre-menu state — stack=1, flag=**still true**
6. Or: AppKit does NOT restore hide, leaving stack=0, flag=true
7. `mouseMoved` fires → safety net checks `isCursorHidden` → true → no action (or not applicable if drawing tool active)
8. Drawing tool path at line 101: `guard !isCursorHidden` → flag is true → **SKIPS** `NSCursor.hide()` call
9. Cursor is visible but CursorManager thinks it's hidden

**Actually, the more dangerous scenario:**
1. Drawing tool active → cursor hidden (stack=1, flag=true)
2. AppKit internal `NSCursor.unhide()` → stack=0, flag=still true
3. `mouseExited` at CanvasView:263 → `showCursor()` → checks flag=true → `NSCursor.unhide()` → stack=-1 (no-op, ignored)
4. Flag set to false
5. `mouseMoved` later → `hideCursor()` → checks flag=false → `NSCursor.hide()` → stack=0 → cursor visible but flag=true
6. Now balanced again? Actually no — we went to -1 then back to 0. Stack is 0 = visible. But flag is true.
7. Safety net: `forceShow()` checks flag=true → calls `unhide()` → stack=-1 (no-op). Flag=false.
8. Actually this self-corrects. The -1 case is a no-op.

**The truly dangerous scenario:** Multiple rapid hide() calls getting through CursorManager's guard.

Wait — CursorManager's guard IS correct for preventing double-hides from its own code. The issue is when **external code** (AppKit) adds extra hide/unhide calls to the stack.

**Key insight:** If AppKit calls `NSCursor.hide()` (stack goes from 1 to 2) and then `NSCursor.unhide()` (stack goes from 2 to 1), and CursorManager's flag remains true throughout — then when CursorManager tries to unhide (e.g., mouseExited), it calls unhide once (stack 1→0). **This is correct.** The AppKit manipulation was balanced.

**The REAL danger:** If AppKit calls `NSCursor.unhide()` without a matching `hide()` (or vice versa). This would permanently offset the stack.

### Deep Dive 2: CursorManager `forceShow()` is identical to `showCursor()`

**File:** `CursorManager.swift:27-32`

```swift
func forceShow() {
    if isCursorHidden {
        NSCursor.unhide()
        isCursorHidden = false
    }
}
```

This is identical to `showCursor()` except it uses `if` instead of `guard`. **The name "forceShow" is misleading** — it doesn't force anything. If `isCursorHidden` is false (but the cursor is actually hidden due to stack corruption), `forceShow()` does nothing.

**A true force-show would need to:**
1. Call `NSCursor.unhide()` regardless of flag state
2. Reset the flag to false
3. Possibly call `NSCursor.unhide()` multiple times to drain the stack

**Proposed fix:** Replace `forceShow()` with a proper stack-drain:
```swift
func forceShow() {
    // Drain the entire NSCursor hide stack
    while NSCursor.isHidden { // Note: there's no public API for this
        NSCursor.unhide()
    }
    isCursorHidden = false
}
```

**Problem:** `NSCursor` does not expose a public `isHidden` property. There's no way to query the stack depth.

**Alternative fix:** Call `NSCursor.unhide()` unconditionally, then reset flag:
```swift
func forceShow() {
    NSCursor.unhide()  // always call, even if flag says not hidden
    isCursorHidden = false
}
```

This risks going to -1 on the stack, but AppKit handles that gracefully (it's a no-op).

### Deep Dive 3: `mouseMoved` safety net is too narrow

**File:** `CanvasView.swift:72-75`

```swift
if activeTool?.toolType.isDrawingTool != true && CursorManager.shared.isCursorHidden {
    CursorManager.shared.forceShow()
}
```

This only fires when:
- Active tool is NOT a drawing tool
- AND `isCursorHidden` flag is true

It does NOT fire when:
- Active tool IS a drawing tool but cursor is actually visible (flag desync)
- `isCursorHidden` is false but cursor is actually hidden (stack corruption)
- Mouse is not over the canvas at all

**Proposed fix:** The safety net should also handle the case where cursor should be visible but isn't. Since we can't query NSCursor's actual state, the fix should be at the CursorManager level.

---

## 6. Recommended Fix

### Root Cause
CursorManager uses a boolean flag to track cursor state, but NSCursor uses a stack-based counter. Any desynchronization (from AppKit internal calls, from edge cases in event ordering, or from flag corruption) means `forceShow()` fails silently because the flag says "already shown" while the cursor is actually hidden.

### Fix Approach

**Option A: Make `forceShow()` truly unconditional (RECOMMENDED)**

Change `forceShow()` to always call `NSCursor.unhide()` regardless of flag state, then set flag to false. Call it multiple times (e.g., 3×) to drain any accumulated stack depth:

```swift
func forceShow() {
    // Drain any NSCursor.hide() stack corruption from AppKit internals
    for _ in 0..<3 {
        NSCursor.unhide()
    }
    NSCursor.arrow.set()  // Also reset the active cursor image
    isCursorHidden = false
}
```

This ensures:
- Stack depth up to 3 is drained (we only ever hide once, so 3 is generous)
- The arrow cursor is explicitly set (covers H1 if invisible cursor were ever used)
- The flag is synchronized

**Where to apply:** `forceShow()` is called in 4 places:
- `EditorPanel.resignKey()` — window deactivation
- `EditorPanel.close()` — window close
- `CaptureCoordinator.cleanupAfterCapture()` — capture complete
- `CaptureCoordinator.dismissOverlays()` — capture canceled

All of these are "transition" moments where we want to guarantee cursor visibility.

**Option B: Add periodic safety net (complementary)**

Add a timer-based safety net that checks cursor state every 2 seconds:
```swift
// In EditorPanel or AppDelegate
Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
    if !CursorManager.shared.isCursorHidden {
        // We think cursor is visible — verify by checking if we're not in a drawing tool context
        // If the user can see this timer fire and their cursor is invisible, force-show
    }
}
```

This is a nuclear option and shouldn't be needed if Option A works. **Recommend Option A only.**

**Option C: Replace boolean with counter (defense in depth)**

Track the actual hide count instead of a boolean:
```swift
private var hideCount = 0

func hideCursor() {
    NSCursor.hide()
    hideCount += 1
}

func showCursor() {
    guard hideCount > 0 else { return }
    NSCursor.unhide()
    hideCount -= 1
}

func forceShow() {
    while hideCount > 0 {
        NSCursor.unhide()
        hideCount -= 1
    }
    // Extra unhide for any AppKit-internal hides we didn't track
    NSCursor.unhide()
    NSCursor.arrow.set()
}
```

This mirrors NSCursor's actual stack behavior. **Recommend this as the long-term solution** combined with the unconditional drain in `forceShow()`.
