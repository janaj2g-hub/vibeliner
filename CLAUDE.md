# Vibeliner — Instructions for Claude Code

Read this file first before any task.

## What this is

Vibeliner is a native macOS menu bar app that captures, annotates, and packages screenshots for AI coding tools. The full product spec is in `docs/VIBELINER_PRD.md`.

## Tech stack

- **Language:** Swift 5.9+
- **Frameworks:** AppKit, macOS 14+ (use SwiftUI only for settings and popover content, hosted in AppKit via NSHostingView)
- **Build:** `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`
- **Test app:** `open dist/Vibeliner.app` (the Vibeliner scheme copies the built app here on every successful build)
- **No third-party dependencies.** Everything is stdlib + AppKit + CoreGraphics + SwiftUI (for hosted views only).

## How you receive work

Work comes as Linear ticket IDs (e.g., `VIB-106`, `VIB-107`). You have Linear MCP access.

### Single ticket

1. Read the ticket description for context
2. Read the **latest** `## Claude Code prompt` comment for executable tasks
3. Update the ticket status to **"AI Coder is implementing"** (state ID: `0061c5f6-1eb9-47b4-9f02-b9059aa4543d`)
4. Create a feature branch: `claude/VIB-XXX-short-slug`
5. Implement the tasks
6. Build: `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`
7. Post a verification comment on the ticket (see format below)
8. Commit with the ticket ID in the message: `git commit -m "VIB-XXX: short description"`
9. Push the branch and open/update a PR to `main`
10. Update ticket status to **"In Review"** (state ID: `96216108-e645-49fd-9bb8-8c3952f09f82`)

### Batch tickets

When the user says **"Run VIB-XXX, VIB-YYY, VIB-ZZZ"** — this is a batch.

**Batch rules:**
1. Create ONE feature branch for the entire batch: `claude/VIB-XXX-YYY-ZZZ-batch`
2. For each ticket in order:
   a. Read the ticket's latest `## Claude Code prompt` comment
   b. Update status to "AI Coder is implementing"
   c. Implement the tasks
   d. Commit with that ticket's ID: `git commit -m "VIB-XXX: description"`
   e. Post a verification comment on that ticket
   f. Update status to "In Review"
3. After ALL tickets in the batch are done:
   a. Run the build: `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`
   b. Push the branch and open/update ONE PR to `main` covering the whole batch
4. Do NOT build or push after each individual ticket in a batch — only at the end
5. Exception: if the batch contains only ONE ticket, treat it as a single ticket (build + push after it)

### What "done" means

A ticket is not done until:
- Code is implemented
- Build succeeds (for single tickets and end of batches)
- Verification comment is posted on the ticket
- Changes are committed and pushed (for single tickets and end of batches)
- Ticket status is "In Review"

## Verification comment format

After completing a ticket, post this comment on the Linear ticket:

```markdown
## Verification results

- [ ] [Assertion from the prompt] : Pass
- [ ] [Assertion from the prompt] : Fail — [explanation]

### Notes
[Implementation decisions, issues encountered, anything the reviewer should know]
```

Every line from the prompt's **Verification** section must appear with Pass or Fail.

## Project structure

```
Vibeliner/
├── App/
│   └── AppDelegate.swift               # Menu bar icon, app lifecycle
├── Design/
│   └── DesignTokens.swift              # ALL colors, dimensions, fonts — single source of truth
├── Config/
│   ├── ConfigManager.swift             # Read/write config.toml
│   └── CapturesManager.swift           # Folder creation, listing captures
├── Hotkey/
│   └── HotkeyManager.swift            # Global Cmd+Shift+6 registration
├── Capture/
│   ├── CaptureCoordinator.swift        # Orchestrates overlay → capture → editor
│   ├── CaptureOverlayWindow.swift      # Full-screen dim overlay
│   ├── CrosshairView.swift             # Purple crosshair cursor
│   ├── RegionSelectionView.swift       # Drag-to-select with bright cutout
│   ├── DimensionLabelView.swift        # Live w/h pill during drag
│   └── ScreenCapture.swift             # CGWindowListCreateImage → PNG
├── Editor/
│   ├── EditorPanel.swift               # Borderless floating NSPanel
│   ├── ScreenshotCanvasView.swift      # Screenshot display with rounded corners
│   ├── CanvasView.swift                # Marks layer + Notes layer
│   ├── ToolbarView.swift               # Pill-shaped floating toolbar
│   ├── ToolButton.swift                # Reusable circular button
│   ├── PinCounterIcon.swift            # Special pin icon with counter
│   ├── StatusPillView.swift            # Floating status pill below screenshot
│   └── FirstUseTooltipView.swift       # One-time IDE/App mode explanation
├── Annotations/
│   ├── AnnotationModel.swift           # Data model: Annotation, AnnotationPosition
│   ├── AnnotationStore.swift           # Single source of truth for annotations
│   ├── UndoRedoManager.swift           # Undo/redo stack
│   ├── Tools/
│   │   ├── PinTool.swift
│   │   ├── ArrowTool.swift
│   │   ├── RectangleTool.swift
│   │   ├── CircleTool.swift
│   │   └── FreehandTool.swift
│   └── Renderers/
│       ├── PinRenderer.swift
│       ├── ArrowRenderer.swift
│       ├── RectangleRenderer.swift
│       ├── CircleRenderer.swift
│       └── FreehandRenderer.swift
├── Output/
│   ├── PromptGenerator.swift           # Generate prompt.txt from annotations
│   ├── ScreenshotExporter.swift        # Bake marks into PNG
│   ├── ClipboardManager.swift          # NSPasteboard for text and image
│   └── AutoSaveManager.swift           # Save on every annotation change
├── Setup/
│   ├── SetupWindowController.swift     # One-time welcome window
│   ├── SetupPanelView.swift            # Reusable 3-state panel
│   ├── PermissionPanel.swift           # Screen recording permission
│   ├── FolderPanel.swift               # Captures folder creation
│   └── ShareExplanationPanel.swift     # How to share explanation
├── Settings/
│   ├── SettingsWindowController.swift  # 3-tab settings window
│   ├── GeneralTabView.swift            # Hotkey, folder, launch at login
│   ├── PromptTabView.swift             # Sub-tabs: Preamble, Tools, Footer
│   ├── ToolDescriptionRow.swift        # Icon + name + editable field
│   ├── PromptPreviewView.swift         # Live preview at bottom
│   └── AboutTabView.swift              # Version, links
└── Popover/
    ├── PopoverViewController.swift     # Dark utility menu
    ├── RecentCapturesSubmenu.swift      # Hover submenu with thumbnails
    └── CaptureRowView.swift            # Thumbnail + timestamp + copy buttons
```

## Conventions

### Code style
- Swift naming: camelCase for vars/funcs, PascalCase for types
- Prefer `let` over `var`
- Use `guard` for early returns
- No force unwraps (`!`) — use `guard let` or `if let`

### Visual constants
- ALL colors, dimensions, and fonts live in `DesignTokens.swift`
- Never hardcode a color hex, pixel value, or font size in any other file
- Import from DesignTokens: `DesignTokens.purpleLight`, `DesignTokens.badgeDiameter`, etc.

### Architecture patterns
- **AppKit** for: editor panel, capture overlay, annotation canvas, screen capture
- **SwiftUI** for: settings views, popover content — hosted via `NSHostingView`
- **NotificationCenter** for change propagation (not Combine)
- **Singleton** managers: `ConfigManager.shared`, `CapturesManager.shared`, `HotkeyManager.shared`
- **Tool protocol:** all 5 annotation tools conform to a shared `AnnotationTool` protocol
- **Renderer protocol:** all 5 renderers conform to a shared `AnnotationRenderer` protocol with `drawMarks(in:)` and `drawNotes(in:)` methods

### File paths
- Config: `~/Documents/vibeliner/config.toml`
- Captures: `~/Documents/vibeliner/YYYY-MM-DD_HHMMSS/screenshot.png + prompt.txt`
- Built app: `dist/Vibeliner.app` (git-ignored, built by xcodebuild)

### What NOT to do
- Do not use ScreenCaptureKit — use CGWindowListCreateImage (fallback: screencapture -R)
- Do not add third-party dependencies
- Do not use SwiftUI Canvas for the annotation view — use AppKit NSView + Core Graphics
- Do not use NSToolbar — the toolbar is a custom NSView
- Do not hardcode colors or dimensions — always use DesignTokens

## Git workflow

- **Remote:** `https://github.com/janaj2g-hub/vibeliner.git`
- **Never work directly on `main`** for ticket implementation
- **Branch naming:** `claude/VIB-XXX-short-slug` (single) or `claude/VIB-XXX-YYY-ZZZ-batch` (batch)
- **Commit messages:** always include the Linear ticket ID
- **Never force-push `main`** or rewrite shared history

## Linear status IDs (vibeliner team)

| Status | State ID |
|---|---|
| Backlog | `2125ae12-fd1e-44e5-b62a-83410800a10e` |
| Todo | `84b9147e-626a-4878-a64d-6ff3471860bc` |
| Prompt Ready | `b2d068c7-5799-4d20-b6da-d1bf778fd9ab` |
| In Progress | `97833b4e-9849-489d-9fad-699848f3bf68` |
| AI Coder is implementing | `0061c5f6-1eb9-47b4-9f02-b9059aa4543d` |
| In Review | `96216108-e645-49fd-9bb8-8c3952f09f82` |
| Done | `d2b05df9-b63f-4261-8dcf-12b0241c2e18` |

## Reference docs

- `docs/VIBELINER_PRD.md` — master product spec (all 13 locked product definitions)
- `docs/TECHNICAL_DECISIONS.md` — failed approaches, architectural decisions
- `CLAUDE.md` — this file (Claude Code instructions)
