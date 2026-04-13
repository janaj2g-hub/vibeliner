# Vibeliner

Annotate screenshots for AI coding tools.

## What it does

Spot a visual bug, press a hotkey, and draw numbered annotations directly on your screen. Vibeliner captures the region, bakes your marks into the screenshot, and generates a structured prompt with matching numbered instructions. Paste both into Claude Code, ChatGPT, or any LLM and it knows exactly what to fix.

## Features

- **6 annotation tools** — Pin, Arrow, Line, Rectangle, Circle, Freehand. Each mark gets a number and a note that becomes part of the prompt.
- **IDE mode** — One paste. The prompt includes the file path so terminal tools (Claude Code, Codex) read the image from disk.
- **App mode** — Two pastes. Copy the prompt and the image separately into chat apps (Claude.ai, ChatGPT, Gemini).
- **Multi-image filmstrip** — Capture additional screenshots into the same session. Assign roles (Observed, Expected, Reference) so the AI knows which image is which.
- **Customizable prompts** — Edit the preamble, per-tool templates, and footer in Settings. The preview updates live while you edit, and **Save** applies those prompt settings to copied/exported prompts and saved `prompt.txt` files.
- **Auto-save** — Every annotation change is saved to disk automatically.
- **Menu bar app** — Lives in the menu bar. No Dock icon, no window clutter.

## Installation

1. Download the latest `.dmg` from [Releases](https://github.com/janaj2g-hub/vibeliner/releases)
2. Drag **Vibeliner** to Applications
3. Launch Vibeliner — grant Screen Recording and Accessibility permissions when prompted

## Usage

1. Press **Cmd + Shift + 6** (configurable in Settings)
2. Drag to select a screen region
3. Annotate with the floating toolbar
4. Click **Copy Prompt** to copy the text, **Copy Image** to copy the annotated screenshot
5. Paste into your AI tool

## Prompt settings

- Changes in **Settings → Prompt** stay in a draft until you click **Save**.
- The preview updates live while you edit, but copied prompts, exported prompts, and saved `prompt.txt` files use the last saved prompt settings.
- Annotation edits still auto-save normally.

## Where data lives

- Captures save under your configured captures folder. The default location is `~/Documents/vibeliner/YYYY-MM-DD_HHMMSS/`.
- App settings save to `~/Library/Application Support/Vibeliner/config.toml`.

## Documentation

- Product requirements: [`docs/VIBELINER_PRD.md`](docs/VIBELINER_PRD.md)
- Design system: [`docs/design-system/`](docs/design-system/)

## Requirements

- macOS 14 (Sonoma) or later

## License

[MIT](LICENSE)
