# Vibeliner — Agent Instructions

Short reference for any AI coding agent working on this project. For full details, read `CLAUDE.md`.

## Quick start

1. Read the Linear ticket description and the latest `## Claude Code prompt` comment
2. Create a branch: `claude/VIB-XXX-slug` or `codex/VIB-XXX-slug`
3. Implement the tasks from the prompt comment
4. Build: `xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build`
5. Test: `open dist/Vibeliner.app`
6. Commit with ticket ID: `git commit -m "VIB-XXX: description"`
7. Push and open PR to `main`

## Batch execution

When given multiple ticket IDs (e.g., "Run VIB-106, VIB-107, VIB-108"):

- One branch for the batch: `claude/VIB-106-107-108-batch`
- Implement each ticket in order, committing after each
- Build and push only ONCE at the end (not after each ticket)
- Exception: single-ticket "batches" build and push immediately

## Key rules

- All colors/dimensions come from `Vibeliner/Design/DesignTokens.swift` — never hardcode
- AppKit for editor, canvas, capture overlay. SwiftUI only for settings/popover content.
- No third-party dependencies
- No force unwraps (`!`)
- Config lives at `~/Documents/vibeliner/config.toml`
- Captures save to `~/Documents/vibeliner/YYYY-MM-DD_HHMMSS/`
- Read `docs/TECHNICAL_DECISIONS.md` before trying a new approach — check if it already failed
- Read `docs/VIBELINER_PRD.md` for the complete product spec

## Git

- Remote: `https://github.com/janaj2g-hub/vibeliner.git`
- Never work on `main` directly
- Never force-push `main`
- Include ticket ID in branch names, commits, and PR titles
