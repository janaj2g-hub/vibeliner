# Vibeliner — Product Definition: Copy Flow & IDE/App Mode

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

Vibeliner supports two workflows for getting annotated screenshots into LLM tools: one for terminal/IDE tools that can read local files, and one for web/app chat tools that cannot. A persistent IDE/App toggle in the editor toolbar controls which buttons are shown.

## The IDE/App toggle

A small toggle switch in the editor toolbar, positioned to the right of undo/redo and left of the copy buttons.

| Property | Value |
|---|---|
| Style | Pill-shaped segmented control with two options: "IDE" and "App" |
| Background | `rgba(255, 255, 255, 0.06)` |
| Active segment | `rgba(175, 169, 236, 0.25)` background, `#AFA9EC` text |
| Inactive segment | Transparent, `rgba(255, 255, 255, 0.3)` text |
| Font | 9px, weight 600 |
| Persistence | The selected mode persists across sessions (stored in config) |
| Default | App mode (safer default — shows both buttons) |

### IDE mode

Shows one button: **Copy Prompt**

For terminal tools (Claude Code, Codex, Aider) that can read files from the local filesystem. The prompt includes an absolute file path to the screenshot. One paste, done.

### App mode

Shows two buttons: **Copy Prompt** and **Copy Image**

For web/app chat tools (Claude.ai, ChatGPT, Gemini) that cannot access the local filesystem. The user copies and pastes the prompt and image separately in two steps.

## Copy buttons

Both buttons use the same pill styling — equal weight, same purple color, side by side. Neither is "primary" or "secondary."

### Button styling

| State | Border | Text | Background |
|---|---|---|---|
| Default | `1.5px solid #a796eb` | `#a796eb` | `rgba(116, 97, 194, 0.25)` |
| Hover | `1.5px solid #c4b8f5` | `#c4b8f5` | `rgba(116, 97, 194, 0.35)` |
| Copied | `1.5px solid rgba(22,163,74,0.5)` | `rgba(22,163,74,0.8)` | `rgba(22,163,74,0.12)` |

### Copy Prompt button

Copies the prompt text to the clipboard with the absolute screenshot file path.

- Shows "Copy Prompt" in default state
- Shows checkmark + "Copied" after clicking (green state)
- Always re-clickable — clicking again re-copies (useful after editing annotations)
- `Cmd+C` (when no text field is focused) is the keyboard shortcut

### Copy Image button (App mode only)

Copies the annotated screenshot image to the system clipboard.

- Shows "Copy Image" in default state
- Shows checkmark + "Copied" after clicking (green state)
- Always re-clickable

### Reset behavior

Any annotation change resets BOTH buttons back to their default purple state:
- Adding an annotation
- Editing annotation text
- Moving or resizing an annotation
- Deleting an annotation

This signals "the capture has changed since you last copied." The image auto-saves to disk immediately after every annotation change, so the file is always current.

## Auto-save contract

Images are saved immediately after:
- A badge/annotation is placed
- Annotation text is confirmed (Enter pressed)
- An annotation is moved, resized, or deleted
- Any edit that changes the visual output

There is no manual save. The capture folder is always in sync with the editor state.

## First-use tooltip

A one-time tooltip appears above the IDE/App toggle the first time the editor opens. Light purple color scheme.

### Tooltip styling

| Property | Value |
|---|---|
| Background | `#f0edf9` |
| Border | `1px solid #d4cef0` |
| Border radius | 12px |
| Width | 380px |
| Shadow | `0 4px 16px rgba(83, 74, 183, 0.1)` |
| Arrow | 12px rotated square, same background, matching border on bottom-right edges |
| Position | Centered above the toggle, 16px clearance |

### Tooltip content

```
Terminal tools can read files on your computer. Web chat apps
cannot. Select a mode based on your workflow.

IDE
Choose when pasting into Claude Code, Codex, or any terminal.
You only need the prompt.

App
Choose when pasting into Claude.ai, ChatGPT, or Gemini. You'll
copy the prompt and the image in two steps.

                          Got it
```

| Element | Style |
|---|---|
| Intro text | `#666`, 12px |
| Mode names (IDE, App) | `#534AB7`, 13px, weight 600 |
| Mode descriptions | `#555`, 12px |
| Divider | `1px solid #d4cef0` |
| "Got it" | `#534AB7`, 12px, weight 600, centered |

### Tooltip behavior

- Appears once on first editor open
- Dismisses permanently when "Got it" is clicked
- Stores dismissal in `config.toml` — never shows again
- Does not reappear on subsequent launches

## Setup flow integration

The current setup flow does not include a dedicated "How to share" panel. The IDE/App distinction is introduced in the editor via the first-use tooltip above the toggle.

## Keyboard shortcuts

| Key | Action |
|---|---|
| `Cmd+C` (no text field focused) | Copy Prompt |
| No shortcut | Copy Image (manual click only) |

## Status pill feedback

When either copy button is clicked, the floating status pill below the screenshot reflects the action:
- "Prompt copied" or "Image copied" briefly
- The pill reverts to showing dimensions + note count after 2 seconds

## Edge cases

### 1. User switches mode after copying
Switching from App to IDE (or vice versa) resets the copied states on both buttons.

### 2. No annotations
Copy Prompt still works — copies the screenshot path with an empty annotation list. Copy Image still works — copies the unannotated screenshot.

### 3. Very fast re-copying
Each click immediately overwrites the clipboard. No debounce needed.
