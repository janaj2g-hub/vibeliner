# Vibeliner Scalability Audit

## 2026-04-13 Dense Annotation Baseline

This repo now has a practical local verification surface for dense editor checks:

```sh
open dist/Vibeliner.app --args --visual-test
```

Use the `Vibeliner Visual Harness` window and focus on these runtime-backed scenarios:

1. `Editor — calm canvas`
2. `Editor — dense hover/select`
3. `Editor — dense filmstrip`

### Manual regression checklist

- `Editor — dense hover/select`
  Move the pointer continuously across note pills and badges for 10-15 seconds. Hover rings, note-pill updates, and selection outlines should keep up without visible stutter or dropped-state flicker.
- `Editor — dense hover/select`
  Drag a selected annotation across the canvas with the Select tool. The mark, badge, and note pill should stay visually locked together while redraw remains responsive.
- `Editor — dense hover/select`
  Resize at least one rectangle or arrow endpoint after selecting it. Handle hit-testing should stay reliable even with many nearby annotations.
- `Editor — dense filmstrip`
  Click between filmstrip cells, then hover and drag a cross-image annotation. Title pills, selection state, and annotation ownership should remain stable while the overlay keeps up.
- `Editor — dense filmstrip`
  Scroll horizontally if needed and repeat the hover/drag checks near cell boundaries. The overlay should continue to track the correct cell geometry and image ownership.

### What counts as a regression

- Multi-frame lag between pointer motion and hover/selection updates.
- Note pills popping, jumping, or visibly desynchronizing from their badges during drag.
- Cross-image arrows or filmstrip annotations appearing to belong to the wrong cell after interaction.
- Horizontal scrolling or cell reselection causing overlays to detach, redraw late, or flicker.

### First hot paths to inspect

- `Vibeliner/Editor/CanvasView.swift`
  Hover hit-testing, drag invalidation, and filmstrip point-to-image resolution.
- `Vibeliner/Annotations/Renderers/NotePillRenderer.swift`
  Dense note-pill update churn and anchor repositioning during hover/drag.
- `Vibeliner/Editor/FilmstripGridView.swift`
  Cell layout churn, scroll-container geometry, and image-area frame calculations.
- `Vibeliner/Editor/ToolbarView.swift`
  Editor chrome validation only if the regression appears to be toolbar-state churn rather than canvas performance.

The goal of this checklist is intentionally practical: future polish work should be able to re-run these scenes locally without Instruments or a separate one-off test harness.

**Date:** 2026-04-09
**Scope:** All 60 Swift files in `Vibeliner/`
**Total LOC:** ~10,000 across 60 files
**Type:** Read-only audit — no code changes

---

## Section 1: Stale Code & Dead References

### 1.1 Dead Properties — `editorPanel` on All 6 Tools

Every annotation tool declares `weak var editorPanel: EditorPanel?` but **never reads it**:

| File | Line | Severity |
|------|------|----------|
| `Annotations/Tools/SelectTool.swift` | 8 | 🔴 Remove |
| `Annotations/Tools/PinTool.swift` | 24 | 🔴 Remove |
| `Annotations/Tools/ArrowTool.swift` | 6 | 🔴 Remove |
| `Annotations/Tools/RectangleTool.swift` | 6 | 🔴 Remove |
| `Annotations/Tools/CircleTool.swift` | 6 | 🔴 Remove |
| `Annotations/Tools/FreehandTool.swift` | 6 | 🔴 Remove |

Copy-paste debt from an earlier architecture. Safe to delete all 6.

### 1.2 Dead Properties — AppDelegate

| Property | File:Line | Severity |
|----------|-----------|----------|
| `settingsWindowController` | `App/AppDelegate.swift:7` | 🟡 Investigate — instantiated lazily from PopoverViewController, not AppDelegate |

### 1.3 Dead Methods

| Method | File:Line | Severity |
|--------|-----------|----------|
| `recentCaptures()` | `Popover/PopoverViewController.swift:246` | 🔴 Remove — selector target never wired |
| `scheduleHide(after:action:)` | `Popover/RecentCapturesSubmenu.swift:98` | 🔴 Remove — replaced by PopoverContentView's own hide logic |
| `cancelHide()` | `Popover/RecentCapturesSubmenu.swift:104` | 🔴 Remove — same |

### 1.4 Unused Constant

| Constant | File:Line | Severity |
|----------|-----------|----------|
| `maxExportWidth` | `Services/CompositeStitcher.swift:7` | 🔴 Remove — defined as 4800 but never referenced |

### 1.5 Unused Design Tokens (31 tokens)

These tokens are defined in `Design/DesignTokens.swift` but **never consumed** by any UI code (`DesignTokens.tokenName` never appears outside the definition file):

#### Legacy Chrome Tokens (superseded by appearance-aware versions)

| Token | Line | Replacement | Severity |
|-------|------|-------------|----------|
| `darkChrome` | 79 | `toolbarBg` | 🔴 Remove |
| `darkChromeStatus` | 82 | `statusPillBg` | 🔴 Remove |
| `darkChromePopover` | 85 | `.popover` material | 🔴 Remove |
| `dividerColor` | 95 | `toolbarDivider` | 🔴 Remove |
| `iconDefault` | 107 | `toolbarIconDefault` | 🔴 Remove |
| `iconHover` | 110 | `toolbarIconHover` | 🔴 Remove |
| `buttonHoverBg` | 113 | `toolbarButtonHoverBg` | 🔴 Remove |
| `toolActiveBg` | 116 | `toolbarToolActiveBg` | 🔴 Remove |
| `closeHoverBg` | 98 | `toolbarCloseHoverBg` | 🔴 Remove |
| `trashHoverBg` | 101 | `toolbarTrashHoverBg` | 🔴 Remove |
| `closeIconHover` | 338 | `toolbarCloseIconHover` | 🔴 Remove |
| `toggleActiveBg` | 329 | `toolbarToggleActiveBg` | 🔴 Remove |
| `toggleBg` | 332 | `toolbarToggleBg` | 🔴 Remove |
| `toggleInactiveText` | 335 | `toolbarToggleInactiveText` | 🔴 Remove |

#### Deprecated Button Tokens

| Token | Line | Replacement | Severity |
|-------|------|-------------|----------|
| `purpleButtonHover` | 21 | — | 🔴 Remove |
| `purpleButtonBgHover` | 27 | — | 🔴 Remove |
| `addImageBg` | 260 | `toolbarSecondaryBg` | 🔴 Remove |
| `addImageBorder` | 266 | `toolbarSecondaryBorder` | 🔴 Remove |
| `addImageHoverBorder` | 273 | `toolbarSecondaryHoverBorder` | 🔴 Remove |

#### Unused Note State Tokens

| Token | Line | Severity |
|-------|------|----------|
| `redNoteBg` | 37 | 🟡 Verify — may be used by NotePillRenderer via different pattern |
| `redNoteBorder` | 40 | 🟡 Verify |
| `noteHoverBg` | 43 | 🟡 Verify |
| `noteHoverBorder` | 46 | 🟡 Verify |
| `noteSelectedBg` | 49 | 🟡 Verify |
| `noteSelectedBorder` | 52 | 🟡 Verify |
| `noteEditingBg` | 55 | 🟡 Verify |
| `notePrefixColor` | 58 | 🟡 Verify |

#### Unused Dimension/Font Tokens

| Token | Line | Severity |
|-------|------|----------|
| `filmstripBg` | 600 | 🔴 Remove — composite uses inline color |
| `toolbarBlur` | 514 | 🟡 Defined but blur applied via `.popover` material |
| `statusPillBlur` | 520 | 🟡 Same |
| `settingsSectionPadding` | 538 | 🔴 Remove — `settingsContentPadding` used instead |
| `noteNumberFont` | 640 | 🔴 Remove — `badgeFont` used for note numbers |
| `toolbarButtonFont` | 655 | 🔴 Remove — inline system font used |
| `tooltipBodyFont` | 658 | 🟡 May be used by FirstUseTooltipView via inline reference |
| `tooltipLabelFont` | 661 | 🟡 Same |
| `setupAmberBg` | 689 | 🔴 Remove — unused in SetupWindowController |
| `setupButtonHoverBg` | 747 | 🔴 Remove — unused |
| `setupTitleBarBg` | 697 | 🔴 Remove — unused |
| `setupWindowRadius` | 776 | 🔴 Remove — unused |
| `setupWindowTitleFont` | 781 | 🔴 Remove — unused |

### 1.6 Duplicate Renderer Instances

Two separate sets of the same 5 static renderer instances exist in memory:

| Location | File:Line |
|----------|-----------|
| Set 1 | `Output/ScreenshotExporter.swift:5-9` |
| Set 2 | `Services/CompositeStitcher.swift:11-15` |

🟡 Consolidate into a shared `RendererSet` or pass renderers as parameters.

### 1.7 TODO / FIXME / HACK Comments

**None found.** Zero technical debt markers across all 60 files. VIB-prefixed issue references (26 instances) serve as traceability, not debt.

### 1.8 Deprecated Annotations

| Item | File:Line | Note |
|------|-----------|------|
| `@available(macOS, deprecated: 14.0)` | `Capture/ScreenCapture.swift:6` | Intentional — CGWindowListCreateImage per project requirements |
| `// MARK: - Add Image Button (deprecated)` | `Design/DesignTokens.swift:258` | Tokens still defined but unused — remove |

### 1.9 Unused Imports

**None found.** All imports are necessary across all 60 files.

---

## Section 2: Performance Patterns

### 2.1 🔴 `needsDisplay = true` on Every Mouse Drag (60+ FPS)

**File:** `Editor/CanvasView.swift:245`

```swift
override func mouseDragged(with event: NSEvent) {
    activeTool?.mouseDragged(to: point, in: self, store: store, undoManager: undoMgr)
    marksLayer.needsDisplay = true  // ← every frame
}
```

Every `mouseDragged` event triggers a full `MarksLayerView.draw()` which calls all 5 renderers, hover glow calculations, badge drawing, selection handles, and ghost preview. At 60-120 FPS on modern Macs, this is the single biggest performance concern.

**Additionally**, each tool also sets `canvas.marksLayer.needsDisplay = true` internally:
- `SelectTool.swift:39, 49, 182`
- `ArrowTool.swift:19`
- `RectangleTool.swift:19`
- `CircleTool.swift:22`
- `FreehandTool.swift:21`

**Recommendation:** Use `CADisplayLink` for synchronized rendering instead of event-driven redraws. Batch updates per display frame.

### 2.2 🔴 O(n) Hit-Testing on Every Mouse Move

**File:** `Editor/CanvasView.swift:112-172`

`hitTestAnnotation(at:)` iterates ALL annotations in reverse on every `mouseMoved` event:
- Badge proximity: 1 `hypot` per annotation
- Arrow endpoints: 1 `hypot`
- Rectangle corners: 4 `hypot` + containment check
- Circle: 2 `hypot` calculations
- Freehand: N `hypot` (per control point)

With 50+ annotations, this means 200+ distance calculations per pixel of mouse movement.

**Recommendation:** Implement bounding-box quick-reject or spatial indexing (QuadTree) for annotation hit-testing.

### 2.3 🟡 NotePillRenderer O(n²) Update Pattern

**File:** `Annotations/Renderers/NotePillRenderer.swift:14-80`

`drawNotePills()` performs 4 sequential iterations over all annotations/pills:
1. Collect existing pills into dictionary
2. Build set of needed IDs
3. Remove stale pills
4. Update or create remaining pills

With 100 annotations: 400+ iterations minimum per render cycle.

**Recommendation:** Maintain a persistent `[UUID: NotePillView]` dictionary; diff incrementally instead of rebuilding.

### 2.4 🟡 Composite Stitching Blocks Main Thread

**File:** `Output/ClipboardManager.swift:19`

`CompositeStitcher.stitch()` runs synchronously on the main thread when copying to clipboard. For 4+ Retina images (~5120×2880 each), this allocates 20-30 MB for the composite image and blocks UI for 100-300ms.

**Recommendation:** Dispatch composite generation to a background queue; show a brief "Copying..." indicator.

### 2.5 🟡 Image Encoding Double-Allocation

**File:** `Capture/ScreenCapture.swift:79-81`

```swift
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:])
```

Creates a full TIFF buffer then converts to PNG — two large allocations. Could use `CGImageDestination` for direct PNG encoding.

### 2.6 🟡 No Image Downsampling for Filmstrip Display

**Confirmed:** `Capture/ScreenCapture.swift:30` uses `.bestResolution` flag. Full Retina images (5120×2880 = ~56 MB uncompressed per image) are stored in memory and displayed at filmstrip thumbnail size.

**Memory estimate for 6 images:** ~340 MB of pixel data in the worst case.

**Recommendation:** Generate downsampled thumbnails for filmstrip display; keep full-resolution originals on disk for export only.

### 2.7 ✅ Auto-Save Is Properly Debounced

**File:** `Output/AutoSaveManager.swift:44`

Auto-save uses a 0.2-second debounce timer. Annotation changes set an `isDirty` flag, then `scheduleSave()` defers the actual disk write. File I/O runs on `DispatchQueue.global(qos: .userInitiated)` — not the main thread.

### 2.8 ✅ ConfigManager Uses Private Queue

**File:** `Config/ConfigManager.swift:19`

All disk I/O wrapped in `queue.sync` on a private `DispatchQueue(label: "com.vibeliner.config")`. Thread-safe.

---

## Section 3: Scalability Assessment

### 3.1 Can the Data Model Handle 6+ Images?

**Current state:** The data model supports it. `CaptureStore` stores an `[NSImage]` array, annotations have `parentImageIndex`, and `CoordinateConverter` uses relative coordinates that survive layout changes.

**Where it would break:**
- **Memory:** 6 Retina screenshots at full resolution ~340 MB (see 2.6)
- **Rendering:** All annotations rendered globally, not filtered by visible image
- **Hit-testing:** O(n) over all annotations, not scoped to current image

**Verdict:** Data model is ready; rendering pipeline is not.

### 3.2 Is EditorPanel Too Large?

**File:** `Editor/EditorPanel.swift` — **662 LOC, 9+ responsibilities**

Current responsibilities:
1. Window creation and sizing
2. Tool instantiation (6 tools, lines 12-17)
3. Multi-image state management (9 properties, lines 25-33)
4. Filmstrip layout (98 lines)
5. Single↔filmstrip transitions
6. Key event handling (175 lines)
7. Auto-save coordination
8. Undo/redo management
9. ToolbarDelegate implementation (7 methods)
10. Annotation store observation

**Verdict:** Yes, this is a God Object. Should be split into:
- `ToolManager` — tool instantiation and switching
- `FilmstripCoordinator` — multi-image state and layout transitions
- `KeyboardController` — key event handling

### 3.3 Is the Annotation System Ready for Per-Image Isolation?

**Current state: ~70% ready.**

**What's in place:**
- `parentImageIndex` on every annotation (`AnnotationModel.swift:40-49`)
- Image deletion with annotation cleanup (`AnnotationStore.swift:97-122`)
- Click-position-based index assignment (`CanvasView.swift` via `imageIndexAtPoint`)
- Cross-image arrow support (`endImageIndex`)

**What's missing:**
- No `annotations(forImageIndex:)` method — all renderers iterate ALL annotations every frame
- Hit-testing not scoped to current image
- No per-image caching of coordinate transforms
- Cross-image arrow validation incomplete (no bounds check on `endImageIndex`)

### 3.4 Is PromptGenerator Modular Enough for Presets?

**File:** `Output/PromptGenerator.swift` — 156 LOC

The generator reads preamble/footer/tool descriptions from `ConfigManager.shared` and assembles them into a prompt string. It's reasonably modular but:
- Role description lookups are O(n) per annotation (`first(where:)` on roles array, line 49)
- Hard to swap prompt formats without modifying the generator itself

**Recommendation:** Extract prompt assembly into a `PromptTemplate` protocol for future preset support.

### 3.5 Tight Couplings That Fight Future Features

| Coupling | Impact | Files |
|----------|--------|-------|
| Singleton overuse (`ConfigManager.shared`, `CapturesManager.shared`, `CursorManager.shared`, `CaptureCoordinator.shared`) | Difficult to test, inject mocks, or support multiple instances | All files |
| Magic notification string `"VibelinerTriggerCapture"` | No compile-time checking, brittle | `App/AppDelegate.swift:35` |
| Settings views directly mutate ConfigManager (25+ references) | No ViewModel layer, fragile state sync | `GeneralTabView.swift`, `PromptTabView.swift` |
| Tools directly mutate `canvas.marksLayer` | Cannot test tools in isolation | All 6 tool files |
| PopoverViewController lazily creates SettingsWindowController on AppDelegate | Ownership unclear, side effects in UI handler | `Popover/PopoverViewController.swift:307-315` |

### 3.6 File Size Analysis

Files over 400 LOC that should be considered for splitting:

| File | LOC | Recommendation |
|------|-----|----------------|
| `Design/DesignTokens.swift` | 861 | Split into `ColorTokens`, `DimensionTokens`, `FontTokens` |
| `Editor/ToolbarView.swift` | 787 | Extract `ModeToggleView`, `CopyPillButton`, `SecondaryPillButton` to own files |
| `Setup/SetupWindowController.swift` | 754 | Extract panel builders, footer builder |
| `Settings/PromptTabView.swift` | 740 | Extract `RoleSwatchView`, role management section |
| `Editor/CanvasView.swift` | 704 | Extract `MarksLayerView`, `NotesLayerView` hit-testing |
| `Editor/EditorPanel.swift` | 662 | Extract `ToolManager`, `FilmstripCoordinator`, `KeyboardController` |
| `Annotations/Renderers/NotePillRenderer.swift` | 400 | Extract `NotePillView` to own file |
| `Editor/FilmstripGridView.swift` | 399 | Acceptable size |

---

## Appendix: Recommended Cleanup Tickets

### 🔴 P0 — Do Before Next Feature

| # | Title | Type | Size |
|---|-------|------|------|
| 1 | Remove 6 unused `editorPanel` properties from annotation tools | Delete | XS |
| 2 | Remove 3 dead methods (PopoverViewController, RecentCapturesSubmenu) | Delete | XS |
| 3 | Remove `maxExportWidth` unused constant from CompositeStitcher | Delete | XS |
| 4 | Remove 19 legacy/deprecated design tokens from DesignTokens.swift + update design system docs | Delete | S |
| 5 | Debounce/batch `needsDisplay` during mouse drag using CADisplayLink | Refactor | M |
| 6 | Move composite stitching off main thread in ClipboardManager | Refactor | S |

### 🟡 P1 — Do Soon

| # | Title | Type | Size |
|---|-------|------|------|
| 7 | Extract `ToolManager` from EditorPanel (tool instantiation + switching) | Refactor | M |
| 8 | Add `annotations(forImageIndex:)` filtering to AnnotationStore and renderers | Refactor | M |
| 9 | Implement bounding-box quick-reject for hit-testing in CanvasView | Refactor | S |
| 10 | Generate downsampled thumbnails for filmstrip display | Refactor | M |
| 11 | Extract `ModeToggleView`, `CopyPillButton`, `SecondaryPillButton` from ToolbarView | Refactor | S |
| 12 | Consolidate duplicate renderer instances (ScreenshotExporter + CompositeStitcher) | Refactor | S |
| 13 | Verify and remove unused note state tokens (redNoteBg, noteHoverBg, etc.) | Delete | XS |
| 14 | Replace magic notification string with typed constant | Refactor | XS |
| 15 | Replace TIFF→PNG double-allocation with direct CGImage encoding | Refactor | S |

### 🟢 P2 — Nice to Have

| # | Title | Type | Size |
|---|-------|------|------|
| 16 | Extract `FilmstripCoordinator` from EditorPanel (multi-image state) | Refactor | M |
| 17 | Extract `KeyboardController` from EditorPanel (key event handling) | Refactor | S |
| 18 | Split DesignTokens.swift into `ColorTokens`, `DimensionTokens`, `FontTokens` | Refactor | S |
| 19 | Extract `NotePillView` from NotePillRenderer into own file | Refactor | S |
| 20 | Add ViewModel layer between Settings views and ConfigManager | Rewrite | M |
| 21 | Implement QuadTree spatial indexing for annotation hit-testing | Rewrite | M |
| 22 | Extract SelectTool rectangle resize logic into helper struct | Refactor | S |
| 23 | Cache role color lookups in ImageRole and PromptGenerator | Refactor | XS |
