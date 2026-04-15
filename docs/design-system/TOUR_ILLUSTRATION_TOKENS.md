# Tour Illustration Tokens

**This file is NOT a standalone design system.** It layers on top of `DesignTokens.swift`. Most values here are references to existing tokens. Only values in the "New tokens" sections need to be added to `DesignTokens.swift`.

**Golden rule:** If it exists in `DesignTokens.swift`, use the token name. Never copy the value. When the main token changes, the illustration changes automatically.

**Two reference files to read together:**
- This file → what token to use for each property
- `docs/prototypes/vibeliner-tutorial-v4.html` → what the layout should look like (HTML structure + CSS)

---

## Maintenance contract

Any ticket that modifies tour illustrations MUST:
1. Use tokens from `DesignTokens.swift` for ALL colors, dimensions, and fonts
2. If a new illustration-only token is needed, add it to `DesignTokens.swift` under `// MARK: - Tour Illustration`
3. Document new tokens in `docs/design-system/DESIGN_SYSTEM.md` with value, usage, and consuming files
4. Add any new visual controls to `docs/design-system/Design_Tester.html`
5. Update `docs/design-system/design-system.html` with new color swatches if applicable

---

## Illustration pane

| Property | Token or value |
|----------|---------------|
| Pane width | `DesignTokens.tourIllustrationRatio` (0.6) × `DesignTokens.tourWindowWidth` |
| Pane height | `DesignTokens.tourWindowHeight` − `DesignTokens.tourHeaderHeight` − `DesignTokens.tourFooterHeight` |
| Internal padding | **[NEW]** `DesignTokens.tourIllustrationPadding` = 24 |
| Pane background tint | **[NEW]** `DesignTokens.tourIllustrationBgTint` = rgba(0,0,0,0.08) |
| Pane purple glow | **[NEW]** `DesignTokens.tourIllustrationGlow` = rgba(175,169,236,0.06) — radial, positioned at 30% 20% from top-left. Approximation OK if radial gradient is impractical in AppKit. |

---

## Components using EXISTING tokens (no new tokens needed)

### Annotation badge → same as real badge
| Property | Existing token |
|----------|---------------|
| Diameter | `DesignTokens.badgeDiameter` |
| Fill | `DesignTokens.red` |
| Font | `DesignTokens.badgeFont` |
| Text color | `.white` |

### Annotation note pill → same as real note pill
| Property | Existing token |
|----------|---------------|
| Height | `DesignTokens.noteHeight` |
| Corner radius | `DesignTokens.noteCornerRadius` |
| Background | `DesignTokens.redNoteBg` |
| Border | `DesignTokens.redNoteBorder` |
| Text color | `DesignTokens.noteTextColor` |

Note: use 11px font in illustrations (slightly smaller than the real 12px `noteTextFont`) for visual scale. This is the one exception where you don't use the exact main token font size.

### Annotation shapes → same as real shapes
| Property | Existing token |
|----------|---------------|
| Stroke width | `DesignTokens.strokeWidth` |
| Stroke color | `DesignTokens.red` |
| Rect fill | `DesignTokens.redFill` |
| Circle fill | `DesignTokens.redFill` |
| Rect corner radius | `DesignTokens.rectCornerRadius` |
| Pin stake width | `DesignTokens.stakeWidth` |
| Pin stake length | `DesignTokens.stakeLength` |

### Annotation arrow → same as real arrow
| Property | Existing token |
|----------|---------------|
| Stroke width | `DesignTokens.strokeWidth` |
| Stroke color | `DesignTokens.red` |
| Chevron length | `DesignTokens.arrowChevronLength` |
| Chevron angle | `DesignTokens.arrowChevronAngle` |

### Mini toolbar → same as real toolbar
The illustration toolbar is a miniature of the real editor toolbar. Always use dark-mode variants directly (the toolbar is always dark chrome, even in system light mode).

| Property | Existing token |
|----------|---------------|
| Background | `DesignTokens.darkChrome` |
| Border | `DesignTokens.chromeBorder` |
| Border radius | `DesignTokens.toolbarCornerRadius` (20px, but use 999px for pill in illustrations) |
| Shadow | `0 8px 30px rgba(0,0,0,0.3)` — use same as toolbar |
| Divider | `DesignTokens.dividerColor` |

### Mini toolbar — tool buttons
| Property | Existing token |
|----------|---------------|
| Default icon color | `DesignTokens.iconDefault` |
| Active background | `DesignTokens.toolActiveBg` |
| Active icon color | `DesignTokens.purpleLight` |

### Mini toolbar — copy buttons
| Property | Existing token |
|----------|---------------|
| Border | `DesignTokens.purpleButton` (with 0.5 alpha for border) |
| Background | `DesignTokens.purpleButtonBg` |
| Text color | `DesignTokens.purpleLight` |

### Mini toolbar — IDE/App toggle
| Property | Existing token |
|----------|---------------|
| Track bg | `DesignTokens.toggleBg` |
| Active segment bg | `DesignTokens.toggleActiveBg` |
| Active text | `DesignTokens.purpleLight` |
| Inactive text | `DesignTokens.toggleInactiveText` |

### Mini toolbar — add image button
| Property | Existing token |
|----------|---------------|
| Background | `DesignTokens.addImageBg` (dark variant) |
| Border | `DesignTokens.addImageBorder` (dark variant) |
| Text | `DesignTokens.purpleLight` |

### Title pills (steps 6, 7) → same as real title pills
| Property | Existing token |
|----------|---------------|
| Height | `DesignTokens.titlePillHeight` |
| Observed bg | `DesignTokens.roleObservedBg` |
| Expected bg | `DesignTokens.roleExpectedBg` |
| Reference bg | `DesignTokens.roleReferenceBg` |
| Observed border | `DesignTokens.roleObservedBorder` |
| Expected border | `DesignTokens.roleExpectedBorder` |
| Reference border | `DesignTokens.roleReferenceBorder` |

### Tour window chrome → already tokenized
| Property | Existing token |
|----------|---------------|
| Window bg | `DesignTokens.tourWindowBg` |
| Header/footer overlay | `DesignTokens.tourBarOverlay` |
| Text primary | `DesignTokens.tourTextPrimary` |
| Text secondary | `DesignTokens.tourTextSecondary` |
| Text dim | `DesignTokens.tourTextDim` |
| Progress active | `DesignTokens.tourProgressActive` |
| Progress inactive | `DesignTokens.tourProgressInactive` |
| Title font | `DesignTokens.tourTitleFont` |
| Body font | `DesignTokens.tourBodyFont` |

---

## Components needing NEW tokens

These are illustration-only elements with no real-app equivalent. Add all of these to `DesignTokens.swift` under `// MARK: - Tour Illustration`.

### Wireframe app mock (fictional screenshot)

The wireframe represents a screenshot of a generic dashboard app. Its colors are static (not themed) because screenshots are always light-background images regardless of system appearance.

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourWireframeBg` | `linear-gradient(#f6f8fc → #eef1f7)` — use top: `NSColor(r:246,g:248,b:252)`, bottom: `NSColor(r:238,g:241,b:247)` | Wireframe body background |
| `tourWireframeTopbarBg` | `rgba(255,255,255,0.8)` | Top bar background |
| `tourWireframeTopbarBorder` | `rgba(0,0,0,0.05)` | Top bar bottom border |
| `tourWireframeSidebarBg` | `rgba(245,247,252,0.9)` | Sidebar background |
| `tourWireframeSidebarBorder` | `rgba(0,0,0,0.04)` | Sidebar right border |
| `tourWireframeSidebarItem` | `rgba(15,23,42,0.07)` | Sidebar nav item pill |
| `tourWireframeSidebarActive` | `rgba(83,74,183,0.16)` | Active sidebar item (uses purple) |
| `tourWireframeHeading` | `rgba(83,74,183,0.14)` | Heading placeholder pill |
| `tourWireframeCardBg` | `rgba(255,255,255,0.85)` | Card background |
| `tourWireframeCardBorder` | `rgba(0,0,0,0.04)` | Card border |
| `tourWireframeCardErrorBorder` | `rgba(239,68,68,0.2)` | Error card border (uses red) |
| `tourWireframeCardErrorBg` | `rgba(255,245,245,0.9)` | Error card background |
| `tourWireframeLine` | `rgba(15,23,42,0.08)` | Generic content line placeholder |
| `tourWireframeTableBg` | `rgba(255,255,255,0.8)` | Table background |
| `tourWireframeTableBorder` | `rgba(0,0,0,0.04)` | Table border |
| `tourWireframeTableHeadBg` | `rgba(240,242,248,0.9)` | Table header row |
| `tourWireframeTableRowBorder` | `rgba(0,0,0,0.04)` | Table row divider |
| `tourWireframeTableErrorBg` | `rgba(255,235,235,0.6)` | Error table row |
| `tourWireframeTableCell` | `rgba(15,23,42,0.07)` | Table cell placeholder |
| `tourWireframeShadow` | `0 20px 60px rgba(0,0,0,0.25)` | Wireframe drop shadow |
| `tourWireframeRadius` | 8 | Corner radius |
| `tourWireframeTopbarHeight` | 36 | Top bar height |
| `tourWireframeSidebarWidth` | 100 | Sidebar width |
| `tourWireframeCardHeight` | 64 | Card height |
| `tourWireframeCardRadius` | 6 | Card corner radius |
| `tourWireframeTableRadius` | 6 | Table corner radius |
| `tourWireframeBrandIconSize` | 16 | Brand icon square |
| `tourWireframeBrandFont` | System 11px bold | "Dashflow" label |
| `tourWireframeBrandColor` | `#263041` — NSColor(r:38,g:48,b:65) | Brand text color |
| `tourWireframeNavPillHeight` | 8 | Navigation pill height |

### Output card

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourOutputCardBg` | `rgba(255,255,255,0.03)` | Card background |
| `tourOutputCardBorder` | `rgba(255,255,255,0.06)` | Card border |
| `tourOutputCardRadius` | 6 | Corner radius |
| `tourOutputCardPadding` | 10 | Internal padding |
| `tourOutputLabelBg` | `rgba(255,255,255,0.05)` | Label pill background |
| `tourOutputLabelBorder` | `rgba(255,255,255,0.06)` | Label pill border |
| `tourOutputLabelFont` | System 10px bold | "screenshot.png" / "prompt.txt" |

### Prompt sheet

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourPromptSheetBg` | `rgba(255,255,255,0.04)` | Sheet background |
| `tourPromptSheetBorder` | `rgba(255,255,255,0.06)` | Sheet border |
| `tourPromptSheetRadius` | 6 | Corner radius |
| `tourPromptSheetPadding` | 14 horizontal, 16 vertical | Internal padding |
| `tourPromptSheetFont` | Monospace 10.5px regular | Code text |
| `tourPromptSheetColor` | `rgba(255,255,255,0.68)` | Normal text |
| `tourPromptSheetDim` | `rgba(255,255,255,0.3)` | Preamble/footer text |
| `tourPromptSheetNumber` | `#f87171` — NSColor(r:248,g:113,b:113) | Annotation number color |

### LLM chat panel

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourLLMPanelBg` | `rgba(255,255,255,0.025)` | Panel background |
| `tourLLMPanelBorder` | `rgba(255,255,255,0.06)` | Panel border (dark), `rgba(15,23,42,0.06)` (light) |
| `tourLLMPanelRadius` | 8 | Corner radius |
| `tourLLMDotSize` | 7 | LLM indicator dot |
| `tourLLMHeaderFont` | System 11px bold | "LLM" / "Your AI tool" |
| `tourLLMBubbleRadius` | 12 top, 12 top, 12 bottom-right, 4 bottom-left | Chat bubble corners |
| `tourLLMBubbleBg` | `rgba(255,255,255,0.05)` | Bubble background |
| `tourLLMBubbleFont` | System 11px regular, line-height 1.5 | Bubble text |
| `tourLLMChatFont` | Monospace 10.5px regular, line-height 1.6 | Step 0 monospace variant |
| `tourLLMChatColor` | `rgba(255,255,255,0.55)` | Chat text color |
| `tourLLMComposerBg` | `rgba(255,255,255,0.04)` | Composer bar bg |
| `tourLLMComposerBorder` | `rgba(255,255,255,0.06)` | Composer bar border |
| `tourLLMComposerRadius` | 8 | Composer corner radius |
| `tourLLMThumbSize` | (36, 28) width × height | Thumbnail in composer |
| `tourLLMSendSize` | 24 | Send button diameter |
| `tourLLMSendBg` | `rgba(175,169,236,0.2)` — uses purpleLight family | Send button fill |

### Flow arrow

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourFlowArrowWidth` | 2 | Arrow stem width |
| `tourFlowArrowHeight` | 28 | Arrow height |
| `tourFlowArrowColor` | `rgba(175,169,236,0.5)` — purpleLight at 50% | Arrow color |
| `tourFlowArrowChevronSize` | 10 | Chevron arm length |

### Mini screenshot (inside output cards)

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourMiniScreenshotRadius` | 4 | Corner radius |
| `tourMiniScreenshotBarHeight` | 18 | Top bar height |
| `tourMiniScreenshotBarBg` | `rgba(255,255,255,0.7)` | Top bar bg |
| `tourMiniScreenshotDotSize` | 5 | Traffic dot size |
| `tourMiniScreenshotDotColor` | `rgba(15,23,42,0.15)` | Traffic dot color |
| `tourMiniScreenshotBodyHeight` | 80 | Body height |
| `tourMiniScreenshotRailWidth` | 30 | Sidebar rail width |
| `tourMiniScreenshotRailBg` | `rgba(245,247,252,0.9)` | Rail bg |
| `tourMiniScreenshotLineColor` | `rgba(15,23,42,0.06)` | Content line color |
| `tourMiniScreenshotAccent` | `rgba(83,74,183,0.12)` | Accent line (uses purple) |
| `tourMiniBadgeSize` | 14 | Small badge diameter |
| `tourMiniRectStroke` | 1.5 | Small rect stroke width |

### Mode card (step 5)

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourModeCardBg` | `rgba(255,255,255,0.025)` | Card background |
| `tourModeCardBorder` | `rgba(255,255,255,0.06)` | Card border |
| `tourModeCardRadius` | 8 | Corner radius |
| `tourModeCardPadding` | 14 | Internal padding |
| `tourModeLabelFont` | System 12px bold | "IDE mode" / "App mode" |
| `tourModeDescFont` | System 11px regular, line-height 1.5 | Description text |
| `tourModeSectionFont` | System 10px bold, uppercase, tracking 0.06em | "Terminal tools" / "Chat tools" |

### Example chip

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourChipBg` | `rgba(255,255,255,0.04)` | Chip background |
| `tourChipBorder` | `rgba(255,255,255,0.06)` | Chip border |
| `tourChipFont` | System 10px semibold | Chip text |
| `tourChipPaddingH` | 8 | Horizontal padding |
| `tourChipPaddingV` | 3 | Vertical padding |

### Filmstrip cell (steps 6, 7)

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourFilmstripCellRadius` | 6 | Cell corner radius |
| `tourFilmstripCellBarHeight` | 16 | Cell top bar height |
| `tourFilmstripCellBarBg` | `rgba(255,255,255,0.7)` | Cell top bar bg |
| `tourFilmstripCellDotSize` | 4 | Traffic dot size |
| `tourFilmstripCellDotColor` | `rgba(15,23,42,0.12)` | Traffic dot color |
| `tourFilmstripCellBodyHeight` | 50 | Body height (step 6), 70 (step 7) |
| `tourFilmstripCellLineColor` | `rgba(15,23,42,0.06)` | Content line |
| `tourFilmstripCellAccent` | `rgba(83,74,183,0.12)` | Accent line |

### Dashed add-image cell

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourAddCellBorder` | `rgba(175,169,236,0.3)` — purpleLight at 30% | Dashed border |
| `tourAddCellBg` | `rgba(175,169,236,0.04)` | Background |
| `tourAddCellDashWidth` | 2 | Dash stroke width |
| `tourAddCellMinHeight` | 70 | Minimum height |
| `tourAddCellPlusSize` | 22 | Plus circle diameter |
| `tourAddCellPlusBg` | `rgba(175,169,236,0.16)` | Plus circle bg |
| `tourAddCellLabelFont` | System 10px semibold | "Add image" label |

### Annotation hint text

| Token name | Value | Usage |
|-----------|-------|-------|
| `tourHintFont` | System 10px regular, line-height 1.4 | Below output cards in step 3 |

---

## Step layout proportions

These proportions come from the CSS in the HTML prototype. Use them as layout weights/ratios in Auto Layout.

| Step | CSS class | Layout | Gaps |
|------|-----------|--------|------|
| 0 | `.s0-layout` | Full width grid, top: wireframe, bottom: LLM strip | 16px gap |
| 1 | `.s1-layout` | Two equal columns | 14px gap |
| 2 | `.s2-layout` | Single column, editor frame fills width | 14px internal gap |
| 3 | `.s3-layout` | Three rows: source (~45%), arrows, outputs (~40%) | 12px gap |
| 4 | `.s4-layout` | Three rows: assets (2 cols, 10px gap), arrow, LLM panel | 12px gap |
| 5 | `.s5-layout` | Flex column: label, mode-row, divider, label, mode-row. Each mode-row: grid `auto 1fr`, 14px gap | 18px gap |
| 6 | `.s6-layout` | Editor frame + filmstrip (3 cols, 10px gap), 22px top padding for pills | 14px gap |
| 7 | same | 3-column grid (12px gap, 70px body), prompt sheet below | 12px gap |

---

## Mini editor frame (steps 2, 6)

| Property | Token or value |
|----------|---------------|
| Border radius | 8 |
| Background (dark) | `rgba(20,20,24,0.9)` — **[NEW]** `tourEditorFrameBg` |
| Background (light) | `rgba(248,248,254,0.96)` — **[NEW]** `tourEditorFrameBgLight` |
| Border (dark) | `rgba(255,255,255,0.05)` |
| Border (light) | `rgba(15,23,42,0.08)` |
| Title bar height | 36px (padding 10px 14px) |
| Title bar text | "Vibeliner", 12px weight 600, secondary color |
| Title bar border | 1px bottom, same as card borders |

---

## Role tag inside title pills

| Property | Token or value |
|----------|---------------|
| Padding | 2px 6px |
| Border radius | 999px |
| Background | `rgba(255,255,255,0.2)` — **[NEW]** `tourRoleTagBg` |
| Font | System 8px bold |
