# Filmstrip Layout — Architecture Decision Record

## Decision
Use a single horizontal row with horizontal scroll for the multi-image filmstrip. Max 6 images. Export matches the editor layout.

## Context
The composite filmstrip feature (VIB-237) needed to display 2+ images in the editor for annotation and comparison.

## What we tried: Multi-row grid
The initial design (Concept 3) used a multi-row grid: rows of up to 3 images, uniform row height per row, widths proportional to aspect ratio. This required:
- LayoutCalculator to chunk images into rows and compute per-row heights
- The editor window to grow taller for additional rows
- Multi-row coordinate translation for annotations
- Row-wrapping logic for 4+ images

### Why it failed
Over 6 attempts (VIB-281 attempts 1-6, VIB-285, VIB-292), the multi-row approach repeatedly broke:
- **Attempt 1-2:** Grid view not wired into editor; only 1 image visible
- **Attempt 3:** All images visible but wrong layout (not Concept 3)
- **Attempt 4:** Title pills and titles fixed, but heights not equalized
- **Attempt 5:** Height equalization worked, but images too small
- **Attempt 6:** Window resize for composites worked, but 4+ images crashed/disappeared

The root cause: multi-row layout creates cascading dependencies between LayoutCalculator, FilmstripGridView, the editor window controller, the annotation canvas, and the composite stitcher. A bug in any one propagates to all others.

### Why single-row works
The single-row Concept 3 math was proven correct by attempt 5. All images share one row height, widths are proportional — the math is simple and doesn't cascade. Horizontal scroll is a standard macOS pattern that NSScrollView handles natively.

## Current approach
- One horizontal row, all images same height
- Horizontal scroll when content exceeds window width
- Max 6 images
- Export = same horizontal strip as editor
- LayoutCalculator computes single-row frames only

## What was removed (VIB-297)
- `chunk()` function in LayoutCalculator (split images into rows of N)
- `maxPerRow` parameter and all references
- `minimumCellWidth` constant and too-narrow row reduction logic
- `rowIndex` field on LayoutFrame
- Sparse row height capping (VIB-292)
- Multi-row `computeFrames` with `availableWidth` — replaced with `rowHeight`
- Multi-row frame stacking in `layoutRow()`
- Window height growth for additional rows in EditorPanel
- Max image cap changed from 12 to 6

## References
- VIB-237: Multi-Image Composite Filmstrip (parent story)
- VIB-254: Phase 1 story
- VIB-281: The main fix ticket (6 attempts)
- VIB-297: This ticket (switch to horizontal scroll)
