# Vibeliner Design System — Token Reference

Last updated: 2026-04-07
Source of truth: `Vibeliner/Design/DesignTokens.swift`

---

## Color Tokens

### Purple — Brand & Active States

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `purpleLight` | #AFA9EC | Crosshair, selection border, active tool highlight, brand accent | ToolbarView, CanvasView, CaptureRowView, CrosshairView, FirstUseTooltipView, PromptTabView, SettingsWindowController |
| `purpleDark` | #534AB7 | Dimension label bg, settings accents | DimensionLabelView, SetupWindowController |
| `purpleButton` | #A796EB | Copy button outline and text (legacy) | SetupWindowController |
| `purpleButtonHover` | #C4B8F5 | Copy button hover (legacy) | — |
| `purpleButtonBg` | rgba(116, 97, 194, 0.25) | Copy button fill (legacy) | SetupWindowController |
| `purpleButtonBgHover` | rgba(116, 97, 194, 0.35) | Copy button hover fill (legacy) | — |

### Red — Annotations

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `red` | #EF4444 | All annotation marks (strokes, badges, caret) | ToolButton, CanvasView, NotePillRenderer, PinRenderer, FreehandRenderer, RectangleRenderer, CircleRenderer, ArrowRenderer, BadgeRenderer, AboutTabView |
| `redFill` | rgba(239, 68, 68, 0.06) | Rectangle/circle shape fills | RectangleRenderer, CircleRenderer |

### Red — Note Pills

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `redNoteBg` | rgba(255, 248, 248, 0.82) | Note pill default background | NotePillRenderer |
| `redNoteBorder` | rgba(239, 68, 68, 0.18) | Note pill default border | NotePillRenderer |
| `noteHoverBg` | rgba(255, 245, 245, 0.88) | Note pill hover background | NotePillRenderer |
| `noteHoverBorder` | rgba(239, 68, 68, 0.4) | Note pill hover border | NotePillRenderer |
| `noteSelectedBg` | rgba(255, 245, 245, 0.9) | Note pill selected background | NotePillRenderer |
| `noteSelectedBorder` | rgba(239, 68, 68, 0.5) | Note pill selected border | NotePillRenderer |
| `noteEditingBg` | rgba(255, 245, 245, 0.92) | Note pill editing background | CanvasView |
| `notePrefixColor` | rgba(153, 27, 27, 0.4) | Note number prefix color | NotePillRenderer |
| `noteTextColor` | #7F1D1D | Note body text color | NotePillRenderer |

### Green — Success States

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `copiedGreen` | rgba(22, 163, 74, 0.9) | Copied state green accent | ToolbarView, StatusPillView, CaptureRowView, PromptTabView |
| `copiedGreenBg` | rgba(22, 163, 74, 0.12) | Copied state background | ToolbarView, CaptureRowView, PromptTabView |
| `copiedGreenBorder` | rgba(22, 163, 74, 0.5) | Copied state border | ToolbarView, PromptTabView |
| `copiedGreenText` | rgba(22, 163, 74, 0.8) | Copied state text | ToolbarView, CaptureRowView, PromptTabView |

### Chrome — Floating UI (Legacy Static Dark)

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `darkChrome` | rgba(30, 30, 30, 0.92) | Toolbar (legacy) | — |
| `darkChromeStatus` | rgba(30, 30, 30, 0.88) | Status pill (legacy) | — |
| `darkChromePopover` | rgba(30, 30, 30, 0.95) | Popover (legacy) | — |
| `dimOverlay` | rgba(0, 0, 0, 0.5) | Capture overlay dim | CrosshairView |
| `dividerColor` | rgba(255, 255, 255, 0.08) | Divider (legacy) | — |
| `chromeBorder` | rgba(175, 169, 236, 0.12) | Toolbar/canvas border | ScreenshotCanvasView, CaptureRowView |

### Chrome — Icons & Buttons (Legacy Static Dark)

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `iconDefault` | rgba(255, 255, 255, 0.4) | Default icon stroke (legacy) | — |
| `iconHover` | rgba(255, 255, 255, 0.8) | Hover icon stroke (legacy) | — |
| `buttonHoverBg` | rgba(255, 255, 255, 0.08) | Button hover bg (legacy) | — |
| `toolActiveBg` | rgba(175, 169, 236, 0.2) | Active tool bg (legacy) | — |
| `closeHoverBg` | rgba(255, 87, 87, 0.2) | Close button hover (legacy) | — |
| `trashHoverBg` | rgba(255, 87, 87, 0.15) | Trash button hover (legacy) | — |
| `closeIconHover` | #FF5F57 | Close icon hover color (legacy) | — |

### Tooltip

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tooltipDarkBg` | rgba(28, 28, 32, 0.96) | Tooltip background | FirstUseTooltipView |
| `tooltipDarkBorder` | rgba(255, 255, 255, 0.1) | Tooltip border | FirstUseTooltipView |

### Toolbar — Appearance-Aware (VIB-235)

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `toolbarBg` | rgba(30,30,30,0.92) | rgba(255,255,255,0.88) | Toolbar background | ToolbarView |
| `toolbarBorder` | rgba(255,255,255,0.12) | rgba(0,0,0,0.06) | Toolbar border | ToolbarView |
| `toolbarIconDefault` | rgba(255,255,255,0.40) | rgba(0,0,0,0.45) | Icon default stroke | ToolButton |
| `toolbarIconHover` | rgba(255,255,255,0.70) | rgba(0,0,0,0.70) | Icon hover stroke | ToolButton |
| `toolbarDivider` | rgba(255,255,255,0.08) | rgba(0,0,0,0.08) | Toolbar dividers | ToolbarView |
| `toolbarPurpleActive` | #AFA9EC | #534AB7 | Active tool/toggle label | ToolbarView, ToolButton |
| `toolbarPurpleButtonBorder` | #A796EB | #534AB7 | Purple pill button border | ToolbarView |
| `toolbarPurpleButtonText` | #A796EB | #534AB7 | Purple pill button text | ToolbarView |
| `toolbarPurpleButtonBg` | rgba(116,97,194,0.25) | rgba(83,74,183,0.08) | Purple pill button bg | ToolbarView |
| `toolbarPurpleButtonHoverBorder` | #C4B8F5 | #7461C2 | Purple pill hover border | ToolbarView |
| `toolbarPurpleButtonHoverText` | #C4B8F5 | #7461C2 | Purple pill hover text | ToolbarView |
| `toolbarPurpleButtonHoverBg` | rgba(116,97,194,0.35) | rgba(83,74,183,0.12) | Purple pill hover bg | ToolbarView |
| `toolbarButtonHoverBg` | rgba(255,255,255,0.08) | rgba(0,0,0,0.06) | Generic button hover bg | ToolButton |
| `toolbarCloseHoverBg` | rgba(255,87,87,0.2) | rgba(255,87,87,0.15) | Close button hover bg | ToolButton |
| `toolbarCloseIconHover` | #FF5F57 | #FF5F57 | Close icon hover color | ToolButton |
| `toolbarTrashHoverBg` | rgba(255,87,87,0.15) | rgba(255,87,87,0.12) | Trash button hover bg | ToolButton |
| `toolbarToolActiveBg` | rgba(175,169,236,0.2) | rgba(83,74,183,0.12) | Selected tool bg | ToolButton |

### Secondary Toolbar Buttons — Appearance-Aware (VIB-330)

Used by "+ Add image" and "New capture" — subtle outlined style, secondary to Copy Prompt/Image.

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `toolbarSecondaryBorder` | rgba(255,255,255,0.20) | rgba(0,0,0,0.15) | Secondary button border | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryText` | rgba(255,255,255,0.60) | rgba(0,0,0,0.55) | Secondary button text | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryBg` | transparent | transparent | Secondary button bg | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryHoverBorder` | rgba(255,255,255,0.35) | rgba(0,0,0,0.25) | Secondary hover border | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryHoverText` | rgba(255,255,255,0.80) | rgba(0,0,0,0.75) | Secondary hover text | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryHoverBg` | rgba(255,255,255,0.05) | rgba(0,0,0,0.04) | Secondary hover bg | ToolbarView (SecondaryPillButton) |

### Add Image Button — Deprecated (VIB-262/320)

Replaced by `toolbarSecondary*` tokens in VIB-330. Kept for backward compatibility.

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `addImageBg` | rgba(175,169,236,0.14) | rgba(83,74,183,0.08) | Add image button bg (deprecated) | — |
| `addImageBorder` | rgba(175,169,236,0.22) | rgba(83,74,183,0.15) | Add image button border (deprecated) | — |
| `addImageHoverBorder` | rgba(175,169,236,0.34) | rgba(83,74,183,0.25) | Add image hover border (deprecated) | — |

### Toggle — Appearance-Aware

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `toolbarToggleBg` | rgba(255,255,255,0.06) | rgba(0,0,0,0.08) | Toggle container bg | ToolbarView |
| `toolbarToggleActiveBg` | rgba(175,169,236,0.25) | rgba(83,74,183,0.22) | Active segment bg | ToolbarView |
| `toolbarToggleInactiveText` | rgba(255,255,255,0.3) | rgba(0,0,0,0.40) | Inactive segment text | ToolbarView |

### Toggle — Legacy Static Dark

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `toggleActiveBg` | rgba(175, 169, 236, 0.25) | Toggle active bg (legacy) | — |
| `toggleBg` | rgba(255, 255, 255, 0.06) | Toggle bg (legacy) | — |
| `toggleInactiveText` | rgba(255, 255, 255, 0.3) | Toggle inactive text (legacy) | — |

### Status Pill — Appearance-Aware

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `statusPillBg` | rgba(30,30,30,0.88) | rgba(255,255,255,0.85) | Status pill bg | StatusPillView |
| `statusPillTextColor` | white | rgba(0,0,0,0.70) | Status pill text | StatusPillView |
| `statusPillBorder` | clear | rgba(0,0,0,0.06) | Status pill border | StatusPillView |

### Settings — Appearance-Aware

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `settingsFieldSurface` | rgba(255,255,255,0.06) | #EEF0F6 | Input field bg | SettingsUI |
| `settingsFrameSurface` | rgba(255,255,255,0.02) | rgba(15,23,42,0.02) | Framed section bg | SettingsUI |
| `settingsPreviewSurface` | #15161A | #F8FAFC | Preview panel bg | SettingsUI |
| `settingsSegmentedTrack` | rgba(255,255,255,0.03) | rgba(15,23,42,0.04) | Segmented control track | SettingsUI |
| `settingsSegmentedActive` | rgba(175,169,236,0.22) | rgba(175,169,236,0.18) | Segmented active fill | SettingsUI |
| `settingsPillBorder` | rgba(175,169,236,0.36) | rgba(114,103,221,0.26) | Pill button border | SettingsUI, PromptTabView |
| `settingsPillFill` | rgba(175,169,236,0.10) | rgba(175,169,236,0.16) | Pill button fill | SettingsUI, PromptTabView |
| `settingsPillText` | #AFA9EC | #7267DD | Pill button text | SettingsUI, AboutTabView, PromptTabView |
| `settingsFieldBorder` | rgba(255,255,255,0.12) | rgba(15,23,42,0.12) | Field border | SettingsUI |

### Role Colors

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `roleObservedBorder` | #AFA9EC (purple) | Observed role border | PromptTabView, FilmstripGridView, TitlePillView |
| `roleObservedBg` | rgba(83,74,183,0.50) | Observed role pill fill | TitlePillView, CompositeStitcher |
| `roleExpectedBorder` | #22C55E (green) | Expected role border | PromptTabView, FilmstripGridView, TitlePillView |
| `roleExpectedBg` | rgba(22,100,52,0.45) | Expected role pill fill | TitlePillView, CompositeStitcher |
| `roleReferenceBorder` | #3B82F6 (blue) | Reference role border | PromptTabView, FilmstripGridView, TitlePillView |
| `roleReferenceBg` | rgba(30,70,140,0.45) | Reference role pill fill | TitlePillView, CompositeStitcher |

### Filmstrip & Title Pill

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `filmstripGap` | 14px | Gap between filmstrip cells | FilmstripGridView, CompositeStitcher |
| `filmstripPadding` | 14px | Composite export padding | CompositeStitcher |
| `filmstripBg` | rgba(15,23,42,0.85) | Composite export background | CompositeStitcher |
| `titlePillHeight` | 30px | Height of title pill in filmstrip | TitlePillView, FilmstripGridView |
| `titlePillGap` | 6px | Gap between title pill and image | FilmstripGridView |
| `titlePillExportShadow` | rgba(0,0,0,0.3) | Export title pill shadow | CompositeStitcher |
| `minCellWidth` | 200px | Minimum filmstrip cell width before scrolling | FilmstripGridView |

### Ghost Preview

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `ghostDotColor` | rgba(175, 169, 236, 0.85) | Ghost anchor dot | PinTool, RectangleTool, CircleTool, ArrowTool, FreehandTool |
| `ghostStrokeColor` | rgba(239, 68, 68, 0.22) | Ghost silhouette stroke | PinTool, RectangleTool, CircleTool, ArrowTool |
| `ghostDashPattern` | [3, 2] | Ghost dash pattern | PinTool, RectangleTool, CircleTool, ArrowTool |

### Setup Window Colors (Static Dark)

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `setupGreen` | #22C55E | Badge done border/text | SetupWindowController |
| `setupGreenBadgeBg` | rgba(34,197,94,0.1) | Badge done fill | SetupWindowController |
| `setupGreenText` | #16A34A | Status text, green button text | SetupWindowController |
| `setupGreenBg` | rgba(34,197,94,0.08) | Green button fill | SetupWindowController |
| `setupGreenBorder` | rgba(34,197,94,0.5) | Green button border | SetupWindowController |
| `setupAmberBg` | rgba(234,179,8,0.08) | Amber status background | — |
| `setupAmberText` | #B45309 | Amber status text | SetupWindowController |
| `setupWindowBg` | #1E1E1E | Window background | SetupWindowController |
| `setupTitleBarBg` | #2A2A2A | Title bar background | — |
| `setupFooterBg` | #222222 | Footer background | SetupWindowController |
| `setupBorder` | #333333 | Dividers and borders | SetupWindowController |
| `setupFieldBg` | rgba(255,255,255,0.05) | Field background | SetupWindowController |
| `setupFieldBorder` | rgba(255,255,255,0.08) | Field border | SetupWindowController |
| `setupTextPrimary` | #E0E0E0 | Primary text | SetupWindowController |
| `setupTextSecondary` | #888888 | Secondary text | SetupWindowController |
| `setupTextDim` | #666666 | Dim/helper text | SetupWindowController |
| `setupGrayText` | #555555 | Locked badge/gray status | SetupWindowController |
| `setupGrayBg` | rgba(255,255,255,0.03) | Locked badge bg | SetupWindowController |
| `setupButtonFill` | rgba(175,169,236,0.08) | Action button fill | SetupWindowController |
| `setupButtonBorder` | rgba(175,169,236,0.55) | Action button border | SetupWindowController |
| `setupButtonText` | #6F69DF | Action button/label text | SetupWindowController |
| `setupButtonHoverBg` | rgba(175,169,236,0.16) | Arrow hover bg | — |
| `setupKbdBorder` | rgba(255,255,255,0.12) | Kbd pill border | SetupWindowController |
| `setupKbdBg` | rgba(255,255,255,0.08) | Kbd pill bg | SetupWindowController |
| `setupKbdText` | rgba(255,255,255,0.55) | Kbd pill text | SetupWindowController |

---

## Dimension Tokens

### Annotations

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `badgeDiameter` | 18px | Badge diameter (radius 9) | CanvasView, NotePillRenderer, PinTool, SelectTool, PinRenderer, ArrowRenderer, BadgeRenderer |
| `noteHeight` | 26px | Note pill height | CanvasView, NotePillRenderer |
| `noteCornerRadius` | 13px | Note pill corner radius | CanvasView, NotePillRenderer |
| `strokeWidth` | 2.5px | Annotation tool strokes | CircleRenderer, RectangleRenderer, FreehandRenderer, ArrowRenderer |
| `stakeLength` | 10px | Pin stake length | CanvasView, PinTool, PinRenderer |
| `stakeWidth` | 2px | Pin stake width | PinRenderer |

### Capture Overlay

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `crosshairTickLength` | 10px | Crosshair tick length | CrosshairView |
| `crosshairThickness` | 2.3px | Crosshair line thickness | CrosshairView |
| `crosshairOpacity` | 0.85 | Crosshair opacity | CrosshairView |
| `selectionBorderWidth` | 1.5px | Selection border width | CrosshairView |
| `minimumSelectionSize` | 10px | Minimum selection size | CaptureCoordinator |

### Dimension Label

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `dimensionLabelCornerRadius` | 5px | Corner radius | DimensionLabelView |
| `dimensionLabelPaddingH` | 10px | Horizontal padding | DimensionLabelView |
| `dimensionLabelHeight` | 24px | Label height | DimensionLabelView |
| `dimensionLabelGap` | 10px | Gap below selection | DimensionLabelView |

### Toolbar

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `toolbarHeight` | 40px | Toolbar height | ToolbarView, EditorPanel |
| `toolbarCornerRadius` | 20px | Toolbar corner radius | ToolbarView |
| `toolbarBlur` | 12px | Toolbar blur radius | ToolbarView |
| `toolButtonSize` | 30px | Tool button size | ToolbarView, ToolButton |
| `iconButtonSize` | 28px | Icon button size | ToolbarView, ToolButton |
| `closeButtonSize` | 24px | Close button size | ToolbarView, ToolButton |

### Status Pill

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `statusPillCornerRadius` | 12px | Corner radius | StatusPillView |
| `statusPillBlur` | 8px | Blur radius | StatusPillView |

### Arrow Tool

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `arrowChevronLength` | 12px | Chevron arm length | ArrowRenderer |
| `arrowChevronAngle` | 28° | Chevron angle | ArrowRenderer |

### Shape Tools

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `rectCornerRadius` | 3px | Rectangle corner radius | RectangleRenderer |
| `freehandMinPoints` | 3 | Minimum freehand points | FreehandTool |
| `freehandSampleInterval` | 3px | Freehand sample interval | FreehandTool |

### Ghost Preview

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `ghostDotRadius` | 3px | Anchor dot radius | PinTool, RectangleTool, CircleTool, ArrowTool, FreehandTool |
| `ghostStrokeWidth` | 1.5px | Silhouette stroke width | PinTool, RectangleTool, CircleTool, ArrowTool |

### Settings

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `settingsContentPadding` | 28px | Content horizontal padding | PromptTabView, GeneralTabView, AboutTabView |
| `settingsSectionLabelWidth` | 128px | Section title width | SettingsUI |
| `settingsSectionPadding` | 24px | Section vertical spacing | — |
| `settingsSectionGap` | 14px | Section inner gap | GeneralTabView |
| `settingsFrameRadius` | 18px | Framed section radius | SettingsUI |
| `settingsFramePadding` | 18px | Framed section padding | PromptTabView |
| `settingsFieldHeight` | 32px | Field height | SettingsUI, GeneralTabView, PromptTabView |
| `settingsSegmentedHeight` | 28px | Segmented control height | SettingsUI |
| `settingsSegmentedInset` | 2px | Segmented control inset | SettingsUI |
| `settingsPillHeight` | 28px | Pill button height | SettingsUI |

### Setup Window

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `setupWindowWidth` | 700px | Window width | SetupWindowController |
| `setupPanelHeight` | 310px | Panel height | SetupWindowController |
| `setupFooterHeight` | 56px | Footer height | SetupWindowController |
| `setupPanelPad` | 28px | Panel padding | SetupWindowController |
| `setupBadgeSize` | 32px | Badge size | SetupWindowController |
| `setupArrowSize` | 36px | Arrow button size | SetupWindowController |
| `setupSmallPillHeight` | 22px | Small pill height | SetupWindowController |
| `setupWindowRadius` | 18px | Window corner radius | — |
| `setupPathBoxRadius` | 8px | Path box corner radius | SetupWindowController |

---

## Font Tokens

| Token | Spec | Usage | Consuming files |
|-------|------|-------|-----------------|
| `badgeFont` | System 9px semibold | Badge numbers | BadgeRenderer |
| `noteNumberFont` | System 8px semibold | Note number prefix | NotePillRenderer |
| `noteTextFont` | System 12px regular | Note body text | CanvasView, NotePillRenderer |
| `dimensionLabelFont` | Mono 11px medium | Dimension label | DimensionLabelView |
| `statusPillFont` | Mono 10px medium | Status pill text | StatusPillView |
| `toolbarButtonFont` | System 11px medium | Toolbar button labels | — |
| `tooltipBodyFont` | System 12px regular | Tooltip body | — |
| `tooltipLabelFont` | System 13px semibold | Tooltip labels | — |
| `settingsSectionFont` | System 13px medium | Section labels | SettingsUI |
| `settingsBodyFont` | System 12px regular | Body copy | SettingsUI |
| `settingsFieldFont` | Mono 12px regular | Field text | SettingsUI |
| `settingsPillFont` | System 11px semibold | Pill button text | — |

### Setup Window Fonts

| Token | Spec | Usage | Consuming files |
|-------|------|-------|-----------------|
| `setupWindowTitleFont` | System 18px semibold | Window title | — |
| `setupPanelTitleFont` | System 16px semibold | Panel titles | SetupWindowController |
| `setupDescFont` | System 13px regular | Description text | SetupWindowController |
| `setupActionLabelFont` | System 13px semibold | Action labels | SetupWindowController |
| `setupHelperFont` | System 11px regular | Helper text | SetupWindowController |
| `setupPathFont` | Mono 13px regular | Path display | SetupWindowController |
| `setupStatusFont` | System 13px semibold | Status text | SetupWindowController |
| `setupSmallPillFont` | System 11px medium | Small pill text | SetupWindowController |
| `setupBadgeFont` | System 14px semibold | Badge numbers | SetupWindowController |
| `setupBadgeCheckFont` | System 16px bold | Badge checkmarks | SetupWindowController |
| `setupKbdFont` | System 12px semibold | Keyboard pills | SetupWindowController |
| `setupShortcutHintFont` | System 12px regular | Shortcut hints | SetupWindowController |

---

## Appearance Strategy

| Surface | Mode | How to set colors |
|---------|------|-------------------|
| Capture overlay | Static dark | DesignTokens directly (`dimOverlay`, `purpleLight`) |
| Editor toolbar | Appearance-aware | Dynamic `NSColor(name:)` tokens (`toolbarBg`, `toolbarBorder`, etc.) |
| Tool buttons | Appearance-aware | Dynamic tokens (`toolbarIconDefault`, `toolbarToolActiveBg`, etc.) |
| Status pill | Appearance-aware | Dynamic tokens (`statusPillBg`, `statusPillTextColor`, etc.) |
| Annotation marks | Static (on screenshot) | DesignTokens directly (`red`, `strokeWidth`) |
| Note pills | Static (on screenshot) | DesignTokens directly (`redNoteBg`, `noteTextColor`) |
| Ghost previews | Static (on screenshot) | DesignTokens directly (`ghostDotColor`, `ghostStrokeColor`) |
| Popover menu | Appearance-aware | System colors + `.popover` material |
| Settings window | Appearance-aware | Dynamic tokens (`settingsFieldSurface`, `settingsPillText`, etc.) |
| Setup window | Static dark | DesignTokens directly (`setupWindowBg`, `setupBorder`, etc.) |

### How appearance-aware tokens work

```swift
// Dynamic NSColor that resolves differently per appearance
static let toolbarBg = NSColor(name: nil) { appearance in
    isDarkAppearance(appearance)
        ? NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.92)
        : NSColor(white: 1.0, alpha: 0.88)
}
```

- Works automatically with SwiftUI views
- For AppKit layer properties (`layer?.backgroundColor`), must use `performAsCurrentDrawingAppearance` or re-apply in `viewDidChangeEffectiveAppearance()`
- Blur backgrounds use `.popover` material which auto-adapts

---

## Utilities

### `makeCenteredTextField(_:font:color:in:)`
Creates an `NSTextField` vertically centered within a container frame. Used for badges, labels, and status text.

### `VerticallyCenteredTextFieldCell`
`NSTextFieldCell` subclass that vertically centers text. Has configurable `horizontalPadding` (default 12px). Used in settings path boxes and fixed-height fields.
