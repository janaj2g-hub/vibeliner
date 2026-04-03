# Vibeliner — Product Definition: Capture Aesthetic

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

Vibeliner uses a custom screen overlay for region selection — not the native macOS `screencapture -i`. This is a branded capture experience that feels like a precision instrument. The aesthetic is quiet, purple-accented, and satisfying.

## Trigger

User presses the global hotkey (default `⌘⇧6`, configurable). A full-screen overlay appears immediately.

## Screen overlay

- **Dim layer:** Full-screen semi-transparent black overlay at 50% opacity (`rgba(0,0,0,0.5)`) over the entire desktop.
- **Covers all displays:** On multi-monitor setups, the overlay covers all screens. The user selects a region on whichever screen they click.

## Crosshair

The cursor becomes a custom crosshair rendered on the overlay.

### Specifications

| Property | Value |
|---|---|
| Style | Short tick marks — horizontal + vertical lines centered on cursor |
| Tick length | 10px from cursor center in each direction (20px total per axis) |
| Color | Purple `#AFA9EC` at 85% opacity → `rgba(175, 169, 236, 0.85)` |
| Thickness | 2.3px |
| Shape | Simple straight lines, no circle, no gap |

### Behavior

- Crosshair follows the cursor in real time with no lag.
- Crosshair is visible only before the drag begins and during the drag (at the drag endpoint). Once the selection is released, the crosshair disappears.
- No cursor icon — the tick marks ARE the cursor.

### Tuning note

These values (10px, 85%, 2.3px) were chosen through interactive prototyping. They may be adjusted during implementation if the feel differs on a real Retina display. The implementation should make these values easy to tweak — ideally constants at the top of the overlay view file.

## Region selection

### Drag behavior

1. User clicks to set the start corner.
2. Drags to expand the selection rectangle.
3. Releases to confirm the selection.

### Selection rectangle

| Property | Value |
|---|---|
| Border color | Purple `#AFA9EC` at 85% opacity |
| Border width | 1.5px |
| Border style | Solid, no dashes |
| Fill | Transparent — the selected region is "cut out" of the dim overlay, showing the desktop at full brightness |
| Corner radius | 0 (sharp corners) |

The bright cutout is the key visual: the selected region pops to full brightness against the dimmed surroundings. This makes it immediately clear what you've captured.

### Dimension label (live readout)

A small pill-shaped label appears below the selection rectangle.

| Property | Value |
|---|---|
| Background | Purple `#534AB7` (solid) |
| Text color | White `#FFFFFF` |
| Font | Monospace, 11px, weight 500 |
| Border radius | 5px |
| Padding | 10px horizontal, centered vertically in 24px height |
| Position | Centered below the selection, 10px gap. If selection is near the bottom edge, label appears above instead. |

### Label content — lifecycle

The label evolves through the capture and annotation lifecycle:

**During drag (capturing):**
```
w 420  h 270
```
Live-updating pixel dimensions with `w` and `h` prefixes. Instrument-panel feel.

**After release (selection confirmed, 0 annotations):**
```
420 × 270 · 0 notes
```
Dimensions lock to final format. Note counter appears.

**During annotation (1+ annotations):**
```
420 × 270 · 3 notes
```
Counter updates in real time as annotations are added or removed.

The label is the same visual element throughout — it starts as a measurement readout and becomes a live annotation status bar.

## Cancel behavior

- Pressing `Escape` during the overlay cancels the capture. Overlay disappears, no file created, app returns to background.
- Clicking without dragging (zero-area selection) is also treated as a cancel.
- Minimum selection size: 10×10 pixels. Anything smaller is treated as a cancel.

## Post-selection transition

After the user releases the drag:

1. The dim overlay fades out (fast, ~150ms).
2. The selected region's screenshot is captured and saved to a temporary file.
3. The editor window opens with the captured image.
4. The purple selection border and dimension label persist visually as part of the editor chrome (the label transitions from the overlay into the editor's bottom bar).

The transition should feel like the selection "becomes" the editor window — the bright rectangle transforms into the editor canvas.

## Annotation badges (visible during capture overlay)

Red numbered circles (`#EF4444` background, white text) appear inside the selection as annotations are added in the editor. These are the same badges defined in the annotation tool specs.

| Property | Value |
|---|---|
| Size | 24px diameter circle |
| Background | Red `#EF4444` |
| Text | White, 11px, weight 500, centered |
| Numbering | Sequential: 1, 2, 3… |

Note: During the initial capture, there are 0 annotations. The badges appear only once the user begins annotating in the editor. They are listed here because the label's note counter references them.

## Color system

The capture experience uses exactly two colors:

1. **Purple** — crosshair, selection border, dimension label. This is the "Vibeliner is active" color.
   - Light purple: `#AFA9EC` (crosshair, selection border)
   - Dark purple: `#534AB7` (label background)
2. **Red** — annotation badges only. `#EF4444`.

No other colors appear in the capture overlay. The monochrome purple keeps the experience calm and focused. Red is reserved exclusively for annotation markers.

## Implementation approach

This is a custom overlay — NOT `screencapture -i`. The implementation requires:

1. A full-screen borderless `NSWindow` at a high window level (above all other windows).
2. A custom `NSView` that handles mouse events for the crosshair and drag selection.
3. Core Graphics rendering for the dim overlay, crosshair ticks, selection cutout, and label.
4. `CGWindowListCreateImage` or similar API to capture the screen content under the selection after release.

### Risk note

Custom region selection is one of the two highest-risk areas in Vibeliner (per TECHNICAL_DECISIONS.md). If the custom overlay proves unreliable across macOS versions or display configurations, the fallback is `screencapture -i` with file output — losing the branded aesthetic but preserving functionality.

## Edge cases

1. **Multi-monitor:** Overlay covers all screens. Selection can span only one screen (the one where the drag starts).
2. **Retina displays:** All pixel values in the label are in screen points, not physical pixels. The actual captured image will be at Retina resolution (2x).
3. **Selection near screen edges:** The dimension label repositions to stay visible (above the selection if too close to the bottom).
4. **Very small selection:** Anything under 10×10 points is treated as a cancel.
5. **Very large selection (full screen):** Works normally. The full screen brightens and the dim overlay effectively disappears except at the edges.
6. **Spaces / full-screen apps:** The overlay must appear above full-screen apps and across Spaces transitions. Window level must be set appropriately.
