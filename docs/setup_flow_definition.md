# Vibeliner — Product Definition: Setup Flow

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

Setup is a one-time welcome window that appears on first launch. It guides the user through two prerequisites, then closes and never reappears. The menu bar popover is the day-to-day interface — setup does not live there.

## Window specification

- **Type:** Standard macOS window (not a popover, not a sheet)
- **Title bar:** Native macOS traffic lights + centered title "Welcome to Vibeliner"
- **Size:** Fixed. Does not resize during the setup process. Approximately 680px wide × 400px tall (titlebar + body + footer).
- **Position:** Centered on screen at launch
- **Behavior:** Appears automatically on first launch. Never reappears after the user clicks "Start using Vibeliner." If something breaks later (permission revoked, folder deleted), the menu bar popover surfaces a subtle inline warning — NOT this window.

## Layout

The window body is split vertically into two equal panels with a 0.5px divider:

- **Left panel:** Step 1 — Screen recording permission
- **Right panel:** Step 2 — Captures folder

Each panel has:
1. **Header** (top) — Step number badge + step label
2. **Content area** (middle, flex-grows) — Description, controls, helper text
3. **Status bar** (bottom-anchored) — Always visible, shows current state

The body height is fixed. Content fills within the frame — no layout shift between states.

## Step 1: Screen recording

### Purpose
macOS requires explicit screen recording permission. Without it, `screencapture` cannot capture screen content.

### States

**Not granted (active):**
- Step number: Blue circle with "1"
- Description: "Vibeliner needs screen recording permission to capture screenshots of your running app."
- Action button: "Open System Settings →" (primary/dark button). Opens System Settings to Privacy & Security → Screen Recording.
- Helper text: "Toggle Vibeliner on in Privacy & Security → Screen Recording. You may need to restart the app."
- Bottom status bar: Warning/amber — "Not yet granted"

**Granted (done):**
- Step number: Green circle with checkmark
- Description text remains
- Helper text: "Vibeliner can now capture your screen."
- Action button removed
- Bottom status bar: Green — "Permission granted"
- Panel opacity: 50%

### Detection
The app polls or checks on window focus whether screen recording permission has been granted. When detected, the panel transitions to the "granted" state automatically.

### Restart handling
macOS may require an app restart after granting screen recording. If the app detects it needs a restart, show a note in the helper text area. On relaunch, the setup window reappears with Step 1 already in the "granted" state.

## Step 2: Captures folder

### Purpose
Vibeliner needs a writable folder to save capture bundles (screenshot + prompt.md + meta.json).

### Locked state
Step 2 is locked (40% opacity, non-interactive) until Step 1 is complete. The bottom status bar shows a lock icon with "Complete step 1 first."

### States

**Unlocked, folder not created (active):**
- Step number: Blue circle with "2"
- Description: "Choose where Vibeliner saves screenshots and prompts. We recommend a folder in Documents."
- Folder path display: Monospace box showing `~/Documents/vibeliner`
- Note: "Each capture gets its own subfolder with the annotated screenshot, prompt, and metadata."
- Action buttons (side by side in one row):
  - "Create folder" (primary/dark button) — creates `~/Documents/vibeliner` and transitions to done
  - "Choose different…" (secondary button) — opens a native macOS folder picker dialog
- Bottom status bar: Warning/amber — "Folder not yet created"

**Folder created (done):**
- Step number: Green circle with checkmark
- Helper text: "~/Documents/vibeliner is ready to receive captures."
- Buttons removed
- Bottom status bar: Green — "Folder created and ready"
- Panel opacity: 50%

### Default folder location
`~/Documents/vibeliner` — visible in Finder, accessible to LLM tools. NOT a hidden dotfile.

### Custom folder
If the user clicks "Choose different…", a native `NSOpenPanel` in directory-selection mode appears. The selected path replaces the default in the folder path display. "Create folder" then creates that path instead.

### Validation
- Path must be writable
- Path must be a directory (not a file)
- If validation fails, show an error in the status bar area

## Footer bar

A bottom bar spanning the full window width with a secondary background.

**Before completion:**
- Right side: Disabled button — "Complete both steps to continue"
- Left side: Empty

**After completion (both steps done):**
- Left side: Subtle hotkey hint — "Capture shortcut: ⌘ ⇧ 6" (each key in a kbd-style pill)
- Right side: Green button — "Start using Vibeliner →"

### Copy mode tip (shown after both steps complete)

A purple-tinted card appears below the two setup panels, above the footer bar. It explains the two copy modes:

> **How to share with AI tools**
>
> **Copy Prompt** — for terminal tools (Claude Code, Cursor, Aider). Paste the text and the AI reads the screenshot from your disk.
>
> **Copy Image** — for web/app tools (Claude.ai, ChatGPT). Paste the image into the chat alongside the prompt.

This tip appears only after both setup steps are complete and before the user clicks "Start using Vibeliner." It is shown once and never reappears.

Style: purple-tinted background (`#EEEDFE`), purple border (`#AFA9EC`), dark purple text (`#3C3489`). Bold for button names.

Clicking "Start using Vibeliner" closes the setup window permanently and activates the menu bar icon as the primary interface.

## Visual style

- Step number badges: 28px circles. Blue (#378ADD bg region) when active, green when complete, gray when pending/locked.
- Status bars: Full-width rounded rectangles at bottom of each panel. Amber for warnings, green for success, gray for locked/pending.
- Buttons: Primary is dark (text-primary bg, background-primary text). Secondary is light with border.
- Typography: System font (SF Pro). 15px step labels, 13px body text, 12px helper text.
- Panel opacity: 100% when active, 50% when done, 40% when locked.
- No gradients, no shadows, no custom title bar. Standard macOS window chrome.

## Persistence

- Store setup-complete flag in `UserDefaults` or `config.toml`
- Store chosen captures folder path in `config.toml`
- On subsequent launches: skip setup window, go straight to menu bar icon
- If screen recording permission is revoked after setup: surface warning in menu bar popover, NOT the setup window

## Edge cases

1. **User closes window without completing setup:** Window reappears on next launch. The app's menu bar icon is visible but capture is disabled.
2. **User grants permission but doesn't restart:** Show restart note if needed. On relaunch, Step 1 is pre-checked.
3. **User picks a folder they don't have write access to:** Validation error in status bar. "Create folder" button stays available.
4. **User deletes the captures folder after setup:** Menu bar popover shows a warning. Setup window does NOT reappear. User fixes via Settings or "Open captures folder" recreates it.
5. **Existing Vibeliner user (already has ~/.vibeliner):** If migrating from a hidden dotfile layout, setup could detect existing captures and offer to keep the old path or migrate. This is a future concern — v1 always shows setup on first launch.
