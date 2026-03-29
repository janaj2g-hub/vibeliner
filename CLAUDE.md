# Vibeliner — Claude Code Conventions

Read this file first before any task.

## How you receive work

Work comes as Linear ticket IDs (e.g., `VIB-2`, `VIB-3`). You have Linear MCP access.

**For each ticket:**
1. Read the ticket description for context, design, and constraints
2. Read the **latest** `## Claude Code prompt` comment on the ticket for executable tasks
3. Update the ticket status to **"AI Coder is implementing"**
4. Execute the tasks
5. Run the build command
6. Commit the finished ticket work with the Linear ticket ID in the commit message
7. Push the branch to GitHub and open or update the pull request to `main`
8. Post a **verification comment** on the ticket (see format below)
9. Update the ticket status to **"In Review"**

**Batch prompts** list multiple ticket IDs. Execute them in order. Read each ticket's latest prompt comment.

**Project:** Vibeliner (team: vibeliner, key: VIB)

## Verification comment format

After completing a ticket, post a comment on the Linear ticket with this format:

```markdown
## Verification results

- [ ] [Assertion from the prompt] : Pass
- [ ] [Assertion from the prompt] : Pass
- [ ] [Assertion from the prompt] : Fail — [brief explanation if failed]

### Notes
[Any implementation notes, decisions made, or issues encountered]
```

Every line from the prompt's **Verification** section must appear with a Pass or Fail. If anything fails, still move to In Review — the reviewer decides next steps.
Do not treat the ticket as complete until the code is built, committed, pushed, and the PR is updated.

## Linear status IDs (vibeliner team)

Use these when updating ticket status:

| Status | State ID |
|---|---|
| AI Coder is implementing | `0061c5f6-1eb9-47b4-9f02-b9059aa4543d` |
| In Review | `96216108-e645-49fd-9bb8-8c3952f09f82` |

##Execution rules
- No parallel work. Execute tickets sequentially, one at a time. Do not spawn subagents or run tasks in parallel. Finish one ticket completely (build, verify, post comment, update status) before starting the next.
- No skipping ahead. If a ticket depends on a previous one, the previous one must be at In Review before you start it.
- Use GitHub for source control. The canonical remote is `https://github.com/janaj2g-hub/vibeliner.git`.
- Do not work directly on `main` for ticket implementation. Create a feature branch first, preferably `claude/<ticket-id>-short-slug`.
- After completing a ticket and verifying the build, commit your changes with the Linear ticket ID in the commit message, push the branch to `origin`, and open or update a pull request back to `main` unless the user explicitly asks for a different flow.
- Treat a normal Claude Code implementation run as incomplete until code changes are built, committed, and pushed to GitHub, unless the user explicitly asks for a local-only or no-git pass.
- For batch Linear work, complete this full cycle for each ticket in order: implement, build, verify, commit, push, and update or open the pull request before moving to the next ticket.
- After each ticket prompt in a batch, stop only after the branch has been pushed and the PR state is current. Do not leave a ticket half-finished locally while moving to the next one.
- Include the Linear ticket ID in branch names, commit messages, and PR titles whenever possible.
- Never force-push `main` or rewrite shared history. Only rewrite your own feature branch if the user explicitly asks for it.
- If the repository is not yet initialized locally, initialize it, ensure `origin` points at the GitHub repo above, and push `main` before starting ticket branches.


## What this is

Vibeliner is a native macOS menu bar app that captures, annotates, and packages screenshots for AI coding tools. See `docs/PRODUCT_VISION.md` for the full product description.

If you touch prompt/export semantics, screenshot-path insertion, or annotation meaning, also read `docs/ANNOTATION_PROMPTING.md` first.

## Tech stack

- **Language:** Swift 5 language mode in Xcode (`SWIFT_VERSION = 5.0`); currently built on this machine with Apple Swift 6.3 / Xcode 26.4
- **Frameworks:** AppKit + SwiftUI, macOS 14+
- **Build:** `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`
- **Run:** `open /Users/jongrossman/Documents/vibeliner/V1/vibeliner/dist/Vibeliner.app` for the latest repo-local app, or run from Xcode
- **Dependencies:** KeyboardShortcuts (Sindre Sorhus), ArgumentParser (Apple, CLI only)

## Technical background

### Product contract
- Vibeliner is a capture-to-prompt pipeline, not an AI-in-the-loop app; the core product artifact is a saved capture folder containing `screenshot.png`, `prompt.md`, and `meta.json`
- The screenshot is the primary source of truth; prompt text exists to frame the screenshot and the numbered annotations, not to restate everything visible on screen
- Saved prompts use a relative screenshot path, while clipboard output resolves that path to an absolute path so pasting works from arbitrary working directories

### Capture model
- For v1, Vibeliner intentionally uses file-based `/usr/sbin/screencapture -i -x <path>` rather than a custom capture stack
- The real capture authority is the child-process result plus screenshot-file materialization; setup and permission state are advisory diagnostics only
- Keep cancellation, true capture failure, and post-capture export failure as separate states in code and in UX

### App lifecycle
- Vibeliner is a menu bar app by default and should behave like a lightweight accessory app outside explicit app-owned UI flows
- Promote into a normal foreground app only when Vibeliner-owned windows or alerts need focus, then drop back when that flow ends
- When debugging behavior differences, prefer launching `dist/Vibeliner.app` after a build rather than assuming the Xcode Run copy matches normal app behavior

### Export and annotation semantics
- Numbered badges are the user's explicit discussion points; attached note text is the primary explanation when present
- Exported screenshots bake in marks and badge numbers, but note text lives in `prompt.md` rather than the image
- If you change prompt wording, screenshot-path handling, or annotation meaning, update `docs/ANNOTATION_PROMPTING.md` in the same change

## Architecture

```
Vibeliner/
├── VibelinerApp.swift              # @main entry, NSApplicationDelegateAdaptor
├── AppDelegate.swift               # Menu bar icon, hotkey, capture orchestration
├── Config.swift                    # ~/.vibeliner/config.toml read/write
├── CaptureManager.swift            # Screen capture via screencapture CLI
├── CaptureStore.swift              # File system: save/read/list/clean capture folders
├── Annotation.swift                # Data model: number, points, note, type
├── AnnotationCanvas.swift          # Custom NSView: draw on image, marks, inline text
├── EditorWindowController.swift    # Borderless NSPanel + canvas + toolbar
├── MenuBarPopover.swift            # SwiftUI popover for menu bar
├── PromptSettingsView.swift        # SwiftUI settings for preamble editing
├── Constants.swift                 # Colors, sizes, shared constants
└── CLI/
    └── VibeLinerCLI.swift          # vibeliner list/copy/send/clean
```

### Component overview
- `AppDelegate` owns menu bar lifecycle, hotkey registration, and capture/editor orchestration
- `CaptureManager` is the capture boundary; it invokes `screencapture`, interprets outcomes, and should remain the source of truth for capture success/failure
- `CaptureStore` owns on-disk capture folders and artifact naming; keep path layout decisions centralized there
- `AnnotationCanvas` owns interaction state, drawing, hit-testing, and annotation editing behavior
- `EditorWindowController` owns the floating editor window shell and toolbar wiring around the canvas
- SwiftUI views (`MenuBarPopover`, `PromptSettingsView`) should stay focused on settings and lightweight presentation, not capture/editor business logic

### Coordinate rules
- Be explicit about coordinate spaces whenever editing annotation or export code: distinguish image-space, canvas/view-space, and output-pixel coordinates
- Do not mix raw view points with persisted annotation geometry without converting through a single canonical mapping
- Keep screenshot-to-export mapping consistent with the displayed image rect; avoid ad hoc offsets or scale factors sprinkled across files
- If annotations are transferred between views or windows, shift coordinates at the transfer boundary and keep the stored model internally consistent afterward
- When positioning AppKit text-editing subviews on top of the canvas, convert model coordinates back into view coordinates instead of storing view-relative points in the model

### Interaction state
- Treat selection, annotation editing, and export as distinct modes with explicit transitions rather than overlapping boolean flags where possible
- Keep toolbar actions consistent with the active mode; actions that mutate annotations should operate on the current canvas state, not infer hidden state from window chrome
- Keyboard shortcuts that mirror toolbar actions, such as copy/export, should go through the same implementation path to avoid behavior drift

## Conventions

### Code style
- Use Swift naming conventions (camelCase for vars/funcs, PascalCase for types)
- Prefer `let` over `var` where possible
- Use `guard` for early returns
- No force unwraps (`!`) except in tests — use `guard let` or `if let`

### UI
- **AppKit** for: editor window, annotation canvas, screen capture
- **SwiftUI** for: menu bar popover, settings sheet, copy panel content
- Host SwiftUI in AppKit via `NSHostingView` where needed
- Use SF Symbols for all icons
- System font throughout — no custom fonts

### Colors
- Annotation red: `#EF4444` / `NSColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1.0)`
- Stroke width: 2.5px
- Badge: 24px diameter red circle, white bold 14px text
- Use named constants from `Constants.swift`, not hardcoded hex values

### File paths
- Config: `~/.vibeliner/config.toml`
- Captures: `~/.vibeliner/captures/` (configurable via `save_dir`)
- Each capture: `YYYY-MM-dd_HHmmss_[slug]/screenshot.png + prompt.md + meta.json`
- Repo-local runnable app: `dist/Vibeliner.app` after a successful app build

### Editor window
- Borderless floating NSPanel — no traffic lights, no title bar
- Dark toolbar strip at top with: X close, tool buttons, undo, trash, Save, Copy for LLM
- X is the only way to close (auto-saves before closing)
- Copy for LLM = save + clipboard + "Copied" toast. Window stays open.
- Cmd+C (when no text field focused) = same as Copy for LLM

### Concurrency & threading
- UI state, AppKit drawing, and window/controller lifecycle belong on the main thread
- File IO, prompt generation, and other non-UI work may happen off-main, but marshal results back to the main thread before mutating UI-observed state
- If a type or helper touches SwiftUI/AppKit rendering APIs, keep actor isolation explicit and prefer `@MainActor` where appropriate
- Avoid introducing background work that races capture-folder creation, prompt writing, or export finalization
- Favor one clear ownership path for async work instead of duplicating capture/export side effects across callers

### What NOT to do
- Do not use ScreenCaptureKit — use file-based `screencapture -i` for v1
- Do not copy GPL code from MacShot — rewrite from scratch
- Do not add third-party dependencies beyond KeyboardShortcuts and ArgumentParser
- Do not use SwiftUI Canvas for the annotation view — use AppKit NSView + Core Graphics
- Do not use NSToolbar — build the toolbar as a plain NSView in the content area

## Build & verify

```bash
# Build the app
xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build

# Open the latest repo-local app bundle produced by the build phase
open /Users/jongrossman/Documents/vibeliner/V1/vibeliner/dist/Vibeliner.app

# Build the CLI (after CLI target exists)
xcodebuild -project Vibeliner.xcodeproj -scheme vibeliner-cli build
```

Notes:
- The shared `Vibeliner` scheme copies the built app to `dist/Vibeliner.app` on every successful app build.
- Treat `dist/Vibeliner.app` as the canonical bundle for manual testing outside Xcode.
- Xcode's Run button still launches the DerivedData app, not `dist/Vibeliner.app`.
- For Screen Recording / TCC debugging, authorize the same bundle path the app reports in About. Prefer `dist/Vibeliner.app` for stable local testing.
- `dist/` is ignored by git; do not commit the built `.app` bundle.

## Reference

- MacShot (github.com/sw33tLie/macshot) — study patterns only, do NOT copy GPL code
- KeyboardShortcuts (github.com/sindresorhus/KeyboardShortcuts)
- Apple docs: NSView, NSPanel, NSBezierPath, Core Graphics
- `docs/ANNOTATION_PROMPTING.md` — source of truth for annotation semantics and the annotated-screenshot prompt contract
