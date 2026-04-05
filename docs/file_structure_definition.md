# Vibeliner — Product Definition: File Structure & LLM Access

**Status:** Locked
**Defined via:** Design session 2026-03-30

---

## Overview

Vibeliner saves each capture as a self-contained folder with two files: the annotated screenshot and a plain text prompt. The folder structure is flat (one stream of captures sorted by date). The prompt file is optimized for pasting directly into LLM tools — both terminal-based (Claude Code, Cursor) and web-based (Claude.ai, ChatGPT).

## Base folder

| Property | Value |
|---|---|
| Location | Configured captures folder (default `~/Documents/vibeliner/`) |
| Set during | First-launch setup flow |
| Configurable | Yes, via settings (can change to any writable directory) |

This is chosen during setup. The configured captures folder also stores `config.toml` at its root.

## Capture folder structure

Every capture creates a new folder inside the base folder:

```
~/Documents/vibeliner/
├── 2026-03-28_143022/
│   ├── screenshot.png
│   └── prompt.txt
├── 2026-03-28_151200/
│   ├── screenshot.png
│   └── prompt.txt
├── 2026-03-30_091545/
│   ├── screenshot.png
│   └── prompt.txt
└── ...
```

### Folder naming

| Property | Value |
|---|---|
| Format | `YYYY-MM-DD_HHMMSS` |
| Timezone | Local system time |
| Uniqueness | Timestamp guarantees uniqueness (one capture per second max) |

### screenshot.png

The annotated screenshot with all marks and badges baked into the image. Note pills are NOT in the image — only the numbered badges, lines, shapes, and strokes.

| Property | Value |
|---|---|
| Format | PNG |
| Content | Screenshot with annotation marks + badges baked in |
| Resolution | Native screen resolution (Retina 2x if applicable) |
| NOT included | Note pill text, handles, hover/edit states |

### prompt.txt

A plain text file containing the prompt for LLM tools.

| Property | Value |
|---|---|
| Format | Plain text (.txt) |
| Encoding | UTF-8 |
| No metadata | No frontmatter, no JSON, no YAML — just natural language |

#### Saved prompt.txt content (relative path)

```
This is a screenshot of my running app. View it at ./screenshot.png

Numbered pins point to a specific issue and arrows point at or between elements. Each annotation has a number and a description.

Fix each issue:

1  [pin] padding too tight
2  [arrow] wrong border radius
3  [arrow] move this element left

Make the changes and verify they match the design.
```

The saved file uses a relative path (`./screenshot.png`) so the prompt makes sense when reading the file from within the capture folder.

#### Clipboard prompt content (absolute path)

When the user clicks "Copy Prompt," the clipboard gets a version with the absolute path:

```
This is a screenshot of my running app. View it at /Users/yourname/Documents/vibeliner/2026-03-30_091545/screenshot.png

Numbered pins point to a specific issue and arrows point at or between elements. Each annotation has a number and a description.

Fix each issue:

1  [pin] padding too tight
2  [arrow] wrong border radius
3  [arrow] move this element left

Make the changes and verify they match the design.
```

The absolute path ensures the prompt works when pasted into Claude Code or Cursor from any working directory.

#### Prompt structure

The prompt has three parts:

1. **Preamble** — user-configurable text with `[Screenshot Path]`
2. **Tool description** — `[Tool Description]` expands based on the tools used in the capture
3. **Annotation list + footer** — one line per annotation in `number  [tool] note` format, followed by the configured footer

The preamble and footer are user-configurable in settings. `[Screenshot Path]` is replaced with a relative path in saved files and an absolute path in IDE clipboard mode. In App clipboard mode, that line is omitted because the image is pasted separately.

## Two clipboard modes

In App mode, both copy actions are visible in the editor toolbar. In IDE mode, only "Copy Prompt" is shown.

### Copy Prompt (primary)

Copies the prompt text (with absolute screenshot path) to the clipboard. One paste into Claude Code, Cursor, Aider, or any terminal tool. `Cmd+C` (when no text field is focused) triggers this action.

### Copy Image (secondary)

Copies the annotated screenshot image to the system clipboard. The user can then paste it into Claude.ai, ChatGPT, or any web tool that accepts image paste. Visible in App mode alongside Copy Prompt.

### Web workflow (two-paste)

For web-based LLM tools:
1. Click "Copy Prompt" → paste the text prompt into the chat
2. Click "Copy Image" → paste the screenshot into the chat

Two separate paste actions. The two-button model makes this explicit and reliable.

### The difference is explained once in the editor

The current setup flow does not show a copy-mode tip card. The IDE/App distinction is explained in the editor's first-use tooltip instead.

## LLM access patterns

### Claude Code / Cursor / terminal tools

These tools run locally and have filesystem access.

1. User clicks "Copy Prompt"
2. Pastes into the terminal/IDE
3. The LLM reads the prompt text and follows the absolute file path to read the screenshot
4. One paste, done

### Claude.ai / ChatGPT / web tools

These tools cannot access the local filesystem.

1. User clicks "Copy Prompt" → pastes prompt text into chat
2. User clicks "Copy Image" → pastes the screenshot into the chat
3. Two pastes, done

### Future: direct integration

A future version could integrate with Claude Code's MCP protocol or Cursor's extension API to push captures directly into the tool's context without clipboard. This is out of scope for v1.

## Auto-save behavior

Captures are saved automatically at every step:
- Screenshot saved immediately after capture
- Annotations saved on every edit (placement, move, text change, delete)
- prompt.txt regenerated on every annotation change
- No manual save action needed
- The capture folder is always in a consistent state

## Cleanup / retention

| Property | Value |
|---|---|
| Auto-delete | None by default |
| Configurable | `retain_days` setting in the future (e.g., delete captures older than 30 days) |
| Manual cleanup | User can delete folders directly in Finder |

## v1 limitations

- No project organization — all captures in one flat stream
- No batch export
- No capture-to-capture linking
- No search or filtering of captures

---

## Future: Multi-project support

Documented here for future reference. NOT part of v1.

### Concept

Users working on multiple codebases can create "projects" in Vibeliner. Each project gets its own subfolder. New captures route to the active project.

### Folder structure (future)

```
~/Documents/vibeliner/
├── my-saas-app/
│   ├── 2026-03-28_143022/
│   │   ├── screenshot.png
│   │   └── prompt.txt
│   └── 2026-03-28_151200/
│       ├── screenshot.png
│       └── prompt.txt
├── mobile-app/
│   └── ...
└── side-project/
    └── ...
```

### Key features (future)

- **Active project selector** in the menu bar popover — switch which project receives new captures
- **Project-specific preamble** — different prompt templates per project
- **In-repo option** — set a project's capture folder to live inside the repo (e.g., `~/Projects/my-app/.vibeliner/`) so captures travel with the code
- **Project filtering** — menu bar popover shows recent captures filtered by active project

### Migration path

When multi-project is added, existing flat-stream captures would be treated as a "Default" project. No data migration needed — the old captures stay in place, new projects create new subfolders alongside them.
