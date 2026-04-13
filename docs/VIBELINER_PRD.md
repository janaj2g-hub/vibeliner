# Vibeliner — Master Product Requirements Document

**Version:** 1.0.0
**Last updated:** 2026-04-13
**Status:** All sections locked via interactive prototyping

---

## Table of Contents

1. Product overview
2. Setup flow
3. Capture experience
4. Annotation tools (Pin, Arrow, Line, Rectangle, Circle, Freehand)
5. Editor window
6. Copy flow and IDE/App mode
7. File structure and LLM access
8. Prompt templates
9. Settings panel
10. Menu bar popover
11. Global design rules
12. Future roadmap

---

## 1. Product Overview

Vibeliner is a native macOS menu bar app that captures, annotates, and packages screenshots for AI coding tools. It bridges the gap between what a developer sees (a visual bug) and what an LLM needs (a text prompt with image context).

**The core loop:** See a bug → capture → annotate with numbered marks and notes → copy → paste into Claude Code, ChatGPT, or any LLM tool.

**Goal:** Eliminate the friction of describing visual bugs to AI. Instead of typing "the padding on the second card is wrong," the user drops a numbered pin on it, types "padding too tight," and pastes the result. The LLM sees the annotated screenshot and reads the numbered notes.

**Platform:** macOS 14+, Swift 5.9+, AppKit + SwiftUI. Menu bar app (no Dock icon by default).

**Design principles:**
- Two colors only: purple (Vibeliner active states) and red (annotation marks)
- Lightweight overlay aesthetic, not a heavy window app
- Auto-save everything, no manual save
- One keyboard shortcut to trigger capture (`⌘⇧6`)
- Prompts are plain text, optimized for LLMs, not humans

---

## 2. Setup Flow

**Goal:** Get the user through the required permissions and captures-folder setup quickly, then never show this window again after completion.

### Window

| Property | Value |
|---|---|
| Type | Standard macOS window, centered on screen |
| Title | "Welcome to Vibeliner" |
| Size | Fixed, 700×366px |
| Behavior | Appears whenever setup is incomplete: first launch, revoked permissions, or a missing captures folder. |

### Layout

Three vertical panels with 0.5px dividers between them:

**Panel 1: Captures folder**
- Blue "1" badge when active, green checkmark when done
- Description explains where screenshots and prompts are saved
- Path field pre-fills the current captures folder on re-run, otherwise starts at "No folder selected"
- "Choose folder…" action opens a directory picker
- Completed state swaps to "Folder ready" plus a green "Change folder" pill
- Panel remains fully visible after completion

**Panel 2: Accessibility**
- Locked until Panel 1 completes
- "Open Accessibility Settings →" button links directly to Privacy & Security → Accessibility
- Helper text notes the app may need relaunch after granting permission
- Bottom status bar: gray "Complete step 1 first" → amber "Not yet granted" → green "Permission granted"
- Panel dims after completion

**Panel 3: Screen recording**
- Locked until Panel 2 completes
- "Open Screen Recording Settings →" button links directly to Privacy & Security → Screen Recording
- Restart warning appears only while this step is active
- Bottom status bar: gray "Complete step 2 first" → amber "Not yet granted" → green "Permission granted"
- Panel dims after completion

### Footer bar

- Before completion: right-aligned text "Complete all steps to continue"
- After completion: left shortcut group showing the current hotkey, right ghost "Take a tour" button, and right green "Start using Vibeliner →" button
- Clicking either completion button marks setup complete and closes the window; "Take a tour" immediately opens the in-app tour

### Edge cases

- Closing the window without completing: reappears on next launch
- Permissions are polled while the window is open; on relaunch completed steps are pre-checked
- User deletes captures folder later: warning surfaces in menu bar popover, not this window

---

## 3. Capture Experience

**Goal:** A branded, precise, satisfying capture experience that replaces the native macOS screenshot tool. Purple-accented and instrument-like.

### Trigger

Global hotkey `⌘⇧6` (configurable in settings). A full-screen overlay appears immediately.

### Screen overlay

| Property | Value |
|---|---|
| Dim layer | `rgba(0, 0, 0, 0.5)` over all displays |
| Multi-monitor | Covers all screens; selection confined to one screen |

### Crosshair cursor

| Property | Value |
|---|---|
| Style | Short tick marks (10px per direction, 20px total per axis) |
| Color | `rgba(175, 169, 236, 0.85)` — purple `#AFA9EC` at 85% |
| Thickness | 2.3px |
| Shape | Straight lines, no circle, no gap at center |

No system cursor visible — the tick marks ARE the cursor. Follows mouse in real time with no lag.

### Selection rectangle

| Property | Value |
|---|---|
| Border | `#AFA9EC` at 85%, 1.5px solid |
| Fill | Transparent cutout — selected region at full brightness |
| Corners | Sharp (0 radius) |

The bright cutout against the dimmed surroundings is the key visual. The selected region pops.

### Dimension label

A pill below the selection, live-updating during drag:

| Property | Value |
|---|---|
| Background | `#534AB7` (solid purple) |
| Text | White, monospace, 11px, weight 500 |
| Border radius | 5px |
| Position | Centered below selection, 10px gap (repositions above if near bottom edge) |

**During drag:** `w 420  h 270` (live dimensions)
**After release:** `420 × 270 · 0 notes` (locked format, becomes the editor status pill)

### Cancel

- `Escape` cancels, overlay disappears
- Click without drag = cancel
- Selection under 10×10px = cancel

### Post-selection

1. Dim overlay fades out (~150ms)
2. Screenshot captured and saved
3. Editor window opens — the selection "becomes" the editor canvas

### Color system

Only two colors in the entire capture + annotation experience:
1. **Purple** (`#AFA9EC` light, `#534AB7` dark) — Vibeliner active states
2. **Red** (`#EF4444`) — annotation marks only

### Implementation

Custom overlay using borderless `NSWindow` + Core Graphics rendering. NOT `screencapture -i`. If custom overlay proves unreliable across macOS versions, fallback is `screencapture -i` with file output.

---

## 4. Annotation Tools

**Goal:** Five tools that let users mark up screenshots with numbered annotations. Each annotation has a red mark on the image (baked into the exported screenshot) and a note pill (text-only, included in the prompt but not the image).

### Shared rules across all tools

- **One sequential counter** — all tools share the same numbering (1, 2, 3…)
- **Badge color:** `#EF4444` (red), always, on all tools
- **Badge size:** 18px diameter (9px radius), white number at 9px weight 600
- **Note pill:** 26px height, `border-radius: 13px`, content = number prefix (9px, light maroon, no period) + user text (12px, dark maroon)
- **Note background:** `rgba(239, 68, 68, 0.05)` with `rgba(239, 68, 68, 0.1)` border
- **Hover:** Soft glow on badge (6px beyond), mutual highlight between badge and note
- **Click note:** Opens text editing. Red border appears on note. Enter confirms, Escape cancels.
- **Badges:** Must stay fully within canvas (clamp to edge)
- **Notes:** Overflow beyond canvas edge (never clipped)
- **Shapes/strokes:** Can clip at canvas edge
- **Auto-numbering:** Sequential across all tools
- **Deletion:** Removing an annotation renumbers the remaining annotations sequentially
- **Undo/redo:** Full support in shared stack for all operations
- **What gets exported to image:** Marks + badges only. Notes, handles, and hover states are NOT in the image.
- **What gets exported to prompt:** Numbered list with `[tool type]` tag and note text

### 4A. Pin Tool

**Goal:** Point at a specific pixel. The simplest annotation — click to place.

**Anatomy:** Badge (red circle with number) → Stake (10px red line, 2px wide) → Note pill (to the right, top-aligned, 10px gap)

**Placement:** Click = 50% ghost follows cursor (stake tip = cursor point). Click to place. Note opens immediately.

**Note positioning:** To the right of the badge, top-aligned. If the note would overflow the right edge, it flips to the left.

**Dragging:** Badge and note are independently draggable. When the note is dragged away from the badge, a tether line connects them. Badge dragging moves the entire pin.

**Note wrapping:** Notes wrap after 25 characters and grow vertically.

### 4B. Arrow Tool

**Goal:** Point at or between elements. Directional annotation.

**Anatomy:** Numbered circle at the start point (on the line, no stake) → Line exits from circle edge → Open chevron (V shape, 12px arms, 28° angle) at endpoint → Note centered on badge, offset above/below based on arrow direction (always away from line)

**Placement:** Click-drag to draw. Line previews at 50% opacity. Both endpoints independently draggable via handles when selected. Minimum 20px drag distance.

**Selection:** Click arrow body = select. 2 endpoint handles appear. Click note = edit text.

### 4C. Rectangle Tool

**Goal:** Highlight a region or container.

**Anatomy:** Red stroke 2.5px + subtle 6% red fill → Badge on the corner where drag started → Note centered on badge, offset to outside of rectangle

**Properties:** 3px corner radius, minimum 15×15px. 4 corner handles when selected (badge corner = badge itself). Notes overflow canvas.

### 4D. Circle Tool

**Goal:** Call out a specific element with a circle.

**Anatomy:** True circle only (always 1:1 aspect ratio). Drag from center outward. Red stroke 2.5px + 6% red fill. Badge at release point (on perimeter).

**Note positioning:** Pushed radially outward from center through badge. Algorithm checks all 4 corners of the note against the circle perimeter, pushes until 8px clearance.

**Selection:** 2 handles — badge (rotate around perimeter) + opposite side (resize). Badge clamps to canvas edge, circle shape can clip.

### 4E. Freehand Tool

**Goal:** Draw a free-form stroke for irregular areas.

**Anatomy:** Smoothed Catmull-Rom curve (3 passes, 0.5 factor), uniform 2.5px stroke, no fill. Badge at stroke start. Note radially outward from stroke's bounding center.

**Properties:** Round cap and join. Point sampling at 3px minimum intervals. Minimum 3 points (~9px movement) to register.

**Selection:** 5–8 evenly spaced control point handles appear. Dragging handles reshapes the curve with real-time Catmull-Rom recalculation.

**v1:** Clean uniform-width smooth curve only. **Future polish:** Pressure fade — last 30% of stroke gradually thins and fades in opacity.

### 4F. Line Tool

**Goal:** Draw a neutral straight line for connections or alignment without implying directional movement.

**Anatomy:** Same as Arrow but with no arrowhead chevron. Plain 2.5px stroke using `DesignTokens.red`. Badge at the start point. Note centered on badge, offset away from line.

**Placement:** Same click-drag behavior as Arrow. Minimum 20px movement to register. Badge anchored at the drag start point.

**Selection:** Endpoint handle at the line's end point. Dashed purple ring around the badge. Same hit-testing as Arrow (line-proximity with generous slop for short and shallow-angle lines).

---

## 5. Editor Window

**Goal:** A lightweight floating overlay that feels like a tool, not a window. Minimal chrome, the screenshot is the content.

### Window

| Property | Value |
|---|---|
| Type | Borderless floating `NSPanel` |
| Level | Above all other windows |
| Size | Matches screenshot dimensions |
| Background | None — screenshot is the content |
| Close | X button or Esc. Auto-saves before closing. |

### Three floating layers

1. **Pill-shaped toolbar** (above screenshot, 48px gap)
2. **Screenshot canvas** (the image + annotations)
3. **Floating status pill** (below screenshot, 32px gap — equal visual spacing)

### Floating toolbar

| Property | Value |
|---|---|
| Shape | Pill (`border-radius: 20px`) |
| Height | 40px |
| Background | `rgba(30, 30, 30, 0.92)` + backdrop blur 12px |
| Shadow | `0 4px 20px rgba(0,0,0,0.25)` |

**Layout (left to right):**

```
[4px] [X close 24px] [30px spacer] [divider] [10px] [Pin] [Arrow] [Rect] [Circle] [Freehand] [10px] [divider] [20px] [Trash] [10px] [Undo][Redo 1px gap] [20px] [divider] [10px] [IDE/App toggle] [10px] [divider] [10px] [Copy Prompt] [4px] [Copy Image*] [4px]
```

*Copy Image only visible in App mode

**Pin icon (special):** Filled purple circle with line (mini pin). The annotation counter number sits inside the circle. Updates across all tools. `#AFA9EC` when active, `rgba(175,169,236,0.6)` when inactive. Counter in dark text (`#1e1e1e`), 8px, weight 700.

**All buttons:** Circular. Every button has a tooltip on hover.

**X close button:** 24px, smaller icon (10px), 30px breathing room. Hover: red background + red icon.

**Trash:** Hover turns red. Deletes selected annotation.

**Undo/Redo:** 1px gap (read as a pair). Standard curved arrow icons.

**IDE/App toggle:** Small segmented pill. 9px, weight 600. Active segment: purple highlight. Persists across sessions.

**Dividers:** 1px × 16px, `rgba(255,255,255,0.08)`

### Copy buttons

Both buttons are equal purple pills. Same styling, same level:

| State | Border | Text | Background |
|---|---|---|---|
| Default | `1.5px solid #a796eb` | `#a796eb` | `rgba(116,97,194,0.25)` |
| Hover | `1.5px solid #c4b8f5` | `#c4b8f5` | `rgba(116,97,194,0.35)` |
| Copied | green border | green text | green 12% bg |

Both always re-clickable. Any annotation change resets both to purple.

### Screenshot canvas

| Property | Value |
|---|---|
| Border radius | 6px |
| Shadow | `0 4px 24px rgba(0,0,0,0.12), 0 1px 4px rgba(0,0,0,0.08)` |
| Marks layer | `overflow: hidden` — clips at canvas edge |
| Notes layer | `overflow: visible` — extends beyond canvas |

### Floating status pill

| Property | Value |
|---|---|
| Shape | Pill (`border-radius: 12px`) |
| Background | `rgba(30,30,30,0.88)` + backdrop blur 8px |
| Font | Monospace, 10px, weight 500, white |
| Content | `{width} × {height} · {count} notes` |

On copy: transitions to green `rgba(22,163,74,0.9)` showing "Copied" for 2 seconds.

### Keyboard shortcuts

| Key | Action |
|---|---|
| Esc | Auto-save and close |
| Cmd+Z | Undo |
| Cmd+Shift+Z | Redo |
| Cmd+C (no text field focused) | Copy Prompt |
| Delete / Backspace | Delete selected annotation |
| 1–6 | Switch tools (`1=Select`, `2=Pin`, `3=Arrow`, `4=Rectangle`, `5=Circle`, `6=Freehand`) |

---

## 6. Copy Flow and IDE/App Mode

**Goal:** Support both terminal tools (one paste) and web chat tools (two pastes) with a clear, non-confusing UX.

### The core problem

Terminal tools (Claude Code, Codex) can read files from disk — one paste of a text prompt with a file path is enough. Web tools (Claude.ai, ChatGPT) cannot read local files — the user must paste the text prompt AND the image separately.

### IDE/App toggle

A small segmented control in the toolbar switches modes:

**IDE mode:** Shows one button — "Copy Prompt." The prompt includes the absolute file path. One paste into the terminal.

**App mode (default):** Shows two buttons — "Copy Prompt" and "Copy Image." The user copies and pastes each separately into the chat app.

The toggle persists across sessions.

### Button behavior

- Both buttons are always re-clickable (click "Copied" again to re-copy)
- Any annotation change (add, edit, move, delete) resets both buttons to purple
- Images auto-save immediately after every annotation change

### First-use tooltip

The shipped app does not currently show a one-time IDE/App mode tooltip. Mode selection happens through the toolbar toggle only.

---

## 7. File Structure and LLM Access

**Goal:** Every capture is a self-contained folder with two files. The structure is simple, portable, and readable by any LLM tool.

### Base folder

Configured captures folder — default `~/Documents/vibeliner/`, set during setup and configurable in settings.

### App config

App configuration is stored separately at `~/Library/Application Support/Vibeliner/config.toml` so changing the captures folder does not move or duplicate the config file.

### Capture folder structure

```
~/Documents/vibeliner/
├── 2026-03-28_143022/
│   ├── screenshot.png
│   └── prompt.txt
├── 2026-03-28_151200/
│   ├── screenshot.png
│   └── prompt.txt
└── ...
```

Folders named `YYYY-MM-DD_HHMMSS` in local time. Flat stream, no nesting (v1).

### screenshot.png

Annotated screenshot with marks + badges baked in. Note pills are NOT in the image. Native resolution (Retina 2x if applicable).

### prompt.txt

Plain text, UTF-8, no metadata. Contains the preamble, annotation list, and footer.

**Saved file:** Uses relative path `./screenshot.png`
**Clipboard (IDE mode):** Uses absolute path `/Users/.../screenshot.png`
**Clipboard (App mode):** No path (image pasted separately)

### Auto-save

Every annotation change immediately saves both `screenshot.png` and regenerates `prompt.txt`. No manual save. The folder is always consistent.

### Future: multi-project

Not in v1. Future versions will support project subfolders, an active project selector in the menu bar, and per-project prompt templates.

---

## 8. Prompt Templates

**Goal:** Generate a prompt that gives the LLM everything it needs to understand the screenshot and act on the annotations. Smart enough to adapt to the tools used, customizable for power users.

### Structure

```
[preamble — customizable]

[annotation list — auto-generated]

[footer — customizable]
```

### Default preamble

```
This is a screenshot of my running app. View it at [Screenshot Path]

[Tool Description] Each annotation has a number and a description.

Fix each issue:
```

### Tokens

| Token | Replacement |
|---|---|
| `[Screenshot Path]` | Relative path (saved file), absolute path (IDE clipboard), omitted (App clipboard) |
| `[Tool Description]` | Auto-generated sentence listing only the tools used, with editable per-tool descriptions |

### Smart tool descriptions

The `[Tool Description]` token resolves based on which tools were actually used:

- Pins only: "Numbered pins point to specific issues."
- Pins + arrows: "Numbered pins point to specific issues and arrows point at or between elements."
- All five: Full listing of all tools with descriptions.

Each tool's description is editable in settings:

| Tool | Default description |
|---|---|
| Pin | points to a specific issue |
| Arrow | points at or between elements |
| Rectangle | highlights a region or container |
| Circle | calls out a specific element |
| Freehand | marks an irregular area |

### Annotation list format

Each line includes the tool type in brackets:

```
1  [pin] padding too tight
2  [arrow] wrong border radius
3  [rectangle] this card needs more height
```

### Default footer

```
Make the changes and verify they match the design.
```

### Full example (IDE clipboard, pins + arrows)

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

## 9. Settings Panel

**Goal:** A clean, standard macOS preferences window with only the essential settings. The Prompt tab uses a persistent top preview and a framed editing subsection so users can see exactly what their changes produce while keeping the layout extensible.

Implementation note: the native Settings UI is fully Auto Layout-based and safe to construct at zero size before being hosted by the window shell. Future sections and tabs should be added by composition, not by frame math.

### Window

| Property | Value |
|---|---|
| Type | Separate macOS window |
| Title | "Vibeliner Settings" |
| Access | Menu bar popover → Settings, or `Cmd+,` |
| Width | ~540px |
| Tabs | General, Prompt, About |

### General tab

| Setting | Control | Default |
|---|---|---|
| Capture hotkey | Key-pill display + shared field surface + pill "Change" button | `⌘⇧6` |
| Captures folder | Boxed path field + helper text + pill "Change" button | `~/Documents/vibeliner` |
| Launch at login | Checkbox + regular-weight helper label | Unchecked |

### Prompt tab

Prompt is split into two sections:

1. **Full Prompt Preview** at the top
2. **Edit Prompt Sections** inside a framed container below

The frame header uses:
- left-aligned `Edit Prompt Sections`
- right-aligned shared `Save`

Centered below the header is a segmented control with three items:
- **Preamble**
- **Tools**
- **Footer**

The active segment changes the editing area inside the frame. `Reset to default` is scoped to the currently visible segment and appears below that segment’s content.

**Preamble sub-tab:**
- Description explains the two tokens: `[Screenshot Path]` and `[Tool Description]`
- Multi-line monospace text editor with the default preamble
- Shared Save button in the frame header
- Per-section Reset to default below the editor

**Tools sub-tab:**
- Five rows: tool icon → tool name → editable text field
- Each description feeds into `[Tool Description]` and appears as `[tool type]` per annotation
- Shared Save + per-section Reset to default

**Footer sub-tab:**
- Multi-line monospace text editor
- Shared Save + per-section Reset to default

**Full Prompt Preview section:**
- Sits above the editing frame, not below it
- Uses a read-only preview surface visually distinct from editable fields
- Shows the full generated prompt with the actual captures path and sample annotations
- Refreshes as prompt drafts change

### About tab

Centered layout: real application icon, "Vibeliner", bundle-derived version label, links (GitHub, Report an Issue, Documentation), tagline.

---

## 10. Menu Bar Popover

**Goal:** A compact dark utility menu for day-to-day access. Quick capture, recent captures with re-copy, and app controls.

### Menu bar icon

Crosshair icon (circle + cross lines), template image that adapts to system appearance.

### Popover appearance

| Property | Value |
|---|---|
| Background | `rgba(30,30,30,0.95)` + backdrop blur 16px |
| Border | `0.5px solid rgba(255,255,255,0.08)` |
| Border radius | 10px |
| Width | 210px |
| Arrow | Points up at menu bar icon |

### Menu items

| Item | Shortcut | Action |
|---|---|---|
| Capture Now | `⌘⇧6` | Triggers capture |
| Recent Captures | → arrow | Hover reveals submenu |
| Open Captures | — | Opens captures folder in Finder |
| Settings | `⌘,` | Opens Settings window |
| *(divider)* | | |
| Quit Vibeliner | `⌘Q` | Quits |

### Recent Captures submenu

Appears to the right on hover (200ms hide delay). Shows last 10 captures.

Each row: thumbnail (40×28px) → timestamp → note count → hover reveals "Copy Prompt" and "Copy Image" buttons.

| Action | Result |
|---|---|
| Click row | Opens that capture's folder in Finder |
| Click "Copy Prompt" | Copies prompt text to clipboard |
| Click "Copy Image" | Copies annotated screenshot to clipboard |

---

## 11. Global Design Rules

### Color system

| Color | Hex | Usage |
|---|---|---|
| Light purple | `#AFA9EC` | Crosshair, selection border, active tool highlight, copy button text/border |
| Dark purple | `#534AB7` | Dimension label, settings accents |
| Button purple | `#a796eb` | Copy button outline and text |
| Button hover purple | `#c4b8f5` | Copy button hover state |
| Button bg purple | `rgba(116,97,194,0.25)` | Copy button fill |
| Red | `#EF4444` | All annotation marks, badges, strokes |
| Dark chrome | `rgba(30,30,30,0.92-0.95)` | Toolbar, status pill, popover |

### Typography

- System font (SF Pro) throughout
- Monospace (SF Mono / ui-monospace) for: dimension labels, file paths, code-like displays, prompt previews
- Body text: 13px
- Labels: 12px
- Helper text: 11–12px
- Badge numbers: 9px, weight 600
- Note text: 12px
- Note number prefix: 9px, weight 600

### Shared annotation constants

| Property | Value |
|---|---|
| Badge diameter | 18px (radius 9px) |
| Badge fill | `#EF4444` |
| Badge number | White, 9px, weight 600 |
| Note height | 26px |
| Note border-radius | 13px |
| Note background | `rgba(239,68,68,0.05)` |
| Note border | `rgba(239,68,68,0.1)` |
| Stroke width (all tools) | 2.5px |
| Shape fill | `rgba(239,68,68,0.06)` |

### Auto-save contract

Every annotation change immediately saves:
1. `screenshot.png` — re-rendered with current marks + badges
2. `prompt.txt` — regenerated with current annotations
3. Both copy buttons reset to purple (if previously "Copied")

### Window levels

1. Capture overlay (highest — above everything)
2. Editor floating panel
3. Menu bar popover
4. Settings window (standard level)

---

## 12. Future Roadmap

Documented for reference. NOT in v1.

| Feature | Description |
|---|---|
| Multi-project support | Project subfolders, active project selector in menu bar, per-project templates |
| Pressure fade (freehand) | Last 30% of stroke thins and fades, simulating pen lift |
| Capture retention | Auto-delete captures older than N days |
| Direct LLM integration | Push captures via MCP protocol or Cursor extension API |
| Batch export | Export multiple captures as a single prompt |
| Search/filter captures | Find past captures by date, note text, or project |
| In-repo captures | Save captures inside the project repository |

---

*This document was compiled from 13 individually locked product definitions, each prototyped interactively on 2026-03-30.*
