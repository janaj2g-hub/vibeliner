# Vibeliner — Product Definition: Pin Annotation Tool

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

The pin is the primary and simplest annotation tool. Click to place a numbered marker at a precise point on the screenshot. Each pin has a note field for describing the issue. The pin and its note form a single visual unit.

## Anatomy of a pin

A pin consists of three parts, top to bottom:

1. **Badge** — red filled circle with a white number
2. **Stake** — short red line connecting the badge to the precise point
3. **Note** — pill-shaped text field to the right of the badge

### Badge

| Property | Value |
|---|---|
| Shape | Filled circle |
| Diameter | 18px (radius 9px) |
| Fill | `#EF4444` |
| Number color | White `#FFFFFF` |
| Number font | System font, 9px, weight 600 |
| Number alignment | Centered horizontally and vertically in the circle |

### Stake

| Property | Value |
|---|---|
| Length | 10px |
| Color | `#EF4444` |
| Width | 2px |
| Cap | Round (`stroke-linecap: round`) |
| Position | Extends downward from the bottom of the badge to the tip point |

The stake tip is the precision point — this is where the user clicked and what the annotation refers to.

### Note (pill)

| Property | Value |
|---|---|
| Shape | Pill (fully rounded ends, `border-radius: 13px`) |
| Height | 26px |
| Position | Vertically centered to the badge. Left edge starts 10px to the right of the badge's right edge. |
| Background | `rgba(239, 68, 68, 0.05)` (very subtle red tint) |
| Border | `rgba(239, 68, 68, 0.10)`, 0.5px |
| Internal padding | 12px horizontal |

### Note content

The note contains two text elements:

1. **Number prefix** — the pin's number (e.g., `1`, `2`, `3`), NO period after it
   - Font size: 9px (matches badge number)
   - Weight: 600
   - Color: `rgba(153, 27, 27, 0.35)` (light maroon)
   - Vertically centered in the pill, aligned to the badge's center line

2. **User text** — the annotation description
   - Font size: 12px
   - Weight: 400
   - Color: `#7f1d1d` (dark maroon)
   - Starts 8px after the number prefix
   - Vertically centered in the pill

The number prefix is non-deletable. It auto-assigns the next sequential number when the pin is placed. The user can only edit the text after the number.

## Placement flow

### 1. Tool activation
User clicks the Pin button in the toolbar. The pin tool is now active.

### 2. Ghost preview
A 50% opacity pin follows the cursor. The cursor tip sits at the stake tip — the user sees exactly where the pin will land. A tiny purple dot (`rgba(175, 169, 236, 0.7)`, 2px radius) marks the exact placement point at the stake tip.

The system cursor is hidden while the ghost preview is active.

### 3. Click to place
User clicks. The pin appears at full opacity. The number is auto-assigned (next in sequence). The note field opens automatically in editing mode.

### 4. Type note
The note field is in editing mode (see Editing state below). The user types their description. The number prefix is visible but non-editable — the cursor starts after the number.

### 5. Confirm
Press Enter to confirm. The note collapses to its default (resting) state. The pin tool remains active for placing the next pin.

Press Escape to cancel — removes the pin entirely.

## Interaction states

### Default (resting)

The pin + note unit at rest. Subtle note background, barely-there border. Designed to be readable without competing with the screenshot content.

- Badge: `#EF4444` fill
- Note background: `rgba(239, 68, 68, 0.05)`
- Note border: `rgba(239, 68, 68, 0.10)`, 0.5px

### Hover

Hovering over EITHER the badge OR the note highlights BOTH — they are always visually linked.

- Badge: A soft circular glow appears behind it — `rgba(239, 68, 68, 0.07)` fill, radius extends 6px beyond the badge edge. No hard border on the glow.
- Note: Background intensifies to `rgba(239, 68, 68, 0.08)`. Border intensifies to `rgba(239, 68, 68, 0.30)`, 1px.
- Cursor: Pointer

The hover effect is calm and generous — a warm glow, not an aggressive highlight.

### Editing

Triggered by clicking the badge OR clicking the note text.

- Note border: `#EF4444`, 1.5px (clear red border)
- Note background: `rgba(239, 68, 68, 0.06)`
- Note width: Expands to at least 200px to give typing room
- Blinking cursor: `#EF4444`, 1.5px, appears after the user text
- Cursor blink: Animates opacity 1→0→1 over 1 second
- Badge: Stays in default state (no highlight) — only the note signals "active"
- Number prefix: Remains visible, lighter, non-editable

### Dragging (pin)

Click + hold on the badge to drag the entire pin to a new position.

- A ghost pin remains at the original position at 20% opacity
- A dashed purple line (`rgba(175, 169, 236, 0.3)`, stroke-dasharray: 4,3) shows the move path from original to new position
- The note follows the pin
- Cursor: Grabbing
- A dashed purple circle (`rgba(175, 169, 236, 0.4)`, stroke-dasharray: 3,3) appears around the badge while dragging

### Dragging (note)

Click + drag the note pill to reposition it independently from the pin.

- A dashed red tether line (`rgba(239, 68, 68, 0.2)`, stroke-dasharray: 3,2) connects the note back to the badge center
- Note border becomes purple dashed (`rgba(175, 169, 236, 0.5)`, 1.5px) while dragging
- The note stays logically tied to the pin — renumbering and export still associate them
- Cursor: Grabbing

## Auto-numbering

- Pins are numbered sequentially: 1, 2, 3, etc.
- The badge number and the note prefix always match
- Deleting a pin causes all subsequent pins to renumber (delete pin 2 → pin 3 becomes pin 2)
- The note prefixes update to match when renumbering occurs

## What gets exported

### In the screenshot image (baked into pixels)
- Badge (filled red circle with white number)
- Stake line
- Any drawn marks (from other tools)

### NOT in the screenshot image
- Note pills and their text

### In prompt.md
The note text appears as a numbered list:
```
1  padding too tight
2  wrong border radius
3  font weight too heavy
```

The numbers in prompt.md match the badge numbers in the screenshot. This is the core contract — LLMs see the image with numbered badges and the prompt with numbered descriptions, and the numbers correspond.

## Color system

| Element | Color |
|---|---|
| Badge fill | `#EF4444` |
| Badge number | `#FFFFFF` |
| Stake line | `#EF4444` |
| Note background (default) | `rgba(239, 68, 68, 0.05)` |
| Note border (default) | `rgba(239, 68, 68, 0.10)` |
| Note background (hover) | `rgba(239, 68, 68, 0.08)` |
| Note border (hover) | `rgba(239, 68, 68, 0.30)` |
| Note border (editing) | `#EF4444` |
| Number prefix text | `rgba(153, 27, 27, 0.35)` |
| User text | `#7f1d1d` |
| Hover glow | `rgba(239, 68, 68, 0.07)` |
| Ghost preview | 50% opacity of all elements |
| Cursor dot (placement) | `rgba(175, 169, 236, 0.7)` |
| Drag indicators | Purple `rgba(175, 169, 236, *)` family |

## Spatial constants

| Property | Value |
|---|---|
| Badge radius | 9px |
| Stake length | 10px |
| Gap between badge and note | 10px |
| Note height | 26px |
| Note border-radius | 13px (pill) |
| Note internal padding (horizontal) | 12px |
| Number prefix font size | 9px |
| User text font size | 12px |
| Space between prefix and user text | 8px |
| Hover glow radius beyond badge | 6px |
| Editing note minimum width | 200px |

## Edge cases

### 1. Pin placed near top edge
The badge (circle + stake) must remain fully within the screenshot canvas at all times. During ghost preview and dragging, if the cursor is too close to the top edge for the full pin to fit, the pin snaps to the lowest valid position (stake tip at the topmost point where the badge still fits entirely within bounds). The user cannot place or drag a pin into a position where the badge is clipped by the top edge.

### 2. Pin placed near right edge
If the note pill would extend beyond the right edge of the canvas, the note repositions to the LEFT of the badge instead (mirrored layout: note → gap → badge → stake). All spacing values remain the same, just flipped. The note may also extend off-canvas to the right since notes are not baked into the exported image — but the flip is preferred for readability during editing.

### 3. Very long note text
The note pill grows horizontally up to 25 characters of user text. Beyond 25 characters, the pill's width is capped and the text wraps — the pill grows vertically (downward) to accommodate additional lines. Text is never clipped or truncated. All note text must be fully visible at all times during editing. It is acceptable for the note pill to extend beyond the canvas edge, since notes are NOT saved into the exported screenshot image — only the numbered pin badges are baked into the export.

### 4. Deleting a pin
Deleting a pin removes both the badge/stake AND its associated note pill. All subsequent pins renumber (delete pin 2 → pin 3 becomes pin 2, etc.). The note prefixes update to match. Deletion is undoable — Cmd+Z restores the pin and note in their exact prior position with their original number.

### 5. Undo / Redo
Full undo/redo support for:
- **Pin placement:** Cmd+Z removes the most recently placed pin. Cmd+Shift+Z re-places it.
- **Pin deletion:** Cmd+Z after deleting restores the pin + note. Renumbering reverses.
- **Pin movement (drag):** Cmd+Z returns the pin to its previous position. Cmd+Shift+Z moves it back.
- **Note movement (drag):** Cmd+Z returns the note to its previous position relative to the pin.
- **Note text edits:** Standard text undo/redo within the editing field.

Undo/redo operates as a single linear stack across all annotation actions (not just pins — all tools share one undo history).

### 6. Overlapping pins
Pins can overlap. The most recently placed or selected pin renders on top (highest z-order). Hover and click targets prioritize the topmost pin. Clicking in an area where multiple pins overlap selects the topmost one. To access a pin underneath, the user can move the top pin or use the note pills (which may not overlap even if badges do).

### 7. 10+ pins
Badge numbers go to 10, 11, etc. The badge circle does not grow — two-digit numbers render at a slightly smaller font size (7px instead of 9px) to fit within the same 18px diameter circle.
