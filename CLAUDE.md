# Vibeliner — Instructions for Claude Code

Read this file first before any task.

## What this is

Vibeliner is a native macOS menu bar app that captures, annotates, and packages screenshots for AI coding tools. The full product spec is in `docs/specs/VIBELINER_PRD.md`.

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
│   ├── AppDelegate.swift               # Menu bar icon, app lifecycle
│   ├── main.swift                      # App entry point
│   ├── VisualTestHarness.swift         # Visual test gallery (core + gallery layout)
│   ├── HarnessPreviewSurfaces.swift    # Test harness: card + setup preview surfaces
│   ├── EditorHarnessSurfaceView.swift  # Test harness: editor canvas scenarios
│   └── EditorHarnessSurfaceView+Annotations.swift  # Test harness: sample annotations
├── Design/
│   ├── DesignTokens.swift              # Core colors — single source of truth
│   ├── DesignTokens+Settings.swift     # Settings + editor interaction tokens
│   ├── DesignTokens+Layout.swift       # Dimensions, filmstrip, ghost, fonts, text field cell
│   ├── DesignTokens+SetupTour.swift    # Setup window + Tour window tokens
│   └── DesignTokens+TourIllustrations.swift  # Tour illustration tokens
├── Config/
│   ├── ConfigManager.swift             # Read/write stable config in Application Support + legacy migration
│   └── CapturesManager.swift           # Folder creation, listing captures
├── Hotkey/
│   └── HotkeyManager.swift            # Global Cmd+Shift+6 registration
├── Capture/
│   ├── CaptureCoordinator.swift        # Orchestrates overlay → capture → editor
│   ├── CaptureOverlayWindow.swift      # Full-screen dim overlay
│   ├── CrosshairView.swift             # Purple crosshair cursor
│   ├── DimensionLabelView.swift        # Live w/h pill during drag
│   └── ScreenCapture.swift             # CGWindowListCreateImage → PNG
├── Editor/
│   ├── EditorPanel.swift               # Borderless floating NSPanel (core + keyboard)
│   ├── EditorPanelHelpers.swift        # EditorToolController + EditorCursorController
│   ├── EditorPanel+Toolbar.swift       # ToolbarDelegate + add image
│   ├── EditorPanel+Filmstrip.swift     # Filmstrip transition + coordinate helpers
│   ├── ScreenshotCanvasView.swift      # Screenshot display with rounded corners
│   ├── CanvasView.swift                # Marks layer + mouse dispatch
│   ├── CanvasView+NoteEditing.swift    # Note pill editing + field delegate
│   ├── MarksLayerView.swift            # Annotation marks rendering
│   ├── ToolbarView.swift               # Pill-shaped floating toolbar (setup + appearance)
│   ├── ToolbarView+State.swift         # Tool selection, copy state, shadow
│   ├── ToolbarIcons.swift              # Icon drawing functions + geometry
│   ├── ToolbarButtons.swift            # ModeToggleView, CopyPillButton, SecondaryPillButton
│   ├── ToolButton.swift                # Reusable circular button
│   ├── StatusPillView.swift            # Floating status pill below screenshot
│   ├── FilmstripGridView.swift         # Multi-image filmstrip layout
│   └── FilmstripCellView.swift         # Individual filmstrip cell view
├── Annotations/
│   ├── AnnotationModel.swift           # Data model: Annotation, AnnotationPosition
│   ├── AnnotationStore.swift           # Single source of truth for annotations
│   ├── UndoRedoManager.swift           # Undo/redo stack
│   ├── Tools/
│   │   ├── SelectTool.swift
│   │   ├── PinTool.swift
│   │   ├── ArrowTool.swift
│   │   ├── LineTool.swift
│   │   ├── RectangleTool.swift
│   │   ├── CircleTool.swift
│   │   └── FreehandTool.swift
│   └── Renderers/
│       ├── BadgeRenderer.swift         # Shared numbered badge drawing
│       ├── NotePillRenderer.swift      # Note pill placement + reuse pool
│       ├── NotePillView.swift          # Note pill interactive view
│       ├── PinRenderer.swift
│       ├── ArrowRenderer.swift
│       ├── LineRenderer.swift
│       ├── RectangleRenderer.swift
│       ├── CircleRenderer.swift
│       └── FreehandRenderer.swift
├── Output/
│   ├── PromptGenerator.swift           # Generate prompt.txt from annotations
│   ├── ScreenshotExporter.swift        # Bake marks into PNG
│   ├── ClipboardManager.swift          # NSPasteboard for text and image
│   └── AutoSaveManager.swift           # Save on every annotation change
├── Setup/
│   ├── SetupWindowController.swift     # Welcome window core + polling
│   ├── SetupComponents.swift           # Setup pill buttons, dividers, surface views
│   ├── SetupWindowController+Panels.swift  # 3-panel builders + UI factories
│   └── SetupWindowController+Actions.swift # Step completion + actions + helpers
├── Settings/
│   ├── SettingsWindowController.swift  # 3-tab settings window
│   ├── GeneralTabView.swift            # Hotkey, folder, launch at login
│   ├── PromptTabView.swift             # Sub-tabs: Preamble, Tools, Footer (core + layout)
│   ├── PromptTabView+ContentBuilders.swift  # Sub-tab content builders + role management
│   ├── PromptTabView+State.swift       # Data sync, drafts, delegates
│   ├── PromptTabCustomViews.swift      # ToolIconView, DraftStateView, RoleSwatchView
│   ├── PromptPreviewView.swift         # Live preview at bottom
│   ├── AboutTabView.swift              # Version, links
│   ├── SettingsUI.swift                # Shared settings view helpers + base classes
│   └── SettingsControls.swift          # PillButton, TextField, KeyPillRow, SegmentedControl
├── Models/
│   ├── CaptureStore.swift              # CaptureSession source of truth
│   ├── CaptureImage.swift              # Per-image capture metadata
│   └── ImageRole.swift                 # Multi-image role model
├── Popover/
│   ├── PopoverWindow.swift             # Surface views + PopoverWindow panel
│   ├── PopoverViewController.swift     # PopoverContentView + PopoverRowView
│   ├── RecentCapturesSubmenu.swift     # Hover submenu with thumbnails
│   └── CaptureRowView.swift            # Thumbnail + timestamp + copy buttons
├── Services/
│   ├── CompositeStitcher.swift         # Filmstrip export renderer
│   ├── CoordinateConverter.swift       # Relative coordinate conversion
│   └── LayoutCalculator.swift          # Filmstrip layout helper
├── Tour/
│   ├── TourWindowController.swift      # Product walkthrough (singleton + state + init)
│   ├── TourWindowController+UIBuilder.swift  # Header + footer construction
│   ├── TourWindowController+Body.swift # Body layout + step rendering
│   ├── TourWindowController+Content.swift  # Illustrations, done screen, factories, actions
│   ├── TourUIComponents.swift          # TourContentView, HoverButton, ExitTourPillView
│   ├── TourStepData.swift              # Tour step configuration data
│   └── Illustrations/                  # Tour-specific illustration helpers
├── Utilities/
│   ├── CursorManager.swift             # Balanced cursor hide/show
│   ├── ImageUtils.swift                # NSImage helpers
│   └── KeyEventGuard.swift             # Shortcut routing safety
└── Views/
    ├── FilmCellView.swift              # Filmstrip screenshot cell
    └── TitlePillView.swift             # Editable filmstrip title + role pill
```

## Conventions

### Code style
- Swift naming: camelCase for vars/funcs, PascalCase for types
- Prefer `let` over `var`
- Use `guard` for early returns
- Avoid force unwraps in production logic. Narrow exceptions are allowed for `fatalError("init(coder:)")` and AppKit construction-time IUOs that are assigned during view or window setup.

### Visual constants
- ALL colors, dimensions, and fonts live in `DesignTokens.swift`
- Never hardcode a color hex, pixel value, or font size in any other file
- Import from DesignTokens: `DesignTokens.purpleLight`, `DesignTokens.badgeDiameter`, etc.

### Architecture patterns
- **AppKit** for: editor panel, capture overlay, annotation canvas, screen capture
- **SwiftUI** for: settings views, popover content — hosted via `NSHostingView`
- **NotificationCenter** for change propagation (not Combine)
- **Singleton** managers: `ConfigManager.shared`, `CapturesManager.shared`, `HotkeyManager.shared`
- **Tool protocol:** all 6 annotation tools conform to a shared `AnnotationTool` protocol
- **Renderer protocol:** all 6 renderers conform to a shared `AnnotationRenderer` protocol with `drawMarks(in:)` and `drawNotes(in:)` methods

### File paths
- Config: `~/Library/Application Support/Vibeliner/config.toml`
- Captures: configured captures folder (default `~/Documents/vibeliner/YYYY-MM-DD_HHMMSS/`) containing `screenshot.png` and `prompt.txt`
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

## Design System

The canonical design-system documentation lives in `docs/design-system/`. These three files are PROTECTED — never delete them.

| File | Purpose | Audience |
|------|---------|----------|
| `DESIGN_SYSTEM.md` | Machine-readable token reference — names, values (light + dark), usage, consuming files | Claude Code prompts |
| `design-system.html` | Visual token reference — color swatches, typography, component previews with light/dark toggle | Human review |
| `Design_Tester.html` | Interactive control playground — every button/control with hover/click states, token mappings | Human review, QA |

**Rules:**
- The runtime source of truth is `Vibeliner/Design/DesignTokens.swift`
- Any ticket that adds, changes, or removes a token in DesignTokens.swift MUST also update all 3 design system files
- Any ticket that adds a new button or interactive control MUST add it to Design_Tester.html
- Never delete these files or overwrite them with empty content
- Do not recreate root-level duplicate peers such as `docs/DESIGN_SYSTEM.md` or `docs/design-system.html`

## Design token rules

These rules are mandatory for every ticket that touches UI.

1. **NEVER create a new color token without checking first.** Before adding any NSColor to DesignTokens.swift, search `docs/design-system/DESIGN_SYSTEM.md` for an existing token with the same purpose. If one exists, use it. If you think a new token is needed, say so in the PR description — do not silently create one.

2. **NEVER create a new button style.** The app has exactly these button families:
   - `pillButton*` (6 tokens) — all purple outlined pill buttons (Copy Prompt, Change, Save, etc.)
   - `pillButtonPrimary*` (5 tokens) — solid-fill purple CTA buttons (tour Next, etc.)
   - `toolbarSecondary*` (6 tokens) — subtle ghost/outlined buttons (+ Add image, New capture)
   - `copiedGreen*` (4 tokens) — success/copied state
   If a ticket needs a button, use one of these. Do NOT create a new family.

3. **NEVER create a new segmented control style.** All segmented controls use `segmented*` (6 tokens). The component accepts any number of segments. Do NOT create surface-specific variants.

4. **NEVER hardcode colors.** Every color in UI code must reference a `DesignTokens.*` token or a system color (`.labelColor`, `.separatorColor`, etc.). No raw `NSColor(red:green:blue:alpha:)` in view files.

5. **Token creation requires a DESIGN_SYSTEM.md update.** If a genuinely new token is approved, add it to both `DesignTokens.swift` AND `docs/design-system/DESIGN_SYSTEM.md` in the same commit.

6. **Tour illustration tokens are quarantined.** They live in `DesignTokens+TourIllustrations.swift` and must never be used outside `Tour/` files. Tour UI chrome (buttons, controls) must use the universal component tokens above.

## Reference docs

- `docs/specs/VIBELINER_PRD.md` — master product spec (all 13 locked product definitions)
- `docs/specs/TECHNICAL_DECISIONS.md` — failed approaches, architectural decisions
- `CLAUDE.md` — this file (Claude Code instructions)
