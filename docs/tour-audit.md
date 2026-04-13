# Tour Audit

Date: 2026-04-10
Historical prototype reference: the older HTML walkthrough prototype is not part of the current repo checkout.
Live reference sources: `Vibeliner/Tour/`, `Vibeliner/Tour/Illustrations/`, and `docs/design-system/DESIGN_SYSTEM.md`
Audited source scope: `Vibeliner/Tour/` and `Vibeliner/Tour/Illustrations/`

## Shared Contract Boundary

- Runtime toolbar chrome in the tour should go through `TourMiniToolbar`, which now reuses the live editor toolbar icon drawers and shared toolbar tokens instead of maintaining a second icon-drawing path.
- Output-card and prompt-sheet shells should go through `TourSurfaceView` / `TourFilenamePillView`, which keep the illustration-specific `tourOutput*` and `tourPromptSheet*` tokens behind one appearance-aware adapter.
- Illustration-only helpers are still allowed for teaching aids such as mini screenshots, flow arrows, and simplified filmstrip cells, but they should stay explicitly tour-specific rather than looking like accidental forks of runtime surfaces.

## Tour Window Chrome

### HTML prototype structure

- `.tour-window` is a single rounded window surface with a dedicated elevated background, border, and shadow.
- `.tour-header` and `.tour-footer` use subtle overlay backgrounds, faint dividers, adaptive text, and pill buttons.
- `.tour-body` is a two-column grid in normal mode and a full-width `done-mode` layout on the final step.
- `.illustration-pane` uses an appearance-aware tinted background, not a permanently dark slab.
- `.tour-exit`, `.btn-ghost`, `.btn-primary`, progress text, and progress bars all have explicit light and dark treatments.

### Current Swift implementation

- `TourWindowController.swift` builds the whole window chrome: panel, header, footer, body, illustration pane, text pane, progress bars, back button, next button, and final done state.
- The final step is not a separate illustration file; it is built inline in `buildDoneContent(in:)`.
- `TourStepData.swift` defines the 9-step sequence and the full-width final step.

### Gaps

- Before the Phase 2 fix, most tour chrome used system colors or dark-only tour tokens instead of the prototype's dedicated adaptive surfaces.
- The prototype includes a reopen-toast pattern after closing the tour. The native implementation still closes immediately and stores `tourCompleted` without a reopen affordance inside the tour.
- The prototype animates slide changes and done-state transitions. The native implementation swaps views without animation.

### Token usage

- `DesignTokens.swift` originally stored most tour tokens as static dark colors, which was the root cause of the light/dark mismatch.
- `TourWindowController.swift` had direct uses of `NSColor.windowBackgroundColor`, `NSColor.separatorColor`, and a hardcoded dark illustration background.
- The current fix moved the shared chrome treatment to appearance-aware tour tokens, but there is still no tokenized reopen-toast implementation because that behavior is not present in native code.

### Light/dark mode

- After the Phase 2 fix, window background, header/footer overlays, dividers, text colors, progress bars, ghost/primary buttons, and illustration-pane tint now respond to appearance changes.
- Remaining light/dark gaps now live mainly inside illustration details, not in the outer tour window chrome.

## Step 0: "Visual bugs are hard to describe"

### HTML prototype structure (`data-slide="0"`)

- `.slide[data-slide="0"]` contains `.s0-layout`.
- `.s0-layout` stacks two blocks with `gap: 16px`.
- Top block is `.s0-app > .app-mock` with topbar, sidebar, card row, and table.
- Bottom block is `.s0-llm-strip` containing `.llm-header` and `.s0-chat-text`.

### Current Swift implementation

- `TourWindowController.buildIllustration(for:in:)` instantiates `TourIllustration0`.
- `TourIllustration0.swift` builds `shadowContainer`, `WireframeAppMock`, and `llmStrip`.
- `llmStrip` contains `LLMDotView`, `llmLabel`, and `promptText`.
- Layout uses `padding = 24`, `gap = 16`, a top mock taking roughly 63% of content height, and a content-sized LLM strip below it.

### Gaps

- Structure is very close. The Swift version matches the two-block composition and spacing intent.
- The prototype's app mock sits inside a more obviously elevated surface because the HTML uses combined window and stage shadowing; Swift uses a single black shadow container.
- The prototype's copy is inside a dedicated `.s0-chat-text` block with prototype text colors; Swift uses a generic monospaced label with tokenized color.

### Token usage

- `TourIllustration0.swift` hardcodes the mock shadow values: black shadow, `0.25` opacity, `-20` offset, `30` radius.
- The LLM strip itself correctly uses `tourLLMPanel*` tokens.
- No missing token blocks this step after the shared appearance token fix, but the mock shadow could be tokenized if exact parity matters.

### Light/dark mode

- This step now follows the shared adaptive tour panel colors.
- The wireframe mock is intentionally light in both modes, matching the prototype.
- Remaining issue: the shadow remains fixed black and may feel heavier than the prototype in light mode.

## Step 1: "Screenshots become LLM ready prompts"

### HTML prototype structure (`data-slide="1"`)

- `.slide[data-slide="1"]` contains `.s1-layout`.
- `.s1-layout` is a two-column grid with two `.output-card` blocks.
- Left card shows `.output-label`, `.app-mock`, and two `.ann-badge` elements.
- Right card shows `.output-label` and `.prompt-sheet`.

### Current Swift implementation

- `TourIllustration1.swift` builds `leftCard`, `rightCard`, `leftMock`, `badge1`, `badge2`, and `promptSheet`.
- `leftCard.contentArea` contains a full `WireframeAppMock` and the two badge views.
- `rightCard.contentArea` contains a `TourPromptSheet`.
- Layout uses equal-width columns and top-aligned cards, matching the prototype's `align-items: start`.

### Gaps

- The hierarchy is almost one-to-one with the HTML prototype.
- The prototype relies on adaptive output-card surfaces; Swift originally rendered these cards with dark-only surfaces.
- The prototype's left screenshot card has a specific shadowed embedded mock treatment. Swift uses the generic wireframe mock without the extra step-specific shadow emphasis.

### Token usage

- `TourOutputCard.swift` and `TourPromptSheet.swift` now rely on adaptive `tourOutput*` and `tourPromptSheet*` tokens.
- Badge positions are still hardcoded in `TourIllustration1.swift` based on HTML offsets, but this is acceptable for static illustration rendering.
- No missing tokens are required for the current fidelity level.

### Light/dark mode

- After the shared token fix, the cards and prompt sheet now adapt correctly.
- This step is now functionally correct in both modes, with only minor shadow-weight drift remaining.

## Step 2: "Point at what you see"

### HTML prototype structure (`data-slide="2"`)

- `.slide[data-slide="2"]` contains `.s2-layout`.
- `.s2-layout` contains `.s2-editor`.
- `.s2-editor` contains `.s2-editor-head`, `.s2-toolbar-wrap > .mini-toolbar`, and `.s2-canvas > .app-mock`.
- The mock includes four annotation groups: pin, arrow, rectangle, and circle, each with badges and notes.

### Current Swift implementation

- `TourIllustration2.swift` builds `editorFrame`, `titleLabel`, `titleDivider`, `toolbarShadow`, `TourMiniToolbar`, and `canvasMock`.
- It adds four annotation groups with `TourAnnotationBadge`, `TourAnnotationStake`, `TourAnnotationArrow`, `TourAnnotationRect`, `TourAnnotationCircle`, and `TourAnnotationNote`.
- Layout computes a content-driven editor height, then places toolbar and canvas manually.

### Gaps

- The overall composition and annotation story match the prototype closely.
- The prototype's toolbar sits in a dedicated top padding wrapper; Swift simulates the same with `toolbarShadow` and manual placement.
- The prototype uses a lighter border treatment on the editor head in light mode. Swift originally rendered the whole editor frame as a dark surface until the shared token fix.
- The annotation note placements are close but not pixel-identical to the HTML example.

### Token usage

- `TourIllustration2.swift` uses `tourEditorFrameBg`, `tourOutputCardBorder`, `tourTextSecondary`, and `tourLLMComposerBg`.
- The toolbar correctly uses shared appearance-aware toolbar tokens via `TourMiniToolbar.swift`.
- The title bar height and toolbar gap are still local constants in the illustration file, though they match the prototype.

### Light/dark mode

- After the shared token fix, the editor frame and title styling now adapt.
- The toolbar was already adaptive before the ticket.
- Remaining issue: note shadows and some annotation shadow weights are still fixed rather than appearance-tuned.

## Step 3: "Marks become instructions"

### HTML prototype structure (`data-slide="3"`)

- `.slide[data-slide="3"]` contains `.s3-layout`.
- Top section is `.s3-source` with `.app-mock` and annotations.
- Middle section is `.s3-arrow-row` with two vertical `.flow-arrow` views.
- Bottom section is `.s3-outputs`, a two-column grid of `.output-card` blocks.
- Left bottom card contains `.mini-screenshot` plus `.annotation-hint`.
- Right bottom card contains `.prompt-sheet` plus `.annotation-hint`.

### Current Swift implementation

- `TourIllustration3.swift` builds `topMock`, `topRect`, badges, notes, two `TourFlowArrow` views, `leftCard`, `rightCard`, `leftMock`, `promptSheet`, and two hint labels.
- The bottom-left output uses `leftCard.contentArea.addSubview(leftMock)` instead of a mini screenshot.
- Hint labels are separate `NSTextField`s placed below the cards instead of inside each output card.

### Gaps

- The top section matches the HTML narrative well.
- The largest gap is the bottom-left card: prototype uses a compact mini screenshot; Swift uses a full `WireframeAppMock`.
- Hint copy placement differs. The prototype keeps the hints inside each card; Swift renders them below the card row.
- Card internals are therefore heavier and less prototype-faithful than intended.

### Token usage

- Hint labels use `tourHintFont` and `tourTextDim`.
- The bottom output cards use the shared adaptive card/prompt tokens after the fix.
- A reusable `TourMiniScreenshot` helper is missing; multiple steps would benefit from a tokenized mini screenshot component instead of improvised full-wireframe substitutions.

### Light/dark mode

- Card and prompt surfaces now adapt.
- The step still has a fidelity problem in both modes because the wrong component type is used for the screenshot output.

## Step 4: "Give your AI the full picture"

### HTML prototype structure (`data-slide="4"`)

- `.slide[data-slide="4"]` contains `.s4-layout`.
- Top section `.s4-assets` holds two `.output-card` blocks: mini screenshot and prompt sheet.
- Middle section is a single vertical `.flow-arrow`.
- Bottom section is `.llm-panel` containing `.llm-header`, `.llm-bubble`, and `.llm-composer`.

### Current Swift implementation

- `TourIllustration4.swift` builds `screenshotCard`, `promptCard`, `miniWireframe`, badges, `promptSheet`, `flowArrow`, and a custom `llmPanel`.
- The LLM panel contains `llmDot`, `llmLabel`, `chatBubble`, `chatText`, `composerBar`, a thumbnail placeholder, badge, three lines, and a send circle.
- The top screenshot asset uses a full `WireframeAppMock`, not a mini screenshot.

### Gaps

- The macro structure is correct: assets, arrow, AI panel.
- The prototype's top screenshot is compact and stylized as `.mini-screenshot`; Swift again substitutes a larger embedded wireframe mock.
- The prototype's LLM dot uses a gradient/glow treatment. Swift uses a flat purple dot.
- The composer lines and thumbnail are simplified placeholders rather than closer reproductions of the HTML elements.

### Token usage

- `TourIllustration4.swift` uses `tourLLMPanel*`, `tourLLMBubbleBg`, `tourLLMComposer*`, and `dividerColor`.
- The `llmDot` still uses `DesignTokens.purpleLight` directly instead of a dedicated tour LLM-dot token pair.
- A dedicated reusable mini-screenshot primitive is also missing here.

### Light/dark mode

- The shared surfaces now adapt correctly.
- The remaining mismatch is visual fidelity, not contrast or readability.

## Step 5: "One paste or two"

### HTML prototype structure (`data-slide="5"`)

- `.slide[data-slide="5"]` contains `.s5-layout`.
- It renders two labeled sections: terminal tools and chat tools.
- Each section contains a `.mini-toolbar` on the left and an `.s5-mode-card` on the right.
- Each mode card contains `.s5-mode-label`, `.s5-mode-desc`, and a row of `.s5-example-chip` pills.

### Current Swift implementation

- `TourIllustration5.swift` builds `terminalLabel`, `ideToolbar`, `ideCard`, `ideTitleLabel`, `ideDescLabel`, chips, divider, then the mirrored chat-tool row.
- Section labels are drawn manually for letter spacing.
- `TourMiniToolbar` already handles the adaptive toolbar treatment.
- The mode cards are built with plain `NSView` containers and local chip factory helpers.

### Gaps

- This step is structurally very close to the prototype.
- The main drift was color fidelity: mode card surfaces, chip surfaces, and title color were dark-biased before the token fix.
- The prototype's mode labels use adaptive purple-dark in light mode; Swift previously used `purpleLight` in all appearances.

### Token usage

- `TourIllustration5.swift` uses `tourModeCard*`, `tourChip*`, and `tourTextDim`, but still hardcodes the title color to `purpleLight`.
- That title color should eventually move to a tour-specific adaptive label token for exact prototype parity.
- No missing structural helper is blocking this step.

### Light/dark mode

- After the shared token work, the cards and chips adapt correctly.
- Remaining issue: the title labels still lean on a static purple value instead of a fully prototype-matched adaptive token.

## Step 6: "Add more screenshots"

### HTML prototype structure (`data-slide="6"`)

- `.slide[data-slide="6"]` contains `.s6-layout`.
- Inside `.s6-editor`, the prototype renders `.s2-editor-head`, a centered `.mini-toolbar`, and `.filmstrip-row`.
- The filmstrip row has three columns: observed cell, expected cell, and `.add-image-cell`.
- The first two columns each show a title pill and a mini screenshot-style filmstrip cell. The third is a dashed add-image placeholder with plus circle and label.

### Current Swift implementation

- `TourIllustration6.swift` builds `editorFrame`, `titleBar`, `titleLabel`, `toolbar`, two `TourTitlePill`s, two plain `NSView` cells with line placeholders, one badge, and a drawn dashed placeholder for cell 3.
- The dashed placeholder is painted in `draw(_:)` using `cell3Rect`.
- Cell internals are simplified to two generic line bars rather than a full filmstrip cell with top bar and body sections.

### Gaps

- The step tells the right story but is the furthest from the prototype's component detail.
- The prototype's filmstrip cells have a bar, body, and screenshot-like structure. Swift uses blank rounded rectangles with two lines.
- The prototype's add-image element is a reusable visual component; Swift manually draws the dashed container and overlays separate plus/label views.
- The toolbar composition is correct, but the filmstrip content is underbuilt.

### Token usage

- `TourIllustration6.swift` uses `tourEditorFrameBg`, `tourFilmstripCell*`, and `tourAddCell*` tokens, but the simplified cells do not actually consume the full filmstrip token family.
- `plusLabel` and `addLabel` use static `purpleLight` instead of a dedicated adaptive add-image text token.
- A shared `TourFilmstripCell` helper is missing and should be created before revisiting this step.

### Light/dark mode

- The editor frame now adapts.
- The add-image placeholder colors remain acceptable in both modes, but the step is still structurally inaccurate because the screenshot cells are simplified.

## Step 7: "Label what each image shows"

### HTML prototype structure (`data-slide="7"`)

- `.slide[data-slide="7"]` reuses the filmstrip language from step 6.
- Top section is a three-column grid of title-pill-plus-filmstrip-cell combinations.
- Bottom section is a full-width `.prompt-sheet` with an `Images:` preamble followed by annotation lines and a footer.

### Current Swift implementation

- `TourIllustration7.swift` builds three `TourTitlePill`s, three plain rounded cells with line placeholders, two badges in the first cell, and a bottom `TourPromptSheet`.
- The prompt sheet includes the image preamble, annotations, and footer text.
- The title pills are rendered by `TourTitlePill.swift`, and the role text is produced there.

### Gaps

- The overall two-section composition matches the prototype.
- The top filmstrip cells are again simplified placeholders, not true mini screenshot cells.
- The title pill role-tag text is lowercase in Swift (`observed`, `expected`, `reference`) while the prototype uses capitalized role text.
- The prompt area is closer than the top grid, but the step still feels flatter than the prototype because the filmstrip visuals are missing.

### Token usage

- `TourIllustration7.swift` benefits from the shared adaptive prompt-sheet tokens after the fix.
- `TourTitlePill.swift` uses role background tokens correctly, but its role-tag text casing should be updated when illustration fidelity work begins.
- A shared filmstrip-cell helper is still the main missing reusable component.

### Light/dark mode

- Prompt and card surfaces now adapt.
- Remaining mismatch is component fidelity, not readability.

## Step 8: "You're all set"

### HTML prototype structure (`data-slide="8"`)

- `.slide[data-slide="8"]` contains `.s8-layout`.
- It shows `.s8-checkmark`, `.s8-heading`, `.s8-body`, and `.s8-hotkey-row`.
- The overall tour body switches to `.done-mode`, hiding the text pane and expanding the illustration pane full width.

### Current Swift implementation

- There is no `TourIllustration8.swift`.
- `TourWindowController.updateLayout(for:)` switches the body to full-width by hiding `textPane` and `dividerView` and expanding `illustrationPane`.
- `buildDoneContent(in:)` creates `checkCircle`, `heading`, `body`, and a `kbdRow` composed of three keyboard pills.

### Gaps

- The overall done-state structure is correct.
- The prototype includes a small `"to capture anytime"` helper label after the hotkey row. Swift omits that suffix and instead keeps the extra sentence inside the body copy.
- The prototype animates the checkmark pop. Swift renders a static done state.
- Because this step is inline in the controller, it is less discoverable than the other illustration implementations.

### Token usage

- `buildDoneContent(in:)` uses `copiedGreen*` and setup keyboard-pill tokens rather than tour-specific done-state tokens.
- The current Phase 2 fix added dedicated tour button tokens, but the done-state body still reuses setup keyboard-pill styling.
- A small tour-specific helper-label token would improve parity if this step gets polished later.

### Light/dark mode

- Heading/body colors now adapt correctly.
- Keyboard pills use adaptive setup tokens, so contrast is acceptable in both modes.
- Remaining gap is polish, not function.

## Proposed illustration improvement process

### Approach

Fix the tour in layers, not step-by-step in isolation. The audit shows that most of the remaining mismatch comes from a handful of shared building blocks being too simplified or too dark-biased. The safest approach is: stabilize shared surfaces first, create missing reusable screenshot/filmstrip primitives, then do short per-step passes from highest drift to lowest drift. That keeps the illustration files from diverging further and prevents repeated one-off rewrites.

### Shared components to fix first

- `TourOutputCard`
  Make sure label pill, border, and surface exactly match the prototype in both appearances. Several steps depend on it.
- `TourPromptSheet`
  Keep the current text composition, but tighten line metrics and confirm dim/default text colors against the prototype in both modes.
- `TourTitlePill`
  Capitalize role-tag text, confirm observed/expected/reference fills, and match the inner tag sizing to the HTML prototype.
- `WireframeAppMock`
  Keep this for the larger mock-based steps, but treat it as the "large app mock" primitive only. Do not keep using it as a stand-in for mini screenshots.
- New shared helper: `TourMiniScreenshot`
  This is the biggest missing primitive. Steps 3, 4, 6, and 7 all want the HTML mini screenshot / filmstrip cell visual language, and they currently substitute a full wireframe or plain lines.
- Optional shared helper: `TourFilmstripCell`
  Build title-pill offset, top chrome bar, body lines, and optional badges once so steps 6 and 7 stop duplicating simplified placeholder logic.

### Per-illustration plan

- Step 0
  Keep the layout. Only tune the shadow and text styling after shared tokens are stable.
- Step 1
  Keep the structure. Do a light polish pass only if the output-card and prompt-sheet primitives still drift after shared-component fixes.
- Step 2
  Keep the overall composition. Revisit only for fine placement and shadow tuning after the shared token cleanup.
- Step 3
  Replace the bottom-left full wireframe card with a true mini screenshot helper, and move the hint labels into the cards to match the prototype.
- Step 4
  Replace the top-left full wireframe with a mini screenshot, add the missing LLM-dot glow/gradient treatment, and tune the composer internals to more closely match the prototype.
- Step 5
  Mostly a polish ticket. Make the title-label color fully appearance-aware and verify chip/card spacing against the prototype.
- Step 6
  Rebuild this step around a shared filmstrip cell helper. This is the most important illustration rewrite because it introduces the visual language reused by step 7.
- Step 7
  After step 6's shared filmstrip work exists, swap in the same helper, fix title-pill casing, and then fine-tune the prompt sheet copy/layout.

### Recommended ticket structure

- Ticket 1: Shared tour primitives
  Cover `TourOutputCard`, `TourPromptSheet`, `TourTitlePill`, `WireframeAppMock` adjustments, and the new `TourMiniScreenshot` / `TourFilmstripCell` helper.
- Ticket 2: High-drift illustration batch
  Fix steps 6 and 7 together, because they share the same missing filmstrip language.
- Ticket 3: Output/AI asset batch
  Fix steps 3 and 4 together, because both need the mini screenshot primitive and better output-card composition.
- Ticket 4: Final polish batch
  Tune steps 0, 1, 2, 5, and 8 for spacing, typography, and small fidelity issues once the shared component layer is stable.
