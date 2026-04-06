# Vibeliner Design System

**Source of truth:** `Vibeliner/Design/DesignTokens.swift`
**Last updated:** 2026-04-06 (post-refactor: note pill reconciliation, setup migration, popover tokens)

---

## How to Use This File

1. Before adding any color, dimension, or font value, search this document for an existing token.
2. Use the token from `DesignTokens.swift` -- never hardcode values in view code.
3. If no token exists, propose one in the PR description and add it here after merge.

---

## Color Tokens

### Purple Family (brand, interactive)

| Token | Value | Appearance | Status | Used By |
|-------|-------|-----------|--------|---------|
| `purpleLight` | `#AFA9EC` | Static | Active | Crosshair, selection border, active tool highlight |
| `purpleDark` | `#534AB7` | Static | Active | Dimension label bg, settings accents, setup badge active |
| `purpleButton` | `#A796EB` | Static | Active | Copy button outline/text, setup small pill border |
| `purpleButtonHover` | `#C4B8F5` | Static | Active | Copy button hover state |
| `purpleButtonBg` | `rgba(116,97,194,0.25)` | Static | Active | Copy button fill, setup small pill bg |
| `purpleButtonBgHover` | `rgba(116,97,194,0.35)` | Static | Active | Copy button hover fill |

### Red Family (annotations -- static, appearance-independent)

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `red` | `#EF4444` | Active | All annotation marks, editing border/shadow (also used via `.withAlphaComponent()` in CanvasView) |
| `redFill` | `rgba(239,68,68,0.06)` | Active | Shape fills |
| `redNoteBg` | `rgba(255,244,244,0.72)` | Active | Note pill default background |
| `redNoteBorder` | `rgba(180,180,180,0.22)` | Active | Note pill default border (gray, not red) |
| `noteHoverBg` | `rgba(255,244,244,0.80)` | Active | Note pill hover background |
| `noteHoverBorder` | `rgba(239,68,68,0.45)` | Active | Note pill hover border |
| `noteSelectedBg` | `rgba(255,244,244,0.88)` | Active | Note pill selected background |
| `noteSelectedBorder` | `rgba(239,68,68,0.55)` | Active | Note pill selected border |
| `noteEditingBg` | `rgba(255,250,250,0.96)` | Active | Note pill editing background |
| `notePrefixColor` | `rgba(153,27,27,0.45)` | Active | Note pill number prefix color |
| `noteTextColor` | `#7F1D1D` | Active | Note pill text color |

### Green Family (success/copied states -- shared across editor, setup, popover)

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `copiedGreen` | `rgba(22,163,74,0.9)` | Active | Copied state icon/badge, setup completed badge border/text |
| `copiedGreenBorder` | `rgba(22,163,74,0.5)` | Active | Copied state border, setup completed pill border |
| `copiedGreenText` | `rgba(22,163,74,0.8)` | Active | Copied state text, setup ready label, setup start button |
| `copiedGreenBg` | `rgba(22,163,74,0.12)` | Active | Copied state background, setup completed badge/pill bg |

### Dark Chrome Family (editor overlay surfaces)

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `darkChrome` | `rgba(30,30,30,0.92)` | Active | Editor toolbar background |
| `darkChromeStatus` | `rgba(30,30,30,0.88)` | Active | Status pill background |
| `darkChromePopover` | `rgba(30,30,30,0.95)` | Unused | Defined for popover; popover now uses system vibrancy |

### Tooltip Family

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `tooltipDarkBg` | `rgba(28,28,32,0.96)` | Active | First-use tooltip background |
| `tooltipDarkBorder` | `rgba(255,255,255,0.1)` | Active | First-use tooltip border |

### UI Chrome Colors

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `dimOverlay` | `rgba(0,0,0,0.5)` | Active | Capture overlay dim |
| `dividerColor` | `rgba(255,255,255,0.08)` | Active | Toolbar divider |
| `closeHoverBg` | `rgba(255,87,87,0.2)` | Active | Close button hover |
| `trashHoverBg` | `rgba(255,87,87,0.15)` | Active | Trash button hover |
| `chromeBorder` | `rgba(175,169,236,0.12)` | Active | Toolbar/canvas border |
| `iconDefault` | `rgba(255,255,255,0.4)` | Active | Default icon stroke |
| `iconHover` | `rgba(255,255,255,0.8)` | Active | Hover icon stroke |
| `buttonHoverBg` | `rgba(255,255,255,0.08)` | Active | Button hover background |
| `toolActiveBg` | `rgba(175,169,236,0.2)` | Active | Active tool background |
| `toggleActiveBg` | `rgba(175,169,236,0.25)` | Active | Toggle active background |
| `toggleBg` | `rgba(255,255,255,0.06)` | Active | Toggle background |
| `toggleInactiveText` | `rgba(255,255,255,0.3)` | Active | Toggle inactive text |
| `closeIconHover` | `#FF5F57` | Active | Close icon hover color |

### Settings Family (appearance-aware via `NSColor(name:nil)`)

| Token | Dark Value | Light Value | Status | Used By |
|-------|-----------|-------------|--------|---------|
| `settingsFieldSurface` | `rgba(255,255,255,0.06)` | `#EEF0F6` | Active | Settings text field bg, setup path box bg, setup hotkey pill bg |
| `settingsFrameSurface` | `rgba(255,255,255,0.02)` | `rgba(15,23,42,0.02)` | Active | Settings framed section bg, setup inactive badge bg |
| `settingsPreviewSurface` | `#15161A` | `#F8FAFC` | Active | Prompt preview surface |
| `settingsSegmentedTrack` | `rgba(255,255,255,0.03)` | `rgba(15,23,42,0.04)` | Active | Segmented control track |
| `settingsSegmentedActive` | `rgba(175,169,236,0.22)` | `rgba(175,169,236,0.18)` | Active | Segmented control active fill |
| `settingsPillBorder` | `rgba(175,169,236,0.36)` | `rgba(114,103,221,0.26)` | Active | Settings pill border, setup action button border |
| `settingsPillFill` | `rgba(175,169,236,0.10)` | `rgba(175,169,236,0.16)` | Active | Settings pill fill, setup action button fill, setup active badge bg |
| `settingsPillText` | `purpleLight` | `#7267DD` | Active | Settings pill title, setup action button text/icon tint |
| `settingsFieldBorder` | `rgba(255,255,255,0.12)` | `rgba(15,23,42,0.08)` | Active | Settings field border, setup path box border, setup hotkey pill border |

### Setup Family

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `setupAmberText` | `#B45309` | Active | Amber status text in setup panels |

> **Note:** The setup window previously had ~28 dedicated tokens (colors for buttons, backgrounds, green states, etc.). These have been consolidated into shared tokens: `copiedGreen*` for success states, `settingsPill*` for action buttons, `settingsField*` for input fields, and system colors (`.labelColor`, `.secondaryLabelColor`, etc.) for text.

---

## Dimension Tokens

### Annotation Dimensions

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `badgeDiameter` | 18px | Active | Pin badge circle |
| `noteHeight` | 26px | Active | Note pill minimum height |
| `noteCornerRadius` | 13px | Active | Note pill corner radius |
| `notePadding` | 12px | Active | Note pill internal horizontal padding |
| `strokeWidth` | 2.5px | Active | All annotation tool strokes |
| `stakeLength` | 10px | Active | Pin stake length |
| `stakeWidth` | 2px | Active | Pin stake width |
| `arrowChevronLength` | 12px | Active | Arrow chevron arm length |
| `arrowChevronAngle` | 28deg | Active | Arrow chevron angle |
| `rectCornerRadius` | 3px | Active | Rectangle corner radius |
| `freehandMinPoints` | 3 | Active | Minimum points for freehand |
| `freehandSampleInterval` | 3px | Active | Freehand sample interval |

### Capture Overlay Dimensions

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `crosshairTickLength` | 10px | Active | Crosshair tick length |
| `crosshairThickness` | 2.3px | Active | Crosshair line thickness |
| `crosshairOpacity` | 0.85 | Active | Crosshair opacity |
| `selectionBorderWidth` | 1.5px | Active | Selection border width |
| `minimumSelectionSize` | 10px | Active | Minimum selection size |
| `dimensionLabelCornerRadius` | 5px | Active | Dimension label corner radius |
| `dimensionLabelPaddingH` | 10px | Active | Dimension label horizontal padding |
| `dimensionLabelHeight` | 24px | Active | Dimension label height |
| `dimensionLabelGap` | 10px | Active | Gap below selection to dimension label |

### Editor Dimensions

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `toolbarHeight` | 40px | Active | Toolbar height |
| `toolbarCornerRadius` | 20px | Active | Toolbar corner radius |
| `toolbarBlur` | 12px | Active | Toolbar blur radius (defined; not yet referenced in ToolbarView) |
| `statusPillCornerRadius` | 12px | Active | Status pill corner radius |
| `statusPillBlur` | 8px | Active | Status pill shadow blur radius |
| `toolButtonSize` | 30px | Active | Tool button size |
| `iconButtonSize` | 28px | Active | Icon button size |
| `closeButtonSize` | 24px | Active | Close button size |

### Popover Dimensions

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `popoverWidth` | 240px | Active | Popover menu width |
| `popoverRowHeight` | 32px | Active | Popover menu row height |
| `popoverCornerRadius` | 10px | Active | Popover corner radius |
| `popoverSubmenuWidth` | 300px | Active | Recent captures submenu width (defined; not yet referenced in RecentCapturesSubmenu) |

### Settings Dimensions

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `settingsContentPadding` | 28px | Active | Settings content horizontal padding |
| `settingsSectionLabelWidth` | 128px | Active | Settings section title width |
| `settingsSectionGap` | 14px | Active | Settings section inner gap |
| `settingsFrameRadius` | 18px | Active | Framed section radius |
| `settingsFramePadding` | 18px | Active | Framed section padding |
| `settingsFieldHeight` | 32px | Active | Field height |
| `settingsSegmentedHeight` | 28px | Active | Segmented control height |
| `settingsSegmentedInset` | 2px | Active | Segmented control inset |
| `settingsPillHeight` | 28px | Active | Pill button height |

### Setup Dimensions

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `setupWindowWidth` | 700px | Active | Setup window width |
| `setupPanelHeight` | 310px | Active | Setup panel height |
| `setupFooterHeight` | 56px | Active | Setup footer height |
| `setupPanelPad` | 28px | Active | Setup panel padding |
| `setupBadgeSize` | 32px | Active | Setup step badge size |
| `setupArrowSize` | 36px | Active | Setup arrow button size |
| `setupSmallPillHeight` | 22px | Active | Setup small pill height |
| `setupWindowRadius` | 18px | Active | Setup window corner radius |
| `setupPathBoxRadius` | 8px | Active | Setup path box corner radius |

### Ghost Preview Dimensions

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `ghostDotRadius` | 3px | Active | Ghost anchor dot radius |
| `ghostStrokeWidth` | 1.5px | Active | Ghost silhouette stroke width |
| `ghostDashPattern` | [3, 2] | Active | Ghost silhouette dash pattern |

### Ghost Preview Colors

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `ghostDotColor` | `rgba(175,169,236,0.85)` | Active | Ghost anchor dot |
| `ghostStrokeColor` | `rgba(239,68,68,0.22)` | Active | Ghost silhouette stroke |

---

## Font Tokens

### Annotation Fonts

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `badgeFont` | system 9px semibold | Active | Badge number |
| `noteNumberFont` | system 8px semibold | Active | Note pill number prefix |
| `noteTextFont` | system 12px regular | Active | Note pill text |

### Editor Fonts

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `dimensionLabelFont` | monospace 11px medium | Active | Dimension label |
| `statusPillFont` | monospace 10px medium | Active | Status pill text |
| `toolbarButtonFont` | system 11px medium | Active | Toolbar button label (defined; not yet referenced in ToolbarView) |
| `tooltipBodyFont` | system 12px regular | Active | Tooltip body text |
| `tooltipLabelFont` | system 13px semibold | Active | Tooltip label text |

### Settings Fonts

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `settingsSectionFont` | system 13px medium | Active | Section labels, setup ready/status labels |
| `settingsBodyFont` | system 12px regular | Active | Body copy, setup descriptions, setup footer hints |
| `settingsFieldFont` | monospace 12px regular | Active | Field text, setup path display |
| `settingsPillFont` | system 11px semibold | Active | Pill button text, setup action buttons, setup hotkey pills |

### Setup Fonts

| Token | Value | Status | Used By |
|-------|-------|--------|---------|
| `setupPanelTitleFont` | system 16px semibold | Active | Setup panel titles |
| `setupHelperFont` | system 11px regular | Active | Setup helper text (restart notes) |
| `setupBadgeFont` | system 14px semibold | Active | Setup badge numbers |
| `setupBadgeCheckFont` | system 16px bold | Active | Setup badge checkmark |

---

## Unused Tokens

The following tokens are defined in `DesignTokens.swift` but not yet referenced in view code. They should be wired or removed in a future cleanup pass.

| Token | Type | Reason |
|-------|------|--------|
| `darkChromePopover` | Color | Popover uses system vibrancy instead; may be removed |
| `toolbarBlur` | Dimension | Defined for toolbar blur radius; ToolbarView not yet updated to reference it |
| `toolbarButtonFont` | Font | Defined for toolbar button labels; ToolbarView not yet updated to reference it |
| `popoverSubmenuWidth` | Dimension | Defined for submenu width; RecentCapturesSubmenu not yet updated to reference it |

---

## Component Token Map

### Capture Overlay
- Crosshair: `purpleLight`, `crosshairThickness`, `crosshairTickLength`, `crosshairOpacity`
- Selection border: `purpleLight`, `selectionBorderWidth`
- Dimension label: `purpleDark` (bg), `dimensionLabelFont`, `dimensionLabelCornerRadius`, `dimensionLabelPaddingH`, `dimensionLabelHeight`, `dimensionLabelGap`
- Overlay dim: `dimOverlay`

### Editor Toolbar
- Surface: `darkChrome`, `chromeBorder`, `toolbarHeight`, `toolbarCornerRadius`
- Tool buttons: `toolButtonSize`, `iconButtonSize`, `iconDefault`, `iconHover`, `buttonHoverBg`, `toolActiveBg`, `purpleLight`
- Mode toggle: `toggleBg`, `toggleActiveBg`, `toggleInactiveText`, `purpleLight`
- Close button: `closeButtonSize`, `closeHoverBg`, `closeIconHover`
- Divider: `dividerColor`

### Status Pill
- Surface: `darkChromeStatus`, `statusPillCornerRadius`, `statusPillBlur`
- Text: `statusPillFont`

### Annotation Tools (all 5 tools + renderers)
- Marks: `red`, `redFill`, `strokeWidth`
- Pin-specific: `badgeDiameter`, `badgeFont`, `stakeLength`, `stakeWidth`
- Arrow-specific: `arrowChevronLength`, `arrowChevronAngle`
- Rectangle-specific: `rectCornerRadius`
- Freehand-specific: `freehandMinPoints`, `freehandSampleInterval`
- Ghost preview: `ghostDotRadius`, `ghostDotColor`, `ghostStrokeColor`, `ghostStrokeWidth`, `ghostDashPattern`

### Note Pills (NotePillRenderer)
- Default: `redNoteBg`, `redNoteBorder`
- Hover: `noteHoverBg`, `noteHoverBorder`
- Selected: `noteSelectedBg`, `noteSelectedBorder`
- Editing: `noteEditingBg`, `red` (border/shadow via `.cgColor`)
- Text: `noteTextColor`, `notePrefixColor`, `noteNumberFont`, `noteTextFont`
- Layout: `noteHeight`, `noteCornerRadius`, `notePadding`, `badgeDiameter`

### Canvas Drawing (CanvasView)
- Uses `DesignTokens.red.withAlphaComponent(N)` for glow (0.08), shadow (0.20), halo (0.3), rect/circle fill (0.14)
- These are static annotation-layer values that do not need appearance awareness

### First-Use Tooltip
- Surface: `tooltipDarkBg`, `tooltipDarkBorder`
- Fonts: `tooltipBodyFont`, `tooltipLabelFont`

### Popover Menu
- Dimensions: `popoverWidth`, `popoverRowHeight`, `popoverCornerRadius`
- Text: system colors (`.labelColor`, `.secondaryLabelColor`, `.tertiaryLabelColor`)
- Borders/dividers: system colors (`.separatorColor`, `.quaternaryLabelColor`)
- Copy buttons: `purpleButton*` family, `copiedGreen*` family, `chromeBorder`
- Submenu: `popoverCornerRadius` (submenu width token `popoverSubmenuWidth` defined but not yet wired)

### Settings Window
- Surface: `settingsFieldSurface`, `settingsFrameSurface`, `settingsPreviewSurface`
- Borders: `settingsFieldBorder`
- Controls: `settingsSegmentedTrack`, `settingsSegmentedActive`, `settingsSegmentedHeight`, `settingsSegmentedInset`
- Pills: `settingsPillBorder`, `settingsPillFill`, `settingsPillText`, `settingsPillFont`, `settingsPillHeight`
- Fields: `settingsFieldHeight`, `settingsFieldFont`
- Layout: `settingsContentPadding`, `settingsSectionLabelWidth`, `settingsSectionGap`, `settingsFrameRadius`, `settingsFramePadding`
- Fonts: `settingsSectionFont`, `settingsBodyFont`

### Setup Window
- **Shared tokens (post-refactor):**
  - Action buttons: `settingsPillBorder`, `settingsPillFill`, `settingsPillText`, `settingsPillFont`
  - Input fields: `settingsFieldSurface`, `settingsFieldBorder`, `settingsFieldFont`
  - Success states: `copiedGreen`, `copiedGreenBorder`, `copiedGreenText`, `copiedGreenBg`
  - Badge inactive: `settingsFrameSurface`
  - Badge active: `purpleDark`, `settingsPillFill`
  - Small pills: `purpleButton`, `purpleButtonBg`
  - Text: system colors (`.labelColor`, `.secondaryLabelColor`, `.tertiaryLabelColor`, `.quaternaryLabelColor`)
  - Body/section fonts: `settingsBodyFont`, `settingsSectionFont`
- **Setup-specific tokens:**
  - Color: `setupAmberText`
  - Dimensions: `setupWindowWidth`, `setupPanelHeight`, `setupFooterHeight`, `setupPanelPad`, `setupBadgeSize`, `setupArrowSize`, `setupSmallPillHeight`, `setupWindowRadius`, `setupPathBoxRadius`
  - Fonts: `setupPanelTitleFont`, `setupHelperFont`, `setupBadgeFont`, `setupBadgeCheckFont`

---

## Design Principles

### Appearance Modes
- **Settings tokens** are appearance-aware (`NSColor(name:nil)` with dark/light branches)
- **Annotation tokens** (red family, note pills) are static -- they render on top of screenshot content, not window chrome
- **Editor chrome** (toolbar, status pill) is always dark frosted glass -- static dark values are correct
- **Popover** uses system colors for text/borders, making it automatically appearance-aware
- **Setup window** uses shared appearance-aware tokens (`settingsField*`, `settingsPill*`) plus system colors

### Token Families
- **Purple**: brand color, interactive elements (crosshair, buttons, active states)
- **Red**: annotation marks and note pills (static, no appearance switching)
- **Green**: success/copied states (shared across editor copy, setup completion, popover copy)
- **Dark Chrome**: frosted glass overlay surfaces (toolbar, status pill)
- **Settings**: appearance-aware window chrome (fields, frames, segments, pills)
- **Setup**: layout dimensions and fonts specific to the setup flow (colors come from shared families)

### Adding New Tokens
1. Check this document and `DesignTokens.swift` for an existing token that fits
2. If a shared token exists (e.g., `settingsPill*`), use it rather than creating a feature-specific duplicate
3. For new tokens: add to `DesignTokens.swift`, update this document, and note the component in the token map
4. Annotation-layer tokens should be static; window chrome tokens should be appearance-aware if the window supports both modes
