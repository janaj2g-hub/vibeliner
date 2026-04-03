# Vibeliner — Product Definition: Settings Panel

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

Settings is a separate macOS window (not in the popover or editor). Standard light appearance with three tabs: General, Prompt, and About. The Prompt tab has three centered sub-tabs with a persistent live preview at the bottom.

## Window

| Property | Value |
|---|---|
| Type | Standard macOS window |
| Title | "Vibeliner Settings" |
| Style | Light, native macOS controls |
| Traffic lights | Standard macOS (close, minimize, zoom) |
| Size | ~540px wide, height adapts to content |
| Access | From menu bar popover or `Cmd+,` |

## Tab bar

Three tabs centered at the top, below the title bar. Purple underline on the active tab.

| Tab | Contents |
|---|---|
| General | Hotkey, captures folder, launch at login |
| Prompt | Preamble, tool descriptions, footer, live preview |
| About | App icon, version, links |

Active tab: `#534AB7` text + 2px bottom border.
Inactive tab: `#888` text, no border.

---

## General tab

### Capture hotkey

| Property | Value |
|---|---|
| Label | "Capture hotkey" |
| Display | Pill showing current keys (e.g., `⌘` `⇧` `6`) |
| Action | "Change" link opens key recorder |
| Default | `⌘⇧6` |

### Captures folder

| Property | Value |
|---|---|
| Label | "Captures folder" |
| Display | Monospace path in a gray box |
| Action | "Change" button opens `NSOpenPanel` folder picker |
| Helper text | "Screenshots and prompts are saved here." |
| Default | `~/Documents/vibeliner` |

### Launch at login

| Property | Value |
|---|---|
| Label | "Launch at login" |
| Control | Checkbox |
| Helper text | "Start Vibeliner when you log in" |
| Default | Unchecked |

---

## Prompt tab

The Prompt tab has three centered sub-tabs: **Preamble**, **Tool descriptions**, **Footer**. Clicking a sub-tab changes the editing area above while the live preview stays pinned at the bottom.

### Sub-tab bar

Centered horizontally. Purple underline on active sub-tab. Same styling as main tabs but smaller (12px font).

### Preamble sub-tab

**Description (above editor):**
Three lines:
- "Text before the annotation list."
- `[Screenshot Path]` inserts the image path.
- `[Tool Description]` auto-generates based on tools used in the capture.

The token tags use the light purple pill style (`#f0edf9` background, `#534AB7` text, `#d4cef0` border).

**Editor:** Multi-line monospace text area.

**Default preamble:**
```
This is a screenshot of my running app. View it at [Screenshot Path]

[Tool Description] Each annotation has a number and a description.

Fix each issue:
```

**Buttons:** "Save" (purple filled) on the left, "Reset to default" (purple text link) on the right.

### Tool descriptions sub-tab

**Description:** "Each tool's description feeds into `[Tool Description]` when that tool is used. The tool type also appears in brackets next to each annotation."

**Five rows, each containing:**
1. Tool icon (28px square, gray background, rounded)
2. Tool name label (12px, weight 500): Pin, Arrow, Rectangle, Circle, Freehand
3. Editable text field with the description

**Default descriptions:**

| Tool | Default description |
|---|---|
| Pin | points to a specific issue |
| Arrow | points at or between elements |
| Rectangle | highlights a region or container |
| Circle | calls out a specific element |
| Freehand | marks an irregular area |

These descriptions are used in two places:
1. **In `[Tool Description]`** — combined into a sentence listing only the tools used in the capture
2. **Per annotation** — the tool type appears in brackets: `1  [pin] padding too tight`

**Buttons:** Save + Reset to default.

### Footer sub-tab

**Description:** "Text after the annotation list. Leave empty for no footer."

**Editor:** Multi-line monospace text area (shorter than preamble).

**Default footer:**
```
Make the changes and verify they match the design.
```

**Buttons:** Save + Reset to default.

### Live preview (persistent)

Always visible at the bottom of the Prompt tab, regardless of which sub-tab is active. Separated by a top border.

| Property | Value |
|---|---|
| Label | "Live preview" (12px, gray, weight 500) |
| Style | Gray background box, monospace, 11px |
| Content | Full generated prompt with sample annotations |
| Path | Uses the actual configured captures folder path |
| Max height | 180px, scrollable |

The preview updates in real time as the user edits the preamble, tool descriptions, or footer.

**Sample preview content:**
```
This is a screenshot of my running app. View it at /Users/jon/Documents/vibeliner/2026-03-30_143022/screenshot.png

Numbered pins point to specific issues and arrows point at or between elements. Each annotation has a number and a description.

Fix each issue:

1  [pin] padding too tight
2  [arrow] wrong border radius
3  [arrow] move this element left

Make the changes and verify they match the design.
```

---

## About tab

Centered layout:

| Element | Value |
|---|---|
| App icon | 64px red rounded square with crosshair |
| App name | "Vibeliner", 18px, weight 600 |
| Version | "Version 1.0.0", 13px, gray |
| Links | GitHub Repository, Report an Issue, Documentation — purple, clickable |
| Tagline | "Made for developers shipping with AI tools.", 11px, light gray |

---

## Updates to Prompt Template definition

This settings panel changes how templates work compared to the earlier prompt template definition:

### Annotation list format (updated)

Each annotation line now includes the tool type in brackets:

```
1  [pin] padding too tight
2  [arrow] wrong border radius
3  [rectangle] this card needs more height
4  [circle] wrong icon size
5  [freehand] this whole area is off
```

The bracketed tool type gives the LLM per-annotation context about what kind of mark was made. The bracket labels match the tool names from settings (lowercase).

### [Tool Description] generation (updated)

The `[Tool Description]` token resolves to a sentence listing only the tools used in the capture, using the editable descriptions from settings:

- If only pins used: "Numbered pins point to specific issues."
- If pins + arrows: "Numbered pins point to specific issues and arrows point at or between elements."
- If all five tools: "Annotations use pins (points to specific issues), arrows (points at or between elements), rectangles (highlights a region or container), circles (calls out a specific element), and freehand marks (marks an irregular area)."
