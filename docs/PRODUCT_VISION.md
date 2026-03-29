# Vibeliner — Product Vision

## What it is

Vibeliner is a native macOS menu bar app that captures, annotates, and packages screenshots for AI coding tools. It turns "I see a bug on screen" into a numbered, annotated screenshot + structured prompt that pastes directly into Claude Code or Cursor.

## Who it's for

Solo developers shipping with AI coding tools. They deploy, visually review their running app, spot problems, and need those problems described in a format their AI coder can act on immediately. They are their own QA.

## What it is not

- Not a team tool — single user, local files, no accounts
- Not a screenshot-to-code tool — it doesn't generate code from screenshots
- Not AI-powered — zero intelligence in the app itself. It's a capture/annotate/output pipeline. The AI comes later when Claude Code reads the output.

## User flow

0. **Setup:** On first launch, the menu bar popover shows whether Screen Recording is granted, whether the captures folder is writable, and whether Vibeliner is ready to capture. "Open captures folder" creates the folder if it doesn't exist yet.
1. **Capture:** Hit `Cmd+Shift+6` (configurable). Vibeliner uses the native macOS region-selection UX via `screencapture`.
2. **Annotate:** A borderless floating editor opens with the captured image. Scribble, draw arrows, circle things. Every mark automatically gets the next number (①, ②, ③) and an inline text input appears at the mark's start point. Type a note ("padding too tight"), hit Enter — it collapses to just the circled number.
3. **Export:** Hit "Copy for LLM" (or Cmd+C). Vibeliner saves a folder with the annotated screenshot + prompt.md + meta.json, and copies a prompt to the clipboard that references the real screenshot with an absolute file path.
4. **Paste:** One paste into Claude Code. Done.

## Annotation model

Every mark gets a number. Pin drop, scribble, arrow — all get the next auto-incrementing number. A numbered badge (red circle, white text) appears at the mark's start point. An inline text input appears right there for typing the note.

During editing, both the number and the note text are visible. In the exported image, only the numbers and drawn marks are baked into pixels. The text notes exist only in `prompt.md`. This keeps the screenshot clean and readable.

Numbers re-sequence on delete (delete ② and ③ becomes ②).

## Output format

One folder per capture:

```
~/.vibeliner/captures/
├── 2026-03-28_143022_card-spacing/
│   ├── screenshot.png      ← annotated image with numbers + marks baked in
│   ├── prompt.md            ← structured prompt referencing the screenshot
│   └── meta.json            ← { created: "...", count: 3 }
```

The `prompt.md` format:

```markdown
View the screenshot at `./screenshot.png` — it shows my running app with red numbered annotations indicating issues to fix.

1. Card title needs more top padding
2. Border radius doesn't match the rest
3. Font weight too heavy on subtitle
```

Saved `prompt.md` files keep the screenshot reference relative to the capture folder. Clipboard output resolves the same prompt to an absolute screenshot path so the paste still works from an arbitrary Claude Code or Cursor working directory.

The preamble text is user-configurable in Prompt Settings. Use the `{{SCREENSHOT_PATH}}` token to place the screenshot path yourself. If the token is omitted, Vibeliner adds a separate screenshot line automatically.

## Editor actions

The editor is a borderless floating NSPanel (like Apple's Markup tool). Three action buttons:

- **Delete (trash icon)** — discard this capture entirely, close window
- **Save** — save to captures folder, keep window open
- **Copy for LLM** — save + copy prompt.md to clipboard + keep window open

Cmd+C (when no text field is focused) is the same as Copy for LLM. The X button in the top-left auto-saves then closes.

## Menu bar

The menu bar popover shows: setup/readiness status, recent captures (click to copy), prompt settings, open captures folder, change hotkey, quit.

## CLI

```bash
vibeliner list              # list captures
vibeliner copy <n>          # prompt to clipboard
vibeliner copy <n> --image  # image to clipboard
vibeliner send <n>          # copy + mark sent
vibeliner clean             # delete old captures
```

## Configuration

`~/.vibeliner/config.toml` — hotkey, save_dir, retain_days, preamble_single, preamble_batch.

## Visual style

- Annotation marks: red `#EF4444`, 2–3px strokes, 24px numbered circles with white text
- App chrome: standard macOS components — `NSVisualEffectView` for frosted glass, SF Symbols for icons, system font throughout, system accent color for buttons
- Editor: borderless floating panel, dark toolbar, no traffic lights
- Should feel like a built-in macOS utility

## Technical approach

- Swift 5.9+, AppKit + SwiftUI, macOS 14+
- AppKit for editor window and screen capture, SwiftUI for menu bar popover and settings
- `screencapture -i` with file output for capture (v1 — native macOS region selection)
- `KeyboardShortcuts` package by Sindre Sorhus for global hotkey
- Core Graphics / NSBezierPath for annotation canvas
- ~10 source files, one custom NSView subclass for the canvas
