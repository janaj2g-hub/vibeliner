# Vibeliner Token Refactor Plan

Implementation blueprint for refactoring the codebase to use DesignTokens everywhere, eliminating hardcoded values and adding appearance support.

**Source data:**
- `docs/design-system/DESIGN_SYSTEM.md` — token inventory and consolidation proposals
- `docs/DESIGN_TOKEN_AUDIT.md` — original audit
- Line numbers verified against current source as of 2026-04-06

---

## Section 1: Token Consolidation

Do this FIRST — it establishes the final token names before wiring.

### 1A. Note Pill Tokens — Reconcile Values

The 8 unused note pill tokens have slightly different values from NotePillRenderer's hardcodes. **Decision: adopt the renderer values** (they are the shipped visual), then wire up the tokens.

| Token | Current Token Value | New Value (from renderer) | Action |
|---|---|---|---|
| `redNoteBg` | rgba(255,248,248,0.82) | rgba(255,244,244,0.72) | Update value |
| `redNoteBorder` | rgba(239,68,68,0.18) | rgba(180,180,180,0.22) | Update value (gray, not red) |
| `noteHoverBg` | rgba(255,245,245,0.88) | rgba(255,244,244,0.80) | Update value |
| `noteHoverBorder` | rgba(239,68,68,0.4) | rgba(239,68,68,0.45) | Update value |
| `noteSelectedBg` | rgba(255,245,245,0.9) | rgba(255,244,244,0.88) | Update value |
| `noteSelectedBorder` | rgba(239,68,68,0.5) | rgba(239,68,68,0.55) | Update value |
| `noteEditingBg` | rgba(255,245,245,0.92) | rgba(255,250,250,0.96) | Update value |
| `notePrefixColor` | rgba(153,27,27,0.4) | rgba(153,27,27,0.45) | Update value |

Files affected: `DesignTokens.swift` only (value updates)

### 1B. Setup Token Consolidation

Replace setup-specific color/button/font tokens with shared app tokens. Keep only geometry tokens.

**Tokens to remove from DesignTokens.swift** (after migrating SetupWindowController):

| Remove Token | Replacement | Notes |
|---|---|---|
| `setupGreen` | `copiedGreenText` with alpha 1.0, or new shared `successGreen` | Close match: setupGreen=#22C55E, copiedGreen base=rgb(22,163,74) |
| `setupGreenBadgeBg` | `copiedGreenBg` | Similar alpha |
| `setupGreenText` | `copiedGreenText` | Identical RGB base |
| `setupGreenBg` | `copiedGreenBg` | Similar |
| `setupGreenBorder` | `copiedGreenBorder` | Same alpha |
| `setupAmberBg` | (delete) | Unused, no code path |
| `setupAmberText` | Keep — unique amber, no equivalent | |
| `setupWindowBg` | System `.windowBackgroundColor` or `darkChrome` | |
| `setupTitleBarBg` | (delete) | Unused |
| `setupFooterBg` | System `.windowBackgroundColor` variant | |
| `setupBorder` | `settingsFieldBorder` or `.separatorColor` | |
| `setupFieldBg` | `settingsFieldSurface` | |
| `setupFieldBorder` | `settingsFieldBorder` | |
| `setupTextPrimary` | `.labelColor` | System color |
| `setupTextSecondary` | `.secondaryLabelColor` | System color |
| `setupTextDim` | `.tertiaryLabelColor` | System color |
| `setupGrayText` | `.quaternaryLabelColor` | System color |
| `setupGrayBg` | `settingsFrameSurface` | |
| `setupButtonFill` | `settingsPillFill` | |
| `setupButtonBorder` | `settingsPillBorder` | |
| `setupButtonText` | `settingsPillText` | |
| `setupButtonHoverBg` | (delete) | Unused |
| `setupKbdBorder` | `settingsFieldBorder` | |
| `setupKbdBg` | `settingsFieldSurface` | |
| `setupKbdText` | `.secondaryLabelColor` | System color |
| `setupWindowTitleFont` | (delete or use `settingsSectionFont` equivalent) | Unused |
| `setupPanelTitleFont` | Keep temporarily — unique 16px semibold | |
| `setupDescFont` | `settingsBodyFont` (13px regular vs 12px — close) | Or `settingsSectionFont` |
| `setupActionLabelFont` | `settingsSectionFont` or `settingsPillFont` | |
| `setupHelperFont` | Keep or create shared 11px regular | |
| `setupSmallPillFont` | `settingsPillFont` (both 11px) | |
| `setupBadgeFont` | Keep — unique 14px semibold | |
| `setupBadgeCheckFont` | Keep — unique 16px bold | |
| `setupKbdFont` | `settingsPillFont` or keep | |
| `setupShortcutHintFont` | `settingsBodyFont` | |
| `setupPathFont` | `settingsFieldFont` (both mono, similar size) | |
| `setupStatusFont` | `settingsSectionFont` | |

Files affected: `DesignTokens.swift`, `SetupWindowController.swift`

### 1C. Other Cleanup

| Token | Action | Reason |
|---|---|---|
| `settingsSectionPadding` | Remove | Unused, superseded by `settingsSectionGap` |
| `setupTitleBarBg` | Remove | Unused |
| `setupAmberBg` | Remove | Unused |
| `setupButtonHoverBg` | Remove | Unused |

### 1D. New Tokens to Create

| Token Name | Value | For |
|---|---|---|
| `popoverWidth` | 240 | PopoverViewController |
| `popoverRowHeight` | 32 | PopoverViewController |
| `popoverCornerRadius` | 10 | PopoverViewController, RecentCapturesSubmenu |
| `popoverSubmenuWidth` | 300 | RecentCapturesSubmenu |
| `notePadding` | 12 | NotePillRenderer internal padding |

---

## Section 2: File-by-File Refactoring Manifest

### NotePillRenderer.swift
**Location:** Vibeliner/Annotations/Renderers/NotePillRenderer.swift
**Hardcoded values remaining:** 14
**Appearance-aware needed:** No (renders on screenshot canvas, static)
**Estimated size:** S

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 261 | `ofSize: 8, weight: .semibold` | `DesignTokens.noteNumberFont` | Exact match |
| 262 | `NSColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 0.45)` | `DesignTokens.notePrefixColor` | After value reconciliation |
| 287 | `ofSize: 12` | `DesignTokens.noteTextFont` with italic trait | Placeholder font |
| 288 | `NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 0.35)` | New token or derive from `noteTextColor` at alpha | Placeholder text color |
| 318 | `padding: CGFloat = 12` | `DesignTokens.notePadding` | New token needed |
| 325 | `ofSize: 8, weight: .semibold` | `DesignTokens.noteNumberFont` | Duplicate of line 261 |
| 405 | `NSColor(red: 1.0, green: 0.957, blue: 0.957, alpha: 0.72)` | `DesignTokens.redNoteBg` | After value reconciliation |
| 406 | `NSColor(red: 180/255, ..., alpha: 0.22)` | `DesignTokens.redNoteBorder` | After value reconciliation |
| 411 | `NSColor(red: 1.0, green: 0.957, ..., alpha: 0.80)` | `DesignTokens.noteHoverBg` | After value reconciliation |
| 412 | `NSColor(red: 239/255, ..., alpha: 0.45)` | `DesignTokens.noteHoverBorder` | After value reconciliation |
| 417 | `NSColor(red: 1.0, green: 0.957, ..., alpha: 0.88)` | `DesignTokens.noteSelectedBg` | After value reconciliation |
| 418 | `NSColor(red: 239/255, ..., alpha: 0.55)` | `DesignTokens.noteSelectedBorder` | After value reconciliation |
| 423 | `NSColor(red: 1.0, green: 0.980, ..., alpha: 0.96)` | `DesignTokens.noteEditingBg` | After value reconciliation |
| 425 | `NSColor(red: 239/255, ..., alpha: 1.0)` | `DesignTokens.red` | Editing shadow, exact match |

### PopoverViewController.swift
**Location:** Vibeliner/Popover/PopoverViewController.swift
**Hardcoded values remaining:** 13
**Appearance-aware needed:** Yes (popover should respect system appearance)
**Estimated size:** M

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 80 | `cornerRadius: CGFloat = 10` | `DesignTokens.popoverCornerRadius` | New token |
| 149 | `NSColor(white: 1, alpha: 0.06)` | `.separatorColor` or `DesignTokens.dividerColor` | System color preferred |
| 165 | `ofSize: 13, weight: .regular` | Use system font for menu items | |
| 166 | `NSColor(white: 1, alpha: 0.85)` | `.labelColor` | Already partially fixed |
| 184 | `ofSize: 16` | System font | Arrow chevron |
| 185 | `NSColor(white: 1, alpha: 0.35)` | `.tertiaryLabelColor` | |
| 198 | `ofSize: 12, weight: .semibold` | DesignTokens font or system | Kbd pill font |
| 199 | `NSColor(white: 1, alpha: 0.55)` | `.secondaryLabelColor` | |
| 209 | `NSColor(white: 1, alpha: 0.08)` | `DesignTokens.settingsFieldSurface` or system | Kbd pill bg |
| 210 | `NSColor(white: 1, alpha: 0.12)` | `DesignTokens.settingsFieldBorder` or system | Kbd pill border |
| 212 | `cornerRadius = 5` | Token or constant | Kbd pill radius |
| 225 | `NSColor(white: 1, alpha: 0.08)` | `.separatorColor` | Popover border |
| 343 | `NSColor(white: 1, alpha: 0.1)` | `.selectedContentBackgroundColor` or token | Row hover |

### RecentCapturesSubmenu.swift
**Location:** Vibeliner/Popover/RecentCapturesSubmenu.swift
**Hardcoded values remaining:** 11
**Appearance-aware needed:** Yes (part of popover)
**Estimated size:** S

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 27 | `cornerRadius = 10` | `DesignTokens.popoverCornerRadius` | New token |
| 30 | `NSColor(white: 1, alpha: 0.08)` | `.separatorColor` or `settingsFieldBorder` | Border |
| 42 | `ofSize: 12` | System font | Empty state |
| 43 | `NSColor(white: 1, alpha: 0.3)` | `.tertiaryLabelColor` | Empty state text |
| 74 | `ofSize: 10, weight: .semibold` | System font | Header |
| 75 | `NSColor(white: 1, alpha: 0.2)` | `.quaternaryLabelColor` | Header text |
| 96 | `NSColor(white: 1, alpha: 0.06)` | `.separatorColor` | Divider |
| 133 | `ofSize: 12` | System font | Folder icon |
| 140 | `ofSize: 12` | System font | Folder label |
| 141 | `NSColor(white: 1, alpha: 0.6)` | `.secondaryLabelColor` | Folder text |
| 153 | `NSColor(white: 1, alpha: 0.1)` | `.selectedContentBackgroundColor` | Hover |

### CaptureRowView.swift
**Location:** Vibeliner/Popover/CaptureRowView.swift
**Hardcoded values remaining:** 12
**Appearance-aware needed:** Yes (part of popover)
**Estimated size:** S

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 34 | `cornerRadius = 4` | Token or constant | Thumbnail radius |
| 37 | `NSColor(white: 1, alpha: 0.06)` | `.separatorColor` | Thumbnail border |
| 53 | `ofSize: 12` | System font | Timestamp |
| 54 | `NSColor(white: 1, alpha: 0.85)` | `.labelColor` | Timestamp text |
| 60 | `ofSize: 10` | System font | Note count |
| 61 | `NSColor(white: 1, alpha: 0.25)` | `.tertiaryLabelColor` | Note count text |
| 68 | `ofSize: 10, weight: .medium` | System font | Button font |
| 70 | `rgba(175,169,236,0.12)` | `DesignTokens.chromeBorder` | Exact match |
| 71 | `cornerRadius = 6` | Token or constant | Button radius |
| 126 | `rgba(175,169,236,0.12)` | `DesignTokens.chromeBorder` | Duplicate |
| 133 | `NSColor(white: 1, alpha: 0.1)` | `.selectedContentBackgroundColor` | Row hover |
| 185 | `NSColor(white: 1, alpha: 0.15)` | Token for button hover | Button hover |

### CanvasView.swift
**Location:** Vibeliner/Editor/CanvasView.swift
**Hardcoded values remaining:** 6
**Appearance-aware needed:** No (renders on screenshot, static)
**Estimated size:** XS

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 320 | `NSColor(red: 1.0, green: 0.961, blue: 0.961, alpha: 0.92)` | New token `editingChromeTint` or keep | Editing pill tint |
| 523 | `rgba(239,68,68,0.08)` | Keep as-is or new `redGlow` token | Hover glow, only used here |
| 528 | `rgba(239,68,68,0.20)` | Keep as-is or new `redShadow` token | Hover shadow |
| 535 | `rgba(239,68,68,0.30)` | Keep as-is or new `redHalo` token | Stake halo |
| 543 | `rgba(239,68,68,0.14)` | Keep as-is | Rectangle hover fill |
| 553 | `rgba(239,68,68,0.14)` | Keep as-is | Circle hover fill (same as above) |

**Note:** These are Core Graphics drawing-context values. Pattern: `DesignTokens.red.withAlphaComponent(0.08).cgColor`. Creating individual tokens for each alpha variant has marginal value since they're only used in this one drawing method.

### ToolbarView.swift
**Location:** Vibeliner/Editor/ToolbarView.swift
**Hardcoded values remaining:** 5
**Appearance-aware needed:** No (static dark, floats over screenshot)
**Estimated size:** XS

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 477 | `cornerRadius = 14` | New token or constant | Mode toggle radius |
| 481 | `cornerRadius = 12` | New token or constant | Toggle segment radius |
| 486 | `ofSize: 9, weight: .semibold` | DesignTokens font | Toggle label |
| 545 | `cornerRadius = 14` | Same as line 477 | Copy button radius |
| 549 | `ofSize: 12, weight: .medium` | DesignTokens font | Copy button label |

### FirstUseTooltipView.swift
**Location:** Vibeliner/Editor/FirstUseTooltipView.swift
**Hardcoded values remaining:** 9
**Appearance-aware needed:** No (static dark, floats over toolbar)
**Estimated size:** XS

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 20 | `cornerRadius = 12` | Token or constant | Tooltip radius |
| 32 | `ofSize: 12, weight: .semibold` | `DesignTokens.settingsPillFont` or similar | Button font |
| 41 | `NSColor(white: 1.0, alpha: 0.06)` | `DesignTokens.dividerColor` | Exact match |
| 65 | `NSColor(white: 1.0, alpha: 0.5)` | Token | Intro text |
| 86 | `ofSize: 10, weight: .semibold` | Token | Badge font |
| 94 | `rgba(175,169,236,0.2)` | `DesignTokens.toolActiveBg` | Exact match |
| 95 | `cornerRadius = 10` | Token | Badge radius |
| 105 | `ofSize: 12` | `DesignTokens.tooltipBodyFont` | |
| 106 | `NSColor(white: 1.0, alpha: 0.45)` | Token | Description text |

### StatusPillView.swift
**Location:** Vibeliner/Editor/StatusPillView.swift
**Hardcoded values remaining:** 1
**Appearance-aware needed:** No (static dark, floats over screenshot)
**Estimated size:** XS

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 21 | `NSColor(red: 0, green: 0, blue: 0, alpha: 0.15)` | Token for shadow | Shadow color |

### SetupWindowController.swift
**Location:** Vibeliner/Setup/SetupWindowController.swift
**Hardcoded values remaining:** 1 (color) + all setup tokens to migrate
**Appearance-aware needed:** Yes (should use system colors after consolidation)
**Estimated size:** M (due to token migration)

| Line | Current Hardcoded Value | Replace With | Notes |
|---|---|---|---|
| 292 | `rgba(83, 74, 183, 0.08)` | `DesignTokens.setupButtonFill` then migrate to `settingsPillFill` | Purple bg for active badge |

Plus: all `DesignTokens.setup*` references need migration to shared tokens (see Section 1B).

---

## Section 3: Phased Implementation Order

### Phase 1 — Token Consolidation (do first, blocks everything)
1. Update 8 note pill token values in DesignTokens.swift to match renderer
2. Create 5 new tokens (popoverWidth, popoverRowHeight, popoverCornerRadius, popoverSubmenuWidth, notePadding)
3. Remove 4 dead tokens (settingsSectionPadding, setupTitleBarBg, setupAmberBg, setupButtonHoverBg)
4. Update design system docs
- **Size:** S
- **Risk:** Low — value updates only, no visual change
- **Dependencies:** None

### Phase 2 — Wire Up Unused Tokens (easy wins, low risk)
1. NotePillRenderer: replace 14 hardcodes with reconciled tokens
2. ToolbarView: apply `toolbarBlur` (and wire `toolbarButtonFont` if size matches)
3. StatusPillView: apply `statusPillBlur`
4. FirstUseTooltipView: apply `tooltipBodyFont`, `tooltipLabelFont`, replace hardcoded colors with tokens
5. SetupWindowController: apply `setupWindowRadius`, fix the one hardcoded purple value
- **Size:** S per file, 2-3 tickets
- **Risk:** Low — replacing hardcodes with identical-value tokens
- **Dependencies:** Phase 1 (note pill values must be reconciled first)

### Phase 3 — Tokenize Popover + Appearance Support (highest user-facing risk)
1. PopoverViewController: replace all `NSColor(white:)` with system colors, apply new popover dimension tokens
2. RecentCapturesSubmenu: replace all hardcodes with system colors and tokens
3. CaptureRowView: replace all hardcodes, wire `chromeBorder` for purple button bg
4. Add `viewDidChangeEffectiveAppearance` or use `NSColor(name:nil)` where needed
5. Test both appearances
- **Size:** M
- **Risk:** Medium — appearance changes are the most visible regressions
- **Dependencies:** Phase 1 (new popover tokens must exist)

### Phase 4 — Setup Token Migration
1. Migrate SetupWindowController from setup* tokens to shared tokens + system colors
2. Remove all setup* color/font tokens from DesignTokens.swift (keep geometry)
3. Setup window becomes appearance-aware
- **Size:** M
- **Risk:** Medium — large number of token references to update
- **Dependencies:** Phase 1

### Phase 5 — Tokenize Remaining Hardcodes
1. CanvasView: use `DesignTokens.red.withAlphaComponent(x).cgColor` pattern for drawing colors
2. ToolbarView: tokenize internal corner radii and font sizes
3. FirstUseTooltipView: tokenize remaining dimensions
- **Size:** S
- **Risk:** Low — these are static dark surfaces
- **Dependencies:** Phases 2-4

### Phase 6 — Verification Pass
1. Test every UI surface in both light and dark mode
2. Verify annotation rendering on screenshots
3. Verify popover, toolbar, settings, setup
4. Update design system docs to reflect final state
- **Size:** S
- **Risk:** N/A — testing only
- **Dependencies:** All prior phases

---

## Section 4: Appearance Mode Strategy

| Surface | Strategy | Reasoning |
|---|---|---|
| Capture overlay | Static dark | Always covers screen with dim overlay |
| Editor toolbar | Static dark | Floats over screenshot, frosted glass always dark |
| Status pill | Static dark | Floats over screenshot |
| Annotation marks (pin, arrow, rect, circle, freehand) | Static | Drawn on screenshot content, appearance-independent |
| Note pills | Static | Drawn on screenshot canvas |
| First-use tooltip | Static dark | Floats over toolbar, dark context |
| Popover menu | Appearance-aware | Standard macOS popover, should respect system preference |
| Recent captures submenu | Appearance-aware | Part of popover |
| Settings window | Appearance-aware | Already done — uses NSColor(name:nil) |
| Setup window | Appearance-aware | After migration to shared tokens, inherits appearance support |

**Implementation patterns:**
- **Static surfaces:** Use `DesignTokens.tokenName` directly
- **Appearance-aware surfaces (AppKit):** Use `NSColor(name:nil) { appearance in ... }` for dynamic tokens, or system colors (`.labelColor`, `.separatorColor`)
- **Appearance-aware surfaces (SwiftUI):** Use `Color(nsColor:)` with appearance-aware NSColor tokens
- **Core Graphics contexts:** Convert via `tokenName.cgColor` or `tokenName.withAlphaComponent(x).cgColor`

---

## Section 5: Risk Assessment

| Phase | Risk | What Could Break | Mitigation |
|---|---|---|---|
| Phase 1: Token consolidation | Low | Nothing — value updates to match shipped visual | Diff token values carefully |
| Phase 2: Wire unused tokens | Low | Visual regression if token values differ from hardcodes | Reconciled in Phase 1 |
| Phase 3: Popover appearance | **Medium** | Popover unreadable in light mode, wrong contrast, broken hover states | Test both appearances manually |
| Phase 4: Setup migration | **Medium** | Setup window visual regression, broken layout | Compare screenshots before/after |
| Phase 5: Remaining hardcodes | Low | Minor visual differences in CanvasView hover states | These are subtle effects |
| Phase 6: Verification | None | Testing phase | |

**Highest-risk files:**
1. **PopoverViewController** — most visible to users, appearance change is dramatic
2. **SetupWindowController** — many token references to migrate, first-run experience
3. **NotePillRenderer** — core annotation rendering, any regression affects all annotations

---

## Section 6: Suggested Ticket Breakdown

| # | Title | Size | Phase | Dependencies | Files |
|---|---|---|---|---|---|
| 1 | `infra: Reconcile note pill token values + create popover tokens` | S | 1 | None | DesignTokens.swift |
| 2 | `fix: Wire unused tokens in NotePillRenderer` | S | 2 | Ticket 1 | NotePillRenderer.swift |
| 3 | `fix: Wire unused tokens in ToolbarView, StatusPillView, FirstUseTooltipView` | S | 2 | Ticket 1 | ToolbarView.swift, StatusPillView.swift, FirstUseTooltipView.swift |
| 4 | `feat: Tokenize popover + appearance support` | M | 3 | Ticket 1 | PopoverViewController.swift, RecentCapturesSubmenu.swift, CaptureRowView.swift |
| 5 | `refactor: Migrate setup window to shared tokens` | M | 4 | Ticket 1 | SetupWindowController.swift, DesignTokens.swift |
| 6 | `polish: Tokenize CanvasView drawing colors + toolbar dimensions` | S | 5 | None | CanvasView.swift, ToolbarView.swift, FirstUseTooltipView.swift |
| 7 | `test: Light/dark mode verification across all surfaces` | S | 6 | Tickets 1-6 | All UI files |

**Total estimated work:** 7 tickets (2 S infra, 2 S fix, 1 M feat, 1 M refactor, 1 S test)
