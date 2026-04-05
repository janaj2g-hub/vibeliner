# Vibeliner — Product Definition: Settings Panel

**Status:** Locked
**Defined via:** Prototype iteration 2026-04-04

---

## Overview

Settings is a separate macOS window with three tabs: `General`, `Prompt`, and `About`.

- `General` is a stack of reusable settings sections
- `Prompt` is split into a persistent top preview plus a framed editing subsection
- `About` is a centered static information tab

The shipped implementation is section-driven so future sections can be inserted into any tab without rewriting vertical frame math.

## Window

| Property | Value |
|---|---|
| Type | Standard macOS window |
| Title | "Vibeliner Settings" |
| Style | Native macOS controls using the current system appearance |
| Traffic lights | Standard macOS (close, minimize, zoom) |
| Size | ~540px wide, fixed preferences-style height |
| Access | Menu bar popover or `Cmd+,` |

## Tab bar

Three tabs centered below the title bar:

- `General`
- `Prompt`
- `About`

Active tab styling:
- light purple text
- short centered underline

Inactive tabs use secondary text with no underline.

---

## General tab

The General tab is a vertical stack of reusable settings sections. Every section follows the same rhythm:

1. title in the left column
2. content in the right column
3. divider between sections

### Capture hotkey

| Property | Value |
|---|---|
| Label | "Capture hotkey" |
| Display | Current shortcut rendered as separate key pills |
| Surface | Same field background and border treatment as the captures-folder field |
| Text color | Light purple key glyphs in both light and dark mode |
| Action | Pill-style `Change` button opens a recorder sheet |
| Save behavior | The next modified keypress is saved immediately |
| Default | `⌘⇧6` |

### Captures folder

| Property | Value |
|---|---|
| Label | "Captures folder" |
| Display | Monospace path in a boxed field surface |
| Helper text | "Screenshots and prompts are saved here." |
| Action | Pill-style `Change` button opens `NSOpenPanel` |
| Default | `~/Documents/vibeliner` |

### Launch at login

| Property | Value |
|---|---|
| Label | "Launch at login" |
| Control | Checkbox |
| Helper text | Regular-weight label: "Start Vibeliner when you log in" |
| Default | Unchecked |

---

## Prompt tab

The Prompt tab is composed of two stacked sections:

1. `Full Prompt Preview`
2. `Edit Prompt Sections`

### Full Prompt Preview

This section stays visible at the top of the Prompt tab at all times.

| Property | Value |
|---|---|
| Label | "Full Prompt Preview" |
| Surface | Read-only preview surface, visually distinct from editable text fields |
| Content | Full generated prompt using the configured captures folder path and sample annotations |
| Typography | Monospaced |
| Behavior | Refreshes as prompt drafts change, and also reflects saves/resets |

### Edit Prompt Sections

This area is a framed subsection below the preview.

Header row:
- `Edit Prompt Sections` title aligned left
- shared `Save` pill aligned right

Below the header is a centered pill-style segmented control with three items:

- `Preamble`
- `Tools`
- `Footer`

The outer track is pill-shaped and the active selector is pill-shaped. Switching segments changes the active editor inside the same frame.

`Reset to default` is scoped to the currently visible segment and appears below that segment’s content area.

### Preamble

Description:

`Text before the annotation list. [Screenshot Path] inserts the image path. [Tool Description] auto-generates based on tools used.`

Editor:
- multi-line
- monospaced
- uses the editable field surface, not the preview surface

Default preamble:

```text
This is a screenshot of my running app. View it at [Screenshot Path]

[Tool Description] Each annotation has a number and a description.

Fix each issue:
```

Actions:
- `Save` writes all Prompt-section drafts
- `Reset to default` resets only the Preamble content

### Tools

Description:

`Each tool's description feeds into [Tool Description] when that tool is used. The tool type also appears in brackets next to each annotation.`

Rows:
1. icon tile
2. tool name
3. editable monospace field

Tool list:

| Tool | Default description |
|---|---|
| Pin | points to a specific issue |
| Arrow | points at or between elements |
| Rectangle | highlights a region or container |
| Circle | calls out a specific element |
| Freehand | marks an irregular area |

These descriptions are used in two places:
1. `[Tool Description]` output
2. per-annotation tool labels such as `1  [pin] ...`

Actions:
- `Save` writes all Prompt-section drafts
- `Reset to default` resets only the Tools fields

### Footer

Description:

`Text after the annotation list. Leave empty for no footer.`

Editor:
- multi-line
- monospaced
- uses the editable field surface

Default footer:

```text
Make the changes and verify they match the design.
```

Actions:
- `Save` writes all Prompt-section drafts
- `Reset to default` resets only the Footer content

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

## Implementation Architecture

The settings UI is intentionally designed for extension:

- Top-level tabs are created from a small tab model in `SettingsWindowController`
- Shared settings visuals live in `DesignTokens.swift`
- Reusable Settings UI components live in `Vibeliner/Settings/SettingsUI.swift`
- General and Prompt are built from reusable section containers rather than manual absolute `y` offsets
- Prompt uses a reusable segmented control so more prompt sections can be added without redesigning the outer frame
