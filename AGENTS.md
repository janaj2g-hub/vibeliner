# Vibeliner — Agent Instructions

Short reference for any AI coding agent working on this project. For full details, read `CLAUDE.md`.

## What this is

Vibeliner is a native macOS menu bar app that captures, annotates, and packages screenshots for AI coding tools. The full product spec is in `docs/specs/VIBELINER_PRD.md`.

## Tech stack

- Swift 5.9+
- macOS 14+
- AppKit for editor, canvas, and capture overlay
- SwiftUI only for settings and popover content, hosted in AppKit via `NSHostingView`
- No third-party dependencies

## Quick start

1. Read the Linear ticket description and the latest `## Claude Code prompt` comment
2. Update the ticket status to `AI Coder is implementing`
3. Create a branch: `claude/VIB-XXX-slug` or `codex/VIB-XXX-slug`
4. Implement the tasks from the prompt comment
5. Build: `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`
6. Test: `open dist/Vibeliner.app`
7. Post a verification comment on the ticket using the format below
8. Commit with ticket ID: `git commit -m "VIB-XXX: description"`
9. Push and open PR to `main`
10. Update the ticket status to `In Review`

## Batch execution

When given multiple ticket IDs (e.g., "Run VIB-106, VIB-107, VIB-108"):

- One branch for the batch: `claude/VIB-106-107-108-batch`
- For each ticket in order: read the latest `## Claude Code prompt` comment, set status to `AI Coder is implementing`, implement, commit with that ticket ID, post a verification comment, then set status to `In Review`
- Build and push only ONCE at the end (not after each ticket)
- Open or update ONE PR to `main` for the whole batch
- Exception: single-ticket "batches" build and push immediately

## Done means

A ticket is not done until:

- Code is implemented
- Build succeeds for single tickets, or at the end of the batch
- A verification comment is posted on the Linear ticket
- Changes are committed and pushed for single tickets, or at the end of the batch
- Ticket status is `In Review`

## Verification comment format

Post this on the Linear ticket after completing work:

```markdown
## Verification results

- [ ] [Assertion from the prompt] : Pass
- [ ] [Assertion from the prompt] : Fail — [explanation]

### Notes
[Implementation decisions, issues encountered, anything the reviewer should know]
```

Every line from the prompt's `Verification` section must be included with `Pass` or `Fail`.

## Key rules

- All colors/dimensions come from `Vibeliner/Design/DesignTokens.swift` — never hardcode
- AppKit for editor, canvas, capture overlay. SwiftUI only for settings/popover content.
- No third-party dependencies
- Avoid force unwraps in production logic. Narrow exceptions are allowed for `fatalError("init(coder:)")` and tightly-scoped AppKit IUO refs that are initialized during view/window construction.
- Prefer `let` over `var`
- Use `guard` for early returns
- Config lives at `~/Library/Application Support/Vibeliner/config.toml`
- Captures save under the configured captures folder (default: `~/Documents/vibeliner/YYYY-MM-DD_HHMMSS/`) with `screenshot.png` and `prompt.txt`
- Built app is `dist/Vibeliner.app`
- Canonical design-system docs live in `docs/design-system/`
- Read `docs/specs/TECHNICAL_DECISIONS.md` before trying a new approach — check if it already failed
- Read `docs/specs/VIBELINER_PRD.md` for the complete product spec
- Use `NotificationCenter` for change propagation, not Combine
- Use singleton managers where the project expects them, such as `ConfigManager.shared`, `CapturesManager.shared`, and `HotkeyManager.shared`
- Do not use `ScreenCaptureKit`; use `CGWindowListCreateImage` with `screencapture -R` as fallback
- Do not use SwiftUI `Canvas` for annotations; use AppKit `NSView` + Core Graphics
- Do not use `NSToolbar`; the toolbar is a custom `NSView`

## Design token rules

Mandatory for every ticket that touches UI.

1. **NEVER create a new color token without checking first.** Search `docs/design-system/DESIGN_SYSTEM.md` for an existing token before adding any NSColor to DesignTokens.swift.
2. **NEVER create a new button style.** Use `pillButton*` (outlined), `pillButtonPrimary*` (solid CTA), `toolbarSecondary*` (ghost), or `copiedGreen*` (success). No new families.
3. **NEVER create a new segmented control style.** All segmented controls use `segmented*` (6 tokens).
4. **NEVER hardcode colors.** Use `DesignTokens.*` or system colors (`.labelColor`, `.separatorColor`). No raw `NSColor(red:green:blue:alpha:)` in view files.
5. **Token creation requires a DESIGN_SYSTEM.md update.** New tokens must be added to both `DesignTokens.swift` and `docs/design-system/DESIGN_SYSTEM.md` in the same commit.
6. **Tour illustration tokens are quarantined.** They live in `DesignTokens+TourIllustrations.swift` and must never be used outside `Tour/` files.

## Git

- Remote: `https://github.com/janaj2g-hub/vibeliner.git`
- Never work on `main` directly
- Never force-push `main`
- Include ticket ID in branch names, commits, and PR titles

## Linear statuses

- `Backlog`: `2125ae12-fd1e-44e5-b62a-83410800a10e`
- `Todo`: `84b9147e-626a-4878-a64d-6ff3471860bc`
- `Prompt Ready`: `b2d068c7-5799-4d20-b6da-d1bf778fd9ab`
- `In Progress`: `97833b4e-9849-489d-9fad-699848f3bf68`
- `AI Coder is implementing`: `0061c5f6-1eb9-47b4-9f02-b9059aa4543d`
- `In Review`: `96216108-e645-49fd-9bb8-8c3952f09f82`
- `Done`: `d2b05df9-b63f-4261-8dcf-12b0241c2e18`
