# Tour Audit

Date: 2026-04-10
Prototype reference: `docs/design-system/vibeliner-tutorial-v4.html`
Audited source scope: every file in `Vibeliner/Tour/` and `Vibeliner/Tour/Illustrations/`

## Summary

- The current native tour already matches the prototype's overall information architecture: 9 steps, split illustration/text layout, progress footer, and a full-width done state.
- The biggest implementation gap is appearance handling. The controller mixes system window colors with tour-specific colors, while most tour illustration tokens in `DesignTokens.swift` are still static dark values. That makes light mode drift from the prototype even when individual layouts are otherwise correct.
- The highest-priority interaction bug is the exit/hover button path in `TourWindowController.swift`. The tracking-area closures are attached, but mouse-enter and mouse-exit events are still sent to the button owner, so the custom hover styling does not reliably run.
- The strongest remaining fidelity gaps are illustration detail gaps, not layout gaps. Steps 3, 4, 6, and 7 use simplified assets compared with the HTML prototype.

## Cross-Cutting Findings

- `DesignTokens.swift` is the real source of the tour light/dark problem. The tour token block is labeled "Static Dark" and uses fixed dark-only values for output cards, prompt sheets, LLM surfaces, chips, dividers, and filmstrip surfaces.
- `TourWindowController.swift` hardcodes the illustration pane to a dark fill in both `buildUI()` and `refreshAppearanceColors()`, which directly contradicts the prototype's light-mode illustration-pane treatment.
- The prototype has a close-and-reopen pattern inside the staged demo shell. The macOS implementation currently exits the tour window immediately and marks `tourCompleted = true`, with no reopen affordance in the tour window itself.
- There is no dedicated illustration file for step 9. The done state is built inline inside `TourWindowController.swift`, which is fine, but it means step-9 visual parity lives outside the illustration folder.

## File Audit

| File | Status | Notes |
| --- | --- | --- |
| `Vibeliner/Tour/TourStepData.swift` | Mostly aligned | Titles, button labels, and 9-step structure match the prototype. Minor copy drift exists in step 1 opening phrasing, but the intent is the same. |
| `Vibeliner/Tour/TourWindowController.swift` | Partial | Layout structure matches, but chrome colors come from system colors instead of prototype-specific surfaces, the illustration pane is forced dark in both appearances, hover tracking for exit/back/next is fragile, and the prototype's reopen behavior is not represented. |
| `Vibeliner/Tour/Illustrations/AnnotationMarkViews.swift` | Mostly aligned | Badge, note, arrow, rect, circle, stake, and flow arrow proportions are close to the prototype. The main gap is that shadows use fixed values and do not participate in the same appearance system as the prototype. |
| `Vibeliner/Tour/Illustrations/TourMiniToolbar.swift` | Strong | This is the closest implementation to the prototype because it already uses appearance-aware toolbar tokens. Remaining differences are small: it is a static illustration renderer, so it does not model hover states or richer button emphasis. |
| `Vibeliner/Tour/Illustrations/TourOutputCard.swift` | Partial | Structure and label pill are correct, but card background and border are dark-only and do not flip to the lighter prototype surfaces. |
| `Vibeliner/Tour/Illustrations/TourPromptSheet.swift` | Partial | Typography and prompt composition match the prototype well. Surface, border, and dim text colors are still dark-only. |
| `Vibeliner/Tour/Illustrations/TourTitlePill.swift` | Partial | Pill anatomy is correct, but the inner role-tag text is lowercase instead of `Observed` / `Expected` / `Reference`, and appearance fidelity depends on shared role tokens rather than prototype-specific tour fills. |
| `Vibeliner/Tour/Illustrations/WireframeAppMock.swift` | Strong | The reusable app mock is structurally faithful to the prototype and drives several steps well. It still depends on fixed light mock colors instead of an explicit tour appearance model. |
| `Vibeliner/Tour/Illustrations/TourIllustration0.swift` | Strong | The app mock plus compact LLM strip matches the prototype's story and composition. Light-mode parity depends on fixing shared tour tokens. |
| `Vibeliner/Tour/Illustrations/TourIllustration1.swift` | Strong | The two-output comparison matches the prototype closely. The remaining gap is mostly surface theming in light mode. |
| `Vibeliner/Tour/Illustrations/TourIllustration2.swift` | Mostly aligned | The editor frame, toolbar, and four active annotation examples match the prototype's narrative well. The main drift is appearance: editor frame and supporting surfaces stay dark-heavy outside the toolbar itself. |
| `Vibeliner/Tour/Illustrations/TourIllustration3.swift` | Partial | The top source mock and overall flow are correct, but the lower-left output uses a full wireframe card instead of the prototype's smaller mini-screenshot treatment. |
| `Vibeliner/Tour/Illustrations/TourIllustration4.swift` | Partial | The top assets, flow arrow, and AI panel structure align, but the screenshot asset is again a full wireframe rather than a mini-screenshot, the LLM dot is flatter than the prototype's gradient/glow treatment, and the chat/composer surfaces are simplified. |
| `Vibeliner/Tour/Illustrations/TourIllustration5.swift` | Mostly aligned | The IDE/App teaching layout matches the prototype well. Mode-card, chip, and title colors still rely on dark-only tour tokens, so light mode is not faithful yet. |
| `Vibeliner/Tour/Illustrations/TourIllustration6.swift` | Partial | The editor and three-column filmstrip story are correct, but the filmstrip cells are simplified line placeholders instead of full mini screenshot bars/bodies, and the add-image placeholder is manually drawn rather than composed from reusable filmstrip primitives. |
| `Vibeliner/Tour/Illustrations/TourIllustration7.swift` | Partial | The three-image narrative and prompt block match the prototype's intent, but the filmstrip cells are simplified, title-pill role text casing differs, and prompt/card surfaces remain dark in light mode. |

## Priority Gaps

1. Appearance system
   Tour tokens are still static dark values, so light mode cannot match the HTML prototype without changing the token layer first.
2. Exit button behavior and styling
   The exit button is visually close, but its hover path is not reliable because the tracking-area closures are not wired through a hover-capable control. The same issue affects back/next hover styling.
3. Step-detail parity
   Steps 3, 4, 6, and 7 are the furthest from the prototype because they use simplified output-card and filmstrip internals.
4. Prototype-only behaviors
   The HTML prototype includes close/reopen staging behavior and animated transitions that are not represented in the native version.

## Illustration Improvement Process

1. Freeze controller behavior first.
   Keep the 9-step structure, progress model, and done-state flow stable while illustration parity work happens underneath.
2. Fix appearance centrally in `DesignTokens.swift`.
   Make every tour surface token appearance-aware before editing any illustration geometry. This unlocks light-mode parity across all illustration files without a broad rewrite.
3. Add a repeatable tour-preview workflow.
   Create a lightweight local preview path that can render each tour step in dark and light mode so comparisons against the HTML prototype stop being manual guesswork.
4. Upgrade shared primitives before individual steps.
   Improve `TourOutputCard`, `TourPromptSheet`, `TourTitlePill`, `WireframeAppMock`, and any reusable mini-screenshot primitive first. That will automatically lift multiple steps at once.
5. Tackle the highest-drift steps in this order: 6, 7, 4, 3.
   Those steps currently have the largest gap between the native illustrations and the prototype's component detail.
6. Only then do per-step polish passes.
   Adjust badge placement, spacing, shadow weight, and text casing after the shared surfaces are correct.
7. Verify with screenshot diffs, not visual memory.
   For each pass, capture dark/light screenshots from the native tour and compare them side-by-side with the HTML prototype before calling the step done.

## Recommended Scope For This Ticket

- Write this audit.
- Fix light/dark mode from the token/controller layer.
- Fix the exit button interaction path in the controller.
- Do not rewrite the step illustration files in this ticket.
