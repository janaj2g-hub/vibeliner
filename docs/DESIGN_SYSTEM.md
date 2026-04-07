# Vibeliner Design System

Canonical reference for every design token in the Vibeliner design system.

- **Runtime source:** `Vibeliner/Design/DesignTokens.swift`
- **Documentation source:** this file (`docs/DESIGN_SYSTEM.md`)
- **Visual proof:** `docs/design-system.html`

---

## 1. Colors

### Purple Family

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `purpleLight` | #AFA9EC | #AFA9EC | Yes | Crosshair, selection border, active tool highlight | CrosshairView, CanvasView, ToolbarView, ToolButton, FirstUseTooltipView, CaptureRowView, PromptTabView, SettingsWindowController |
| `purpleDark` | #534AB7 | #534AB7 | Yes | Dimension label bg, settings accents | DimensionLabelView, SetupWindowController |
| `purpleButton` | #A796EB | #A796EB | Yes | Copy button outline and text | ToolbarView, SetupWindowController |
| `purpleButtonHover` | #C4B8F5 | #C4B8F5 | Yes | Copy button hover outline | ToolbarView |
| `purpleButtonBg` | rgba(116, 97, 194, 0.25) | rgba(116, 97, 194, 0.25) | Yes | Copy button fill | ToolbarView, SetupWindowController |
| `purpleButtonBgHover` | rgba(116, 97, 194, 0.35) | rgba(116, 97, 194, 0.35) | Yes | Copy button hover fill | ToolbarView |

### Red / Annotation Family

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `red` | #EF4444 | #EF4444 | Yes | All annotation marks (pin, arrow, rect, circle, freehand) | PinRenderer, ArrowRenderer, RectangleRenderer, CircleRenderer, FreehandRenderer, NotePillRenderer, BadgeRenderer, CanvasView, ToolButton, AboutTabView |
| `redFill` | rgba(239, 68, 68, 0.06) | rgba(239, 68, 68, 0.06) | Yes | Shape fills (rect, circle) | RectangleRenderer, CircleRenderer |
| `redNoteBg` | rgba(255, 248, 248, 0.82) | rgba(255, 248, 248, 0.82) | Yes | Note pill default background | (unused) |
| `redNoteBorder` | rgba(239, 68, 68, 0.18) | rgba(239, 68, 68, 0.18) | Yes | Note pill default border | (unused) |
| `noteHoverBg` | rgba(255, 245, 245, 0.88) | rgba(255, 245, 245, 0.88) | Yes | Note pill hover background | (unused) |
| `noteHoverBorder` | rgba(239, 68, 68, 0.4) | rgba(239, 68, 68, 0.4) | Yes | Note pill hover border | (unused) |
| `noteSelectedBg` | rgba(255, 245, 245, 0.9) | rgba(255, 245, 245, 0.9) | Yes | Note pill selected background | (unused) |
| `noteSelectedBorder` | rgba(239, 68, 68, 0.5) | rgba(239, 68, 68, 0.5) | Yes | Note pill selected border | (unused) |
| `noteEditingBg` | rgba(255, 245, 245, 0.92) | rgba(255, 245, 245, 0.92) | Yes | Note pill editing background | (unused) |
| `notePrefixColor` | rgba(153, 27, 27, 0.4) | rgba(153, 27, 27, 0.4) | Yes | Note number prefix color | (unused) |
| `noteTextColor` | #7F1D1D | #7F1D1D | Yes | Note text color | NotePillRenderer |

### Copied / Green Family

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `copiedGreenBorder` | rgba(22, 163, 74, 0.5) | rgba(22, 163, 74, 0.5) | Yes | Copy success border | ToolbarView, PromptTabView |
| `copiedGreenText` | rgba(22, 163, 74, 0.8) | rgba(22, 163, 74, 0.8) | Yes | Copy success text | ToolbarView, PromptTabView |
| `copiedGreenBg` | rgba(22, 163, 74, 0.12) | rgba(22, 163, 74, 0.12) | Yes | Copy success background | ToolbarView, PromptTabView |
| `copiedGreen` | rgba(22, 163, 74, 0.9) | rgba(22, 163, 74, 0.9) | Yes | Copied state green (status pill) | StatusPillView |

### Chrome / Dark UI Family

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `darkChrome` | rgba(30, 30, 30, 0.92) | rgba(30, 30, 30, 0.92) | Yes | Toolbar background | ToolbarView |
| `darkChromeStatus` | rgba(30, 30, 30, 0.88) | rgba(30, 30, 30, 0.88) | Yes | Status pill background | StatusPillView |
| `darkChromePopover` | rgba(30, 30, 30, 0.95) | rgba(30, 30, 30, 0.95) | Yes | Popover background | (unused) |
| `chromeBorder` | rgba(175, 169, 236, 0.12) | rgba(175, 169, 236, 0.12) | Yes | Toolbar/canvas border | ToolbarView, ScreenshotCanvasView |
| `toolActiveBg` | rgba(175, 169, 236, 0.2) | rgba(175, 169, 236, 0.2) | Yes | Active tool background | ToolButton |
| `dimOverlay` | rgba(0, 0, 0, 0.5) | rgba(0, 0, 0, 0.5) | Yes | Capture overlay dim | CrosshairView |
| `dividerColor` | rgba(255, 255, 255, 0.08) | rgba(255, 255, 255, 0.08) | Yes | Divider lines | ToolbarView |
| `closeHoverBg` | rgba(255, 87, 87, 0.2) | rgba(255, 87, 87, 0.2) | Yes | Close button hover | ToolButton |
| `trashHoverBg` | rgba(255, 87, 87, 0.15) | rgba(255, 87, 87, 0.15) | Yes | Trash button hover | ToolButton |
| `iconDefault` | rgba(255, 255, 255, 0.4) | rgba(255, 255, 255, 0.4) | Yes | Default icon stroke | ToolButton |
| `iconHover` | rgba(255, 255, 255, 0.8) | rgba(255, 255, 255, 0.8) | Yes | Hover icon stroke | ToolButton |
| `buttonHoverBg` | rgba(255, 255, 255, 0.08) | rgba(255, 255, 255, 0.08) | Yes | Button hover background | ToolButton |
| `closeIconHover` | #FF5F57 | #FF5F57 | Yes | Close icon hover color | ToolButton |

### Toggle Family

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `toggleActiveBg` | rgba(175, 169, 236, 0.25) | rgba(175, 169, 236, 0.25) | Yes | Toggle active background | ToolbarView |
| `toggleBg` | rgba(255, 255, 255, 0.06) | rgba(255, 255, 255, 0.06) | Yes | Toggle background | ToolbarView |
| `toggleInactiveText` | rgba(255, 255, 255, 0.3) | rgba(255, 255, 255, 0.3) | Yes | Toggle inactive text | ToolbarView |

### Tooltip Family

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `tooltipDarkBg` | rgba(28, 28, 32, 0.96) | rgba(28, 28, 32, 0.96) | Yes | Tooltip background | FirstUseTooltipView |
| `tooltipDarkBorder` | rgba(255, 255, 255, 0.1) | rgba(255, 255, 255, 0.1) | Yes | Tooltip border | FirstUseTooltipView |

### Ghost Preview Family

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `ghostDotColor` | rgba(175, 169, 236, 0.85) | rgba(175, 169, 236, 0.85) | Yes | Ghost anchor dot | PinTool, ArrowTool, RectangleTool, CircleTool, FreehandTool |
| `ghostStrokeColor` | rgba(239, 68, 68, 0.22) | rgba(239, 68, 68, 0.22) | Yes | Ghost silhouette stroke | PinTool, ArrowTool, RectangleTool, CircleTool |

### Settings Family (appearance-aware)

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `settingsFieldSurface` | #EEF0F6 | rgba(255, 255, 255, 0.06) | No | Field surface background | SettingsUI |
| `settingsFrameSurface` | rgba(15, 23, 42, 0.02) | rgba(255, 255, 255, 0.02) | No | Framed section surface | SettingsUI |
| `settingsPreviewSurface` | #F8FAFC | rgba(21, 22, 26, 1.0) | No | Preview surface | SettingsUI |
| `settingsSegmentedTrack` | rgba(15, 23, 42, 0.04) | rgba(255, 255, 255, 0.03) | No | Segmented control track | SettingsUI |
| `settingsSegmentedActive` | rgba(175, 169, 236, 0.18) | rgba(175, 169, 236, 0.22) | No | Segmented control active fill | SettingsUI |
| `settingsPillBorder` | rgba(114, 103, 221, 0.26) | rgba(175, 169, 236, 0.36) | No | Pill button border | SettingsUI, PromptTabView |
| `settingsPillFill` | rgba(175, 169, 236, 0.16) | rgba(175, 169, 236, 0.10) | No | Pill button fill | SettingsUI, PromptTabView |
| `settingsPillText` | rgba(114, 103, 221, 1.0) | #AFA9EC | No | Pill button text | SettingsUI, PromptTabView, AboutTabView |
| `settingsFieldBorder` | rgba(15, 23, 42, 0.08) | rgba(255, 255, 255, 0.12) | No | Field border | SettingsUI |

### Setup Family

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `setupGreen` | #22C55E | #22C55E | Yes | Badge done border/text | SetupWindowController |
| `setupGreenBadgeBg` | rgba(34, 197, 94, 0.1) | rgba(34, 197, 94, 0.1) | Yes | Badge done fill | SetupWindowController |
| `setupGreenText` | #16A34A | #16A34A | Yes | Status text, green button text | SetupWindowController |
| `setupGreenBg` | rgba(34, 197, 94, 0.08) | rgba(34, 197, 94, 0.08) | Yes | Green button fill | SetupWindowController |
| `setupGreenBorder` | rgba(34, 197, 94, 0.5) | rgba(34, 197, 94, 0.5) | Yes | Green button border | SetupWindowController |
| `setupAmberBg` | rgba(234, 179, 8, 0.08) | rgba(234, 179, 8, 0.08) | Yes | Amber status background | (unused) |
| `setupAmberText` | #B45309 | #B45309 | Yes | Amber status text | SetupWindowController |
| `setupWindowBg` | #1E1E1E | #1E1E1E | Yes | Setup window background | SetupWindowController |
| `setupTitleBarBg` | #2A2A2A | #2A2A2A | Yes | Setup title bar background | (unused) |
| `setupFooterBg` | #222222 | #222222 | Yes | Setup footer background | SetupWindowController |
| `setupBorder` | #333333 | #333333 | Yes | Setup dividers and borders | SetupWindowController |
| `setupFieldBg` | rgba(255, 255, 255, 0.05) | rgba(255, 255, 255, 0.05) | Yes | Setup field background | SetupWindowController |
| `setupFieldBorder` | rgba(255, 255, 255, 0.08) | rgba(255, 255, 255, 0.08) | Yes | Setup field border | SetupWindowController |
| `setupTextPrimary` | #E0E0E0 | #E0E0E0 | Yes | Setup primary text | SetupWindowController |
| `setupTextSecondary` | #888888 | #888888 | Yes | Setup secondary text | SetupWindowController |
| `setupTextDim` | #666666 | #666666 | Yes | Setup dim/helper text | SetupWindowController |
| `setupGrayText` | #555555 | #555555 | Yes | Setup locked badge/gray status | SetupWindowController |
| `setupGrayBg` | rgba(255, 255, 255, 0.03) | rgba(255, 255, 255, 0.03) | Yes | Setup locked badge bg | SetupWindowController |
| `setupButtonFill` | rgba(175, 169, 236, 0.08) | rgba(175, 169, 236, 0.08) | Yes | Setup action button fill | SetupWindowController |
| `setupButtonBorder` | rgba(175, 169, 236, 0.55) | rgba(175, 169, 236, 0.55) | Yes | Setup action button border | SetupWindowController |
| `setupButtonText` | #6F69DF | #6F69DF | Yes | Setup action button/label text | SetupWindowController |
| `setupButtonHoverBg` | rgba(175, 169, 236, 0.16) | rgba(175, 169, 236, 0.16) | Yes | Setup arrow hover bg | (unused) |
| `setupKbdBorder` | rgba(255, 255, 255, 0.12) | rgba(255, 255, 255, 0.12) | Yes | Setup kbd pill border | SetupWindowController |
| `setupKbdBg` | rgba(255, 255, 255, 0.08) | rgba(255, 255, 255, 0.08) | Yes | Setup kbd pill bg | SetupWindowController |
| `setupKbdText` | rgba(255, 255, 255, 0.55) | rgba(255, 255, 255, 0.55) | Yes | Setup kbd pill text | SetupWindowController |

---

## 2. Typography

| Token Name | Font Family | Size (px) | Weight | Usage | Consuming Files |
|---|---|---|---|---|---|
| `badgeFont` | System | 9 | Semibold (600) | Badge numbers | BadgeRenderer |
| `noteNumberFont` | System | 8 | Semibold (600) | Note number prefix | (unused) |
| `noteTextFont` | System | 12 | Regular | Note pill text | CanvasView, NotePillRenderer |
| `dimensionLabelFont` | Monospaced System | 11 | Medium (500) | Dimension label | DimensionLabelView |
| `statusPillFont` | Monospaced System | 10 | Medium (500) | Status pill text | StatusPillView |
| `toolbarButtonFont` | System | 11 | Medium (500) | Toolbar button label | (unused) |
| `tooltipBodyFont` | System | 12 | Regular | Tooltip body text | (unused) |
| `tooltipLabelFont` | System | 13 | Semibold (600) | Tooltip label text | (unused) |
| `settingsSectionFont` | System | 13 | Medium (500) | Settings section label | SettingsUI |
| `settingsBodyFont` | System | 12 | Regular | Settings body copy | SettingsUI |
| `settingsFieldFont` | Monospaced System | 12 | Regular | Settings field text | SettingsUI |
| `settingsPillFont` | System | 11 | Semibold (600) | Settings pill text | SettingsUI |
| `setupWindowTitleFont` | System | 18 | Semibold (600) | Setup window title | (unused) |
| `setupPanelTitleFont` | System | 16 | Semibold (600) | Setup panel title | SetupWindowController |
| `setupDescFont` | System | 13 | Regular | Setup description text | SetupWindowController |
| `setupActionLabelFont` | System | 13 | Semibold (600) | Setup action button label | SetupWindowController |
| `setupHelperFont` | System | 11 | Regular | Setup helper text | SetupWindowController |
| `setupPathFont` | Monospaced System | 13 | Regular | Setup path display | SetupWindowController |
| `setupStatusFont` | System | 13 | Semibold (600) | Setup status text | SetupWindowController |
| `setupSmallPillFont` | System | 11 | Medium (500) | Setup small pill text | SetupWindowController |
| `setupBadgeFont` | System | 14 | Semibold (600) | Setup badge number | SetupWindowController |
| `setupBadgeCheckFont` | System | 16 | Bold (700) | Setup badge checkmark | SetupWindowController |
| `setupKbdFont` | System | 12 | Semibold (600) | Setup keyboard shortcut | SetupWindowController |
| `setupShortcutHintFont` | System | 12 | Regular | Setup shortcut hint | SetupWindowController |

---

## 3. Dimensions

| Token Name | Value | Usage | Consuming Files |
|---|---|---|---|
| `badgeDiameter` | 18 | Badge diameter (radius 9) | CanvasView, PinTool, SelectTool, PinRenderer, ArrowRenderer, NotePillRenderer, BadgeRenderer, VisualTestHarness |
| `noteHeight` | 26 | Note pill height | CanvasView, NotePillRenderer |
| `noteCornerRadius` | 13 | Note pill corner radius | CanvasView, NotePillRenderer |
| `strokeWidth` | 2.5 | Annotation tool stroke width | ArrowRenderer, RectangleRenderer, CircleRenderer, FreehandRenderer |
| `stakeLength` | 10 | Pin stake length | CanvasView, PinTool, PinRenderer, VisualTestHarness |
| `stakeWidth` | 2 | Pin stake width | PinRenderer |
| `crosshairTickLength` | 10 | Crosshair tick length | CrosshairView |
| `crosshairThickness` | 2.3 | Crosshair line thickness | CrosshairView |
| `crosshairOpacity` | 0.85 | Crosshair opacity | CrosshairView |
| `selectionBorderWidth` | 1.5 | Selection border width | CrosshairView |
| `toolbarHeight` | 40 | Toolbar height | EditorPanel, ToolbarView, VisualTestHarness |
| `toolbarCornerRadius` | 20 | Toolbar corner radius | ToolbarView |
| `toolbarBlur` | 12 | Toolbar blur radius | (unused) |
| `statusPillCornerRadius` | 12 | Status pill corner radius | StatusPillView |
| `statusPillBlur` | 8 | Status pill blur radius | (unused) |
| `toolButtonSize` | 30 | Tool button size | ToolbarView, ToolButton |
| `iconButtonSize` | 28 | Icon button size | ToolbarView, ToolButton |
| `closeButtonSize` | 24 | Close button size | ToolbarView, ToolButton |
| `arrowChevronLength` | 12 | Arrow chevron arm length | ArrowRenderer |
| `arrowChevronAngle` | 28 | Arrow chevron angle (degrees) | ArrowRenderer |
| `rectCornerRadius` | 3 | Rectangle corner radius | RectangleRenderer |
| `freehandMinPoints` | 3 | Minimum points for freehand | FreehandTool |
| `freehandSampleInterval` | 3 | Freehand sample interval | FreehandTool |
| `dimensionLabelCornerRadius` | 5 | Dimension label corner radius | DimensionLabelView |
| `dimensionLabelPaddingH` | 10 | Dimension label horizontal padding | DimensionLabelView |
| `dimensionLabelHeight` | 24 | Dimension label height | DimensionLabelView |
| `dimensionLabelGap` | 10 | Gap below selection to label | DimensionLabelView |
| `minimumSelectionSize` | 10 | Minimum selection size | CaptureCoordinator |
| `ghostDotRadius` | 3 | Ghost anchor dot radius | PinTool, ArrowTool, RectangleTool, CircleTool, FreehandTool |
| `ghostStrokeWidth` | 1.5 | Ghost silhouette stroke width | PinTool, ArrowTool, RectangleTool, CircleTool |
| `ghostDashPattern` | [3, 2] | Ghost silhouette dash pattern | PinTool, ArrowTool, RectangleTool, CircleTool |
| `settingsContentPadding` | 28 | Settings content horizontal padding | PromptTabView, GeneralTabView, AboutTabView |
| `settingsSectionLabelWidth` | 128 | Settings section title width | SettingsUI |
| `settingsSectionPadding` | 24 | Settings section vertical spacing | (unused) |
| `settingsSectionGap` | 14 | Settings section inner gap | GeneralTabView |
| `settingsFrameRadius` | 18 | Settings framed section radius | SettingsUI |
| `settingsFramePadding` | 18 | Settings framed section padding | PromptTabView |
| `settingsFieldHeight` | 32 | Settings field height | SettingsUI, PromptTabView, GeneralTabView |
| `settingsSegmentedHeight` | 28 | Settings segmented control height | SettingsUI |
| `settingsSegmentedInset` | 2 | Settings segmented control inset | SettingsUI |
| `settingsPillHeight` | 28 | Settings pill button height | SettingsUI |
| `setupWindowWidth` | 700 | Setup window width | SetupWindowController |
| `setupPanelHeight` | 310 | Setup panel height | SetupWindowController |
| `setupFooterHeight` | 56 | Setup footer height | SetupWindowController |
| `setupPanelPad` | 28 | Setup panel padding | SetupWindowController |
| `setupBadgeSize` | 32 | Setup badge size | SetupWindowController |
| `setupArrowSize` | 36 | Setup arrow size | SetupWindowController |
| `setupSmallPillHeight` | 22 | Setup small pill height | SetupWindowController |
| `setupWindowRadius` | 18 | Setup window corner radius | (unused) |
| `setupPathBoxRadius` | 8 | Setup path box corner radius | SetupWindowController |

---

## 4. Filmstrip & Roles

### Role Color Tokens (appearance-aware)

| Token Name | Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|
| `roleObservedBg` | rgba(83, 74, 183, 0.35) | Yes | Observed role pill background (purple tint) | TitlePillView, CompositeStitcher |
| `roleObservedBorder` | rgba(175, 169, 236, 0.5) | Yes | Observed role pill border | TitlePillView, CompositeStitcher |
| `roleExpectedBg` | rgba(22, 100, 52, 0.35) | Yes | Expected role pill background (green tint) | TitlePillView, CompositeStitcher |
| `roleExpectedBorder` | rgba(134, 239, 172, 0.5) | Yes | Expected role pill border | TitlePillView, CompositeStitcher |
| `roleReferenceBg` | rgba(30, 70, 140, 0.35) | Yes | Reference role pill background (blue tint) | TitlePillView, CompositeStitcher |
| `roleReferenceBorder` | rgba(147, 197, 253, 0.5) | Yes | Reference role pill border | TitlePillView, CompositeStitcher |

### Title Pill Tokens (static)

| Token Name | Value | Usage | Consuming Files |
|---|---|---|---|
| `titlePillHeight` | 30 | Title pill height | TBD |
| `titlePillGap` | 6 | Gap between pill bottom and image top | TBD |
| `titlePillExportShadow` | NSShadow(offset: 0,-2, blur: 8, color: rgba(0,0,0,0.3)) | Shadow on baked-in export pill for contrast | TBD |

### Filmstrip Container Tokens

| Token Name | Light Value | Dark Value | Static? | Usage | Consuming Files |
|---|---|---|---|---|---|
| `filmstripGap` | 14 | 14 | Yes | Equal gap between all filmstrip cells | FilmstripGridView, LayoutCalculator |
| `filmstripPadding` | 14 | 14 | Yes | Padding inside filmstrip container (= filmstripGap) | FilmstripGridView |
| `filmstripBg` | rgba(15, 15, 20, 0.65) | rgba(15, 15, 20, 0.65) | Yes | Container background (multi-image only) | FilmstripGridView |
| `filmstripBorder` | rgba(175, 169, 236, 0.20) | rgba(175, 169, 236, 0.20) | Yes | Container border (multi-image only) | FilmstripGridView |

---

## 5. Proposed New Tokens (pre-existing)

| Token Name | Proposed Value | Rationale | Would Be Used By |
|---|---|---|---|
| `popoverWidth` | 240 | Hardcoded in PopoverViewController; needed for consistent popover sizing | PopoverViewController |
| `popoverRowHeight` | 32 | Hardcoded row height in popover layout | PopoverViewController |
| `popoverCornerRadius` | 10 | Hardcoded popover corner radius | PopoverViewController |
| `popoverSubmenuWidth` | 300 | Hardcoded submenu width | RecentCapturesSubmenu |

---

## 6. Unused Tokens

| Token Name | Defined Value | Recommendation | Notes |
|---|---|---|---|
| `redNoteBg` | rgba(255, 248, 248, 0.82) | Wire up | NotePillRenderer uses hardcoded duplicate with slightly different alpha |
| `redNoteBorder` | rgba(239, 68, 68, 0.18) | Wire up | NotePillRenderer uses hardcoded duplicate with different color |
| `noteHoverBg` | rgba(255, 245, 245, 0.88) | Wire up | NotePillRenderer uses hardcoded duplicate |
| `noteHoverBorder` | rgba(239, 68, 68, 0.4) | Wire up | NotePillRenderer uses hardcoded duplicate |
| `noteSelectedBg` | rgba(255, 245, 245, 0.9) | Wire up | NotePillRenderer uses hardcoded duplicate |
| `noteSelectedBorder` | rgba(239, 68, 68, 0.5) | Wire up | NotePillRenderer uses hardcoded duplicate |
| `noteEditingBg` | rgba(255, 245, 245, 0.92) | Wire up | NotePillRenderer uses hardcoded duplicate |
| `notePrefixColor` | rgba(153, 27, 27, 0.4) | Wire up | NotePillRenderer uses hardcoded duplicate |
| `darkChromePopover` | rgba(30, 30, 30, 0.95) | Clarify | Popover uses NSVisualEffectView vibrancy instead; may remove if vibrancy stays |
| `toolbarBlur` | 12 | Wire up | Should be applied in ToolbarView for blur radius |
| `statusPillBlur` | 8 | Wire up | Should be applied in StatusPillView for blur radius |
| `settingsSectionPadding` | 24 | Clarify | Settings uses `settingsSectionGap` (14) instead; naming overlap |
| `noteNumberFont` | System 8px Semibold | Wire up | NotePillRenderer uses hardcoded `ofSize: 8` instead |
| `toolbarButtonFont` | System 11px Medium | Wire up | ToolbarView uses hardcoded font sizes |
| `tooltipBodyFont` | System 12px Regular | Wire up | FirstUseTooltipView uses hardcoded fonts |
| `tooltipLabelFont` | System 13px Semibold | Wire up | FirstUseTooltipView uses hardcoded fonts |
| `setupWindowRadius` | 18 | Wire up | Should be applied in SetupWindowController for window corner radius |
| `setupWindowTitleFont` | System 18px Semibold | Wire up | Should be applied in SetupWindowController for window title |

---

## 7. Component Token Map

### Pin Annotation
- Badge: `red`, `badgeDiameter`, `badgeFont`
- Stake: `red`, `stakeLength`, `stakeWidth`
- Note pill: `redNoteBg`*, `redNoteBorder`*, `noteHoverBg`*, `noteHoverBorder`*, `noteSelectedBg`*, `noteSelectedBorder`*, `noteEditingBg`*, `notePrefixColor`*, `noteTextColor`, `noteTextFont`, `noteNumberFont`*, `noteHeight`, `noteCornerRadius`
- Ghost preview: `ghostDotColor`, `ghostDotRadius`, `ghostStrokeColor`, `ghostStrokeWidth`, `ghostDashPattern`

(*) Token exists but is currently unused; NotePillRenderer uses hardcoded values.

### Arrow Annotation
- Badge: `red`, `badgeDiameter`, `badgeFont`
- Shaft: `red`, `strokeWidth`
- Chevron: `red`, `arrowChevronLength`, `arrowChevronAngle`
- Note pill: same tokens as Pin
- Ghost preview: `ghostDotColor`, `ghostDotRadius`, `ghostStrokeColor`, `ghostStrokeWidth`, `ghostDashPattern`

### Rectangle Annotation
- Stroke: `red`, `strokeWidth`, `rectCornerRadius`
- Fill: `redFill`
- Badge: `red`, `badgeDiameter`, `badgeFont`
- Note pill: same tokens as Pin
- Ghost preview: `ghostDotColor`, `ghostDotRadius`, `ghostStrokeColor`, `ghostStrokeWidth`, `ghostDashPattern`

### Circle Annotation
- Stroke: `red`, `strokeWidth`
- Fill: `redFill`
- Badge: `red`, `badgeDiameter`, `badgeFont`
- Note pill: same tokens as Pin
- Ghost preview: `ghostDotColor`, `ghostDotRadius`, `ghostStrokeColor`, `ghostStrokeWidth`, `ghostDashPattern`

### Freehand Annotation
- Stroke: `red`, `strokeWidth`
- Badge: `red`, `badgeDiameter`, `badgeFont`
- Note pill: same tokens as Pin
- Ghost preview: `ghostDotColor`, `ghostDotRadius`

### Editor Toolbar
- Background: `darkChrome`, `chromeBorder`, `toolbarBlur`*
- Tools: `toolActiveBg`, `iconDefault`, `iconHover`, `buttonHoverBg`, `toolButtonSize`, `iconButtonSize`
- Close: `closeButtonSize`, `closeHoverBg`, `closeIconHover`
- Trash: `trashHoverBg`
- Toggle: `toggleActiveBg`, `toggleBg`, `toggleInactiveText`
- Divider: `dividerColor`
- Layout: `toolbarHeight`, `toolbarCornerRadius`
- Font: `toolbarButtonFont`*

### Copy Buttons
- Default: `purpleButton`, `purpleButtonBg`
- Hover: `purpleButtonHover`, `purpleButtonBgHover`
- Copied: `copiedGreenBorder`, `copiedGreenText`, `copiedGreenBg`

### Status Pill
- Background: `darkChromeStatus`, `statusPillBlur`*
- Layout: `statusPillCornerRadius`
- Font: `statusPillFont`
- Copied state: `copiedGreen`

### Popover
- Background: `darkChromePopover`*
- Border: `chromeBorder`
- Layout: `popoverWidth`**, `popoverRowHeight`**, `popoverCornerRadius`**, `popoverSubmenuWidth`**

(**) Proposed new token; currently hardcoded.

### Settings
- Surfaces: `settingsFieldSurface`, `settingsFrameSurface`, `settingsPreviewSurface`
- Controls: `settingsSegmentedTrack`, `settingsSegmentedActive`, `settingsSegmentedHeight`, `settingsSegmentedInset`
- Fields: `settingsFieldBorder`, `settingsFieldHeight`, `settingsFieldFont`
- Pills: `settingsPillBorder`, `settingsPillFill`, `settingsPillText`, `settingsPillHeight`, `settingsPillFont`
- Layout: `settingsContentPadding`, `settingsSectionLabelWidth`, `settingsSectionGap`, `settingsFrameRadius`, `settingsFramePadding`
- Fonts: `settingsSectionFont`, `settingsBodyFont`

### Setup
- Window: `setupWindowBg`, `setupTitleBarBg`, `setupFooterBg`, `setupBorder`, `setupWindowWidth`, `setupWindowRadius`*
- Panels: `setupPanelHeight`, `setupPanelPad`
- Badges: `setupGreen`, `setupGreenBadgeBg`, `setupGrayText`, `setupGrayBg`, `setupBadgeSize`, `setupBadgeFont`, `setupBadgeCheckFont`
- Buttons: `setupButtonFill`, `setupButtonBorder`, `setupButtonText`, `setupButtonHoverBg`, `setupArrowSize`
- Status: `setupGreenText`, `setupGreenBg`, `setupGreenBorder`, `setupAmberBg`, `setupAmberText`, `setupStatusFont`
- Fields: `setupFieldBg`, `setupFieldBorder`, `setupPathFont`, `setupPathBoxRadius`
- Kbd pills: `setupKbdBorder`, `setupKbdBg`, `setupKbdText`, `setupKbdFont`
- Text: `setupTextPrimary`, `setupTextSecondary`, `setupTextDim`
- Fonts: `setupWindowTitleFont`*, `setupPanelTitleFont`, `setupDescFont`, `setupActionLabelFont`, `setupHelperFont`, `setupSmallPillFont`, `setupShortcutHintFont`
- Layout: `setupFooterHeight`, `setupSmallPillHeight`

### First-Use Tooltip
- Background: `tooltipDarkBg`, `tooltipDarkBorder`
- Fonts: `tooltipBodyFont`*, `tooltipLabelFont`*

(*) Token exists but is currently unused.
