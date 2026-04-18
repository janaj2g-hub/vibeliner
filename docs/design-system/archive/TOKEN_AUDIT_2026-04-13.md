# Design Token Audit

> Generated 2026-04-13 for VIB-437 (Design Token Consolidation).
> Source files: `Vibeliner/Design/DesignTokens*.swift`
> Method: `grep -r` of each `static let/var/func` across all `.swift` files, excluding `Design/` folder.

---

## 1. Dead Tokens

Tokens defined but never referenced outside their definition file. Safe to delete.

### DesignTokens.swift (4 tokens)

| Token | Value | Notes |
|---|---|---|
| `purpleButton` | `#A796EB` (static dark-only) | Legacy copy-button color, superseded by `toolbarPurpleButton*` family |
| `purpleButtonBg` | `rgba(116,97,194,0.25)` (static dark-only) | Legacy copy-button fill, superseded by `toolbarPurpleButtonBg` |
| `tooltipDarkBg` | `rgba(28,28,32,0.96)` | Unshipped tooltip feature — never consumed |
| `tooltipDarkBorder` | `rgba(255,255,255,0.10)` | Unshipped tooltip feature — never consumed |

### DesignTokens+Settings.swift (1 function)

| Token | Type | Notes |
|---|---|---|
| `roleBorderColor(forRoleName:)` | `static func` | 0 call sites. Related `roleColor(forHex:)` and `roleBgColor(forHex:)` ARE alive. |

### DesignTokens+SetupTour.swift (1 token)

| Token | Value | Notes |
|---|---|---|
| `tourNextButtonPaddingH` | `18` (CGFloat) | Dimension never consumed by any view |

### DesignTokens+TourIllustrations.swift (6 tokens)

| Token | Value | Notes |
|---|---|---|
| `tourIllustrationBgTint` | `= tourIllustrationPaneBg` | Dead alias — duplicates another token and is itself unused |
| `tourIllustrationGlow` | `dynamicColor(dark: rgba(175,169,236,0.06), light: rgba(83,74,183,0.05))` | Illustration glow layer never consumed |
| `tourPromptSheetNumber` | `#F87171` | Prompt-sheet line-number color, never consumed |
| `tourChipPaddingV` | `3` (CGFloat) | Vertical chip padding, never consumed (H is alive) |
| `tourAddCellMinHeight` | `70` (CGFloat) | Add-cell minimum height, never consumed |
| `tourAddCellLabelFont` | `NSFont.systemFont(ofSize: 10, weight: .semibold)` | Add-cell label font, never consumed |

### False positives (expected dead but alive)

| Token | Consuming file | Why alive |
|---|---|---|
| `redNoteBg` | `Tour/Illustrations/AnnotationMarkViews.swift:49` | Used for red-tinted note styling in tour |
| `redNoteBorder` | `Tour/Illustrations/AnnotationMarkViews.swift:51` | Used for red-tinted note border in tour |

---

## 2. Duplicate Families

Groups of tokens that serve the same visual purpose (purple-accented CTA, segmented control, note pill) but with different values per surface.

### Family 1: Purple Button (5 groups, ~14 color tokens)

All provide a "purple-accented action button" but each surface defines its own set.

| Group | Tokens | Dark border | Dark fill | Dark text | Surfaces |
|---|---|---|---|---|---|
| **Legacy (DEAD)** | `purpleButton`, `purpleButtonBg` | #A796EB | rgba(116,97,194,0.25) | #A796EB | None (dead) |
| **Toolbar** | `toolbarPurpleButton{Border,Bg,Text}` + hover variants | #A796EB | rgba(116,97,194,0.25) | #A796EB | `ToolbarButtons.swift`, `TourMiniToolbar.swift` |
| **Settings pill** | `settingsPill{Border,Fill,Text}` | rgba(175,169,236,0.36) | rgba(175,169,236,0.10) | #AFA9EC | `SettingsControls.swift`, `PromptTabView.swift`, `PromptTabCustomViews.swift`, `AboutTabView.swift`, `CaptureRowView.swift` |
| **Setup** | `setupButton{Fill,Border,Text}` | rgba(175,169,236,0.55) | rgba(175,169,236,0.10) | #6F69DF | `SetupComponents.swift`, `SetupWindowController+UIFactories.swift`, `HarnessPreviewSurfaces.swift` |
| **Popover copy** | `popoverCopyButton{Text,Bg}` | — | rgba(175,169,236,0.10) | #AFA9EC | `CaptureRowView.swift` |

**Key divergences:** Alpha values differ across groups. Hue families vary: toolbar uses `#A796EB`, settings pill uses `#AFA9EC`/`#7267DD`, setup uses `#6F69DF`. These could potentially unify into a single parametric set.

### Family 2: Segmented Control (2 groups, ~9 tokens)

| Group | Tokens | Surfaces |
|---|---|---|
| **Toolbar toggle** | `toolbarToggleBg`, `toolbarToggleActiveBg`, `toolbarToggleInactiveText` | `ToolbarButtons.swift`, `SettingsControls.swift`, `TourMiniToolbar.swift` |
| **Settings segmented** | `settingsSegmentedTrack`, `settingsSegmentedActive`, `settingsSegmentedBorder`, `settingsSegmentedActiveBorder`, `settingsSegmentedActiveText`, `settingsSegmentedInactiveText` | `SettingsControls.swift`, `SettingsUI.swift` |

**Note:** After VIB-436, the toolbar toggle and settings segmented are already unified in `SettingsControls.swift` (both surfaces use the same `SegmentedControl` component). The token split remains for now.

### Family 3: Note Pill (2 groups, ~6 tokens)

| Group | Tokens | Surfaces |
|---|---|---|
| **Red note (legacy)** | `redNoteBg` (rgba(255,248,248,0.82)), `redNoteBorder` (rgba(239,68,68,0.18)) | `AnnotationMarkViews.swift` (tour illustration only) |
| **Editor note (stateful)** | `editorNoteSurface{Default,Hover,Selected,Editing}`, `editorNoteBorder{Default,Hover,Selected}`, `editorNoteEditingGlow` | `NotePillView.swift`, `CanvasView+NoteEditing.swift` |

**Note:** `redNote*` are used only in tour illustrations for static display. `editorNote*` are used for the live interactive note pills with hover/selected/editing states. They serve different purposes (static vs interactive) but share the same visual identity.

---

## 3. Tour Aliases

Tokens whose assigned value is literally another DesignTokens property rather than an `NSColor()` constructor. These add indirection without adding semantic value — consumers could reference the core token directly.

| Alias token | Core token it references | File | Alive? | Consuming files |
|---|---|---|---|---|
| `tourIllustrationBgTint` | `tourIllustrationPaneBg` | TourIllustrations:9 | No (DEAD) | — |
| `tourMiniScreenshotBadgeBg` | `red` | TourIllustrations:180 | Yes | `TourMiniScreenshot.swift` |
| `tourMiniScreenshotMarkColor` | `red` | TourIllustrations:182 | Yes | `TourMiniScreenshot.swift` |
| `tourFilmstripCellBadgeBg` | `red` | TourIllustrations:237 | Yes | `TourFilmstripCell.swift` |
| `tourGhostButtonText` | `tourTextDim` | SetupTour:170 | Yes | `TourWindowController+Content.swift` |
| `tourGhostButtonHoverText` | `tourTextSecondary` | SetupTour:177 | Yes | `TourWindowController+Content.swift` |
| `settingsSegmentedActiveText` | `settingsPillText` | Settings:87 | Yes | `SettingsControls.swift`, `SettingsUI.swift` |
| `editorNoteEditingGlow` | `red` | Settings:231 | Yes | `CanvasView+NoteEditing.swift` |

---

## 4. Summary

| Metric | Count |
|---|---|
| **Total tokens defined** | 401 `let/var` + 6 `func` = 407 |
| **Dead tokens** | 12 (11 `let/var` + 1 `func`) |
| **Duplicate family members** | ~29 tokens across 3 families |
| **Tour aliases** | 8 (1 also dead) |
| **Estimated reduction (dead only)** | 12 tokens removed (~3% of total) |
| **Estimated reduction (dead + alias consolidation)** | 19 tokens removed (~5% of total) |
| **Estimated reduction (dead + aliases + family unification)** | ~30-40 tokens removed (~7-10% of total) |

### Files by dead token count

| File | Dead tokens |
|---|---|
| `DesignTokens+TourIllustrations.swift` | 6 |
| `DesignTokens.swift` | 4 |
| `DesignTokens+Settings.swift` | 1 |
| `DesignTokens+SetupTour.swift` | 1 |
| `DesignTokens+Layout.swift` | 0 |
