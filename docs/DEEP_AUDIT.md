# Deep Architecture Audit — VIB-173B

**Date:** 2026-04-02
**Codebase:** 45 Swift files, ~6,750 lines total
**Audit type:** READ-ONLY diagnostic. No code changes.

---

## Part 1: File-Level Inventory

| File | Lines | Responsibility | Convention | Funcs | External Refs | Potentially Dead Functions |
|---|---|---|---|---|---|---|
| `App/main.swift` | 6 | App entry point | N/A | 0 | — | — |
| `App/AppDelegate.swift` | 131 | Menu bar setup, hotkey wiring, popover management | Yes | 4 | — | `createCrosshairImage` (only internal) |
| `App/VisualTestHarness.swift` | 279 | Debug test window with sample annotations | Yes | 5 | 1 | `smoothPoints` (duplicate of FreehandTool's) |
| `Annotations/AnnotationModel.swift` | 48 | Data model: AnnotationToolType, AnnotationPosition, Annotation struct | Yes | 0 | — | — |
| `Annotations/AnnotationStore.swift` | 95 | Single source of truth for annotation state, CRUD operations | Yes | 12 | 12 | — |
| `Annotations/UndoRedoManager.swift` | 76 | Linear undo/redo stack | Yes | 5 | 3 | — |
| `Annotations/Tools/PinTool.swift` | 64 | Pin placement: click to place, ghost preview | Yes (Tool) | 11 | 1 | `hitTestPin`, `drawBadge` (internal helpers) |
| `Annotations/Tools/ArrowTool.swift` | 47 | Arrow placement: drag start→end | Yes (Tool) | 4 | 1 | — |
| `Annotations/Tools/RectangleTool.swift` | 55 | Rectangle placement: drag origin→corner | Yes (Tool) | 5 | 1 | `rectFromPoints` (internal) |
| `Annotations/Tools/CircleTool.swift` | 49 | Circle placement: drag center→perimeter | Yes (Tool) | 4 | 1 | — |
| `Annotations/Tools/FreehandTool.swift` | 89 | Freehand drawing: collect points, smooth, store | Yes (Tool) | 6 | 1 | `downsample` (still defined, no longer called) |
| `Annotations/Tools/SelectTool.swift` | 253 | Select mode: hit testing, badge drag, handle resize | Yes (Tool) | 6 | 1 | — |
| `Annotations/Renderers/PinRenderer.swift` | 74 | Pin rendering: badge + stake + ghost glow | Yes (Renderer) | 4 | 2 | — |
| `Annotations/Renderers/ArrowRenderer.swift` | 85 | Arrow rendering: line + chevron + badge + number | Yes (Renderer) | 3 | 2 | — |
| `Annotations/Renderers/RectangleRenderer.swift` | 50 | Rectangle rendering: rounded rect + fill + stroke + badge | Yes (Renderer) | 3 | 2 | — |
| `Annotations/Renderers/CircleRenderer.swift` | 46 | Circle rendering: ellipse + fill + stroke + badge | Yes (Renderer) | 3 | 2 | — |
| `Annotations/Renderers/FreehandRenderer.swift` | 73 | Freehand rendering: Catmull-Rom bezier path + badge | Yes (Renderer) | 3 | 3 | — |
| `Annotations/Renderers/NotePillRenderer.swift` | 351 | Note pill rendering + placement + hover/click interaction | Partial | 12 | 5 | `createNotePillForTest` (only VisualTestHarness) |
| `Capture/CaptureCoordinator.swift` | 187 | Orchestrates capture: overlay windows, mouse routing, selection | Yes | 11 | 3 | — |
| `Capture/CaptureOverlayWindow.swift` | 25 | Full-screen borderless overlay NSWindow | Yes | 0 | 1 | — |
| `Capture/CrosshairView.swift` | 113 | Crosshair cursor drawing + mouse/key event handling | Yes (View) | 9 | 0 | — |
| `Capture/DimensionLabelView.swift` | 73 | Dimension label pill below selection | Yes (View) | 5 | 3 | — |
| `Capture/ScreenCapture.swift` | 93 | CGWindowListCreateImage capture + fallback | Yes | 2 | 1 | `captureWithFallback` (private but functional) |
| `Config/ConfigManager.swift` | 189 | TOML-based config persistence | Yes | 10 | 8 | — |
| `Config/CapturesManager.swift` | 100 | Captures folder management, listing recent captures | Yes | 4 | 4 | — |
| `Design/DesignTokens.swift` | 239 | All colors, dimensions, fonts as static constants | Yes | 0 | — | `badgeFontSmall` (never used externally) |
| `Editor/CanvasView.swift` | 493 | Two-layer annotation canvas: marks (clipped) + notes (overflow) | Yes (View) | 19 | 7 | — |
| `Editor/EditorPanel.swift` | 256 | Floating editor window: toolbar + canvas + status pill | Yes | 9 | 2 | — |
| `Editor/FirstUseTooltipView.swift` | 125 | Dark tooltip explaining IDE/App modes | Yes (View) | 3 | 1 | — |
| `Editor/ScreenshotCanvasView.swift` | 54 | Screenshot image display with rounded corners + shadow | Yes (View) | 0 | 1 | — |
| `Editor/StatusPillView.swift` | 99 | Floating dimension/status pill below canvas | Yes (View) | 6 | 4 | — |
| `Editor/ToolButton.swift` | 105 | Reusable circular toolbar button with state-based colors | Yes | 6 | 1 | — |
| `Editor/ToolbarView.swift` | 601 | Complete toolbar: buttons, toggle, copy pills, icon drawing | Partial (View) | 37 | 6 | Multiple static `draw*Icon` only used by settings |
| `Hotkey/HotkeyManager.swift` | 69 | Global ⌘⇧6 hotkey registration | Yes | 4 | 2 | — |
| `Output/AutoSaveManager.swift` | 64 | Debounced auto-save on annotation changes | Yes | 4 | 2 | `saveIfNeeded` (defined, never called) |
| `Output/ClipboardManager.swift` | 18 | Copy prompt/image to system clipboard | Yes | 2 | 2 | — |
| `Output/PromptGenerator.swift` | 103 | Generate prompt.txt from annotations | Yes | 3 | 3 | — |
| `Output/ScreenshotExporter.swift` | 48 | Bake marks+badges into PNG (no notes) | Yes | 2 | 2 | — |
| `Popover/PopoverViewController.swift` | 375 | Custom dark popover window + menu content | Partial | 14 | 1 | — |
| `Popover/RecentCapturesSubmenu.swift` | 83 | Recent captures submenu with thumbnails | Yes | 6 | 1 | `cancelHide` (defined, only called internally) |
| `Popover/CaptureRowView.swift` | 139 | Individual capture row with copy buttons | Yes (View) | 8 | 1 | — |
| `Settings/SettingsWindowController.swift` | 99 | Settings window with tab switching | Yes | 2 | 1 | — |
| `Settings/GeneralTabView.swift` | 137 | General settings: hotkey, folder, login | Yes (View) | 4 | 1 | — |
| `Settings/PromptTabView.swift` | 300 | Prompt settings: preamble, tool descriptions, footer | Yes (View) | 9 | 1 | — |
| `Settings/PromptPreviewView.swift` | 58 | Live prompt preview | Yes (View) | 2 | 1 | — |
| `Settings/AboutTabView.swift` | 90 | About tab: icon, version, links | Yes (View) | 1 | 1 | — |
| `Setup/SetupWindowController.swift` | 544 | Self-contained setup flow: permissions + folder + tip | Yes | 15 | 1 | — |

### Dead code found:

| Location | Function | Evidence |
|---|---|---|
| `FreehandTool.swift:78` | `downsample(_:count:)` | Defined but no longer called after VIB-177 fix removed the call |
| `AutoSaveManager.swift:40` | `saveIfNeeded()` | Defined but never called from any file |
| `DesignTokens.swift:220` | `badgeFontSmall` | Defined but never referenced outside DesignTokens |
| `VisualTestHarness.swift:185` | `smoothPoints(_:passes:)` | Duplicate of FreehandTool's version |

---

## Part 2: Architecture Pattern Analysis

All 5 tools follow the **Tool → Model → Renderer** pattern consistently:

| | Mouse Input | Model Creation | Canvas Rendering | Note Placement | Hit Testing |
|---|---|---|---|---|---|
| **Pin** | `PinTool.swift` | `PinTool.mouseUp` → `store.add()` | `PinRenderer.swift` via `MarksLayerView` | `NotePillRenderer.notePlacement` case `.pin` | `SelectTool.hitTest` case `.pin` (badge only) |
| **Arrow** | `ArrowTool.swift` | `ArrowTool.mouseUp` → `store.add()` | `ArrowRenderer.swift` via `MarksLayerView` | `NotePillRenderer.notePlacement` case `.arrow` | `SelectTool.hitTest` case `.arrow` (badge + endpoint) |
| **Rectangle** | `RectangleTool.swift` | `RectangleTool.mouseUp` → `store.add()` | `RectangleRenderer.swift` via `MarksLayerView` | `NotePillRenderer.notePlacement` case `.rectangle` | `SelectTool.hitTest` case `.rectangle` (badge + corners + body) |
| **Circle** | `CircleTool.swift` | `CircleTool.mouseUp` → `store.add()` | `CircleRenderer.swift` via `MarksLayerView` | `NotePillRenderer.notePlacement` case `.circle` | `SelectTool.hitTest` case `.circle` (badge + resize + body) |
| **Freehand** | `FreehandTool.swift` | `FreehandTool.mouseUp` → `store.add()` | `FreehandRenderer.swift` via `MarksLayerView` | `NotePillRenderer.notePlacement` case `.freehand` | `SelectTool.hitTest` case `.freehand` (badge + control points) |

**Deviation:** `PinTool` has its own internal hit testing and ghost rendering (`hitTestPin`, `drawBadge`, `drawGhost`) that partially duplicates `SelectTool` and `PinRenderer`. The other tools are cleaner — they delegate all hit testing to `SelectTool` and all rendering to their `*Renderer`.

**Badge + number rendering is duplicated** across all 5 renderers. Each renderer independently draws the badge circle, sets fill color, draws the number text with `badgeFont`. This is ~15 lines of identical code per renderer. A shared `BadgeRenderer.drawBadge(at:number:in:)` function would eliminate this.

---

## Part 3: State Management Map

### 1. Single source of truth
**`AnnotationStore`** (`AnnotationStore.swift:7`) — holds `annotations: [Annotation]` array. All mutations go through its methods.

### 2. Mutation points
| File | Method | What |
|---|---|---|
| `PinTool.swift:41` | `store.add(annotation)` | Create pin |
| `ArrowTool.swift:35` | `store.add(annotation)` | Create arrow |
| `RectangleTool.swift:35` | `store.add(annotation)` | Create rectangle |
| `CircleTool.swift:37` | `store.add(annotation)` | Create circle |
| `FreehandTool.swift:42` | `store.add(annotation)` | Create freehand |
| `SelectTool.swift:20` | `store.select(id:)` | Select annotation |
| `SelectTool.swift:32` | `store.deselectAll()` | Deselect |
| `SelectTool.swift:67-175` | `store.updatePosition/updateBadgePosition` | Move/resize via handles |
| `CanvasView.swift:312` | `store.remove(id:)` | Delete on empty confirm |
| `CanvasView.swift:314` | `store.update(id:, noteText:)` | Confirm note text |
| `EditorPanel.swift:229` | `store.remove(id:)` | Delete selected (toolbar) |
| `UndoRedoManager.swift:50-54` | `store.remove/reinsert/updatePosition` | Undo/redo |

### 3. Undo/redo stack
**`UndoRedoManager`** (`UndoRedoManager.swift`) — **cleanly separated** from the store. Holds its own `undoStack` and `redoStack` of `UndoAction` enums. Uses `isApplying` flag to prevent feedback loops when undo/redo triggers store notifications.

### 4. Copy button reset chain
1. `AnnotationStore.notifyChange()` (`AnnotationStore.swift:93`) posts `.annotationsDidChange`
2. `EditorPanel` observer (`EditorPanel.swift:131-137`) receives notification → calls `toolbarView.resetCopyState()`
3. `ToolbarView.resetCopyState()` (`ToolbarView.swift:305`) calls `copyPromptButton?.resetState()` and `copyImagePillButton?.resetState()`
4. `CopyPillButton.resetState()` (`ToolbarView.swift:559`) reverts border/bg/text from green to purple

**Also reset on mode switch:** `ModeToggleView.onModeChange` (`ToolbarView.swift:247`) calls `self?.resetCopyState()`.

**Assessment:** Clean observer pattern. No ad-hoc state tracking.

### 5. Auto-save
- Triggered by `.annotationsDidChange` notification → `AutoSaveManager` observer (`AutoSaveManager.swift:20`)
- **Debounced** to 0.2s via `Timer.scheduledTimer` (`AutoSaveManager.swift:47`)
- File I/O dispatched to **background queue** (`AutoSaveManager.swift:59`): `DispatchQueue.global(qos: .userInitiated).async`
- `saveNow()` path (close/Escape) also uses background dispatch

### 6. State duplication
**No duplication found.** All tools receive `store: AnnotationStore` as a parameter. `MarksLayerView` holds a reference to the store and reads `store.annotations` in `draw()`. `CanvasView` reads `store.annotations` for note pill rendering. No local caches or mirrors.

---

## Part 4: Coordinate System Analysis

### 1. Capture overlay coordinate system
The overlay window covers the full screen (`CaptureOverlayWindow.init` uses `screen.frame`). Mouse events are in **view-local coordinates** (origin at view's bottom-left). `CrosshairView.mouseUp` converts via:
```
view.convert(rect, to: nil)  → window coordinates
window.convertToScreen(...)  → global screen coordinates (NSScreen, bottom-left origin)
```
(`CaptureCoordinator.swift:132-133`)

### 2. CGWindowListCreateImage expects
**Global display coordinates, top-left origin.** The rect covers all screens in a unified coordinate space where (0,0) is the top-left of the primary display.

### 3. Conversion location
`ScreenCapture.swift:19-25` — flips Y using `mainScreenH - rect.origin.y - rect.height`.

### 4. backingScaleFactor
**Not used in the capture path.** Only a comment at `ScreenCapture.swift:17` explicitly stating NOT to multiply. The image size is set to point dimensions at line 37: `NSImage(cgImage: cgImage, size: NSSize(width: rect.width, height: rect.height))`.

### 5. Multi-monitor screen detection
`CaptureCoordinator.swift:41` — `NSScreen.screens.first { $0.frame.intersects(rect) }`. Uses the global screen rect (from `convertToScreen`) to find the intersecting screen.

### 6. Y-axis flipping
Single location: `ScreenCapture.swift:20` — `let flippedY = mainScreenH - rect.origin.y - rect.height`. Uses the primary screen's height (`NSScreen.screens.first?.frame.height`).

**Risk:** If the primary screen is not the tallest screen, the flipped Y could be negative for screens above the primary. This is a potential multi-monitor bug for non-standard display arrangements.

---

## Part 5: View Hierarchy and Clipping

```
EditorPanel (NSPanel, borderless, floating)
  └─ contentView (NSView)
       masksToBounds = false  ← set at EditorPanel.swift:78
       └─ ToolbarView (NSView, pill-shaped)
       │    masksToBounds = false  ← shadow needs to escape
       │    cornerRadius = bounds.height / 2  ← dynamic
       │    └─ blurView (NSVisualEffectView, masksToBounds=true, cornerRadius=dynamic)
       │    └─ tintOverlay (NSView, masksToBounds=true, cornerRadius=dynamic)
       │    └─ [ToolButtons, ModeToggleView, CopyPillButtons]
       │
       └─ ScreenshotCanvasView (NSView)
       │    masksToBounds = false  ← VIB-167 fix
       │    cornerRadius = NONE  ← removed to prevent implicit clipping
       │    └─ clipView (NSView, masksToBounds=true, cornerRadius=6, border 1px)
       │    │    └─ imageView (NSImageView)
       │    │
       │    └─ CanvasView (NSView)  ← added as subview of ScreenshotCanvasView, NOT clipView
       │         masksToBounds = false  ← VIB-167 fix
       │         └─ MarksLayerView (NSView, masksToBounds=true)  ← shapes clip here
       │         └─ notesLayer (NSView, masksToBounds=false)  ← notes overflow
       │              └─ [NotePillView instances]
       │              └─ [editing pill container]
       │
       └─ StatusPillView (NSView, cornerRadius=12)
```

**Note pill clipping chain:**
`NotePillView` → `notesLayer` (no clip) → `CanvasView` (no clip) → `ScreenshotCanvasView` (no clip) → `contentView` (no clip) → `EditorPanel` (NSPanel).

**Finding:** The clipping chain is now clean. All ancestors have `masksToBounds = false`. However, `CanvasView` is a subview of `ScreenshotCanvasView` (not `clipView`), which means note pills CAN overflow — but the CanvasView's frame is the same size as ScreenshotCanvasView, so note pills only overflow if their positions extend beyond the canvas bounds. This is correct behavior.

---

## Part 6: Thread Safety

### FileManager calls on main thread (potential blockers):

| File:Line | Context | Risk |
|---|---|---|
| `ConfigManager.swift:71,87` | `load()`/`save()` — reads/writes TOML config | **Low** — small file, fast |
| `CapturesManager.swift:14+` | `listRecentCaptures`, `createCaptureFolder` | **Medium** — scans folder, could be slow with many captures |
| `SetupWindowController.swift:529` | `createDirectory` — creates captures folder | **Low** — one-time operation |
| `ScreenCapture.swift:48,72` | Fallback capture temp file — write/delete | **Low** — fallback path rarely used |

### FileManager calls on background thread (safe):

| File:Line | Context |
|---|---|
| `AutoSaveManager.swift:59` | `DispatchQueue.global` — screenshot export + prompt write |
| `PromptGenerator.swift:60-61` | Called from AutoSaveManager's background queue |
| `ScreenshotExporter.swift:45-46` | Called from AutoSaveManager's background queue |

### CapturesManager.listRecentCaptures risk
Called from `RecentCapturesSubmenu.setupView()` which runs on main thread when the submenu appears. With many captures (100+), the folder scan + prompt.txt parsing could freeze the UI. **Should be dispatched to background.**

---

## Part 7: Performance Concerns

### needsDisplay frequency
`needsDisplay = true` appears 22 times across the codebase. During mouse dragging in select mode, `SelectTool.mouseDragged` sets it 2× per event (`marksLayer.needsDisplay` + `refreshNotePills()`), which triggers a full canvas redraw + note pill teardown/rebuild. **This is the most expensive per-frame operation.**

### Full canvas redraw
Yes — `MarksLayerView.draw()` iterates ALL annotations on every draw call. There's no dirty rect optimization. For <20 annotations this is fine; for 50+ it could lag.

### Note pill teardown/rebuild
`refreshNotePills()` removes ALL note pill subviews and recreates them on every annotation change. This includes allocating `NSVisualEffectView`, `CALayer` with `CIGaussianBlur`, and `NSTextField` instances. **This is the most likely cause of perceived sluggishness.** A pool/reuse pattern would be significantly faster.

### Timers and asyncAfter
| Location | Delay | Purpose |
|---|---|---|
| `CaptureCoordinator.swift:49` | 50ms | Wait for overlay to disappear before capture |
| `AutoSaveManager.swift:47` | 200ms | Debounce auto-save |
| `StatusPillView.swift:74` | 2s | Revert copied state |
| `SetupWindowController.swift:502` | 400ms | Delay tip card appearance |
| `SetupWindowController.swift:512` | 2s | Permission polling interval |
| `PopoverViewController.swift:306` | 200ms | Submenu hide delay |
| `CopyPillButton` (`ToolbarView.swift:554`) | 2s | Revert copied state |
| `CanvasView.swift:297` | next run loop | Focus text field |

### Toolbar resize
`updateCopyButtonVisibility` (`ToolbarView.swift:290`) hides the Copy Image button and recalculates width via `setFrameSize`. Resizes `blurView`, `tintOverlay`, and updates `shadowPath`. **Not animated** — instant resize. Could cause a visual jump.

---

## Part 8: Convention Violations

### isFlipped
**No NSView subclasses override `isFlipped`.** All views use AppKit's default bottom-left origin. This is consistent throughout but differs from UIKit convention. The codebase handles this by flipping Y explicitly in note placement (NotePillRenderer) and capture coordinates (ScreenCapture).

### Force-unwrap (IUO) properties
| File:Line | Property | Risk |
|---|---|---|
| `AppDelegate.swift:4` | `statusItem: NSStatusItem!` | Low — set in `applicationDidFinishLaunching` |
| `EditorPanel.swift:10` | `undoRedoManager: UndoRedoManager!` | Low — set in `init` |
| `PromptTabView.swift:7-11` | `preambleEditor`, `footerEditor`, `previewView` | Low — set in `setupView` |
| `SetupWindowController.swift:14-25` | 9 IUO view properties | Low — set in `buildUI` |

All are standard AppKit patterns for views initialized in setup methods. **No runtime crash risk** as long as setup runs before access.

### Retain cycles
**None found.** All closures stored as properties use `[weak self]`. Timer closures use `[weak self]`. Notification observers are removed in `deinit`.

### Weak delegates
`ToolbarView.delegate` is declared `weak` (`ToolbarView.swift:15`). `NotePillView.pillDelegate` is `weak` (`NotePillRenderer.swift:187`). **Correct.**

### Notification cleanup
All three notification observers (`CanvasView`, `EditorPanel`, `AutoSaveManager`) remove their observer in `deinit`. **Correct.**

---

## Part 9: Simplification Opportunities

### 1. Badge rendering duplication
**5 renderers** (Pin, Arrow, Rectangle, Circle, Freehand) each independently draw: badge circle → fill red → draw number. ~15 identical lines per renderer. **Extract to shared `drawBadge(at:number:in:context:)` function.**

### 2. Protocol with many conformers (no issue)
- `AnnotationRenderer` — 5 conformers (one per tool). Justified.
- `AnnotationTool` — 6 conformers (5 tools + select). Justified.
- `NotePillDelegate` — 1 conformer (CanvasView). **Could be a closure instead of a protocol.**
- `ToolbarDelegate` — 1 conformer (EditorPanel). **Could be a closure instead of a protocol.**

### 3. Dead `downsample` function
`FreehandTool.swift:78-84` — `downsample(_:count:)` is no longer called after VIB-177 removed the call. Can be deleted.

### 4. Dead `saveIfNeeded` method
`AutoSaveManager.swift:40-42` — defined but never called from anywhere.

### 5. Duplicated `smoothPoints` in VisualTestHarness
`VisualTestHarness.swift:185` has its own copy of the smoothing function that's identical to `FreehandTool.smoothPoints`. Should call the tool's version or extract to a shared utility.

### 6. Large files that could be split

| File | Lines | Potential Split |
|---|---|---|
| `ToolbarView.swift` | 601 | Extract `ModeToggleView` (60 lines), `CopyPillButton` (80 lines), icon drawing functions (100 lines) into separate files |
| `SetupWindowController.swift` | 544 | Could extract `SetupStepBadge`, `SetupStatusPill`, `SetupKbdPill` helper views |
| `CanvasView.swift` | 493 | Could extract `CanvasNoteFieldDelegate` (20 lines) and `MarksLayerView` (100 lines) |
| `NotePillRenderer.swift` | 351 | Could extract `NotePillView` (170 lines) into its own file |
| `PopoverViewController.swift` | 375 | Could extract `PopoverContentView` (200 lines) and `PopoverRowView` (30 lines) |

### 7. Manager that could be simpler
`ClipboardManager` (18 lines) — two static functions that each call one method. Could be inlined at the call sites (EditorPanel.swift) without losing clarity.

---

## Summary of Key Findings

### Critical (recurring bug sources)
1. **Coordinate system** — Y-flip uses primary screen height which could be wrong for screens positioned above the primary display
2. **Note pill teardown/rebuild** — complete view hierarchy recreation on every annotation change is the main performance bottleneck

### Important (code quality)
3. **Badge rendering duplicated 5×** — extract to shared function
4. **4 dead functions** — `downsample`, `saveIfNeeded`, `badgeFontSmall`, `smoothPoints` (in test harness)
5. **CapturesManager.listRecentCaptures on main thread** — potential UI freeze with many captures

### Nice to have (cleanup)
6. **ToolbarView at 601 lines** — split out ModeToggleView, CopyPillButton, icon drawers
7. **NotePillDelegate and ToolbarDelegate** — single-conformer protocols could be closures
8. **No isFlipped overrides** — consistent but requires manual Y-flip in placement code
