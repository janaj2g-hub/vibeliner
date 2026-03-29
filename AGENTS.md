# Vibeliner — Codex Conventions

Read this file first before any task.

## How you receive work

Work comes as Linear ticket IDs (e.g., `VIB-2`, `VIB-3`). You have Linear MCP access.

**For each ticket:**
1. Read the ticket description for context, design, and constraints
2. Read the **latest** `## Codex prompt` comment on the ticket for executable tasks
3. Update the ticket status to **"AI Coder is implementing"**
4. Execute the tasks
5. Run the build command
6. Post a **verification comment** on the ticket (see format below)
7. Update the ticket status to **"In Review"**

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

## Linear status IDs (vibeliner team)

Use these when updating ticket status:

| Status | State ID |
|---|---|
| AI Coder is implementing | `0061c5f6-1eb9-47b4-9f02-b9059aa4543d` |
| In Review | `96216108-e645-49fd-9bb8-8c3952f09f82` |

##Execution rules
- No parallel work. Execute tickets sequentially, one at a time. Finish one ticket completely before starting the next.
- No skipping ahead. If a ticket depends on a previous one, the previous one must be at In Review before you start it.
- Use GitHub for source control. The canonical remote is `https://github.com/janaj2g-hub/vibeliner.git`.
- Do not work directly on `main` for ticket implementation. Create a feature branch first, preferably `codex/<ticket-id>-short-slug`.
- After completing a ticket and verifying the build, commit your changes with the Linear ticket ID in the commit message, push the branch to `origin`, and open or update a pull request back to `main` unless the user explicitly asks for a different flow.
- Treat a normal Codex implementation run as incomplete until code changes are built, committed, and pushed to GitHub, unless the user explicitly asks for a local-only or no-git pass.
- For batch Linear work, complete this full cycle for each ticket in order: implement, build, verify, commit, push, and update or open the pull request before moving to the next ticket.
- Include the Linear ticket ID in branch names, commit messages, and PR titles whenever possible.
- Never force-push `main` or rewrite shared history. Only rewrite your own feature branch if the user explicitly asks for it.
- If the repository is not yet initialized locally, initialize it, ensure `origin` points at the GitHub repo above, and push `main` before starting ticket branches.


## What this is

Vibeliner is a native macOS menu bar app that captures, annotates, and packages screenshots for AI coding tools. See `docs/PRODUCT_VISION.md` for the full product description.

## Tech stack

- **Language:** Swift 5.9+
- **Frameworks:** AppKit + SwiftUI, macOS 14+
- **Build:** `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`
- **Run:** `open build/Release/Vibeliner.app` or run from Xcode
- **Dependencies:** KeyboardShortcuts (Sindre Sorhus), ArgumentParser (Apple, CLI only)

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

### Editor window
- Borderless floating NSPanel — no traffic lights, no title bar
- Dark toolbar strip at top with: X close, tool buttons, undo, trash, Save, Copy for LLM
- X is the only way to close (auto-saves before closing)
- Copy for LLM = save + clipboard + "Copied" toast. Window stays open.
- Cmd+C (when no text field focused) = same as Copy for LLM

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

# Build the CLI (after CLI target exists)
xcodebuild -project Vibeliner.xcodeproj -scheme vibeliner-cli build
```

## Reference

- MacShot (github.com/sw33tLie/macshot) — study patterns only, do NOT copy GPL code
- KeyboardShortcuts (github.com/sindresorhus/KeyboardShortcuts)
- Apple docs: NSView, NSPanel, NSBezierPath, Core Graphics
