# Vibeliner — Product Definition: Menu Bar Popover

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

The menu bar popover is the day-to-day interface for Vibeliner. It's a compact dark utility menu accessed by clicking the Vibeliner icon in the macOS menu bar. It provides quick access to capture, recent captures, the captures folder, settings, and quit.

## Menu bar icon

| Property | Value |
|---|---|
| Style | Crosshair icon (circle + crosshair lines) matching Vibeliner's capture aesthetic |
| Size | Standard macOS menu bar icon size (18×18 points) |
| Color | Template image (adapts to system light/dark menu bar) |

## Popover appearance

| Property | Value |
|---|---|
| Background | `rgba(30, 30, 30, 0.95)` with backdrop blur (16px) |
| Border | `0.5px solid rgba(255, 255, 255, 0.08)` |
| Border radius | 10px |
| Shadow | `0 8px 32px rgba(0,0,0,0.35)` |
| Width | 210px |
| Arrow | 12px rotated square pointing up at the menu bar icon |

Dark appearance matching the editor toolbar.

## Menu items

Five items in the main popover, top to bottom:

### 1. Capture Now

| Property | Value |
|---|---|
| Icon | Camera icon |
| Label | "Capture Now" |
| Shortcut | `⌘⇧6` (shown as kbd badge) |
| Action | Triggers screen capture (same as the hotkey) |

### 2. Recent Captures

| Property | Value |
|---|---|
| Icon | Clock icon |
| Label | "Recent Captures" |
| Arrow | Right-pointing triangle (`▸`) indicating a submenu |
| Action | Hovering reveals a submenu to the right |

### 3. Open Captures

| Property | Value |
|---|---|
| Icon | Folder icon |
| Label | "Open Captures" |
| Action | Opens the captures folder in Finder |

### 4. Settings

| Property | Value |
|---|---|
| Icon | Gear icon |
| Label | "Settings" |
| Shortcut | `⌘,` |
| Action | Opens the Settings window |

### 5. Quit Vibeliner

| Property | Value |
|---|---|
| Icon | Exit/logout icon |
| Label | "Quit Vibeliner" |
| Shortcut | `⌘Q` |
| Action | Quits the app |
| Separated | Divider line above this item |

## Menu item styling

| State | Background | Text color |
|---|---|---|
| Default | Transparent | `rgba(255, 255, 255, 0.8)` |
| Hover | `rgba(255, 255, 255, 0.06)` | `rgba(255, 255, 255, 0.8)` |

Icons: `rgba(255, 255, 255, 0.4)` default.
Keyboard shortcuts: `rgba(255, 255, 255, 0.25)` in monospace, with a subtle `rgba(255, 255, 255, 0.04)` background pill.

Items have 6px horizontal padding, 5px border-radius on hover.

## Recent Captures submenu

Appears to the right of the main popover when hovering "Recent Captures." Shows the last 10 captures.

### Submenu appearance

| Property | Value |
|---|---|
| Background | Same as main popover |
| Width | 220px |
| Border radius | 10px |
| Position | 8px to the right of the main popover, top-aligned with the trigger row |
| Show delay | Immediate on hover |
| Hide delay | 200ms after mouse leaves (prevents flicker when moving between popover and submenu) |

### Submenu header

"Recent" — 10px, uppercase, weight 600, `rgba(255, 255, 255, 0.2)`.

### Capture rows

Each row contains:

| Element | Style |
|---|---|
| Thumbnail | 40×28px rounded rect, showing a mini preview of the screenshot |
| Timestamp | 11px, `rgba(255, 255, 255, 0.6)` — e.g., "2 min ago", "Yesterday" |
| Note count | 9px, `rgba(255, 255, 255, 0.25)` — e.g., "3 notes" |
| Copy Prompt | 10px, `#a796eb` — appears on hover, right side |
| Copy Image | 10px, `#a796eb` — appears on hover, next to Copy Prompt |

### Capture row interactions

| Action | Result |
|---|---|
| Click the row (thumbnail, time, or note count) | Opens the capture folder in Finder, revealing that specific capture |
| Click "Copy Prompt" (hover action) | Copies the prompt text to clipboard (absolute path version) |
| Click "Copy Image" (hover action) | Copies the annotated screenshot image to clipboard |

The two copy buttons appear on hover, sitting to the right of the row. They provide quick re-copying without opening the editor or navigating to the folder.

### Capture row hover state

| State | Background |
|---|---|
| Default | Transparent |
| Hover | `rgba(255, 255, 255, 0.06)` |

Border-radius: 5px on hover.

## Popover behavior

### Opening
Click the menu bar icon to toggle the popover. Click anywhere outside to dismiss.

### No setup state
The popover never shows setup/readiness information. Setup is handled by the one-time setup window. If something breaks later (permissions revoked, folder deleted), a small warning indicator appears on the menu bar icon (e.g., a tiny red dot) and the popover shows an inline warning at the top — but this is an error state, not a setup flow.

### Error state (future)

If the captures folder is missing or screen recording permission is revoked:
- A small red dot appears on the menu bar icon
- The top of the popover shows a warning row: "Screen recording permission needed" or "Captures folder not found" with a "Fix" action
- The rest of the menu items remain functional (except Capture Now, which is disabled)

## Keyboard shortcuts (from popover)

| Key | Action |
|---|---|
| `⌘⇧6` | Capture Now (also works globally, not just from popover) |
| `⌘,` | Open Settings |
| `⌘Q` | Quit |

## Edge cases

### 1. No recent captures
The "Recent Captures" row still appears but the submenu shows "No captures yet" in gray text.

### 2. Captures folder deleted
The "Open Captures" row shows a warning state. Clicking it attempts to recreate the folder.

### 3. Very old captures
Timestamps show relative time up to 7 days ("2 days ago"), then switch to dates ("Mar 23").

### 4. Popover while editor is open
Both can be open simultaneously. The popover sits above the editor (higher window level).
