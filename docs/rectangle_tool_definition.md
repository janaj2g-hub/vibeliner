# Vibeliner — Product Definition: Rectangle Annotation Tool

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

The rectangle tool draws a bounded box around an area of the screenshot. Use it to highlight containers, cards, sections, or any rectangular region. The numbered badge sits on the corner where the user started dragging, and the note pill is centered on the badge, offset to the outside of the rectangle.

## Anatomy of a rectangle annotation

1. **Rectangle** — red outlined box with a very subtle red fill
2. **Numbered badge** — red filled circle with white number, sitting on the corner where the drag started
3. **Note pill** — text field centered horizontally on the badge, offset to the outside of the rectangle

### Rectangle

| Property | Value |
|---|---|
| Stroke | `#EF4444`, 2.5px |
| Fill | `rgba(239, 68, 68, 0.06)` (very subtle, 6% opacity) |
| Corner radius | 3px |

The subtle fill tints the bounded area just enough to show what's selected without obscuring the screenshot content underneath.

### Numbered badge

| Property | Value |
|---|---|
| Shape | Filled circle |
| Diameter | 18px (radius 9px) |
| Fill | `#EF4444` |
| Number color | White `#FFFFFF` |
| Number font | System font, 9px, weight 600 |
| Position | Exactly on the corner point where the user started dragging |

The badge sits directly on the rectangle's corner — centered on the corner point. There is no stake. The badge overlaps the rectangle border.

### Badge corner placement

The badge goes on whichever corner the user started the drag from:

| Drag direction | Badge corner |
|---|---|
| Top-left → bottom-right | Top-left |
| Top-right → bottom-left | Top-right |
| Bottom-left → top-right | Bottom-left |
| Bottom-right → top-left | Bottom-right |

This means the user naturally controls badge placement by choosing where to start their drag.

### Note pill

| Property | Value |
|---|---|
| Shape | Pill (`border-radius: 13px`) |
| Height | 26px |
| Horizontal alignment | Centered on the badge |
| Vertical position | Offset to the OUTSIDE of the rectangle, 6px gap from the badge edge |

Note content follows the same spec as pin and arrow: number prefix (9px, non-deletable, light maroon) followed by user text (12px, dark maroon).

### Smart note placement

The note always positions on the outside of the rectangle, away from the rectangle's interior:

| Badge corner | Note position |
|---|---|
| Top-left | Above the badge |
| Top-right | Above the badge |
| Bottom-left | Below the badge |
| Bottom-right | Below the badge |

The note is always horizontally centered on the badge regardless of corner position.

## Placement flow

### 1. Tool activation
User clicks the Rectangle button in the toolbar.

### 2. Click (start corner)
User clicks to set the first corner. This determines where the badge will sit.

### 3. Drag (drawing)
User drags to the opposite corner. During the drag:
- The rectangle previews at 50% opacity with the badge on the start corner
- A purple dot marks the current cursor position (opposite corner)
- Minimum size: 15×15px to register (prevents accidental micro-rectangles)

### 4. Release (placed)
User releases. The rectangle appears at full opacity. The note pill opens immediately in editing mode.

### 5. Type note
User types description. Press Enter to confirm. Press Escape to cancel (removes the rectangle).

## Interaction states

### Default (resting)
Rectangle with subtle fill, badge on corner, note pill offset outside. Same subtle styling as other tools.

### Hover
Hovering over ANY part of the rectangle (stroke, fill, badge, or note) highlights the entire unit:
- Soft glow behind the badge
- Note intensifies
- No handles on hover

### Selected
Clicking the rectangle body (stroke, fill, or badge) selects it:
- Three corner handles appear (white circles with red border, 5px radius)
- The badge corner does NOT get a handle — the badge itself is the fourth corner
- Handles appear on the three non-badge corners

### Resize (drag corner)
Drag any corner handle to resize the rectangle:
- Dashed ghost of the original rectangle
- Live resize preview
- Badge stays locked to its corner
- Note stays centered on the badge, repositioning as needed
- Active handle: purple fill with dashed purple ring

### Move (drag badge)
Drag the badge to move the entire rectangle:
- Ghost of original position at 15% opacity
- The rectangle, badge, and note all move together
- All four corners move by the same offset

### Edit note
Clicking the note pill opens text editing:
- Red border, blinking cursor
- Handles not shown during text editing
- Same editing behavior as pin and arrow tools

## Interaction model

| Click target | Action |
|---|---|
| Rectangle body, stroke, or badge | Select → handles appear |
| Corner handle (when selected) | Drag to resize |
| Badge (when selected) | Drag to move entire rectangle |
| Note pill | Edit note text |
| Click elsewhere | Deselect |

## Auto-numbering

Same shared sequence as all annotation tools. Pins, arrows, rectangles, circles, and freehand all share one counter.

## What gets exported

### In the screenshot image (baked into pixels)
- Rectangle outline + fill
- Numbered badge

### NOT in the screenshot image
- Note pills and their text
- Handles

### In prompt.md
Same numbered list format as all other tools.

## Note overflow rule (applies to ALL tools)

Note pills are NEVER clipped by the canvas edge. They render on top of and beyond the canvas boundary. If a badge is near the edge of the screenshot and the note pill extends past the frame, the note is still fully visible — it overflows the canvas.

Implementation: notes should render in a layer above the canvas that does not clip (`overflow: visible`), or in a separate overlay layer. Annotation marks (rectangles, lines, badges) are clipped to the canvas, but note pills are not.

This rule applies globally to pins, arrows, rectangles, circles, and freehand annotations.

## Color system

Same as all tools — `#EF4444` family for marks, maroon family for note text, purple for interactive states.

## Spatial constants

| Property | Value |
|---|---|
| Rectangle stroke width | 2.5px |
| Rectangle fill opacity | 6% (`0.06`) |
| Rectangle corner radius | 3px |
| Badge radius | 9px (same as all tools) |
| Note offset from badge edge | 6px |
| Note height | 26px (same as all tools) |
| Note border-radius | 13px (pill, same as all tools) |
| Corner handle radius | 5px |
| Active handle ring radius | 10px |
| Minimum rectangle size | 15×15px |

## Edge cases

### 1. Very small rectangle
Minimum 15×15px to register. Anything smaller on either axis is discarded.

### 2. Badge near canvas edge
The badge must stay fully within the canvas (same rule as all tools). If the user starts a drag too close to the edge for the badge to fit, the badge snaps to the nearest valid position.

### 3. Note extending beyond canvas
The note pill overflows the canvas edge — it is never clipped. See "Note overflow rule" above.

### 4. Overlapping rectangles
Same z-order rules as all tools. Most recently placed or selected rectangle renders on top. Click targets prioritize the topmost annotation.

### 5. Rectangle covering most of the canvas
Works normally. The subtle 6% fill ensures the screenshot is still visible through the rectangle.

### 6. Undo/redo
Full support in the shared undo stack:
- Undo placement (removes rectangle + note)
- Undo resize (reverts to previous dimensions)
- Undo move (reverts to previous position)
- Undo note text edits
- Redo all of the above
