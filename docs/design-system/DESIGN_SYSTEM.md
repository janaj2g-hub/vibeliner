# Vibeliner Design System — Token Reference

Last updated: 2026-04-08
Source of truth: `Vibeliner/Design/DesignTokens.swift`

---

## Color Tokens

### Purple — Brand & Active States

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `purpleLight` | #AFA9EC | Crosshair, selection border, active tool highlight, brand accent | ToolbarView, CanvasView, CaptureRowView, CrosshairView, FirstUseTooltipView, PromptTabView, SettingsWindowController |
| `purpleDark` | #534AB7 | Dimension label bg, settings accents | DimensionLabelView, SetupWindowController |
| `purpleButton` | #A796EB | Copy button outline and text (legacy) | SetupWindowController |
| `purpleButtonBg` | rgba(116, 97, 194, 0.25) | Copy button fill (legacy) | SetupWindowController |

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
| `dimOverlay` | rgba(0, 0, 0, 0.5) | Capture overlay dim | CrosshairView |
| `dividerColor` | rgba(255, 255, 255, 0.08) | Divider (legacy) | — |
| `chromeBorder` | rgba(175, 169, 236, 0.12) | Toolbar/canvas border | ScreenshotCanvasView, CaptureRowView |

### Tooltip

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tooltipDarkBg` | rgba(28, 28, 32, 0.96) | Tooltip background | FirstUseTooltipView |
| `tooltipDarkBorder` | rgba(255, 255, 255, 0.1) | Tooltip border | FirstUseTooltipView |

### Toolbar — Appearance-Aware (VIB-235)

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `toolbarBg` | rgba(30,30,30,0.92) | rgba(255,255,255,0.88) | Toolbar background | ToolbarView |
| `toolbarBorder` | rgba(255,255,255,0.12) | rgba(0,0,0,0.10) | Toolbar border | ToolbarView |
| `toolbarIconDefault` | rgba(255,255,255,0.40) | rgba(0,0,0,0.45) | Icon default stroke | ToolButton |
| `toolbarIconHover` | rgba(255,255,255,0.70) | rgba(0,0,0,0.70) | Icon hover stroke | ToolButton |
| `toolbarDivider` | rgba(255,255,255,0.08) | rgba(0,0,0,0.12) | Toolbar dividers | ToolbarView |
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
| `toolbarSecondaryText` | rgba(255,255,255,0.60) | rgba(0,0,0,0.65) | Secondary button text | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryBg` | transparent | transparent | Secondary button bg | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryHoverBorder` | rgba(255,255,255,0.35) | rgba(0,0,0,0.25) | Secondary hover border | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryHoverText` | rgba(255,255,255,0.80) | rgba(0,0,0,0.75) | Secondary hover text | ToolbarView (SecondaryPillButton) |
| `toolbarSecondaryHoverBg` | rgba(255,255,255,0.05) | rgba(0,0,0,0.04) | Secondary hover bg | ToolbarView (SecondaryPillButton) |

### Add Image Button

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `addImageBg` | rgba(175,169,236,0.14) | rgba(83,74,183,0.08) | Add image button bg | TourMiniToolbar |
| `addImageBorder` | rgba(175,169,236,0.22) | rgba(83,74,183,0.15) | Add image button border | TourMiniToolbar |

### Toggle — Appearance-Aware

| Token | Dark value | Light value | Usage | Consuming files |
|-------|-----------|-------------|-------|-----------------|
| `toolbarToggleBg` | rgba(255,255,255,0.06) | rgba(0,0,0,0.08) | Toggle container bg | ToolbarView |
| `toolbarToggleActiveBg` | rgba(175,169,236,0.25) | rgba(83,74,183,0.22) | Active segment bg | ToolbarView |
| `toolbarToggleInactiveText` | rgba(255,255,255,0.3) | rgba(0,0,0,0.40) | Inactive segment text | ToolbarView |

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
| `roleObservedBg` | rgba(83,74,183,0.85) | Observed role pill fill | TitlePillView, CompositeStitcher |
| `roleExpectedBorder` | #22C55E (green) | Expected role border | PromptTabView, FilmstripGridView, TitlePillView |
| `roleExpectedBg` | rgba(22,100,52,0.85) | Expected role pill fill | TitlePillView, CompositeStitcher |
| `roleReferenceBorder` | #3B82F6 (blue) | Reference role border | PromptTabView, FilmstripGridView, TitlePillView |
| `roleReferenceBg` | rgba(30,70,140,0.85) | Reference role pill fill | TitlePillView, CompositeStitcher |

### Filmstrip & Title Pill

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `filmstripGap` | 14px | Gap between filmstrip cells | FilmstripGridView, CompositeStitcher |
| `filmstripPadding` | 14px | Composite export padding | CompositeStitcher |
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
| `setupAmberText` | #B45309 | Amber status text | SetupWindowController |
| `setupWindowBg` | #1E1E1E | Window background | SetupWindowController |
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
| `setupKbdBorder` | rgba(255,255,255,0.12) | Kbd pill border | SetupWindowController |
| `setupKbdBg` | rgba(255,255,255,0.08) | Kbd pill bg | SetupWindowController |
| `setupKbdText` | rgba(255,255,255,0.55) | Kbd pill text | SetupWindowController |

### Tour Window Colors (Static Dark)

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourWindowBg` | rgba(30,30,30,0.92) | Tour window background | TourWindowController |
| `tourBarOverlay` | rgba(255,255,255,0.015) | Header/footer overlay | TourWindowController |
| `tourProgressActive` | #AFA9EC | Active progress bar | TourWindowController |
| `tourProgressInactive` | rgba(255,255,255,0.06) | Inactive progress bar | TourWindowController |
| `tourTextPrimary` | #E0E0E0 | Tour primary text | TourWindowController |
| `tourTextSecondary` | rgba(255,255,255,0.55) | Tour secondary text | TourWindowController |
| `tourTextDim` | rgba(255,255,255,0.35) | Tour dim text | TourWindowController |

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
| `toolButtonSize` | 30px | Tool button size | ToolbarView, ToolButton |
| `iconButtonSize` | 28px | Icon button size | ToolbarView, ToolButton |
| `closeButtonSize` | 24px | Close button size | ToolbarView, ToolButton |

### Status Pill

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `statusPillCornerRadius` | 12px | Corner radius | StatusPillView |

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
| `setupPathBoxRadius` | 8px | Path box corner radius | SetupWindowController |

### Tour Window

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourWindowWidth` | 880px | Window width | TourWindowController |
| `tourWindowHeight` | 700px | Window height | TourWindowController |
| `tourWindowRadius` | 10px | Window corner radius | TourWindowController |
| `tourHeaderHeight` | 44px | Header bar height | TourWindowController |
| `tourFooterHeight` | 48px | Footer bar height | TourWindowController |
| `tourIllustrationRatio` | 0.6 | Illustration pane width ratio | TourWindowController |
| `tourTextMaxWidth` | 300px | Text pane max content width | TourWindowController |
| `tourProgressBarWidth` | 16px | Progress bar segment width | TourWindowController |
| `tourProgressBarHeight` | 3px | Progress bar segment height | TourWindowController |
| `tourNextButtonHeight` | 34px | Next/Back button height | TourWindowController |
| `tourNextButtonPaddingH` | 18px | Next button horizontal padding | TourWindowController |

---

## Font Tokens

| Token | Spec | Usage | Consuming files |
|-------|------|-------|-----------------|
| `badgeFont` | System 9px semibold | Badge numbers | BadgeRenderer |
| `noteTextFont` | System 12px regular | Note body text | CanvasView, NotePillRenderer |
| `dimensionLabelFont` | Mono 11px medium | Dimension label | DimensionLabelView |
| `statusPillFont` | Mono 10px medium | Status pill text | StatusPillView |
| `settingsSectionFont` | System 13px medium | Section labels | SettingsUI |
| `settingsBodyFont` | System 12px regular | Body copy | SettingsUI |
| `settingsFieldFont` | Mono 12px regular | Field text | SettingsUI |
| `settingsPillFont` | System 11px semibold | Pill button text | — |

### Setup Window Fonts

| Token | Spec | Usage | Consuming files |
|-------|------|-------|-----------------|
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

### Tour Window Fonts

| Token | Spec | Usage | Consuming files |
|-------|------|-------|-----------------|
| `tourHeaderFont` | System 13px semibold | Header title | TourWindowController |
| `tourStepBadgeFont` | System 11px medium | Step badge ("Step N of 9") | TourWindowController |
| `tourTitleFont` | System 22px bold | Step title | TourWindowController |
| `tourBodyFont` | System 14px regular | Step body text | TourWindowController |
| `tourProgressFont` | System 11px medium | Progress label | TourWindowController |
| `tourButtonFont` | System 13px semibold | Navigation buttons | TourWindowController |
| `tourExitFont` | System 11px semibold | Exit tour button | TourWindowController |
| `tourDoneTitleFont` | System 26px bold | Final step heading | TourWindowController |

### Tour Illustration

#### Illustration Pane

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourIllustrationPadding` | 24px | Internal pane padding | TourIllustration0-7 |
| `tourIllustrationBgTint` | rgba(0,0,0,0.08) | Pane background tint | TourIllustration0-7 |
| `tourIllustrationGlow` | rgba(175,169,236,0.06) | Pane purple glow | TourIllustration0-7 |

#### Wireframe App Mock

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourWireframeBgTop` | #F6F8FC | Wireframe gradient top | WireframeAppMock |
| `tourWireframeBgBottom` | #EEF1F7 | Wireframe gradient bottom | WireframeAppMock |
| `tourWireframeTopbarBg` | rgba(255,255,255,0.8) | Topbar background | WireframeAppMock |
| `tourWireframeTopbarBorder` | rgba(0,0,0,0.05) | Topbar border | WireframeAppMock |
| `tourWireframeSidebarBg` | rgba(245,247,252,0.9) | Sidebar background | WireframeAppMock |
| `tourWireframeSidebarBorder` | rgba(0,0,0,0.04) | Sidebar border | WireframeAppMock |
| `tourWireframeSidebarItem` | rgba(15,23,42,0.07) | Sidebar item placeholder | WireframeAppMock |
| `tourWireframeSidebarActive` | rgba(83,74,183,0.16) | Sidebar active item | WireframeAppMock |
| `tourWireframeHeading` | rgba(83,74,183,0.14) | Heading placeholder | WireframeAppMock |
| `tourWireframeCardBg` | rgba(255,255,255,0.85) | Card background | WireframeAppMock |
| `tourWireframeCardBorder` | rgba(0,0,0,0.04) | Card border | WireframeAppMock |
| `tourWireframeCardErrorBorder` | rgba(239,68,68,0.2) | Error card border | WireframeAppMock |
| `tourWireframeCardErrorBg` | rgba(255,245,245,0.9) | Error card background | WireframeAppMock |
| `tourWireframeLine` | rgba(15,23,42,0.08) | Content line placeholder | WireframeAppMock |
| `tourWireframeTableBg` | rgba(255,255,255,0.8) | Table background | WireframeAppMock |
| `tourWireframeTableBorder` | rgba(0,0,0,0.04) | Table border | WireframeAppMock |
| `tourWireframeTableHeadBg` | rgba(240,242,248,0.9) | Table header background | WireframeAppMock |
| `tourWireframeTableRowBorder` | rgba(0,0,0,0.04) | Table row border | WireframeAppMock |
| `tourWireframeTableErrorBg` | rgba(255,235,235,0.6) | Table error row background | WireframeAppMock |
| `tourWireframeTableCell` | rgba(15,23,42,0.07) | Table cell placeholder | WireframeAppMock |
| `tourWireframeRadius` | 8px | Wireframe corner radius | WireframeAppMock |
| `tourWireframeTopbarHeight` | 36px | Topbar height | WireframeAppMock |
| `tourWireframeSidebarWidth` | 100px | Sidebar width | WireframeAppMock |
| `tourWireframeCardHeight` | 64px | Card height | WireframeAppMock |
| `tourWireframeCardRadius` | 6px | Card corner radius | WireframeAppMock |
| `tourWireframeTableRadius` | 6px | Table corner radius | WireframeAppMock |
| `tourWireframeBrandIconSize` | 16px | Brand icon size | WireframeAppMock |
| `tourWireframeBrandFont` | System 11px bold | Brand label font | WireframeAppMock |
| `tourWireframeBrandColor` | #263041 | Brand label color | WireframeAppMock |
| `tourWireframeNavPillHeight` | 8px | Nav pill height | WireframeAppMock |

#### Output Card

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourOutputCardBg` | rgba(255,255,255,0.03) | Output card background | TourOutputCard, TourIllustration6, TourIllustration7 |
| `tourOutputCardBorder` | rgba(255,255,255,0.06) | Output card border | TourOutputCard, TourIllustration6, TourIllustration7 |
| `tourOutputCardRadius` | 6px | Output card corner radius | TourOutputCard, TourIllustration6, TourIllustration7 |
| `tourOutputCardPadding` | 10px | Output card padding | TourOutputCard, TourIllustration6, TourIllustration7 |
| `tourOutputLabelBg` | rgba(255,255,255,0.05) | Output label background | TourOutputCard, TourIllustration6, TourIllustration7 |
| `tourOutputLabelBorder` | rgba(255,255,255,0.06) | Output label border | TourOutputCard, TourIllustration6, TourIllustration7 |
| `tourOutputLabelFont` | System 10px bold | Output label font | TourOutputCard, TourIllustration6, TourIllustration7 |
| `tourOutputLabelPaddingH` | 8px | Output label horizontal padding | TourOutputCard |
| `tourOutputLabelPaddingV` | 3px | Output label vertical padding | TourOutputCard |
| `tourOutputLabelGap` | 8px | Gap between output label and content | TourOutputCard |

#### Prompt Sheet

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourPromptSheetBg` | rgba(255,255,255,0.04) | Prompt sheet background | TourPromptSheet |
| `tourPromptSheetBorder` | rgba(255,255,255,0.06) | Prompt sheet border | TourPromptSheet |
| `tourPromptSheetRadius` | 6px | Prompt sheet corner radius | TourPromptSheet |
| `tourPromptSheetPaddingH` | 14px | Prompt sheet horizontal padding | TourPromptSheet |
| `tourPromptSheetPaddingV` | 16px | Prompt sheet vertical padding | TourPromptSheet |
| `tourPromptSheetFont` | Mono 10.5px regular | Prompt sheet font | TourPromptSheet |
| `tourPromptSheetLineHeight` | 17.85px | Prompt sheet line height (1.7x) | TourPromptSheet |
| `tourPromptSheetColor` | rgba(255,255,255,0.68) | Prompt sheet text color | TourPromptSheet |
| `tourPromptSheetDim` | rgba(255,255,255,0.3) | Prompt sheet dim text | TourPromptSheet |
| `tourPromptSheetNumber` | #F87171 | Prompt sheet number color | TourPromptSheet |

#### Tour Title Pill

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourTitlePillHeight` | 22px | Tour title pill height | TourTitlePill |
| `tourTitlePillPaddingLeading` | 8px | Tour title pill left padding | TourTitlePill |
| `tourTitlePillPaddingTrailing` | 4px | Tour title pill right padding | TourTitlePill |
| `tourTitlePillGap` | 5px | Gap between title text and role tag | TourTitlePill |
| `tourTitlePillFont` | System 9px semibold | Tour title pill font | TourTitlePill |
| `tourTitlePillText` | #FFFFFF | Tour title pill text color | TourTitlePill |
| `tourTitlePillTagFont` | System 8px bold | Tour title pill role-tag font | TourTitlePill |
| `tourTitlePillTagPaddingH` | 6px | Role-tag horizontal padding | TourTitlePill |
| `tourTitlePillTagPaddingV` | 2px | Role-tag vertical padding | TourTitlePill |
| `tourTitlePillShadowColor` | rgba(0,0,0,0.15) | Tour title pill shadow color | TourTitlePill |
| `tourTitlePillShadowBlur` | 8px | Tour title pill shadow blur | TourTitlePill |
| `tourTitlePillShadowYOffset` | 2px | Tour title pill shadow offset | TourTitlePill |

#### LLM Chat Panel

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourLLMPanelBg` | rgba(255,255,255,0.025) | LLM panel background | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMPanelBorder` | rgba(255,255,255,0.06) | LLM panel border | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMPanelRadius` | 8px | LLM panel corner radius | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMDotSize` | 7px | LLM status dot size | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMHeaderFont` | System 11px bold | LLM header font | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMBubbleBg` | rgba(255,255,255,0.05) | LLM bubble background | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMBubbleFont` | System 11px regular | LLM bubble font | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMChatFont` | Mono 10.5px regular | LLM chat font | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMChatColor` | rgba(255,255,255,0.55) | LLM chat text color | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMComposerBg` | rgba(255,255,255,0.04) | LLM composer background | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMComposerBorder` | rgba(255,255,255,0.06) | LLM composer border | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMComposerRadius` | 8px | LLM composer corner radius | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMThumbWidth` | 36px | LLM thumbnail width | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMThumbHeight` | 28px | LLM thumbnail height | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMSendSize` | 24px | LLM send button size | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |
| `tourLLMSendBg` | rgba(175,169,236,0.2) | LLM send button background | TourIllustration0, TourIllustration2, TourIllustration4, TourIllustration6 |

#### Flow Arrow

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourFlowArrowWidth` | 2px | Flow arrow stroke width | AnnotationMarkViews |
| `tourFlowArrowHeight` | 28px | Flow arrow height | AnnotationMarkViews |
| `tourFlowArrowColor` | rgba(175,169,236,0.5) | Flow arrow color | AnnotationMarkViews |
| `tourFlowArrowChevronSize` | 10px | Flow arrow chevron size | AnnotationMarkViews |

#### Mini Screenshot

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourMiniScreenshotRadius` | 4px | Mini screenshot corner radius | Tour Illustrations |
| `tourMiniScreenshotBgTop` | #F6F8FC | Mini screenshot gradient top | TourMiniScreenshot |
| `tourMiniScreenshotBgBottom` | #EEF1F7 | Mini screenshot gradient bottom | TourMiniScreenshot |
| `tourMiniScreenshotShadowColor` | rgba(0,0,0,0.12) | Mini screenshot shadow color | TourMiniScreenshot |
| `tourMiniScreenshotShadowBlur` | 16px | Mini screenshot shadow blur | TourMiniScreenshot |
| `tourMiniScreenshotShadowYOffset` | 4px | Mini screenshot shadow offset | TourMiniScreenshot |
| `tourMiniScreenshotBarHeight` | 18px | Mini screenshot title bar height | Tour Illustrations |
| `tourMiniScreenshotBarBg` | rgba(255,255,255,0.7) | Mini screenshot title bar bg | Tour Illustrations |
| `tourMiniScreenshotBarPaddingH` | 6px | Mini screenshot title bar padding | TourMiniScreenshot |
| `tourMiniScreenshotDotSize` | 5px | Mini screenshot traffic light dot | Tour Illustrations |
| `tourMiniScreenshotDotGap` | 4px | Mini screenshot traffic light gap | TourMiniScreenshot |
| `tourMiniScreenshotDotColor` | rgba(15,23,42,0.15) | Mini screenshot dot color | Tour Illustrations |
| `tourMiniScreenshotBodyHeight` | 80px | Mini screenshot body height | Tour Illustrations |
| `tourMiniScreenshotRailWidth` | 30px | Mini screenshot sidebar rail width | Tour Illustrations |
| `tourMiniScreenshotRailBg` | rgba(245,247,252,0.9) | Mini screenshot rail background | Tour Illustrations |
| `tourMiniScreenshotRailPaddingV` | 6px | Mini screenshot rail vertical padding | TourMiniScreenshot |
| `tourMiniScreenshotRailPaddingH` | 4px | Mini screenshot rail horizontal padding | TourMiniScreenshot |
| `tourMiniScreenshotRailGap` | 4px | Mini screenshot rail pill gap | TourMiniScreenshot |
| `tourMiniScreenshotRailPillHeight` | 6px | Mini screenshot rail pill height | TourMiniScreenshot |
| `tourMiniScreenshotRailPillColor` | rgba(15,23,42,0.07) | Mini screenshot rail pill color | TourMiniScreenshot |
| `tourMiniScreenshotContentPadding` | 8px | Mini screenshot content padding | TourMiniScreenshot |
| `tourMiniScreenshotContentGap` | 4px | Mini screenshot content line gap | TourMiniScreenshot |
| `tourMiniScreenshotLineHeight` | 6px | Mini screenshot content line height | TourMiniScreenshot |
| `tourMiniScreenshotLineColor` | rgba(15,23,42,0.06) | Mini screenshot content line color | Tour Illustrations |
| `tourMiniScreenshotAccent` | rgba(83,74,183,0.12) | Mini screenshot accent | Tour Illustrations |
| `tourMiniScreenshotAccentWidthRatio` | 0.5 | Mini screenshot accent width ratio | TourMiniScreenshot |
| `tourMiniScreenshotBadgeBg` | #EF4444 | Mini screenshot badge fill | TourMiniScreenshot |
| `tourMiniScreenshotBadgeText` | #FFFFFF | Mini screenshot badge text | TourMiniScreenshot |
| `tourMiniScreenshotMarkColor` | #EF4444 | Mini screenshot annotation mark stroke | TourMiniScreenshot |
| `tourMiniScreenshotRectFill` | rgba(239,68,68,0.06) | Mini screenshot annotation rect fill | TourMiniScreenshot |
| `tourMiniScreenshotRectRadius` | 2px | Mini screenshot annotation rect radius | TourMiniScreenshot |
| `tourMiniBadgeSize` | 14px | Mini annotation badge size | Tour Illustrations |
| `tourMiniBadgeFont` | System 7px bold | Mini annotation badge font | TourMiniScreenshot, TourFilmstripCell |
| `tourMiniRectStroke` | 1.5px | Mini annotation rect stroke | Tour Illustrations |

#### Mode Card

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourModeCardBg` | rgba(255,255,255,0.025) | Mode card background | TourIllustration5 |
| `tourModeCardBorder` | rgba(255,255,255,0.06) | Mode card border | TourIllustration5 |
| `tourModeCardRadius` | 8px | Mode card corner radius | TourIllustration5 |
| `tourModeCardPadding` | 14px | Mode card padding | TourIllustration5 |
| `tourModeLabelFont` | System 12px bold | Mode card label font | TourIllustration5 |
| `tourModeDescFont` | System 11px regular | Mode card description font | TourIllustration5 |
| `tourModeSectionFont` | System 10px bold | Mode card section font | TourIllustration5 |

#### Example Chip

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourChipBg` | rgba(255,255,255,0.04) | Chip background | TourIllustration5 |
| `tourChipBorder` | rgba(255,255,255,0.06) | Chip border | TourIllustration5 |
| `tourChipFont` | System 10px semibold | Chip font | TourIllustration5 |
| `tourChipPaddingH` | 8px | Chip horizontal padding | TourIllustration5 |
| `tourChipPaddingV` | 3px | Chip vertical padding | TourIllustration5 |

#### Filmstrip Cell

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourFilmstripCellRadius` | 6px | Filmstrip cell corner radius | TourIllustration6, TourIllustration7 |
| `tourFilmstripCellBgTop` | #F6F8FC | Filmstrip cell gradient top | TourFilmstripCell |
| `tourFilmstripCellBgBottom` | #EEF1F7 | Filmstrip cell gradient bottom | TourFilmstripCell |
| `tourFilmstripCellShadowColor` | rgba(0,0,0,0.12) | Filmstrip cell shadow color | TourFilmstripCell |
| `tourFilmstripCellShadowBlur` | 16px | Filmstrip cell shadow blur | TourFilmstripCell |
| `tourFilmstripCellShadowYOffset` | 4px | Filmstrip cell shadow offset | TourFilmstripCell |
| `tourFilmstripCellBarHeight` | 16px | Filmstrip cell title bar height | TourIllustration6, TourIllustration7 |
| `tourFilmstripCellBarBg` | rgba(255,255,255,0.7) | Filmstrip cell title bar bg | TourIllustration6, TourIllustration7 |
| `tourFilmstripCellBarPaddingH` | 5px | Filmstrip cell title bar padding | TourFilmstripCell |
| `tourFilmstripCellDotSize` | 4px | Filmstrip cell traffic light dot | TourIllustration6, TourIllustration7 |
| `tourFilmstripCellDotGap` | 3px | Filmstrip cell traffic light gap | TourFilmstripCell |
| `tourFilmstripCellDotColor` | rgba(15,23,42,0.12) | Filmstrip cell dot color | TourIllustration6, TourIllustration7 |
| `tourFilmstripCellBodyHeight` | 50px | Filmstrip cell default body height | TourFilmstripCell |
| `tourFilmstripCellBodyPadding` | 6px | Filmstrip cell body padding | TourFilmstripCell |
| `tourFilmstripCellBodyGap` | 3px | Filmstrip cell line gap | TourFilmstripCell |
| `tourFilmstripCellLineHeight` | 4px | Filmstrip cell line height | TourFilmstripCell |
| `tourFilmstripCellLineColor` | rgba(15,23,42,0.06) | Filmstrip cell content line color | TourIllustration6, TourIllustration7 |
| `tourFilmstripCellAccent` | rgba(83,74,183,0.12) | Filmstrip cell accent | TourIllustration6, TourIllustration7 |
| `tourFilmstripCellAccentWidthRatio` | 0.45 | Filmstrip cell accent width ratio | TourFilmstripCell |
| `tourFilmstripCellBadgeBg` | #EF4444 | Filmstrip cell badge fill | TourFilmstripCell |
| `tourFilmstripCellBadgeText` | #FFFFFF | Filmstrip cell badge text | TourFilmstripCell |

#### Dashed Add-Image Cell

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourAddCellBorder` | rgba(175,169,236,0.3) | Add cell dashed border | TourIllustration6 |
| `tourAddCellBg` | rgba(175,169,236,0.04) | Add cell background | TourIllustration6 |
| `tourAddCellDashWidth` | 2px | Add cell dash width | TourIllustration6 |
| `tourAddCellMinHeight` | 70px | Add cell minimum height | TourIllustration6 |
| `tourAddCellPlusSize` | 22px | Add cell plus icon size | TourIllustration6 |
| `tourAddCellPlusBg` | rgba(175,169,236,0.16) | Add cell plus icon background | TourIllustration6 |
| `tourAddCellLabelFont` | System 10px semibold | Add cell label font | TourIllustration6 |

#### Editor Frame

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourEditorFrameBg` | rgba(20,20,24,0.9) | Editor frame dark background | Tour Illustrations |
| `tourEditorFrameBgLight` | rgba(248,248,254,0.96) | Editor frame light background | Tour Illustrations |

#### Role Tag

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourRoleTagBg` | rgba(255,255,255,0.2) | Role tag background | TourTitlePill |

#### Hint Text

| Token | Value | Usage | Consuming files |
|-------|-------|-------|-----------------|
| `tourHintFont` | System 10px regular | Hint text font | TourIllustration3 |

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
| Tour window | Static dark | DesignTokens directly (`tourWindowBg`, `tourTextPrimary`, etc.) |

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
