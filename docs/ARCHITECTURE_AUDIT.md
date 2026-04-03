# Architecture Audit — VIB-173

**Date:** 2026-04-02
**Codebase:** 7,189 lines across 50 Swift files (pre-audit)
**Post-audit:** ~6,800 lines across 45 Swift files

## Deleted (5 files, ~430 lines)

| File | Lines | Reason |
|---|---|---|
| `Setup/SetupPanelView.swift` | 128 | Dead code — `SetupWindowController` was rewritten as self-contained; this reusable panel class is no longer referenced |
| `Setup/ShareExplanationPanel.swift` | 69 | Dead code — "How to share" card is now inline in `SetupWindowController` |
| `Setup/PermissionPanel.swift` | 76 | Dead code — permission step is inline in `SetupWindowController` |
| `Setup/FolderPanel.swift` | 110 | Dead code — folder step is inline in `SetupWindowController` |
| `Editor/PinCounterIcon.swift` | 45 | Dead code — pin icon is now drawn inline in `ToolbarView.drawPinIcon()` using the same pattern as all other tool icons. No counter number. |

### Dead DesignTokens removed

| Token | Reason |
|---|---|
| `tooltipBg` | Light-mode tooltip color — tooltip uses dark bg (`tooltipDarkBg`) |
| `tooltipBorder` | Light-mode tooltip border — unused |
| `purpleLightInactive` | Only used by deleted `PinCounterIcon` |
| `pinCounterFont` | Pin counter number removed (VIB-164) |
| `pinCounterFontSmall` | Pin counter number removed (VIB-164) |

## Consolidated

| What | From | To |
|---|---|---|
| Hardcoded `NSColor(red: 127/255, green: 29/255, blue: 29/255, alpha: 1.0)` | CanvasView.swift, NotePillRenderer.swift | `DesignTokens.noteTextColor` |
| Hardcoded `NSColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 0.4)` | CanvasView.swift, NotePillRenderer.swift | `DesignTokens.notePrefixColor` |
| Hardcoded `NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)` | AboutTabView.swift | `DesignTokens.red` |
| Pin icon drawing (2 implementations) | Inline in ToolbarView + static `drawPinIcon` | Single `ToolbarView.drawPinIcon()` used everywhere |

## Flagged (NOT fixed — separate tickets or intentional)

| Issue | Rationale |
|---|---|
| `ToolbarView.swift` is 601 lines | Contains all toolbar layout, icon drawing functions, mode toggle, and copy buttons. Could be split but all pieces are tightly coupled and there's no natural seam that wouldn't increase complexity. |
| `SetupWindowController.swift` is 544 lines | Self-contained setup flow. Splitting would require passing state between files for a window that only appears once. |
| Remaining hardcoded colors in note pill border states (NotePillRenderer) | These are state-specific RGBA values used in switch cases. Adding 8 more DesignTokens for each border state would add more code than it saves. The values match the prototype NP component exactly. |
| IUO (`!`) properties in SetupWindowController, PromptTabView | Standard AppKit pattern for views initialized in setup methods called from init. Converting to optionals would add guard-let boilerplate with no safety benefit. |
| `VisualTestHarness.swift` (279 lines, debug-only) | Test harness is intentionally separate from production code. Only runs with `--visual-test` flag. |

## File structure (verified)

```
App/          — AppDelegate, main, VisualTestHarness
Capture/      — CaptureCoordinator, CaptureOverlayWindow, CrosshairView, DimensionLabelView, ScreenCapture
Editor/       — EditorPanel, CanvasView, ToolbarView, ToolButton, StatusPillView, ScreenshotCanvasView, FirstUseTooltipView
Annotations/  — AnnotationModel, AnnotationStore, UndoRedoManager, Tools/*, Renderers/*
Output/       — PromptGenerator, ScreenshotExporter, ClipboardManager, AutoSaveManager
Popover/      — PopoverViewController, RecentCapturesSubmenu, CaptureRowView
Settings/     — SettingsWindowController, GeneralTabView, PromptTabView, PromptPreviewView, AboutTabView
Setup/        — SetupWindowController (self-contained)
Design/       — DesignTokens
Config/       — ConfigManager, CapturesManager
Hotkey/       — HotkeyManager
```

All tools end in `Tool`, renderers in `Renderer`, views in `View`. One responsibility per file.
