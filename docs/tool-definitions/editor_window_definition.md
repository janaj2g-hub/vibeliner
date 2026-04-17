# Vibeliner — Product Definition: Editor Window

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

The editor is a lightweight floating overlay — not a traditional window. A pill-shaped floating toolbar hovers above the screenshot, and a floating status pill sits below. The screenshot itself has a subtle shadow and rounded corners, sitting directly on the screen with no window chrome wrapping it.

The aesthetic is inspired by macOS Markup tools — minimal, tool-like, and non-intrusive.

## Window behavior

| Property | Value |
|---|---|
| Type | Borderless floating `NSPanel` |
| Level | Above all other windows (floating) |
| Size | Canvas matches the displayed screenshot; the panel adds overflow space for notes plus separate toolbar/status positioning |
| Position | Centered on screen after capture |
| Background | None — the screenshot is the window content |
| Close | X button or Esc key. Auto-saves before closing. |

## Layout structure

Three layers, top to bottom:

1. **Floating toolbar** (above the screenshot)
2. **Screenshot canvas** (the image + annotations)
3. **Floating status pill** (below the screenshot)

The toolbar and status pill float independently — they are not contained in a window frame.

## Floating toolbar

### Shape and style

| Property | Value |
|---|---|
| Shape | Pill (fully rounded, `border-radius: 20px`) |
| Height | 40px |
| Background | `rgba(30, 30, 30, 0.92)` with backdrop blur (12px) |
| Shadow | `0 4px 20px rgba(0,0,0,0.25)` |
| Position | Centered horizontally above the screenshot, 48px gap from top edge |

### Toolbar layout (left to right)

```
[sm] [X close] [xl spacer] [divider] [md] [Select] [Pin] [Arrow] [Rect] [Circle] [Freehand] [md] [Trash] [md] [Undo][Redo] [lg] [divider] [md] [IDE/App toggle] [md] [divider] [md] [Copy Prompt] [4px] [Copy Image*] [sm]
```

Spacer sizes: sm = 4px, md = 10px, lg = 20px, xl = 30px

`*` Copy Image is only visible in App mode.

### Close button (X)

| Property | Value |
|---|---|
| Size | 24px × 24px, circular (`border-radius: 12px`) |
| Icon | 10px × 10px X mark |
| Icon color | `rgba(255, 255, 255, 0.4)` default, `#FF5F57` on hover |
| Hover background | `rgba(255, 87, 87, 0.2)` |
| Tooltip | "Close (Esc)" |

The X has generous breathing room (30px spacer) separating it from the tool group. It reads as a quiet escape hatch, not a primary action.

### Annotation tool buttons

All tool buttons are circular: 30px × 30px, `border-radius: 15px`.

| State | Background | Icon color |
|---|---|---|
| Default | Transparent | `rgba(255, 255, 255, 0.4)` |
| Hover | `rgba(255, 255, 255, 0.08)` | `rgba(255, 255, 255, 0.8)` |
| Active (selected) | `rgba(175, 169, 236, 0.2)` | `#AFA9EC` |

#### Pin icon

The pin tool icon is a filled circle with a small line, matching the current toolbar icon drawing used elsewhere in settings.

| Property | Value |
|---|---|
| Circle | Filled, uses the active/inactive toolbar icon colors |
| Line | Same color as circle, 1.8px stroke |

#### Other tool icons

Standard outlined icons using the `.ts` stroke class. 15px × 15px SVG, 1.4px stroke weight.

Each tool shows a tooltip on hover: "Pin", "Arrow", "Rectangle", "Circle", "Freehand".

### Trash button

| Property | Value |
|---|---|
| Size | 28px × 28px, circular |
| Icon | 14px trash can outline |
| Default color | `rgba(255, 255, 255, 0.4)` |
| Hover | Background `rgba(255, 87, 87, 0.15)`, icon color `#EF4444` |
| Tooltip | "Delete" |

Deletes the currently selected annotation only.

### Undo / Redo buttons

| Property | Value |
|---|---|
| Size | 28px × 28px each, circular |
| Gap between them | 1px (they read as a pair) |
| Icon | 14px curved arrow (undo points left, redo points right) |
| Default color | `rgba(255, 255, 255, 0.4)` |
| Hover | Background `rgba(255, 255, 255, 0.1)`, icon `rgba(255, 255, 255, 0.8)` |
| Tooltips | "Undo", "Redo" |

### Dividers

| Property | Value |
|---|---|
| Width | 1px |
| Height | 16px |
| Color | `rgba(255, 255, 255, 0.08)` |

### Copy Prompt button (primary)

| Property | Value |
|---|---|
| Shape | Pill (`border-radius: 14px`) |
| Padding | 5px 14px |
| Font | 12px, weight 500 |
| Tooltip | "Copy prompt text for Claude Code & Cursor" |

#### Normal state

| Property | Value |
|---|---|
| Border | 1.5px solid `#a796eb` |
| Text color | `#a796eb` |
| Background | `rgba(116, 97, 194, 0.25)` |

#### Hover state

| Property | Value |
|---|---|
| Border | 1.5px solid `#c4b8f5` |
| Text color | `#c4b8f5` |
| Background | `rgba(116, 97, 194, 0.35)` |

#### Behavior
Copies the prompt text (with absolute screenshot path) to the clipboard. Changes the status pill to "Copied" in green for 2 seconds. `Cmd+C` (when no text field is focused) triggers this action.

### Copy Image button (secondary, App mode only)

| Property | Value |
|---|---|
| Shape | Pill (`border-radius: 12px`) |
| Padding | 4px 12px |
| Font | 11px, weight 500 |
| Tooltip | "Copy image for Claude.ai & ChatGPT" |

#### Normal state

| Property | Value |
|---|---|
| Border | 1px solid `rgba(255, 255, 255, 0.2)` |
| Text color | `rgba(255, 255, 255, 0.55)` |
| Background | Transparent |

#### Hover state

| Property | Value |
|---|---|
| Border | 1px solid `rgba(255, 255, 255, 0.4)` |
| Text color | `rgba(255, 255, 255, 0.8)` |
| Background | `rgba(255, 255, 255, 0.06)` |

#### Behavior
Copies the annotated screenshot image to the system clipboard. Changes the status pill to "Image copied" in green for 2 seconds. Used when pasting into web-based LLM tools that accept image paste.

### Two-button layout

In App mode, the buttons sit side by side at the right end of the toolbar, with 4px gap between them. In IDE mode, only "Copy Prompt" is shown.

## Screenshot canvas

| Property | Value |
|---|---|
| Border radius | 6px |
| Shadow | `0 4px 24px rgba(0,0,0,0.12), 0 1px 4px rgba(0,0,0,0.08)` |
| Overflow | Marks layer clips to canvas. Notes layer overflows (visible beyond edges). |

The canvas contains two SVG layers:
1. **Marks layer** (`overflow: hidden`) — annotation shapes, lines, badges. Clips at canvas edge.
2. **Notes layer** (`overflow: visible`) — note pills. Can extend beyond canvas edge.

## Floating status pill

| Property | Value |
|---|---|
| Shape | Pill (`border-radius: 12px`) |
| Background | `rgba(30, 30, 30, 0.88)` with backdrop blur (8px) |
| Shadow | `0 2px 8px rgba(0,0,0,0.15)` |
| Font | Monospace, 10px, weight 500, white |
| Position | Centered horizontally below the screenshot, 32px gap from bottom edge |
| Content | `{width} × {height} · {count} notes` |

### Copy confirmation state

When a copy button is clicked:
- Background transitions to `rgba(22, 163, 74, 0.9)` (green)
- Text changes to the specific action message such as "Prompt copied" or "Image copied"
- Reverts to normal after 2 seconds
- Transition: 0.3s ease

## Keyboard shortcuts

| Key | Action |
|---|---|
| Esc | Auto-save and close the editor |
| Cmd+Z | Undo |
| Cmd+Shift+Z | Redo |
| Cmd+C (no text field focused) | Copy Prompt |
| Delete / Backspace | Delete selected annotation |
| 1-6 | Switch tools (1=Select, 2=Pin, 3=Arrow, 4=Rect, 5=Circle, 6=Freehand) |

## Auto-save behavior

The editor auto-saves continuously:
- Every annotation placement, edit, or deletion triggers a save
- Closing (X or Esc) saves before closing
- The capture folder is always up to date — there is no unsaved state
- No explicit "Save" button needed

## Edge cases

### 1. Very large screenshot
The window resizes to fit but caps at the screen's usable area. If the screenshot is larger than the screen, it scales down to fit (maintaining aspect ratio) and a zoom indicator appears in the status pill.

### 2. Very small screenshot
The toolbar may be wider than the screenshot. The toolbar stays centered and extends beyond the screenshot edges — this is fine since it's floating independently.

### 3. Multiple monitors
The editor appears on the same screen where the capture was taken.

### 4. No annotations placed
The status pill shows "0 notes". Copy actions still work with an empty annotation list.
