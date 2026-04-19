# Vibeliner Design System Principles

These are the rules that govern what goes into `Vibeliner/Design/DesignTokens*.swift`. They exist because reactive consolidation (VIB-487) is expensive — every surplus token is a permanent cognitive tax on anyone reading the system. Read them before adding, renaming, or duplicating a token.

## 1. Tokens belong to one of three tiers

Every token is either a **primitive** (a raw value in the scale — `purpleLight`, `red`, a radius, a font size), a **component** token (scoped to a reusable family like pill-button, note-pill, segmented control — e.g., `pillButtonBorder`, `segmentedActiveFill`), or a **surface** token (scoped to one window or overlay, e.g., `setupWindowWidth`). Primitives compose into components, components compose into surfaces — never the other way around. When a new token is proposed, name its tier first; if it doesn't fit cleanly, the design isn't ready.

## 2. Surface-specific color tokens are the default "no"

A token prefixed with a surface name (`setup*`, `settings*`, `editor*`) is only legitimate when it encodes a dimension that genuinely belongs to that surface's layout — `setupWindowWidth` is fine because the setup window has a width that no other surface shares. A surface-specific **color** almost never passes that bar. The `setupGreen*` family that shadowed `copiedGreen*`, and the parallel `settingsPillHeight` / `settingsSegmentedHeight` that duplicated universal pill and segmented dimensions, are what happens when this rule is skipped. Default answer for "can I add a setup-specific color?" is no — use the primitive or the component token.

## 3. A new token must answer a design question no existing token answers

Before adding a token, write down the design question it resolves. "I need a slightly different green for one button" is not a design question — it's a request for a second green, and the right answer is to use the existing one. "The copied state needs to read as success across light and dark mode" is a design question, and `copiedGreen*` is the answer. Tokens encode decisions; they do not catalog preferences.

## 4. Unused tokens are deleted, not saved for later

A token with zero non-preview consumers is not "future intent" — it's dead weight. The current catalog still carries `roleGrayBorder`, `roleOrangeBorder`, `rolePinkBorder`, `roleTealBorder`, and `roleYellowBorder` with no real consumers; they were added speculatively and have outlived the speculation. If a design need actually emerges, the token gets added at that moment with the consumer attached. Preview-only references (`App/HarnessPreviewSurfaces.swift`, visual test harnesses) do **not** count as consumers for this rule — preview code follows the real app, it does not preserve tokens the real app has abandoned.

## 5. Aliases over duplicates

When a token should always equal another token, declare it as a typed alias in Swift — do not copy the literal value. Two independently-defined `NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)` declarations will drift the first time someone tweaks one and forgets the other. If the equivalence is intentional, encode it in the type system.

The stronger form of this principle is a **ladder**: when a set of tokens share a derivation rule (e.g., five alphas of the same color), define them once at the base and let every consumer reference the ladder rather than spelling its own alpha. The purple ladder (`purpleFaint`, `purpleSubtle`, `purpleStrong`, `purpleBorder`, `purpleHover`) and neutral ladder (`neutralHairline`, `neutralBorder`, `neutralDim`, `neutralStrong`, `neutralPrimary`) are the canonical example — ~45 surface-specific purple/gray tokens collapsed to these 10 primitives in VIB-504..512. Before defining a new alpha variant, check whether a ladder step already encodes it.

## 6. When in doubt, don't add the token

The cost of a missing token is five minutes: the next ticket adds it, with a real consumer, and the system is no worse off. The cost of a surplus token is permanent — every future reader has to decide whether it's the right choice, and the audit that eventually removes it is hours of work. If the case for a new token is not obvious, the case for not adding it is.

## 7. Tour tokens are quarantined

Tour-specific tokens (prefix `tour*`) live in `Vibeliner/Design/DesignTokens+TourIllustrations.swift` and the tour-prefixed entries in `DesignTokens+SetupTour.swift`. They are documented in the hand-authored `tour-design.html`, **not** in the main `design-system.html` and **not** in `tokens-metadata.yaml`. Main-app code may not reference `tour*` tokens; tour code may reference main tokens — the quarantine runs one way. New tour tokens must use the `tour*` prefix. Tour UI chrome (buttons, segmented controls) uses the universal component tokens, not tour-prefixed substitutes.

## Applying these principles

Every ticket that adds, renames, or modifies a design token must cite this document in its prompt or PR description — typically as "DS principle #N applies" or "this violates principle #N; justification: …". Reviewers are expected to push back on any token change that does not. The codegen pipeline (`scripts/design_system_codegen.py`) and the validator (`scripts/validate_design_system.py`, which runs as the first phase of every `xcodebuild`) enforce mechanical consistency — YAML↔Swift drift, missing metadata, unreachable tokens in HTML — but they cannot enforce these principles. That's the human's job.

If you believe a principle is wrong for a specific situation, say so in the PR description and proceed; if you believe a principle is wrong in general, open a ticket to amend this document. Do not silently violate and do not quietly add a token that the rules say should not exist. The mirror of this document in Linear (Vibeliner project → "Design System Principles") is updated after each PR that changes this file merges; if the two drift, the markdown wins.

---

*Last updated: 2026-04-18. Source of truth: this file at `docs/design-system/PRINCIPLES.md`. The Linear document mirror is updated after each merge — if the two disagree, the markdown is authoritative.*
