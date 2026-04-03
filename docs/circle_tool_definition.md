# Vibeliner — Product Definition: Circle Annotation Tool

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

The circle tool draws a true circle (always 1:1 ratio) around an area of the screenshot. Use it to call out a specific element, button, icon, or cluster. The user drags from the center outward to set the radius. The badge sits on the perimeter at the release point, and the note is pushed radially outward so it never overlaps the circle.

## Anatomy of a circle annotation

1. **Circle** — red outlined circle with a very subtle red fill
2. **Numbered badge** — red filled circle with white number, sitting on the perimeter where the user released
3. **Note pill** — text field pushed radially outward from the badge, guaranteed outside the circle

### Circle shape

| Property | Value |
|---|---|
| Stroke | `#EF4444`, 2.5px |
| Fill | `rgba(239, 68, 68, 0.06)` (same 6% as rectangle) |
| Shape | True circle only — always 1:1 ratio, no ellipses |

### Numbered badge

| Property | Value |
|---|---|
| Shape | Filled circle, 18px diameter (radius 9px) |
| Fill | `#EF4444` |
| Number | White, 9px, weight 600 |
| Position | On the circle perimeter, at the point where the user released the drag |

### Note pill

| Property | Value |
|---|---|
| Shape | Pill (`border-radius: 13px`), 26px height |
| Content | Number prefix (9px, light maroon) + user text (12px, dark maroon) |
| Position | Radially outward from the circle center through the badge point |

## Placement flow

### 1. Tool activation
User clicks the Circle button in the toolbar.

### 2. Click (center point)
User clicks to set the center of the circle.

### 3. Drag outward (radius)
User drags outward from the center to define the radius. During the drag:
- Circle previews at 50% opacity, growing from the center
- Badge preview at 50% on the perimeter at the current cursor position
- A purple dot marks the cursor position on the perimeter
- Minimum radius of 15px to register

### 4. Release (placed)
User releases. The circle appears at full opacity. The badge sits at the release point on the perimeter. The note pill opens immediately in editing mode, positioned radially outward.

### 5. Type note
User types description. Press Enter to confirm. Press Escape to cancel.

## Radial note placement algorithm

The note pill is positioned along the radial line from the circle center through the badge point, pushed outward until it fully clears the circle perimeter.

### Algorithm

1. Calculate the unit direction vector from circle center to badge (`ux`, `uy`)
2. Place the note center at: `badge position + (ux, uy) * (badge_radius + 8px + note_height/2)`
3. Check all four corners of the note pill against the circle perimeter
4. If any corner is less than 8px outside the circle perimeter, push the note further outward along the radial direction
5. Repeat until all four corners have at least 8px clearance from the circle edge

This guarantees the note never overlaps its own circle, regardless of badge position (top, right, bottom, left, or any angle).

### Clearance constant

| Property | Value |
|---|---|
| Minimum clearance from circle edge to nearest note corner | 8px |

## Interaction states

### Default, hover, selected, editing
Same patterns as rectangle tool:
- Hover: glow behind badge, note intensifies, entire unit highlights
- Selected: click circle body → handles appear (see below)
- Edit note: click note pill → text editing

### Handles (when selected)

When selected, handles appear for editing the circle:
- **Badge handle** (on perimeter): drag to rotate the badge position around the circle. The note follows.
- **Resize handle**: a single handle on the opposite side of the circle from the badge. Drag to resize the radius. The center stays fixed.

Two handles total — badge repositioning and resize.

### Move
Drag the circle fill area (not a handle) to move the entire circle. Badge and note follow.

## Edge behavior — CRITICAL

### Badge clamping
The badge must NEVER be clipped by the canvas edge. If the user drags outward such that the badge would land outside the canvas boundary:
- The badge clamps to the nearest point on the canvas edge
- The badge stays on the circle perimeter if possible, but stops at the canvas boundary
- The badge is always fully visible

### Circle clipping
The circle shape itself CAN extend beyond the canvas and be clipped. Only the visible portion within the canvas renders. This is fine — the circle is a visual mark, and partial circles near edges are still useful.

### Note overflow
Notes can extend beyond the canvas edge (same global rule as all tools). Notes are never clipped.

### Summary

| Element | Can be clipped by canvas edge? |
|---|---|
| Circle shape (stroke + fill) | Yes — clips at edge |
| Badge | No — clamps to edge, always fully visible |
| Note pill | No — overflows beyond edge, always fully visible |

## Auto-numbering

Same shared sequence as all annotation tools.

## What gets exported

### In the screenshot image (baked into pixels)
- Circle outline + fill (clipped to canvas)
- Numbered badge

### NOT in the screenshot image
- Note pills
- Handles

### In prompt.md
Same numbered list format as all other tools.

## Spatial constants

| Property | Value |
|---|---|
| Circle stroke width | 2.5px |
| Circle fill opacity | 6% (`0.06`) |
| Badge radius | 9px (same as all tools) |
| Note clearance from circle edge | 8px |
| Note height | 26px (same as all tools) |
| Note border-radius | 13px (pill, same as all tools) |
| Minimum circle radius | 15px |

## Edge cases

### 1. Very small circle
Minimum 15px radius to register. Smaller drags are discarded.

### 2. Badge at exact top of circle
Note pushes straight up. Works naturally with the radial algorithm.

### 3. Badge at exact bottom
Note pushes straight down. May overflow below the canvas — that's fine (notes overflow).

### 4. Very large circle (larger than canvas)
Circle clips at canvas edges. Badge clamps to stay visible. The user can still annotate the portion visible within the canvas.

### 5. Circle drawn near canvas edge
Circle clips. Badge clamps to edge. Note overflows. All elements remain usable.

### 6. Undo/redo
Full support in the shared undo stack:
- Undo placement, resize, move, badge rotation, note text edits
- Redo all of the above
