# Rescue Report — Lost Commits from Closed PRs

Generated: 2026-04-08

## Background

29 PRs (#45–#73) were closed without merging when PR #75 (vib-328-post-testing-fixes) was merged into main. These PRs formed a **linear chain** of 47 unique commits — none of which were on main. The remote branches were deleted, but all commit objects were recovered via GitHub's `refs/pull/*/head` refs.

```bash
git fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'
```

## Recovery Status

All 47 commits are accessible via `origin/pr/45` through `origin/pr/73`. PR #73 is the tip of the longest chain and contains all 47 commits. The most complete codebase state is at:

```
origin/pr/73  →  bac8a7e  (47 commits ahead of main)
```

---

## Tier 1 — Critical: Core Multi-Image Feature

These commits implement the entire multi-image composite pipeline that is **completely absent** from main.

### VIB-257: Multi-image data model
- **SHA:** `3f4e82e`
- **PR:** #49
- **Files created:**
  - `Vibeliner/Models/CaptureImage.swift` — image entry with role, path, dimensions
  - `Vibeliner/Models/CaptureStore.swift` — ordered image collection with add/remove/reorder
  - `Vibeliner/Models/ImageRole.swift` — enum: observed, expected, reference
- **Files modified:** AutoSaveManager.swift
- **Impact:** 200 insertions — replaces the ad-hoc `images: [NSImage]` array added in VIB-329

### VIB-258: Filmstrip design tokens
- **SHA:** `037a1b3`
- **PR:** #49
- **Files modified:** DesignTokens.swift
- **Impact:** Role colors, title pill tokens, filmstrip spacing tokens (more complete than VIB-329's additions)

### VIB-259: Title pill component
- **SHA:** `ba1fb56`
- **PR:** #50
- **Files created:** `Vibeliner/Views/TitlePillView.swift`
- **Impact:** Reusable title pill with role color, dropdown, chevron

### VIB-260: Filmstrip grid layout engine
- **SHA:** `16b979b`
- **PR:** #50
- **Files created:** `Vibeliner/Views/FilmstripGridView.swift`
- **Impact:** The original filmstrip — more mature than VIB-329's rebuild

### VIB-261–266: Editor wiring, add image, transitions, status updates
- **SHAs:** `f7a44dd`, `12390a1`, `9bdbc0e`, `2bd73e3`, `6295b14`
- **PRs:** #51, #53
- **Impact:** Film cell rendering, + add image button, 1→2 transition with smart role defaults, status pill updates

### VIB-264: Composite stitching for export
- **SHA:** `fb719e1`
- **PR:** #52
- **Files created:** `Vibeliner/Services/CompositeStitcher.swift` (196 lines)
- **Files modified:** AutoSaveManager, ClipboardManager, EditorPanel
- **Impact:** Stitches multiple images into a single composite PNG for clipboard/file export. **Critical for copy-image flow.**

### VIB-265: Multi-image prompt template
- **SHA:** `7c93f33`
- **PR:** #52
- **Files modified:** PromptGenerator.swift
- **Impact:** Per-image sections in prompt output with role descriptions

### VIB-268: Image-relative annotation coordinates
- **SHA:** `634d6a2`
- **PR:** #69
- **Files created:** `Vibeliner/Services/CoordinateConverter.swift` (131 lines)
- **Files modified:** CanvasView, EditorPanel, UndoRedoManager
- **Impact:** 310 insertions — annotations stored relative to their parent image, not absolute pixels. **Required for correct multi-image annotations.**

### VIB-269: Image-name auto-prefix on annotations
- **SHA:** `b299af3`
- **PR:** #70
- **Files modified:** NotePillRenderer, CanvasView, EditorPanel, PromptGenerator
- **Impact:** 116 insertions — "Image 1: ..." prefix on note pills and prompt output

### VIB-271: Image deletion from composite
- **SHA:** `48e95f3`
- **PR:** #71
- **Files modified:** EditorPanel (266 lines), CaptureStore, FilmCellView, FilmstripGridView
- **Impact:** 429 insertions — delete images from filmstrip with annotation index shifting and undo support

---

## Tier 2 — Important: UX Polish & Bug Fixes

### VIB-281/282: Filmstrip sizing (6 attempts)
- **SHAs:** `fe01b59`, `84c8bf3`, `e00c954`, `fee2d45`, `60ae3c6`, `4798962`, `e33b910`
- **PRs:** #54–#59
- **Impact:** Editor window resizing for composite mode, pill z-order, gap reduction, cell layout. Use attempt 6 (`4798962`) as the final version.

### VIB-285/286: Crash fix + pill styling
- **SHAs:** `f019594`, `94d7ae8`
- **PR:** #60
- **Impact:** Fix editor crash at 4 images, title pill width/readability

### VIB-289–296: Annotation fixes, layout, filmstrip refinements
- **SHAs:** `cf36f9b`, `fa3da7c`, `aca8dc4`, `98bc3a2`, `703a700`, `dbda0e8`, `b7aa099`
- **PRs:** #61–#62
- **Impact:** Fix annotations on multi-image composites, coordinate mapping, clickable title pills, darkened filmstrip background

### VIB-297: Horizontal scroll filmstrip
- **SHA:** `2e4c261`
- **PR:** #63
- **Impact:** Switch from multi-row grid to single-row horizontal scroll (max 6 visible)

### VIB-300: Settings folder picker z-order
- **SHA:** `52fa26f`
- **PR:** #64
- **Files modified:** GeneralTabView.swift (+5 lines)
- **Impact:** Fix NSOpenPanel opening behind floating Settings window

### VIB-301: Config persistence across rebuilds
- **SHA:** `ff8befc`
- **PR:** #64
- **Files modified:** ConfigManager.swift (+42 lines)
- **Impact:** Captures folder config survives app rebuilds

### VIB-303: Setup panel reorder
- **SHA:** `08169ca`
- **PR:** #65
- **Files modified:** SetupWindowController.swift (228 lines changed)
- **Impact:** Captures folder first, accessibility second, screen recording third

### VIB-304: Quit & Reopen fix
- **SHA:** `dc9b10b`
- **PR:** #65
- **Files modified:** AppDelegate, ConfigManager, SetupWindowController
- **Impact:** Re-show setup after Screen Recording permission restart

### VIB-305: Text truncation fix
- **SHA:** `82f0e8c`
- **PR:** #65
- **Impact:** Fix helper text truncation in setup panels

### VIB-306–309: Filmstrip scroll + composite export rendering
- **SHAs:** `ea86e91`, `d3303d0`, `01cfe20`, `13514b8`, `8fba14b`
- **PR:** #66
- **Impact:** Vertical wheel → horizontal scroll, height cap, annotations in composite export, export pill styling

### VIB-311: KeyEventGuard
- **SHA:** `1c77cf4`
- **PR:** #67
- **Files created:** `Vibeliner/Utilities/KeyEventGuard.swift` (34 lines)
- **Files modified:** CrosshairView, EditorPanel, HotkeyCapturePanel
- **Impact:** Centralized keyboard handler preventing monitor leaks

### VIB-312/313: Title pill design + filmstrip spacing
- **SHAs:** `6598172`, `9b92d5e`, `b2dd981`
- **PRs:** #67–#68
- **Impact:** Brighter pill backgrounds, vertical centering, content-hugging grid width, role colors fix

### VIB-314: Ghost cursor scoping
- **SHA:** `84bef5e`
- **PR:** #67
- **Impact:** Ghost cursor only appears over images, not gaps or title pills

---

## Tier 3 — Nice-to-Have: Design System & Docs

### VIB-242/243: Design system wiring + token refactor plan
- **SHAs:** `68b3d60`, `c2afba3`
- **PR:** #45
- **Impact:** CLAUDE.md/AGENTS.md references, file-by-file refactor blueprint

### VIB-245–252: Design token refactor (8 commits)
- **SHAs:** `3195f02` through `46e7a0d`
- **PR:** #46
- **Impact:** Tokenize PopoverViewController, RecentCapturesSubmenu, CaptureRowView, SetupWindowController, CanvasView; update design system docs

### VIB-244/253: Button playground
- **SHAs:** `f206240`, `8280229`
- **PRs:** #47–#48
- **Impact:** Interactive button & control playground HTML

### VIB-270: Settings role descriptions and colors
- **SHA:** `d794757`
- **PR:** #72
- **Impact:** Settings UI for role descriptions (may overlap with VIB-319 batch work already on main)

### VIB-272: Design system cleanup gate
- **SHA:** `bac8a7e`
- **PR:** #73
- **Impact:** Final cleanup iteration

---

## Recovery Commands

To inspect any commit:
```bash
git show <SHA>                          # View the full diff
git show <SHA>:path/to/file.swift      # View a file at that commit
git diff main..<SHA> -- path/to/file   # Compare to current main
```

To recover the most complete multi-image state (PR #73 tip):
```bash
git checkout -b rescue/filmstrip-full origin/pr/73
```

To cherry-pick individual features:
```bash
# Example: just the data model + composite stitcher
git cherry-pick 3f4e82e 037a1b3 ba1fb56 16b979b fb719e1
```

**Warning:** These commits were built on a different base than current main. Cherry-picking will likely require conflict resolution. A safer approach may be to branch from `origin/pr/73` and rebase onto main.

---

## Recommended Recovery Strategy

1. **Branch from PR #73 tip** — it has the most complete state (47 commits of filmstrip work)
2. **Rebase onto current main** — resolve conflicts with the VIB-319/328/329 changes
3. **Remove VIB-329's stub FilmstripGridView** — replace with the mature version from the chain
4. **Verify build** and test the full multi-image flow
5. **Open a single PR** with all recovered work
