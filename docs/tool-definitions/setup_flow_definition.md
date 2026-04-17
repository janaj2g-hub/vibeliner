# Vibeliner — Product Definition: Setup Flow

**Status:** Locked
**Defined via:** Prototype iteration 2026-03-30

---

## Overview

Setup is a one-time welcome window that appears on first launch. It guides the user through three steps, then closes and never reappears after completion. The menu bar popover is the day-to-day interface — setup does not live there.

## Window specification

- **Type:** Standard macOS window (not a popover, not a sheet)
- **Title bar:** Native macOS traffic lights + centered title "Welcome to Vibeliner"
- **Size:** Fixed. Does not resize during the setup process. Approximately 680px wide × 400px tall (titlebar + body + footer).
- **Position:** Centered on screen at launch
- **Behavior:** Appears automatically on first launch. Never reappears after the user clicks "Start using Vibeliner." If something breaks later (permission revoked, folder deleted), the menu bar popover surfaces a subtle inline warning — NOT this window.

## Layout

The window body is split vertically into three panels with 0.5px dividers:

- **Left panel:** Step 1 — Screen recording permission
- **Middle panel:** Step 2 — Accessibility
- **Right panel:** Step 3 — Captures folder

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

## Step 2: Accessibility

### Purpose
Vibeliner needs accessibility permission so the global `⌘⇧6` hotkey works from any app.

### Locked state
Step 2 is locked until Step 1 is complete. The bottom status bar shows "Complete step 1 first."

### States

**Unlocked, not granted (active):**
- Step number: Blue circle with "2"
- Description: "Vibeliner needs accessibility permission so the capture hotkey (⌘⇧6) works from any app."
- Action button: "Open Accessibility Settings →"
- Helper text: "You may need to relaunch after granting."
- Bottom status bar: Warning/amber — "Not yet granted"

**Granted (done):**
- Step number: Green circle with checkmark
- Buttons removed
- Bottom status bar: Green — "Permission granted"
- Panel opacity: 45%

## Step 3: Captures folder

### Purpose
Vibeliner needs a writable folder to save capture bundles and the base `config.toml`.

### Locked state
Step 3 is locked until Step 2 is complete. The bottom status bar shows "Complete step 2 first."

### States

**Unlocked, folder not chosen (active):**
- Step number: Blue circle with "3"
- Description: "Choose where Vibeliner saves screenshots and prompts."
- Folder path display: Monospace box showing the chosen folder, pre-filled with `~/Documents/vibeliner` if it already exists
- Action button: "Choose folder…"
- Bottom status bar: Warning/amber — "Folder not yet chosen"

**Folder ready (done):**
- Step number: Green circle with checkmark
- Path display shows the selected folder
- Bottom status bar: Green — "Folder ready"
- Panel opacity: stays fully visible

### Default folder location
Default: `~/Documents/vibeliner` — visible in Finder, accessible to LLM tools. NOT a hidden dotfile.

### Custom folder
If the user clicks "Choose folder…", a native `NSOpenPanel` in directory-selection mode appears. The selected path is saved directly as the captures folder.

## Footer bar

A bottom bar spanning the full window width with a secondary background.

**Before completion:**
- Right side: Text only — "Complete all steps to continue"
- Left side: Empty

**After completion (all three steps done):**
- Left side: Subtle hotkey hint — "Capture shortcut: ⌘ ⇧ 6" (each key in a kbd-style pill)
- Right side: Green button — "Start using Vibeliner →"

Clicking "Start using Vibeliner" closes the setup window permanently and activates the menu bar icon as the primary interface.

## Visual style

- Step number badges: 28px circles. Blue (#378ADD bg region) when active, green when complete, gray when pending/locked.
- Status bars: Full-width rounded rectangles at bottom of each panel. Amber for warnings, green for success, gray for locked/pending.
- Buttons: Primary is dark (text-primary bg, background-primary text). Secondary is light with border.
- Typography: System font (SF Pro). 15px step labels, 13px body text, 12px helper text.
- Panel opacity: 100% when active, 50% when done, 40% when locked.
- No gradients, no shadows, no custom title bar. Standard macOS window chrome.

## Persistence

- Store setup-complete flag in `config.toml`
- Store chosen captures folder path in `config.toml`
- On subsequent launches: skip setup window, go straight to menu bar icon
- If screen recording permission is revoked after setup: surface warning in menu bar popover, NOT the setup window

## Edge cases

1. **User closes window without completing setup:** Window reappears on next launch. The app's menu bar icon is visible but capture is disabled.
2. **User grants permission but doesn't relaunch:** Step 2 helper text notes a relaunch may be needed. On relaunch, completed steps are pre-checked.
3. **User deletes the captures folder after setup:** Setup does NOT reappear. The user fixes it via Settings or by choosing a new folder.
