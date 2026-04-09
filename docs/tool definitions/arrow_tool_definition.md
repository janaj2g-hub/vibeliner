# Vibeliner — Product Definition: Arrow Annotation Tool

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

The arrow tool draws a directional line between two points. Use it to show direction, point at something specific, or indicate "move this here." The numbered circle sits directly on the line at the start point, and the note pill is centered on the circle, offset above or below to stay clear of the arrow line.

## Anatomy of an arrow

An arrow consists of three parts:

1. **Numbered circle** — red filled circle with white number, sitting ON the line at the start point
2. **Line** — red line extending from the circle's edge to the endpoint
3. **Open chevron** — two lines forming a V at the endpoint (arrowhead)
4. **Note pill** — text field centered horizontally on the circle, offset above or below

### Numbered circle

| Property | Value |
|---|---|
| Shape | Filled circle |
| Diameter | 18px (radius 9px) |
| Fill | `#EF4444` |
| Number color | White `#FFFFFF` |
| Number font | System font, 9px, weight 600 |
| Position | Directly on the line at the start point. The line begins from the circle's edge, not its center. |

There is NO stake. The circle IS the start point, sitting directly on the arrow line.

### Line

| Property | Value |
|---|---|
| Color | `#EF4444` |
| Width | 2.5px |
| Cap | Round (`stroke-linecap: round`) |
| Origin | Starts from the edge of the numbered circle (not the center) |
| Endpoint | The tip of the chevron |

### Open chevron (arrowhead)

| Property | Value |
|---|---|
| Style | Two lines forming an open V — NOT a filled triangle |
| Arm length | 12px |
| Angle | 28° from the line axis |
| Stroke | Same as line: `#EF4444`, 2.5px, round cap, round join |

### Note pill

| Property | Value |
|---|---|
| Shape | Pill (fully rounded ends, `border-radius: 13px`) |
| Height | 26px |
| Horizontal alignment | Centered on the numbered circle |
| Vertical offset | 6px gap between circle edge and note edge |
| Position rule | If arrow points upward (endpoint above start), note goes BELOW. If arrow points downward (endpoint below start), note goes ABOVE. The note always positions away from the arrow direction so it never overlaps the line. |

Note content follows the same spec as the pin tool: number prefix (9px, non-deletable, light maroon) followed by user text (12px, dark maroon).

## Placement flow

### 1. Tool activation
User clicks the Arrow button in the toolbar. Arrow tool is active.

### 2. Click (start point)
User clicks to set the start point. This is where the numbered circle will sit.

### 3. Drag (drawing)
User drags to extend the arrow. During the drag:
- The entire arrow (circle + line + chevron) previews at 50% opacity
- The line and chevron update in real time as the cursor moves
- A small purple dot (`rgba(175, 169, 236, 0.6)`, 3px radius) marks the current endpoint
- Minimum drag distance of 20px to register as an arrow (prevents accidental micro-arrows)

### 4. Release (placed)
User releases. The arrow appears at full opacity. The note pill opens immediately in editing mode, centered on the circle, offset above or below based on arrow direction.

### 5. Type note
User types their description. Press Enter to confirm.

### 6. Done
Note collapses to resting state. Arrow tool remains active for the next arrow.

Press Escape during text editing to cancel — removes the arrow entirely.

## Interaction states

### Default (resting)
Arrow at rest with all elements at default styling. Note pill uses the same subtle styling as the pin tool (5% red fill, barely-there border).

### Hover
Hovering over ANY part of the arrow (circle, line, chevron, or note) highlights the entire unit:
- Soft circular glow behind the numbered circle (same as pin hover)
- Note background and border intensify
- No handles appear on hover — just visual feedback
- Cursor: pointer

### Selected
Clicking the arrow line, circle, or chevron (NOT the note pill) selects the arrow:
- Two white handle dots appear:
  - Start handle: centered on the numbered circle (radius 5px, white fill, red border)
  - End handle: centered on the chevron tip (same style)
- Handles signal that both endpoints are independently draggable
- The arrow stays selected until the user clicks elsewhere or presses Escape

### Drag start point
Grab the start handle to move the arrow's origin:
- Ghost of the original arrow at 15% opacity
- Purple dashed line showing the move path
- Active handle: purple fill with dashed purple ring
- The circle, line origin, and note all move together
- The endpoint stays fixed
- The note auto-repositions (may flip above/below) based on the new arrow direction

### Drag end point
Grab the end handle to redirect the arrow:
- Ghost of the original chevron position at 15% opacity
- Purple dashed line showing the move path
- Active handle: purple fill with dashed purple ring
- The arrow pivots around the fixed start point
- The note may flip above/below as the direction changes

### Edit note
Clicking the note pill specifically (not the arrow body) opens text editing:
- Red border (1.5px), blinking red cursor
- Handles are NOT shown during text editing — the contexts don't overlap
- Click outside or press Enter to finish editing

## Interaction model summary

| Click target | Action |
|---|---|
| Arrow line, circle, or chevron | Select → handles appear |
| Note pill | Edit note text |
| Start handle (when selected) | Drag to reposition start |
| End handle (when selected) | Drag to redirect end |
| Click elsewhere | Deselect |

This separation ensures the user never accidentally starts text editing when trying to reposition, or vice versa.

## Smart note placement rules

The note pill always positions itself away from the arrow line:

| Arrow direction | Note position |
|---|---|
| Points up (endpoint Y < start Y) | Note below the circle |
| Points down (endpoint Y > start Y) | Note above the circle |
| Points horizontally (endpoint Y ≈ start Y) | Note above the circle (default) |

The note is always horizontally centered on the numbered circle regardless of arrow direction.

When dragging either endpoint, the note re-evaluates its position in real time and may flip from above to below (or vice versa) as the arrow direction changes. This ensures the note never overlaps the arrow line.

## Auto-numbering

Same rules as the pin tool:
- Sequential numbering: 1, 2, 3, etc.
- Shared number sequence with ALL annotation tools (pins, arrows, rectangles, circles, freehand all share one counter)
- Deleting renumbers the remaining annotations sequentially
- Badge number and note prefix always match

## What gets exported

### In the screenshot image (baked into pixels)
- Numbered circle
- Arrow line
- Open chevron

### NOT in the screenshot image
- Note pills and their text
- Handles

### In prompt.md
Same format as pin tool — numbered list entries. The numbers match across all annotation types.

## Color system

Same as pin tool. All annotation tools share the red `#EF4444` family for marks and the maroon family for note text. Purple is used only for interactive states (placement preview, drag indicators, active handles).

## Spatial constants

| Property | Value |
|---|---|
| Circle radius | 9px (same as pin badge) |
| Line width | 2.5px |
| Chevron arm length | 12px |
| Chevron angle | 28° |
| Note offset from circle edge | 6px |
| Note height | 26px (same as pin) |
| Note border-radius | 13px (pill, same as pin) |
| Handle radius | 5px |
| Active handle ring radius | 10px |
| Minimum drag distance | 20px |

## Edge cases

### 1. Very short arrow
Minimum 20px drag to register. Anything shorter is treated as a click (no arrow placed).

### 2. Arrow near canvas edge
The numbered circle must stay fully within the canvas (same rule as pin badge). The chevron endpoint can extend to the very edge. The note pill may extend beyond the canvas since it's not exported.

### 3. Arrow pointing straight down
Note goes above the circle. The note is centered horizontally, so it doesn't interfere with a vertical line.

### 4. Arrow pointing straight up
Note goes below the circle. Same logic.

### 5. Nearly horizontal arrow
Default to note above. The threshold for "pointing up" vs "pointing down" is whether the endpoint Y is less than or greater than the start Y.

### 6. Overlapping arrows
Same z-order rules as pins. Most recently placed or selected arrow renders on top.

### 7. Undo/redo
Full support — same shared undo stack as all tools:
- Undo arrow placement (removes arrow + note)
- Undo start/end point drag (reverts position)
- Undo note text edits
- Redo all of the above
