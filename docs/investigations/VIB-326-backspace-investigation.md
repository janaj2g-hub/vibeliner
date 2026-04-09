# VIB-326 Investigation: Backspace Doesn't Work After New Capture

**Date:** 2026-04-09
**Type:** Root-cause investigation (no code changes)
**Previous fix:** Moved `NSEvent.removeMonitor` from `deinit` to `close()` — backspace STILL fails

---

## 1. Event Monitor Inventory

| File:Line | Type | Matching events | Installed when | Removed when |
|-----------|------|-----------------|----------------|--------------|
| `EditorPanel.swift:163` | Local (.keyDown) | All keyDown in app | `init()` | `close()` at :197 + `deinit` at :183 |
| `HotkeyManager.swift:63` | Global (.keyDown) | keyDown when app not focused | `register()` | `unregister()` at :148 |
| `HotkeyManager.swift:72` | Local (.keyDown) | keyDown when app focused | `register()` | `unregister()` at :152 |
| `HotkeyCapturePanel.swift:65` | Local (.keyDown) | keyDown during hotkey capture | Sheet presented | `close()` at :93 |
| `PopoverViewController.swift:60` | Global (mouseDown) | Left/right click outside app | Popover shown | Popover hidden at :68 |

**Key insight:** There are **3 local keyDown monitors** potentially active simultaneously:
1. EditorPanel's keyMonitor
2. HotkeyManager's localMonitor
3. HotkeyCapturePanel's monitor (only during hotkey capture)

---

## 2. Key Event Flow: Backspace Through the Responder Chain

When the user presses Backspace in a text field:

```
NSEvent (.keyDown, keyCode 51)
  ↓
1. NSEvent LOCAL MONITORS (in registration order):
   a. HotkeyManager.localMonitor → checks isHotkeyMatch → NO for backspace → returns event (pass through)
   b. EditorPanel.keyMonitor → checks isEditingNote? → if YES: only Escape consumed, returns event
                              → if NO: calls handleKeyEvent() → KeyEventGuard check
   c. (HotkeyCapturePanel.monitor — only if sheet is shown)
  ↓
2. NSApp.sendEvent → NSWindow.sendEvent
  ↓
3. performKeyEquivalent chain (responder chain, top-down):
   a. EditorPanel.performKeyEquivalent → checks isEditingNote? → if YES: handles Cmd+C/V/X/A/Z only
                                        → for plain Backspace: returns false
  ↓
4. keyDown chain (responder chain, first responder up):
   a. NSTextView (field editor) → handles Backspace for text deletion
   b. OR: EditorPanel.keyDown → calls handleKeyEvent()
```

### The critical path for backspace in a note text field:

1. **EditorPanel.keyMonitor** (local monitor at :163):
   - Checks `canvas.isEditingNote` at line 167
   - If editing: only intercepts Escape (keyCode 53), **returns event** for everything else
   - **Backspace passes through** ✓

2. **EditorPanel.handleKeyEvent** — should NOT be reached during note editing because the monitor returns the event before calling `handleKeyEvent`.

3. **But what about `EditorPanel.keyDown`** at line 261?
   - This is the `NSWindow.keyDown` override
   - It calls `handleKeyEvent()` which checks `isEditingNote` at line 271
   - If editing: only Escape consumed, returns false → `super.keyDown()` → responder chain

4. **`handleKeyEvent()` at line 327-333**: Delete/Backspace handling:
   ```swift
   } else if keyCode == 51 || keyCode == 117 { // Delete/Backspace
       if annotationStore.selectedAnnotation != nil {
           toolbarView.delegate?.toolbarDidRequestDelete()
       } else if isFilmstripMode, images.count > 1 {
           removeImageAtIndex(filmstripView?.selectedIndex ?? 0)
       }
       return true  // ← ALWAYS returns true, even if no action taken!
   }
   ```
   
   **CRITICAL FINDING:** `handleKeyEvent()` returns `true` for Delete/Backspace **unconditionally** — even when nothing is selected and we're not in filmstrip mode. The `return true` at line 333 is outside the `if` blocks. This means **backspace is ALWAYS consumed** by `handleKeyEvent()` if it gets there.

5. **KeyEventGuard.shouldHandleShortcut** at line 282:
   - Called before the keyCode checks
   - Returns `false` when a text field/text view is first responder
   - Causes `handleKeyEvent()` to return `false` → backspace passes through ✓

---

## 3. New Capture Flow: Step-by-Step

When the user clicks "New capture" (or uses the hotkey from within the editor):

### Via toolbar button:
1. `EditorPanel.toolbarDidRequestNewCapture()` at line 397
2. `autoSaveManager?.saveNow()` at line 398
3. `close()` at line 399:
   - Removes keyMonitor at line 197-199 ✓
   - Calls `CursorManager.shared.forceShow()` at line 201
   - Calls `super.close()` at line 203
4. `DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)` at line 400
5. After 200ms: `CaptureCoordinator.shared.startCapture()` at line 401

### Via hotkey (Cmd+Shift+6):
1. `HotkeyManager.localMonitor` fires → `onHotkeyPressed?()` → dispatches to main
2. `CaptureCoordinator.shared.startCapture()` at line 28
3. Capture overlay opens
4. User selects region
5. `completeSelection()` at line 62:
   - Overlays ordered out at line 67-69
   - After 50ms delay at line 72:
     - Image captured
     - `cleanupAfterCapture()` at line 98
     - **`self.editorPanel?.close()`** at line 102 — closes OLD editor
     - New EditorPanel created at line 105
     - `panel.makeKeyAndOrderFront(nil)` at line 106
     - `self.editorPanel = panel` at line 107

### Critical timing analysis of the hotkey path:

The issue is at `CaptureCoordinator.completeSelection()` lines 100-107:

```swift
// VIB-311+326: Close old editor first — removes its stale key monitor
self.editorPanel?.close()  // line 102

// Open editor panel
let panel = EditorPanel(image: image, on: screen, captureFolder: folderURL)  // line 105
panel.makeKeyAndOrderFront(nil)  // line 106
self.editorPanel = panel  // line 107
```

**At line 102:** Old editor's `close()` runs:
- `NSEvent.removeMonitor(keyMonitor)` at EditorPanel:198 ✓
- `keyMonitor = nil` at EditorPanel:199

**At line 105:** New editor's `init()` runs:
- New `keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown)` at EditorPanel:163

**This looks correct.** Old monitor removed, new monitor installed. No overlap.

---

## 4. Round 1: Hypotheses

### H1: EditorPanel.close() not actually called — `deinit` never fires either

**File:** `CaptureCoordinator.swift:102`

`self.editorPanel?.close()` — what if `editorPanel` is nil? This would skip close entirely. The old monitor stays alive.

**When could it be nil?** Only if it was never set or already set to nil. Looking at the code: `self.editorPanel = panel` at line 107 always sets it. It's only nil before the first capture.

**Rating: Unlikely** — `editorPanel` is set on first capture.

### H2: Old EditorPanel not deallocated — `isReleasedWhenClosed = false`

**File:** `EditorPanel.swift:90`

```swift
isReleasedWhenClosed = false
```

After `close()` is called, the panel is removed from screen but **not deallocated**. The reference at `CaptureCoordinator.editorPanel` is overwritten at line 107, so the old panel should be eligible for deallocation. **But** if any other reference holds the old panel (e.g., a strong reference in a closure, a NotificationCenter observer, or the `autoSaveManager`), the old panel persists in memory.

**Even though the keyMonitor was removed in close()**, could there be another issue? Let me check...

The old panel's `deinit` would remove the notification observer at line 181. If `deinit` doesn't run (because the panel is retained), the `storeObserver` notification at line 149 stays active — but that's for annotation changes, not key events.

**Rating: Possible** — Memory leak of old panel, but keyMonitor is properly removed in `close()`.

### H3: **HotkeyManager's local monitor intercepts backspace before EditorPanel's monitor**

**File:** `HotkeyManager.swift:72-81`

```swift
localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
    if self?.isHotkeyMatch(event) == true {
        // ...
        return nil  // consumed
    }
    return event  // pass through
}
```

This monitor is always active (registered at app launch, never unregistered during normal use). It checks `isHotkeyMatch` which tests for the configured hotkey (default: Cmd+Shift+6). **Backspace doesn't match** → returns event.

**Rating: Unlikely** — Hotkey monitor passes through non-matching events.

### H4: **`handleKeyEvent()` line 333 consumes Backspace unconditionally**

**File:** `EditorPanel.swift:327-334`

```swift
} else if keyCode == 51 || keyCode == 117 { // Delete/Backspace
    if annotationStore.selectedAnnotation != nil {
        toolbarView.delegate?.toolbarDidRequestDelete()
    } else if isFilmstripMode, images.count > 1 {
        removeImageAtIndex(filmstripView?.selectedIndex ?? 0)
    }
    return true  // ← ALWAYS CONSUMED
}
```

`return true` at line 333 is **outside** the `if/else if` blocks. Even when no annotation is selected and we're not in filmstrip mode, `handleKeyEvent` returns `true`, which causes the keyMonitor to return `nil` (swallowing the event).

**But this should be gated by KeyEventGuard!** Line 282:
```swift
guard KeyEventGuard.shouldHandleShortcut(in: self) else { return false }
```

If a text field is first responder, `shouldHandleShortcut` returns false and `handleKeyEvent` returns false early, so line 333 is never reached.

**AND** the keyMonitor at line 167 checks `isEditingNote` first:
```swift
if let canvas = self.canvasOverlay, canvas.isEditingNote {
    if event.keyCode == 53 { // Escape
        canvas.cancelNoteEditing()
        return nil
    }
    return event  // pass through
}
```

So if a **note** is being edited, the monitor returns the event before `handleKeyEvent` is called.

**KEY QUESTION:** What if the user is editing a **title pill text field** (not a note)? `isEditingNote` would be false because it's based on `activeNoteField != nil`. The title pill's text field is NOT tracked by `isEditingNote`.

In that case:
1. keyMonitor fires
2. `isEditingNote` is false → falls through to `handleKeyEvent(event)`
3. `handleKeyEvent()` at line 282: `KeyEventGuard.shouldHandleShortcut(in: self)`
4. `shouldHandleShortcut` checks `window.firstResponder` — if it's the title pill's NSTextView field editor → returns false
5. `handleKeyEvent` returns false → keyMonitor returns the event (pass through)
6. Backspace reaches the title pill text field ✓

**So this path is covered.** But wait — what if `window.firstResponder` is NOT the field editor for some reason?

### H5: **First responder not properly set on new EditorPanel**

**File:** `CaptureCoordinator.swift:106`

```swift
panel.makeKeyAndOrderFront(nil)
```

The new panel becomes key window. But no `makeFirstResponder` is called. The first responder is the panel itself (or its content view). When the user later clicks on a note to edit it, `openNoteEditor` at CanvasView:383 dispatches `makeFirstResponder(tf)` asynchronously.

**Between opening the new editor and clicking a note:** The first responder is the panel's content view (an NSView), not a text field. `KeyEventGuard.shouldHandleShortcut` returns true. `handleKeyEvent` runs normally. Backspace at line 333 returns true → **consumed**.

**But this is correct!** There's no text field to receive backspace. The user shouldn't be typing into anything at this point.

### H6: **`isEditingNote` is false but a field editor is active — stale first responder from old editor**

**Trigger sequence:**
1. Old editor is open, user is editing a note (field editor is active, isEditingNote = true)
2. User presses hotkey (Cmd+Shift+6) without confirming the note
3. HotkeyManager.localMonitor fires → `onHotkeyPressed()` → `startCapture()`
4. CaptureCoordinator.startCapture() runs → overlays open
5. User completes capture
6. `completeSelection()` → `self.editorPanel?.close()` at line 102
7. Old editor's `close()` runs:
   - Removes keyMonitor ✓
   - But does NOT call `confirmNoteEditing()` or `cancelNoteEditing()`
   - The old CanvasView's `activeNoteField` is non-nil but the view is being destroyed
   - `autoSaveManager?.saveNow()` is NOT called in this path (it IS called in `toolbarDidRequestNewCapture` but NOT in `completeSelection`)

8. New editor opens at line 105
9. New editor's `isEditingNote` = false (fresh CanvasView)
10. User clicks on note in new editor → `openNoteEditor` → `makeFirstResponder(tf)`
11. Backspace should work because `isEditingNote` is now true

**Hmm, this doesn't explain the bug.** Let me reconsider.

### H7: **The keyMonitor closure captures `self` weakly — but the NEW editor's monitor checks the NEW editor's state**

After the new editor is created at CaptureCoordinator line 105, its `init` at EditorPanel:163 installs a fresh keyMonitor. The closure captures `[weak self]` where `self` is the NEW EditorPanel. The new canvas's `isEditingNote` starts as false.

When the user types in a note in the new editor:
1. `openNoteEditor` sets `editingAnnotationId` and `activeNoteField`
2. `isEditingNote` returns true
3. keyMonitor checks `isEditingNote` → true → only Escape consumed, returns event
4. Backspace reaches field editor ✓

**This should work.** Unless...

### H8: **`performKeyEquivalent` swallows Backspace on borderless panel**

**File:** `EditorPanel.swift:211-258`

The `performKeyEquivalent` override handles Cmd+C/V/X/A/Z/W. For plain Backspace (no modifiers):
- Line 215: `flags == .command` → false (no modifiers)
- Falls through to line 238: `flags == .command` → false
- Returns false at line 258

**Backspace should NOT be swallowed by performKeyEquivalent.** ✓

### H9: **`EditorPanel.keyDown` override at line 261 — reached when keyMonitor returns the event**

When `isEditingNote` is true, the keyMonitor at line 167-173 returns the event (passes through). The event then goes through the normal responder chain:
1. `performKeyEquivalent` on EditorPanel → returns false for Backspace
2. `keyDown` on first responder (the field editor NSTextView) → handles Backspace ✓

But wait — does `EditorPanel.keyDown` at line 261 also fire?

**NO.** `EditorPanel.keyDown` fires only if the event reaches the NSPanel in the responder chain. If the field editor (NSTextView) handles Backspace in its own `keyDown`, the event does not bubble up to the panel.

**UNLESS:** The field editor's `keyDown` doesn't handle Backspace. This could happen if `doCommandBySelector:` is overridden and the `deleteBackward:` selector is intercepted.

**File:** `CanvasView.swift:515-521`

```swift
func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
        canvas?.cancelNoteEditing()
        return true
    }
    return false
}
```

Only `cancelOperation:` (Escape) is intercepted. `deleteBackward:` (Backspace) returns false → handled normally by text view. ✓

### H10: **The bug is in `keyDown` path, not keyMonitor — the event reaches handleKeyEvent via EditorPanel.keyDown**

Let me reconsider the event flow for the new editor after new capture:

1. User opens note in new editor
2. `makeFirstResponder(textField)` runs async (CanvasView:383)
3. **For a brief moment**, the first responder is still the panel content view
4. If user types during that brief moment: keyMonitor fires, `isEditingNote` is true (because `editingAnnotationId` was set at line 374 BEFORE the async `makeFirstResponder`), event is returned
5. Event reaches responder chain → but first responder is NOT the field editor yet → event goes to panel → `keyDown` → `handleKeyEvent`
6. `handleKeyEvent` checks `isEditingNote` at line 271 → true → returns false for backspace
7. `super.keyDown()` → no one handles it → beep

**Rating: Possible but brief** — Only during the async gap in `openNoteEditor`.

### H11: **The REAL issue — focus/responder chain breaks after editor panel window ordering**

**Trigger sequence:**
1. First editor open, user is NOT editing a note
2. User takes new capture via hotkey
3. Capture completes
4. Old editor closes, new editor opens and becomes key
5. User clicks on a note in new editor → `openNoteEditor` → sets up field
6. `DispatchQueue.main.async` at line 383: `window.makeKeyAndOrderFront(nil)` + `window.makeFirstResponder(tf)`
7. First responder is now the text field → field editor becomes actual first responder
8. User types → backspace should work via field editor

**But what if `window.makeKeyAndOrderFront(nil)` at line 385 triggers `resignKey` on the same window temporarily?** No — it's already the key window.

I'm not finding a clear single root cause. Let me look at the problem from a different angle.

### H12: **Multiple `handleKeyEvent` calls — keyMonitor AND keyDown both fire**

For a single keyDown event:
1. Local monitors fire first (order of registration)
2. If the monitor returns the event (non-nil), AppKit continues
3. The event goes through the responder chain: `performKeyEquivalent` → `keyDown`

**EditorPanel.keyDown at line 261:**
```swift
override func keyDown(with event: NSEvent) {
    if !handleKeyEvent(event) {
        super.keyDown(with: event)
    }
}
```

**So for every non-consumed event, `handleKeyEvent` is called TWICE:**
1. Once from the keyMonitor (line 175)
2. Once from `keyDown` (line 262) — if the event reaches the panel

**During note editing:** The keyMonitor returns the event at line 172 (NOT calling handleKeyEvent). The event goes to the field editor's `keyDown`. If the field editor handles it, the event doesn't reach EditorPanel.keyDown. **Correct.**

**When NOT editing a note:** The keyMonitor calls `handleKeyEvent(event)` at line 175. If handleKeyEvent returns true → monitor returns nil → event consumed. The event never reaches `keyDown`. If handleKeyEvent returns false → monitor returns event → event reaches responder chain → could reach `keyDown` → handleKeyEvent called again. **But since it returned false the first time, it returns false the second time too.** The event passes to `super.keyDown()`.

**This seems correct.** No double-handling.

---

## 5. Round 2: Critique

| # | Hypothesis | Rating | Evidence |
|---|-----------|--------|----------|
| H1 | EditorPanel is nil during close | Unlikely | Always set after first capture |
| H2 | Old panel not deallocated | Possible | `isReleasedWhenClosed = false` but keyMonitor removed in close() |
| H3 | HotkeyManager intercepts backspace | Unlikely | Only matches configured hotkey |
| H4 | handleKeyEvent consumes backspace unconditionally | **LIKELY as root cause** | `return true` at line 333 is always reached for keyCode 51/117 IF KeyEventGuard passes |
| H5 | First responder not set on new panel | Unlikely | Handled by openNoteEditor |
| H6 | Stale first responder from old editor | Possible | Old editor close doesn't resign field editor explicitly — but old window closes |
| H7 | New monitor checks new state | Unlikely | Fresh state is correct |
| H8 | performKeyEquivalent swallows backspace | Unlikely | Only handles Cmd+key combos |
| H9 | keyDown path reached despite monitor | **Possible** | Could double-process under certain conditions |
| H10 | Async gap in makeFirstResponder | **Possible** | Brief window where first responder isn't field editor |
| H11 | Window ordering breaks responder chain | Possible | No clear evidence |
| H12 | handleKeyEvent called twice | Unlikely | Second call returns same result |

---

## 6. Round 3: Deep Dive on Top 3

### Deep Dive 1: H4 — `handleKeyEvent` consuming backspace unconditionally

**File:** `EditorPanel.swift:327-334`

The code:
```swift
} else if keyCode == 51 || keyCode == 117 { // Delete/Backspace
    if annotationStore.selectedAnnotation != nil {
        toolbarView.delegate?.toolbarDidRequestDelete()
    } else if isFilmstripMode, images.count > 1 {
        removeImageAtIndex(filmstripView?.selectedIndex ?? 0)
    }
    return true  // ← BUG: Always consumed
}
```

**The `return true` should be inside the `if`/`else if` blocks.** When no annotation is selected and we're not in filmstrip mode (or only 1 image), backspace is consumed with no action.

**But how does this cause the reported bug?** The KeyEventGuard at line 282 should prevent this from being reached during text editing. Let me trace more carefully:

**Scenario:** User is editing a **title pill** text field in filmstrip mode (not a note).

1. keyMonitor fires at line 163
2. `canvas.isEditingNote` → false (title pill is not tracked as a note)
3. Falls to `handleKeyEvent(event)` at line 175
4. `handleKeyEvent` at line 282: `KeyEventGuard.shouldHandleShortcut(in: self)`
5. `shouldHandleShortcut` checks `window?.firstResponder`:
   - If the title pill's field editor (NSTextView) is first responder → returns false ✓
   - `handleKeyEvent` returns false, monitor returns event, backspace passes through

**This should work.** Unless the title pill's field editor is NOT the first responder for some reason.

**Alternative scenario:** The title pill uses a custom NSTextField, and its field editor is a standard NSTextView. When the user clicks the title pill, does `makeFirstResponder` get called? TitlePillView likely uses `becomeFirstResponder` or AppKit's default field activation.

### Deep Dive 2: H10 — Async gap in `openNoteEditor`

**File:** `CanvasView.swift:372-392`

```swift
// VIB-204 (attempt 3): Set editingAnnotationId BEFORE adding pill to view
editingAnnotationId = annotation.id  // line 374 — isEditingNote becomes true
// ...
notesLayer.addSubview(pillContainer)  // line 378
activeNoteField = textField  // line 379

// VIB-193: Force panel to become key so makeFirstResponder works
DispatchQueue.main.async { [weak self, weak textField] in  // line 383
    guard let self, let window = self.window, let tf = textField else { return }
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(tf)  // line 386
    // ...
}
```

Between line 379 and the async block at 383:
- `isEditingNote` is true (activeNoteField is set)
- But `window.firstResponder` is NOT the text field yet

If a keyDown event fires in this gap:
1. keyMonitor checks `isEditingNote` → true → returns event (doesn't call handleKeyEvent) ✓
2. Event goes to responder chain
3. First responder is NOT the field editor → event reaches panel → `keyDown` → `handleKeyEvent`
4. `handleKeyEvent` checks `isEditingNote` at line 271 → true → returns false for backspace
5. `super.keyDown()` → no handler → system beep

**This could cause ONE backspace failure** when opening the note editor, but it self-corrects once `makeFirstResponder` completes. This wouldn't explain persistent backspace failure.

### Deep Dive 3: Revised theory — **Something prevents `close()` from running on the old EditorPanel**

**File:** `CaptureCoordinator.swift:100-107`

What if the issue is specific to the **toolbar "New capture" button path** vs the **hotkey path**?

**Toolbar path (EditorPanel.toolbarDidRequestNewCapture):**
```swift
func toolbarDidRequestNewCapture() {
    autoSaveManager?.saveNow()
    close()  // ← removes keyMonitor
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        CaptureCoordinator.shared.startCapture()
    }
}
```

Here, `close()` runs BEFORE capture starts. Monitor removed. ✓

**Hotkey path (CaptureCoordinator.completeSelection):**
```swift
self.editorPanel?.close()  // line 102 — removes old monitor
let panel = EditorPanel(...)  // line 105 — installs new monitor
```

Both paths properly close the old editor before creating the new one. ✓

**BUT** — what about the **hotkey path where the user takes a capture while the editor is open**?

1. HotkeyManager.localMonitor fires Cmd+Shift+6
2. `onHotkeyPressed?()` → dispatches to main
3. Main thread: `CaptureCoordinator.shared.startCapture()` at CaptureCoordinator:28
4. `guard !isCapturing` → true (not currently capturing) → proceeds
5. Capture overlays open
6. User selects region → `completeSelection()`
7. 50ms later: old editor closed at line 102, new editor created at line 105

**Everything seems correct.** The old editor IS closed.

### Revised H4a: **What if `close()` doesn't actually remove the monitor because `keyMonitor` is already nil?**

Could there be a path where `keyMonitor` is set to nil before `close()` runs?

Looking at EditorPanel, `keyMonitor` is set to nil only in:
- `close()` at line 199 (after removing the monitor)
- `deinit` at line 184 (implicit, after removing)

No other code sets it to nil. ✓

### Revised H13: **The bug was actually fixed but a DIFFERENT backspace issue persists**

The original bug (backspace doesn't work in the SECOND editor after new capture) was fixed by moving removeMonitor to close(). But a DIFFERENT manifestation might remain:

**Scenario:** After taking a new capture, backspace doesn't work **until the user clicks inside the text field again**. This could be because:
1. The text field has focus (is first responder)
2. But the **field editor** didn't properly activate
3. The field editor needs a mouse click or `becomeFirstResponder` to fully engage text editing

This would be a **first responder chain** issue, not an event monitor issue.

**Checking:** In `openNoteEditor` at CanvasView:383-391:
```swift
DispatchQueue.main.async {
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(tf)
    if let fieldEditor = window.fieldEditor(true, for: tf) as? NSTextView {
        fieldEditor.insertionPointColor = DesignTokens.red
        fieldEditor.setSelectedRange(NSRange(location: fieldEditor.string.count, length: 0))
    }
}
```

`makeFirstResponder(tf)` triggers AppKit to create a field editor and make it first responder. The `fieldEditor(true, for: tf)` call ensures it's created. The cursor is positioned at the end.

**This should work.** But what if the window is not yet key when `makeFirstResponder` is called? Line 385 calls `makeKeyAndOrderFront(nil)` first. ✓

---

## 7. Recommended Fix

### Root Cause Assessment

The most likely remaining cause is **not a single smoking gun** but a combination of edge cases:

1. **Primary:** `handleKeyEvent()` line 333 returns `true` for Delete/Backspace unconditionally, even when no action is taken. If KeyEventGuard fails to detect an active text field for any reason (edge case in field editor lifecycle), backspace is silently consumed.

2. **Secondary:** The `isEditingNote` check in the keyMonitor only covers **annotation note** text fields, not title pill text fields or any other text input that might exist in the editor.

3. **Tertiary:** The async gap in `openNoteEditor` between setting `activeNoteField` and `makeFirstResponder` could briefly break backspace.

### Fix Approach (3 changes):

**Fix 1: Make Delete/Backspace handling conditional (CRITICAL)**

In `handleKeyEvent()`, move `return true` inside the action blocks:
```swift
} else if keyCode == 51 || keyCode == 117 {
    if annotationStore.selectedAnnotation != nil {
        toolbarView.delegate?.toolbarDidRequestDelete()
        return true
    } else if isFilmstripMode, images.count > 1 {
        removeImageAtIndex(filmstripView?.selectedIndex ?? 0)
        return true
    }
    return false  // Don't consume if no action taken
}
```

This ensures backspace passes through to the responder chain when there's nothing to delete.

**Fix 2: Broaden isEditing check in keyMonitor (IMPORTANT)**

Replace the narrow `canvas.isEditingNote` check with a broader "is any text field active" check:
```swift
keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
    guard let self, self.isVisible else { return event }
    
    // If ANY text field is editing, only intercept Escape
    if !KeyEventGuard.shouldHandleShortcut(in: self) {
        if event.keyCode == 53 { // Escape
            if let canvas = self.canvasOverlay, canvas.isEditingNote {
                canvas.cancelNoteEditing()
                return nil
            }
        }
        return event  // pass ALL other keys through to text field
    }
    
    return self.handleKeyEvent(event) ? nil : event
}
```

This uses KeyEventGuard as the primary gate, covering notes, title pills, and any future text inputs.

**Fix 3: Remove async gap in openNoteEditor (MINOR)**

Move `editingAnnotationId` and `activeNoteField` assignment inside the async block, after `makeFirstResponder`:
```swift
DispatchQueue.main.async { [weak self, weak textField] in
    guard let self, let window = self.window, let tf = textField else { return }
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(tf)
    self.editingAnnotationId = annotation.id
    self.activeNoteField = tf
    // ...
}
```

**Caveat:** This changes the order of `editingAnnotationId` being set vs. `refreshNotePills()` — would need careful testing.

### Recommended priority:
1. **Fix 1** — highest impact, fixes the silent consumption bug
2. **Fix 2** — eliminates the class of bugs where non-note text fields are affected
3. **Fix 3** — minor, only affects the brief async gap
