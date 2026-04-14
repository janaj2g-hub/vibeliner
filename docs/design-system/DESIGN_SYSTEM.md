# Vibeliner Design System — Token Reference

Last updated: 2026-04-13 (VIB-437 consolidation)
Source of truth: `Vibeliner/Design/DesignTokens*.swift`

---

## 1. Core Palette

| Name | Hex | Usage |
|------|-----|-------|
| `purpleLight` | #AFA9EC | Crosshair, selection border, active tool highlight, brand accent |
| `purpleDark` | #534AB7 | Dimension label bg, settings accents, light-mode pill button text |
| `red` | #EF4444 | All annotation marks, badges, note editing glow |
| `redFill` | rgba(239,68,68,0.06) | Annotation shape fills |
| `copiedGreen` | rgba(22,163,74,0.9) | Copy success accent |
| `dimOverlay` | rgba(0,0,0,0.5) | Capture overlay dim |
| `chromeBorder` | rgba(175,169,236,0.12) | Toolbar/canvas border |
| `dividerColor` | Dynamic | Dividers — dark: rgba(255,255,255,0.08), light: rgba(0,0,0,0.08) |

System colors (`.labelColor`, `.separatorColor`, `.windowBackgroundColor`) are used for appearance-aware surfaces throughout settings and setup.

---

## 2. Component Tokens

### Pill Button — `pillButton*`

All purple outlined pill buttons: Copy Prompt, Copy Image, Change Hotkey, Change Folder, Save Draft, role pills, popover copy, tour mini-toolbar.

| Token | Dark | Light | Consuming files |
|-------|------|-------|-----------------|
| `pillButtonBorder` | #A796EB | #534AB7 | ToolbarButtons, SettingsControls, SetupComponents, CaptureRowView, TourMiniToolbar |
| `pillButtonText` | #A796EB | #534AB7 | ToolbarButtons, SettingsControls, SetupComponents, CaptureRowView, PromptTabView, AboutTabView, TourMiniToolbar |
| `pillButtonBg` | rgba(116,97,194,0.25) | rgba(83,74,183,0.08) | ToolbarButtons, SettingsControls, SetupComponents, CaptureRowView, TourMiniToolbar |
| `pillButtonHoverBorder` | #C4B8F5 | #7461C2 | ToolbarButtons |
| `pillButtonHoverText` | #C4B8F5 | #7461C2 | ToolbarButtons |
| `pillButtonHoverBg` | rgba(116,97,194,0.35) | rgba(83,74,183,0.12) | ToolbarButtons |

### Pill Button Primary — `pillButtonPrimary*`

Solid-fill CTA buttons (tour Next/Back button). White text on solid purple in light mode.

| Token | Dark | Light | Consuming files |
|-------|------|-------|-----------------|
| `pillButtonPrimaryText` | #AFA9EC | white | TourWindowController+Content |
| `pillButtonPrimaryBg` | rgba(175,169,236,0.16) | #534AB7 | TourWindowController+Content |
| `pillButtonPrimaryBorder` | rgba(175,169,236,0.36) | #534AB7 | TourWindowController+Content |
| `pillButtonPrimaryHoverBg` | rgba(175,169,236,0.22) | #6055C4 | TourWindowController+Content |
| `pillButtonPrimaryHoverBorder` | rgba(175,169,236,0.48) | #6055C4 | TourWindowController+Content |

### Segmented Control — `segmented*`

All segmented controls: toolbar IDE/App toggle, Preamble/Tools/Footer sub-tabs, Single/Multi-Image switcher, Light/Dark/System appearance selector.

| Token | Dark | Light | Consuming files |
|-------|------|-------|-----------------|
| `segmentedTrack` | rgba(255,255,255,0.03) | rgba(15,23,42,0.04) | ToolbarButtons, SettingsControls, TourMiniToolbar |
| `segmentedTrackBorder` | rgba(255,255,255,0.08) | rgba(15,23,42,0.08) | SettingsUI |
| `segmentedActiveFill` | rgba(175,169,236,0.16) | rgba(175,169,236,0.14) | ToolbarButtons, SettingsUI, TourMiniToolbar |
| `segmentedActiveBorder` | rgba(175,169,236,0.20) | rgba(114,103,221,0.18) | SettingsUI |
| `segmentedActiveText` | = `pillButtonText` | = `pillButtonText` | SettingsControls |
| `segmentedInactiveText` | rgba(255,255,255,0.58) | rgba(15,23,42,0.58) | ToolbarButtons, SettingsControls, TourMiniToolbar |

### Secondary Button — `toolbarSecondary*`

Subtle ghost/outlined buttons: + Add image, New capture.

| Token | Dark | Light | Consuming files |
|-------|------|-------|-----------------|
| `toolbarSecondaryBorder` | rgba(255,255,255,0.20) | rgba(0,0,0,0.15) | ToolbarButtons |
| `toolbarSecondaryText` | rgba(255,255,255,0.60) | rgba(0,0,0,0.65) | ToolbarButtons |
| `toolbarSecondaryBg` | clear | clear | ToolbarButtons |
| `toolbarSecondaryHoverBorder` | rgba(255,255,255,0.35) | rgba(0,0,0,0.25) | ToolbarButtons |
| `toolbarSecondaryHoverText` | rgba(255,255,255,0.80) | rgba(0,0,0,0.75) | ToolbarButtons |
| `toolbarSecondaryHoverBg` | rgba(255,255,255,0.05) | rgba(0,0,0,0.04) | ToolbarButtons |

### Note Pill — `editorNoteSurface*` / `editorNoteBorder*`

Interactive note pill with 4 states: default, hover, selected, editing.

| Token | Value | Consuming files |
|-------|-------|-----------------|
| `editorNoteSurfaceDefault` | rgba(255,244,244,0.72) | NotePillView |
| `editorNoteSurfaceHover` | rgba(255,244,244,0.80) | NotePillView |
| `editorNoteSurfaceSelected` | rgba(255,244,244,0.88) | NotePillView |
| `editorNoteSurfaceEditing` | rgba(255,250,250,0.96) | NotePillView, CanvasView+NoteEditing |
| `editorNoteBorderDefault` | rgba(180,180,180,0.22) | NotePillView |
| `editorNoteBorderHover` | rgba(239,68,68,0.45) | NotePillView |
| `editorNoteBorderSelected` | rgba(239,68,68,0.55) | NotePillView |
| `editorNoteShadow` | rgba(0,0,0,0.06) | NotePillView |

Note editing glow uses `DesignTokens.red` directly (no alias).

### Copy Success — `copiedGreen*`

| Token | Value | Consuming files |
|-------|-------|-----------------|
| `copiedGreen` | rgba(22,163,74,0.9) | ToolbarButtons |
| `copiedGreenBg` | rgba(22,163,74,0.12) | ToolbarButtons, PromptTabView |
| `copiedGreenBorder` | rgba(22,163,74,0.5) | ToolbarButtons, PromptTabView |
| `copiedGreenText` | rgba(22,163,74,0.8) | ToolbarButtons, CaptureRowView, PromptTabView |

### Status Pill — `statusPill*`

| Token | Dark | Light | Consuming files |
|-------|------|-------|-----------------|
| `statusPillBg` | rgba(30,30,30,0.88) | rgba(255,255,255,0.85) | StatusPillView |
| `statusPillTextColor` | white | rgba(0,0,0,0.70) | StatusPillView |
| `statusPillBorder` | clear | rgba(0,0,0,0.06) | StatusPillView |

---

## 3. Surface Tokens

### Toolbar

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `toolbarBg` | rgba(30,30,30,0.92) | rgba(255,255,255,0.88) | Toolbar background |
| `toolbarBorder` | rgba(255,255,255,0.12) | rgba(0,0,0,0.10) | Toolbar border |
| `toolbarIconDefault` | rgba(255,255,255,0.40) | rgba(0,0,0,0.45) | Icon default stroke |
| `toolbarIconHover` | rgba(255,255,255,0.70) | rgba(0,0,0,0.70) | Icon hover stroke |
| `toolbarDivider` | rgba(255,255,255,0.08) | rgba(0,0,0,0.12) | Toolbar dividers |
| `toolbarPurpleActive` | #AFA9EC | #534AB7 | Active tool/toggle label |
| `toolbarToolActiveBg` | rgba(175,169,236,0.2) | rgba(83,74,183,0.12) | Active tool button bg |
| `toolbarButtonHoverBg` | rgba(255,255,255,0.08) | rgba(0,0,0,0.06) | Generic button hover bg |
| `toolbarCloseHoverBg` | rgba(255,87,87,0.2) | rgba(255,87,87,0.15) | Close button hover bg |
| `toolbarCloseIconHover` | #FF5F57 | #FF5F57 | Close icon hover color |
| `toolbarTrashHoverBg` | rgba(255,87,87,0.15) | rgba(255,87,87,0.12) | Trash button hover bg |
| `addImageBg` | rgba(175,169,236,0.14) | rgba(83,74,183,0.08) | Add image button bg |
| `addImageBorder` | rgba(175,169,236,0.22) | rgba(83,74,183,0.15) | Add image button border |

### Settings

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| `settingsFieldSurface` | rgba(255,255,255,0.06) | #EEF0F6 | Input field bg |
| `settingsFrameSurface` | rgba(255,255,255,0.02) | rgba(15,23,42,0.02) | Framed section bg |
| `settingsPreviewSurface` | #15161A | #F8FAFC | Preview panel bg |
| `settingsFieldBorder` | rgba(255,255,255,0.12) | rgba(15,23,42,0.12) | Field border |

### Editor Interaction

| Token | Value | Usage |
|-------|-------|-------|
| `editorAnnotationHoverFill` | rgba(239,68,68,0.08) | Annotation hover halo fill |
| `editorAnnotationHoverStroke` | rgba(239,68,68,0.30) | Annotation hover outline |
| `editorAnnotationHoverShadow` | rgba(239,68,68,0.20) | Annotation hover glow |
| `editorAnnotationHoverShapeFill` | rgba(239,68,68,0.14) | Shape hover fill |

### Capture Overlay

Static dark-mode colors (no light variant — overlay is always dark).

| Token | Value | Usage |
|-------|-------|-------|
| `dimOverlay` | rgba(0,0,0,0.5) | Full-screen dim |
| `chromeBorder` | rgba(175,169,236,0.12) | Canvas/toolbar border |

---

## 4. Annotation Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `red` | #EF4444 | All annotation marks |
| `redFill` | rgba(239,68,68,0.06) | Shape fills |
| `redNoteBg` | rgba(255,248,248,0.82) | Note pill bg (tour illustrations) |
| `redNoteBorder` | rgba(239,68,68,0.18) | Note pill border (tour illustrations) |
| `noteTextColor` | #7F1D1D | Note pill text |

### Ghost Preview

| Token | Value | Usage |
|-------|-------|-------|
| `ghostDotRadius` | 3px | Ghost dot size |
| `ghostDotColor` | rgba(175,169,236,0.85) | Ghost dot fill |
| `ghostStrokeColor` | rgba(239,68,68,0.22) | Ghost stroke color |
| `ghostStrokeWidth` | 1.5px | Ghost stroke width |
| `ghostDashPattern` | [3, 2] | Ghost dash pattern |

---

## 5. Role Colors

8 preset role colors for multi-image annotation roles.

| Name | Border | Background |
|------|--------|------------|
| Purple (Observed) | `roleObservedBorder` #AFA9EC | `roleObservedBg` rgba(83,74,183,0.85) |
| Green (Expected) | `roleExpectedBorder` #22C55E | `roleExpectedBg` rgba(22,100,52,0.85) |
| Blue (Reference) | `roleReferenceBorder` #3B82F6 | `roleReferenceBg` rgba(30,70,140,0.85) |
| Orange | `roleOrangeBorder` #F97316 | — |
| Pink | `rolePinkBorder` #EC4899 | — |
| Teal | `roleTealBorder` #14B8A6 | — |
| Yellow | `roleYellowBorder` #EAB308 | — |
| Gray | `roleGrayBorder` #6B7280 | — |

Helper functions: `roleColor(forHex:)`, `roleBgColor(forHex:)`.
Swatch chrome: `roleSwatchOutline`, `roleSwatchInnerBorder`, `roleSwatchSelectedRing`.

---

## 6. Layout Tokens

### Annotation Dimensions

| Token | Value | Token | Value |
|-------|-------|-------|-------|
| `badgeDiameter` | 18 | `noteHeight` | 26 |
| `noteCornerRadius` | 13 | `strokeWidth` | 2.5 |
| `stakeLength` | 10 | `stakeWidth` | 2 |
| `selectionBorderWidth` | 1.5 | `minimumSelectionSize` | 10 |
| `arrowChevronLength` | 12 | `arrowChevronAngle` | 28° |
| `rectCornerRadius` | 3 | `freehandMinPoints` | 3 |
| `freehandSampleInterval` | 3 | | |

### Capture Overlay

| Token | Value | Token | Value |
|-------|-------|-------|-------|
| `crosshairTickLength` | 10 | `crosshairThickness` | 2.3 |
| `crosshairOpacity` | 0.85 | `dimensionLabelCornerRadius` | 5 |
| `dimensionLabelPaddingH` | 10 | `dimensionLabelHeight` | 24 |
| `dimensionLabelGap` | 10 | | |

### Toolbar

| Token | Value | Token | Value |
|-------|-------|-------|-------|
| `toolbarHeight` | 40 | `toolbarCornerRadius` | 20 |
| `toolButtonSize` | 30 | `toolbarToolButtonGap` | 2 |
| `iconButtonSize` | 28 | `closeButtonSize` | 24 |
| `statusPillCornerRadius` | 12 | | |

### Settings

| Token | Value | Token | Value |
|-------|-------|-------|-------|
| `settingsContentPadding` | 28 | `settingsSectionLabelWidth` | 128 |
| `settingsSectionGap` | 14 | `settingsFrameRadius` | 18 |
| `settingsFramePadding` | 18 | `settingsFieldHeight` | 32 |
| `settingsSegmentedHeight` | 28 | `settingsSegmentedInset` | 2 |
| `settingsSegmentedItemPadding` | 14 | `settingsPillHeight` | 28 |

### Filmstrip

| Token | Value | Token | Value |
|-------|-------|-------|-------|
| `filmstripGap` | 14 | `filmstripPadding` | 14 |
| `titlePillHeight` | 30 | `titlePillGap` | 6 |

### Fonts

| Token | Font |
|-------|------|
| `badgeFont` | System 9px semibold |
| `noteTextFont` | System 12px regular |
| `dimensionLabelFont` | Monospace 11px medium |
| `statusPillFont` | Monospace 10px medium |
| `settingsSectionFont` | System 13px medium |
| `settingsBodyFont` | System 12px regular |
| `settingsFieldFont` | Monospace 12px regular |
| `settingsPillFont` | System 11px semibold |
| `settingsSegmentedPrimaryFont` | System 12px semibold |
| `settingsSegmentedSecondaryFont` | System 11px medium |

---

## 7. Tour Illustrations

Tour illustration tokens live in `DesignTokens+TourIllustrations.swift`. They are for **fake UI wireframes** in the product tour only — not real app components.

See the file header for guidance on when to add tokens here vs in `DesignTokens.swift`.

Tour UI chrome (Next button, Back button) uses `pillButtonPrimary*` and ghost button borders from `DesignTokens+SetupTour.swift`. The Done button (green) uses `tourDoneButton*` tokens.

---

## 8. Appearance Strategy

| Surface | Mode | How |
|---------|------|-----|
| Capture overlay | Static dark | Direct NSColor values |
| Toolbar | Appearance-aware | `dynamicColor(dark:light:)` |
| Settings | Appearance-aware | `dynamicColor(dark:light:)` |
| Setup | Appearance-aware | System colors + `dynamicColor` |
| Tour | Appearance-aware | `dynamicColor(dark:light:)` |
| Tour illustrations | Mixed | Some static, some dynamic |

```swift
// How dynamicColor works:
static func dynamicColor(dark: NSColor, light: NSColor) -> NSColor {
    NSColor(name: nil) { appearance in
        isDarkAppearance(appearance) ? dark : light
    }
}
```

### Shared Appearance Surfaces

`SettingsUI.swift` provides the canonical surface styling functions:

- `styleSurface(_:background:border:cornerRadius:borderWidth:)` — fill/border shell for layer-backed controls
- `styleSegmentedTrackSurface(_:)` — segmented track + border
- `styleSegmentedHighlightSurface(_:)` — active segment fill + border
- `AppearanceAwareSurfaceView` / `AppearanceAwareSurfaceButton` — auto-refresh on appearance change
