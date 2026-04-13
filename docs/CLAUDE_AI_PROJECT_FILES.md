# Vibeliner — Claude.ai Project Files Update Guide

This document lists which Claude.ai project files need updating to match the current repo state (post-VIB-402, post-VIB-429).

---

## Files that need updating

### 1. System Instructions (Claude.ai project settings)

**Status:** Replace with `docs/CLAUDE_AI_SYSTEM_INSTRUCTIONS.md`

**What changed:**
- Annotation tools: now 6 (added Line tool with shortcut 7, prompt tag `[line]`)
- File structure: added LineTool.swift, LineRenderer.swift, FilmstripGridView.swift, SettingsUI.swift, VisualTestHarness.swift, main.swift, TourStepData.swift, SelectTool.swift, BadgeRenderer.swift, NotePillRenderer.swift
- Tool registry section added (VIB-420 centralized registration)
- CaptureSession model section added
- Stop-if-Linear-auth-fails rule added
- Run command corrected to `open dist/Vibeliner.app`

### 2. VIBELINER_PRD.md (if used as a project file)

**Status:** Already updated in the repo

**What changed in VIB-429:**
- Section 4 TOC: added Line to tool list
- Section 4F: new Line Tool section
- Section 5 toolbar layout: added `[Line]` between Arrow and Rect
- Section 5 keyboard shortcuts: updated 1-6 → 1-7, added `7=Line`
- Section 8 default tool descriptions table: added Line row

### 3. Design_System_Rules.md (if used as a project file)

**Status:** Review against `docs/design-system/DESIGN_SYSTEM.md`

**What changed in VIB-429:**
- Added 31 previously undocumented tokens (tour buttons, role preset colors, popover buttons, settings segmented fonts, tour editor frame, tour LLM dimensions)
- Removed 2 phantom tokens (`minCellWidth`, `tourEditorFrameBgLight`) that were documented but not in code
- Added Line Tool section (no new tokens — reuses Arrow's tokens)

### 4. Linear_Conventions.md (if used as a project file)

**Status:** No changes needed — the Linear state IDs and conventions are unchanged

### 5. Ticket-Making_Instructions.md (if used as a project file)

**Status:** Review prompt template

**Potential changes:**
- Design tokens section should reference 6 annotation tools
- Prompt template should mention reading `docs/TECHNICAL_DECISIONS.md`

### 6. VERIFICATION_RULES.md (if used as a project file)

**Status:** No changes needed

---

## Summary of repo-level doc changes in VIB-429

| File | Action |
|------|--------|
| `CLAUDE.md` | Fixed file tree (added 8 missing files), counts updated to 6 tools/renderers |
| `AGENTS.md` | No changes needed (doesn't enumerate tools) |
| `README.md` | Already updated in VIB-402 (6 tools) |
| `docs/VIBELINER_PRD.md` | Added Line to Sections 4, 5, 8 |
| `docs/design-system/DESIGN_SYSTEM.md` | Added 31 undocumented tokens, removed 2 phantoms, added Line Tool section |
| `docs/design-system/Design_Tester.html` | Already updated in VIB-402 (Line tool button) |
| `docs/TECHNICAL_DECISIONS.md` | No changes needed |
| `docs/investigations/` | Consolidated: moved SCALABILITY_AUDIT.md and tour-audit.md from root |
| `docs/CLAUDE_AI_SYSTEM_INSTRUCTIONS.md` | **New** — drop-in replacement for Claude.ai system instructions |
| `docs/CLAUDE_AI_PROJECT_FILES.md` | **New** — this file |
