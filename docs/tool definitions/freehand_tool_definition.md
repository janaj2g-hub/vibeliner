# Vibeliner — Product Definition: Freehand Annotation Tool

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

The freehand tool draws a free-form stroke on the screenshot. Use it when the problem area is irregular, when you want to loosely circle something, or when no other tool fits. The stroke is smoothed into a clean curve. The badge sits at the start of the stroke, and the note is pushed radially outward from the stroke's center.

## Anatomy of a freehand annotation

1. **Stroke** — smoothed red curve following the user's drawing path
2. **Numbered badge** — red filled circle with white number, at the stroke start point
3. **Note pill** — text field pushed radially outward from the stroke's bounding center

### Stroke

| Property | Value |
|---|---|
| Color | `#EF4444` |
| Width | 2.5px (uniform, consistent with all tools) |
| Cap | Round (`stroke-linecap: round`) |
| Join | Round (`stroke-linejoin: round`) |
| Fill | None — stroke only, never filled |
| Smoothing | Catmull-Rom spline interpolation (3 passes at 0.5 factor) |
| Point sampling | Minimum 3px distance between recorded points during drawing |

### v1 vs future

**v1:** Clean uniform-width smooth curve. No taper, no pressure simulation. Simple to render and edit.

**Future polish:** Add pressure fade — the last 30% of the stroke gradually thins and fades in opacity, simulating pen lift. This would require rendering the stroke as a variable-width filled shape rather than a stroked path. Tracked as a separate polish ticket.

### Numbered badge

| Property | Value |
|---|---|
| Shape | Filled circle, 18px diameter (radius 9px) |
| Fill | `#EF4444` |
| Number | White, 9px, weight 600 |
| Position | At the first point of the stroke (where the user started drawing) |

The badge sits directly on the stroke start point. There is no stake — the badge overlaps the beginning of the stroke line.

### Note pill

| Property | Value |
|---|---|
| Shape | Pill (`border-radius: 13px`), 26px height |
| Content | Number prefix (9px, light maroon) + user text (12px, dark maroon) |
| Position | Radially outward from the stroke's bounding box center through the badge |

## Note placement algorithm

Same radial-outward approach as the circle tool, adapted for freehand:

1. Calculate the bounding box center of the stroke (average of min/max x and y of all points)
2. Calculate the direction vector from bounding center to badge (stroke start point)
3. Push the note along this vector, away from the center
4. Check all four corners of the note pill against the stroke's bounding circle (a circle centered on the bounding center with radius = max distance from center to any stroke point)
5. Push outward until all corners have at least 8px clearance from the bounding circle

This ensures the note doesn't overlap the stroke in most cases. For very irregular strokes, the bounding circle is conservative — the note may be further out than strictly necessary, which is acceptable.

## Placement flow

### 1. Tool activation
User clicks the Freehand button in the toolbar.

### 2. Click and draw
User clicks and drags to draw. The stroke renders in real time as a smoothed curve at full opacity. Points are sampled at minimum 3px intervals.

### 3. Release (placed)
User releases. The stroke is finalized with Catmull-Rom smoothing. The badge appears at the start point. The note pill opens immediately in editing mode.

### 4. Type note
User types description. Press Enter to confirm. Press Escape to cancel (removes the stroke).

### Minimum stroke
At least 3 points (approximately 9px of movement) required to register as a stroke. Single clicks or micro-movements are discarded.

## Interaction states

### Default (resting)
Stroke at rest with badge and note pill in their default subtle styling.

### Hover
Hovering over any part of the stroke, badge, or note highlights the entire unit:
- Soft glow behind the badge
- Note background and border intensify
- The stroke itself subtly brightens (opacity increases from 1.0 to 1.0 — no change needed, the glow on the badge is sufficient)

### Selected
Clicking the stroke line or badge selects the annotation:
- **Control point handles** appear along the stroke — approximately 5-8 evenly spaced white handles (5px radius, same style as other tools)
- The first handle is at the badge (stroke start)
- The last handle is at the stroke end
- Intermediate handles are spaced evenly along the path

### Reshape (drag handle)
Drag any control point handle to reshape the stroke:
- The stroke redraws through the new handle position
- Catmull-Rom smoothing recalculates in real time
- Other handles stay in place
- The note repositions if the bounding center shifts significantly

### Move (drag badge or stroke body)
Drag the badge or the stroke body (not a handle) to move the entire annotation:
- Stroke, badge, and note all move together

### Edit note
Clicking the note pill opens text editing. Same behavior as all tools.

## Interaction model

| Click target | Action |
|---|---|
| Stroke line or badge | Select → handles appear |
| Control point handle (when selected) | Drag to reshape |
| Badge or stroke body (when selected) | Drag to move |
| Note pill | Edit note text |
| Click elsewhere | Deselect |

## Edge behavior

Same rules as all tools:
- Badge clamps to canvas edge (never clipped)
- Stroke clips at canvas edge
- Note pills overflow beyond canvas edge (never clipped)

## Auto-numbering

Same shared sequence as all annotation tools.

## What gets exported

### In the screenshot image (baked into pixels)
- Smoothed stroke
- Numbered badge

### NOT in the screenshot image
- Note pills
- Control point handles

### In prompt.md
Same numbered list format as all other tools.

## Spatial constants

| Property | Value |
|---|---|
| Stroke width | 2.5px |
| Stroke smoothing | Catmull-Rom, 3 passes, 0.5 factor |
| Point sampling interval | 3px minimum |
| Badge radius | 9px (same as all tools) |
| Note clearance from bounding circle | 8px |
| Note height | 26px (same as all tools) |
| Note border-radius | 13px (pill, same as all tools) |
| Control point handle radius | 5px |
| Minimum stroke length | 3 points (~9px) |
| Control points shown when selected | 5-8 (evenly spaced) |

## Edge cases

### 1. Very short stroke
Minimum 3 points to register. Shorter movements are discarded.

### 2. Stroke that crosses itself
Works fine — the stroke is just a line, no fill. The smoothing handles self-crossing naturally.

### 3. Nearly closed stroke (user draws a rough circle)
The freehand tool treats it as an open stroke. If the user wants a closed circle, they should use the circle tool. The freehand stroke does not auto-close.

### 4. Very long or complex stroke
All points are recorded and smoothed. Performance concern for extremely long strokes (1000+ points) — in practice, screenshot annotations are short. If needed, downsample points while preserving curve shape.

### 5. Stroke near canvas edge
Stroke clips at edge. Badge clamps. Note overflows.

### 6. Undo/redo
Full support in the shared undo stack:
- Undo stroke placement (removes stroke + note)
- Undo handle reshape (reverts control point position)
- Undo move (reverts position)
- Undo note text edits
- Redo all of the above

### 7. Future: pressure fade
When pressure fade is added as a polish pass, the stroke rendering changes from a stroked path to a variable-width filled shape. The control point editing model stays the same — handles control the path centerline, and the taper is applied on top. This is a rendering change, not an interaction change.
