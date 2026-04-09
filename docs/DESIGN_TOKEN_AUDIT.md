# Vibeliner Design Token Audit

**Date:** 2026-04-05
**Scope:** Full codebase audit of hardcoded colors, dimensions, and fonts vs. DesignTokens coverage.

---

## Executive Summary

DesignTokens.swift is well-structured with ~90 tokens across colors, dimensions, and fonts. However, the codebase has **~60+ hardcoded color values** across 12 files, **18 unused tokens** that have hardcoded duplicates in the actual code, and **no appearance-aware tokens** for popover, toolbar, or annotation rendering. The Settings window was recently made appearance-reactive, but the Popover, Editor toolbar, and annotation renderers still use dark-only hardcoded values.

---

## Token Coverage by Area

### Well-Tokenized (low risk)
| Area | Files | Status |
|------|-------|--------|
| Capture overlay | CrosshairView, DimensionLabelView | Uses `crosshairThickness`, `purpleLight`, etc. |
| Settings window | SettingsWindowController, tabs, SettingsUI | Uses `settings*` tokens, now appearance-reactive |
| Setup window | SetupWindowController | Has dedicated `setup*` token family |
| Annotation tools | Pin/Arrow/Rect/Circle/Freehand tools | Uses `strokeWidth`, `red`, `redFill` |

### Partially Tokenized (medium risk)
| Area | Files | Issue |
|------|-------|-------|
| Editor toolbar | ToolbarView.swift | Uses some tokens (`darkChrome`, `chromeBorder`, `toolActiveBg`) but has hardcoded dimensions (corner radii, padding magic numbers) |
| Note pills | NotePillRenderer.swift | Tokens exist (`redNoteBg`, `noteHoverBg`, etc.) but **are never used** — the renderer has its own hardcoded values |
| Status pill | StatusPillView.swift | Uses `darkChromeStatus`, `statusPillFont` but has hardcoded shadow color |

### Not Tokenized (high risk)
| Area | Files | Issue |
|------|-------|-------|
| Popover menu | PopoverViewController, RecentCapturesSubmenu, CaptureRowView | All `NSColor(white:1,alpha:X)` — dark-only, no tokens |
| First-use tooltip | FirstUseTooltipView | Hardcoded whites, dimensions, fonts |
| Canvas drawing | CanvasView | Red annotation colors with varying alpha hardcoded in draw() |

---

## Hardcoded Values Inventory

### Popover Menu (3 files, ~25 hardcodes)

**PopoverViewController.swift:**
| Line | Value | Type | What It Does |
|------|-------|------|-------------|
| 149 | `NSColor(white: 1, alpha: 0.06).cgColor` | Color | Divider background |
| 165 | `NSColor(white: 1, alpha: 0.85)` | Color | Row label text (fixed to .labelColor) |
| 184 | `NSColor(white: 1, alpha: 0.35)` | Color | Arrow chevron (fixed to .tertiaryLabelColor) |
| 199 | `NSColor(white: 1, alpha: 0.55)` | Color | Kbd pill text (fixed to .secondaryLabelColor) |
| 209 | `NSColor(white: 1, alpha: 0.08).cgColor` | Color | Kbd pill bg |
| 210 | `NSColor(white: 1, alpha: 0.12).cgColor` | Color | Kbd pill border |
| 92 | `rowH=32, rowGap=2, vPad=6, hPad=6, dividerH=9` | Dimensions | Layout constants |
| 80 | `cornerRadius: 10` | Dimension | Popover corner radius |
| 40 | `popWidth: 240` | Dimension | Popover width |

**RecentCapturesSubmenu.swift:**
| Line | Value | Type | What It Does |
|------|-------|------|-------------|
| 30 | `NSColor(white: 1, alpha: 0.08).cgColor` | Color | Border |
| 43 | `NSColor(white: 1, alpha: 0.3)` | Color | Empty state text |
| 75 | `NSColor(white: 1, alpha: 0.2)` | Color | Header text |
| 96 | `NSColor(white: 1, alpha: 0.06).cgColor` | Color | Divider |
| 141 | `NSColor(white: 1, alpha: 0.6)` | Color | Label text |
| 153 | `NSColor(white: 1, alpha: 0.1).setFill()` | Color | Hover state |
| 23-38 | `submenuW=300, rowH=42, openFolderH=34` | Dimensions | Layout constants |

**CaptureRowView.swift:**
| Line | Value | Type | What It Does |
|------|-------|------|-------------|
| 37 | `NSColor(white: 1, alpha: 0.06).cgColor` | Color | Thumbnail border |
| 54 | `NSColor(white: 1, alpha: 0.85)` | Color | Timestamp text |
| 61 | `NSColor(white: 1, alpha: 0.25)` | Color | Note count text |
| 70 | `rgba(175, 169, 236, 0.12).cgColor` | Color | Prompt button bg (=chromeBorder value) |
| 126 | `rgba(175, 169, 236, 0.12).cgColor` | Color | Button hover |
| 133 | `NSColor(white: 1, alpha: 0.1).setFill()` | Color | Row hover |

**Assessment:** All popover colors are dark-only. They need to either use system colors (`.labelColor`, `.separatorColor`) or become appearance-aware tokens. The popover menu text was partially fixed in the last commit but RecentCapturesSubmenu and CaptureRowView are still fully hardcoded.

**Recommendation:** Replace with system colors where possible (labels, borders, separators). For purple tints, use existing `purpleButton*` or `chromeBorder` tokens.

---

### Note Pill Renderer (1 file, ~12 hardcodes)

**NotePillRenderer.swift** has hardcoded state colors that **duplicate tokens that already exist but are never used:**

| Hardcoded Value | Existing Unused Token |
|----------------|----------------------|
| `rgba(1.0, 0.957, 0.957, 0.72)` default bg | `redNoteBg` = `rgba(255, 248, 248, 0.82)` (close but different alpha) |
| `rgba(180, 180, 180, 0.22)` default border | `redNoteBorder` = `rgba(239, 68, 68, 0.18)` (different color entirely) |
| `rgba(1.0, 0.957, 0.957, 0.80)` hover bg | `noteHoverBg` = `rgba(255, 245, 245, 0.88)` (close) |
| `rgba(239, 68, 68, 0.45)` hover border | `noteHoverBorder` = `rgba(239, 68, 68, 0.4)` (close) |
| `rgba(1.0, 0.957, 0.957, 0.88)` selected bg | `noteSelectedBg` = `rgba(255, 245, 245, 0.9)` (close) |
| `rgba(239, 68, 68, 0.55)` selected border | `noteSelectedBorder` = `rgba(239, 68, 68, 0.5)` (close) |
| `rgba(1.0, 0.980, 0.980, 0.96)` editing bg | `noteEditingBg` = `rgba(255, 245, 245, 0.92)` (close) |
| `rgba(153, 27, 27, 0.45)` prefix color | `notePrefixColor` = `rgba(153, 27, 27, 0.4)` (close) |

Also has hardcoded: `ofSize: 8` (should use `noteNumberFont`), `padding = 12`.

**Assessment:** The tokens were created to match the prototype but the renderer was never updated to use them. The values are slightly different (the renderer was likely tuned by eye after the tokens were defined).

**Recommendation:** Decide which values are correct (token or renderer), update the tokens to match, then replace the hardcodes in the renderer. This is an easy win since the tokens already exist.

---

### Canvas Drawing (1 file, ~6 hardcodes)

**CanvasView.swift** — red annotation colors with varying alpha in drawing context:
| Line | Value | Purpose |
|------|-------|---------|
| 523 | `rgba(239, 68, 68, 0.08)` | Fill glow |
| 528 | `rgba(239, 68, 68, 0.20)` | Shadow |
| 535 | `rgba(239, 68, 68, 0.3)` | Halo stroke |
| 543 | `rgba(239, 68, 68, 0.14)` | Rectangle fill |
| 553 | `rgba(239, 68, 68, 0.14)` | Circle fill |

Also: `rgba(1.0, 0.961, 0.961, 0.92)` for chrome tint (editing state).

**Assessment:** These are all variants of `DesignTokens.red` at different alpha levels. They're used in Core Graphics drawing contexts where `NSColor` dynamic resolution isn't available, so they need to be static.

**Recommendation:** Keep as-is. These are drawing-specific alpha variants that don't need to change with appearance (they're drawn on top of screenshot content, not on window chrome). Could create `redGlow`, `redShadow`, `redHalo` tokens for documentation, but the value is marginal since they're only used in one file.

---

### Editor Toolbar (1 file, ~10 hardcodes)

**ToolbarView.swift:**
| Line | Value | Type | Purpose |
|------|-------|------|---------|
| 20 | `cornerRadius = 14` | Dimension | Toggle button radius |
| 32 | `cornerRadius = 14` | Dimension | Tool button radius |
| 58 | `cornerRadius = 12` | Dimension | Highlight view radius |
| 81 | magic number `30` | Dimension | Spacing after close button |
| 486 | `ofSize: 9` | Font | IDE/App toggle label |
| 549 | `ofSize: 12` | Font | Toggle label |
| 558 | `padding = 28` | Dimension | Toggle button padding |

**Assessment:** These dimensions define the toolbar's internal layout. They're only used in ToolbarView and unlikely to be reused elsewhere. The toolbar has a unique visual identity (frosted glass pill) that doesn't share dimensions with other UI areas.

**Recommendation:** Low priority. Could create `toolbarButtonRadius`, `toolbarToggleFontSize` tokens for documentation, but these won't be shared across features.

---

### First-Use Tooltip (1 file, ~8 hardcodes)

**FirstUseTooltipView.swift:**
| Line | Value | Type |
|------|-------|------|
| 41 | `NSColor(white: 1.0, alpha: 0.06).cgColor` | Color — divider |
| 65 | `NSColor(white: 1.0, alpha: 0.5)` | Color — intro text |
| 94 | `rgba(175, 169, 236, 0.2).cgColor` | Color — badge bg |
| 106 | `NSColor(white: 1.0, alpha: 0.45)` | Color — field text |
| 20 | `cornerRadius = 12` | Dimension |
| 26 | `width = 480` | Dimension |

**Assessment:** This is a one-time tooltip that appears on first launch. It uses the same dark chrome aesthetic as the toolbar. Low reuse potential.

**Recommendation:** Low priority. Could replace `NSColor(white:1,alpha:X)` with system colors for appearance safety, but the tooltip is toolbar-adjacent and always appears over the screenshot (dark context).

---

### Setup Window (1 file, 1 hardcode outside tokens)

**SetupWindowController.swift:**
| Line | Value | Purpose |
|------|-------|---------|
| 292 | `rgba(83, 74, 183, 0.08).cgColor` | Purple background (should use `setupButtonFill` or `DesignTokens.purpleDark`) |

**Assessment:** The setup window is very well tokenized — it has its own `setup*` token family (~25 tokens). This single hardcode is a miss.

**Recommendation:** Replace with `DesignTokens.setupButtonFill` (same value).

---

## Unused Tokens (18 total)

These tokens are defined in DesignTokens.swift but never referenced anywhere in the codebase:

### Colors (9 unused)
| Token | Should Keep? | Reason |
|-------|-------------|--------|
| `redNoteBg` | **Yes** — fix NotePillRenderer to use it | Correct value exists, renderer uses hardcoded duplicate |
| `redNoteBorder` | **Yes** — fix NotePillRenderer to use it | Same |
| `noteHoverBg` | **Yes** — fix NotePillRenderer to use it | Same |
| `noteHoverBorder` | **Yes** — fix NotePillRenderer to use it | Same |
| `noteSelectedBg` | **Yes** — fix NotePillRenderer to use it | Same |
| `noteSelectedBorder` | **Yes** — fix NotePillRenderer to use it | Same |
| `noteEditingBg` | **Yes** — fix NotePillRenderer to use it | Same |
| `notePrefixColor` | **Yes** — fix NotePillRenderer to use it | Same |
| `darkChromePopover` | **Maybe** — popover uses NSVisualEffectView instead | Could remove if popover stays vibrancy-based |

### Dimensions (3 unused)
| Token | Should Keep? | Reason |
|-------|-------------|--------|
| `toolbarBlur` | **Yes** — apply in ToolbarView | Blur radius should be tokenized |
| `statusPillBlur` | **Yes** — apply in StatusPillView | Same |
| `settingsSectionPadding` | **Maybe** — settings spacing uses `settingsSectionGap` instead | Clarify naming vs. gap |

### Fonts (4 unused)
| Token | Should Keep? | Reason |
|-------|-------------|--------|
| `noteNumberFont` | **Yes** — fix NotePillRenderer to use it | Renderer has hardcoded `ofSize: 8` instead |
| `toolbarButtonFont` | **Yes** — apply in ToolbarView | Toolbar has hardcoded `ofSize: 9` and `ofSize: 12` |
| `tooltipBodyFont` | **Yes** — apply in FirstUseTooltipView | Tooltip has hardcoded fonts |
| `tooltipLabelFont` | **Yes** — apply in FirstUseTooltipView | Same |

### Setup (2 unused)
| Token | Should Keep? | Reason |
|-------|-------------|--------|
| `setupWindowRadius` | **Yes** — apply in SetupWindowController | Should be used for window corner radius |
| `setupWindowTitleFont` | **Yes** — apply in SetupWindowController | Should be used for window title |

---

## Missing Tokens (should be created)

### For Popover Reuse
| Proposed Token | Value (Dark) | Value (Light) | Used By |
|---------------|-------------|--------------|---------|
| `popoverWidth` | 240 | 240 | PopoverViewController |
| `popoverRowHeight` | 32 | 32 | PopoverViewController |
| `popoverCornerRadius` | 10 | 10 | PopoverViewController |
| `popoverSubmenuWidth` | 300 | 300 | RecentCapturesSubmenu |

### For Cross-Feature Button Reuse
The `purpleButton*` tokens (`purpleButton`, `purpleButtonHover`, `purpleButtonBg`, `purpleButtonBgHover`) are currently only used in the editor toolbar copy buttons. The `settingsPill*` tokens serve a similar purpose in settings. These should be unified into a single "action button" token family that works everywhere:

| Current Token | Editor Toolbar | Settings | Popover |
|--------------|---------------|----------|---------|
| `purpleButton` (outline) | Yes | No (uses `settingsPillBorder`) | No |
| `purpleButtonBg` (fill) | Yes | No (uses `settingsPillFill`) | No |
| `settingsPillBorder` | No | Yes | No |
| `settingsPillFill` | No | Yes | No |

**Recommendation:** Keep both families. The editor toolbar buttons need higher contrast (they sit on frosted glass) while settings pills sit on window chrome. Document the distinction so future features pick the right family.

---

## Appearance Mode Readiness

### Fully Appearance-Aware
- Settings window (all `settings*` tokens use `NSColor(name:nil)` + `viewDidChangeEffectiveAppearance`)
- System colors used in Settings (`.labelColor`, `.secondaryLabelColor`, `.separatorColor`)
- PopoverViewController text labels (recently fixed to system colors)

### Dark-Only (will break in light mode)
- RecentCapturesSubmenu — all hardcoded white-on-dark
- CaptureRowView — all hardcoded white-on-dark
- FirstUseTooltipView — hardcoded white-on-dark (acceptable — always on dark toolbar)
- Editor toolbar — hardcoded white-on-dark (acceptable — always on dark frosted glass)
- Canvas/annotation rendering — hardcoded red-on-screenshot (acceptable — appearance-independent)

### Static but Safe
- Setup window — has its own `setup*` tokens but they're all dark-mode only. The setup window doesn't need light mode since it's a one-time flow, but if appearance toggle is accessible before setup completes, this could be an issue.

---

## Priority Recommendations

### P0 — Fix Now (broken or inconsistent)
1. **Wire up unused note pill tokens** in NotePillRenderer — tokens exist, renderer ignores them
2. **Fix RecentCapturesSubmenu + CaptureRowView** — these are visible in light mode and currently unreadable (same issue as PopoverViewController was)

### P1 — Fix Soon (tech debt, blocks reuse)
3. **Create popover dimension tokens** — needed before adding new popover features
4. **Unify or document button token families** — `purpleButton*` vs `settingsPill*` distinction should be clear for new features
5. **Apply unused font/dimension tokens** — `toolbarBlur`, `noteNumberFont`, `toolbarButtonFont`, etc.

### P2 — Fix Eventually (nice to have)
6. **Tokenize toolbar internal dimensions** — corner radii, spacing magic numbers
7. **Tokenize tooltip dimensions and colors** — low reuse but good hygiene
8. **Setup window appearance support** — make `setup*` tokens appearance-aware if the appearance toggle becomes accessible before setup
