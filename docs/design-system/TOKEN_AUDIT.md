# Vibeliner Design Token Audit — Visual-Pattern Pass

**Date:** 2026-04-18
**Current token count:** 364 `static let` declarations (160 tour-illustration quarantined; 204 main-app in-scope)
**Complements:** the [VIB-498 principles-lens audit](https://linear.app/jonworkinghub/issue/VIB-498/496b-audit-all-370-tokens-against-design-system-principles#comment-84803797)
**Lens:** visual pattern — "what looks the same at a glance?" This audit deliberately uses a different heuristic than VIB-498, which scanned against the 7 principles in [PRINCIPLES.md](PRINCIPLES.md). The two audits are cumulative: VIB-498's 9 consolidation groups + this pass's groups combine into the approved execution plan.

---

## Doc inventory (Phase 1)

Snapshot of `docs/design-system/` after this ticket's archive cleanup:

| File | Classification | Action |
|---|---|---|
| `PRINCIPLES.md` | Current + canonical — merged 2026-04-18 by VIB-497 | Keep |
| `README.md` | Current + canonical — codegen workflow | Keep |
| `TOKEN_AUDIT.md` *(this file)* | Current + canonical — replaces 2026-04-13 version | Keep |
| `design-system.html` | Generated (by `design_system_codegen.py`) | Keep |
| `tour-design.html` | Current + canonical (hand-authored tour reference, VIB-476) | Keep |
| `tokens-metadata.yaml` | Current + canonical (codegen source) | Keep |
| `templates/` | Current + canonical (Jinja2 templates) | Keep |
| `archive/TOKEN_AUDIT_2026-04-13.md` | Historical (pre-VIB-487; references 407 tokens, dead tokens like `purpleButton`, `tooltipDarkBg`) | Moved to archive |
| `archive/TOUR_ILLUSTRATION_TOKENS.md` | Historical spec (superseded by `tour-design.html` + shipped `+TourIllustrations.swift`) | Moved to archive |
| `archive/vibeliner-tutorial-v4.html` | Historical tour mockup (paired with `TOUR_ILLUSTRATION_TOKENS.md`, orphan after tour shipped) | Moved to archive |

No `audits/` folder exists — nothing to flatten. All moves are path-only; file content unchanged. The only internal reference between archived files (`TOUR_ILLUSTRATION_TOKENS.md` → `vibeliner-tutorial-v4.html`) is preserved because both moved together.

---

## 1. System-color alias tokens (Category A)

Tokens whose value is literally a macOS `NSColor.*` constant. These tokens add a name but no design decision — consumers should reference the system color directly, which documents the "follows system" intent more clearly than a custom name.

| Token | Value | Consumers (non-Design) | Call sites |
|---|---|---|---|
| `setupWindowBg` | `NSColor.windowBackgroundColor` | SetupWindowController, SetupWindowController+Panels, HarnessPreviewSurfaces | ~5 |
| `setupBorder` | `NSColor.separatorColor` | SetupWindowController+Panels, SetupComponents, SetupWindowController+UIFactories, HarnessPreviewSurfaces | ~8 |
| `setupFieldBorder` | `NSColor.separatorColor` | SetupComponents, SetupWindowController+UIFactories, HarnessPreviewSurfaces | ~4 |
| `setupTextPrimary` | `NSColor.labelColor` | SetupComponents, SetupWindowController+UIFactories, SetupWindowController+Panels, HarnessPreviewSurfaces | ~7 |
| `setupTextSecondary` | `NSColor.secondaryLabelColor` | SetupWindowController+Panels, SetupWindowController+UIFactories, SetupWindowController+Actions, HarnessPreviewSurfaces | ~5 |
| `setupTextDim` | `NSColor.tertiaryLabelColor` | SetupComponents, SetupWindowController+UIFactories, HarnessPreviewSurfaces | ~3 |
| `setupGrayText` | `NSColor.tertiaryLabelColor` | SetupWindowController+UIFactories, HarnessPreviewSurfaces | ~2 |

**Total:** 7 tokens, ~34 call-site edits across 7 files (verified by grep).

**Recommendation:** delete all 7. Replace consumer references with the direct `NSColor.*` call. Benefits: (a) "this is the system color" is self-documenting at the call site; (b) matches the `PRINCIPLES.md` #3 rule that tokens should encode a decision — "use the system default" isn't a decision worth a token; (c) removes the illusion that changing `setupTextPrimary` would retint setup-only text (the current behavior silently follows system changes anyway).

**Overlap with VIB-498:** VIB-498 flagged `setupFieldBg`/`setupFieldBorder` in its Group 5 but proposed aliasing to settings equivalents. This audit goes further: `setupFieldBorder` should not alias *anywhere* — it should be deleted and consumers use `NSColor.separatorColor` directly. (The `setupFieldBg` pair is a dynamic overlay, not a system-color alias, so it's legitimately a token — VIB-498 Group 5 still applies.)

---

## 2. Same-value duplicates (Category B)

Tokens with identical values under different names — visually indistinguishable, should be one token.

| Group | Tokens | Shared value | Action |
|---|---|---|---|
| Separator variants | `setupBorder`, `setupFieldBorder` | both = `NSColor.separatorColor` | Delete both per Category A; consumers use `NSColor.separatorColor` directly |
| Tertiary-label variants | `setupTextDim`, `setupGrayText` | both = `NSColor.tertiaryLabelColor` | Delete both per Category A; consumers use `NSColor.tertiaryLabelColor` directly |
| Purple brand dynamic | `toolbarPurpleActive`, `tourProgressActive`, `pillButtonText` | all = `dynamic(#AFA9EC dark / #534AB7 light)` | Already covered by VIB-498 Group 3 (aliases to `pillButtonText`) |
| Purple brand literal | `roleObservedBorder` vs `purpleLight` | both = `#AFA9EC` | Already covered by VIB-498 Group 2 (alias) |

**Note on `settingsFieldBorder` vs setup borders:** `settingsFieldBorder` is a CUSTOM `dynamic(rgba(255,255,255,0.12) / rgba(15,23,42,0.12))` — **not** identical to `NSColor.separatorColor`. VIB-498 Group 5 proposed aliasing `setupFieldBorder` → `settingsFieldBorder`, but they're visually different. This audit's Category A recommendation (delete `setupFieldBorder`, use `NSColor.separatorColor` directly) is cleaner; VIB-498 Group 5 should be narrowed or superseded — see Judgment Call 1 below.

---

## 3. Functionally-identical-at-glance (Category C)

Tokens whose values differ by 1-5% alpha but produce visually indistinguishable results.

| Pair / group | Values | Visual impact of collapse |
|---|---|---|
| `setupGrayBg` vs `setupFieldBg` | gray: dark `rgba(1,0.03)` / light `rgba(0,0.03)` — field: dark `rgba(1,0.05)` / light `rgba(0,0.03)` | Difference of 0.02 alpha in dark mode only; light mode identical. Collapsible. |
| `setupGreenBadgeBg` vs `copiedGreenBg` | badge: `rgba(34,197,94,0.10)` — copied: `rgba(22,163,74,0.12)` | Already flagged in VIB-498 Group 4 (green palette harmonization) — confirming case study |
| Tour chrome "faint neutral overlay" trio: `tourBarDivider`, `tourGhostButtonBorder`, `tourProgressInactive` | alpha 0.04/0.05, 0.07/0.08, 0.06/0.07 — all dark-white / light-slate `rgba(15,23,42,*)` | Three variants of the same "faint dark/light chrome line" within 3% alpha spread. At least two could collapse. |
| Tour chrome vs main: `tourBarDivider` (0.04/0.05) vs `dividerColor` (0.08/0.08) | Tour is half the opacity of main divider | Not identical — tour intentionally quieter. Keep. |
| `statusPillBg` (rgba 30,30,30,0.88 dark / 255,255,255,0.85 light) vs `toolbarBg` (rgba 30,30,30,0.92 dark / 255,255,255,0.88 light) | 0.03-0.04 alpha delta | Subtle but intentional — status pill is slightly more transparent for layering over screenshots. Keep. |

**Net Category C finding:** 1 clear collapse (`setupGrayBg` into `setupFieldBg`), 1 cluster to thin within tour chrome (depends on Judgment Call 2 about tour chrome un-quarantining — same dependency as VIB-498 Group 6), 2 pairs to keep (statusPill/toolbar).

---

## 4. Unclear intent (Category D)

Tokens flagged for Jonathan review because name + value + consumers don't clearly explain the design question answered.

| Token | Value | Consumers | Question |
|---|---|---|---|
| `setupAmberText` | `#b45309` (rgba 180,83,9) | 1 — `SetupWindowController+UIFactories.swift:89` (status label) | Only amber/orange in the entire system. Is amber a real status state or a one-off? If status states matter long-term, should this become a `warning*` family alongside `copiedGreen*`? If it's a one-off, inline the hex. |
| `setupGrayBg` | `rgba(1.0, alpha:0.03)` / `rgba(0, alpha:0.03)` | 2 — HarnessPreviewSurfaces (preview), SetupWindowController+UIFactories:21 (locked badge surface) | Extremely faint (0.03 alpha). Indistinguishable from `setupFieldBg` in light mode. Probably should collapse into `setupFieldBg` regardless of other decisions. |
| `setupGreenText` (rgba 22,163,74,1.0) | — | Single consumer path | Same RGB family as `copiedGreen*` but 1.0 alpha. VIB-498 Group 4 covers it, but listed here because the 1.0 vs `copiedGreen` (0.9) distinction is the kind of thing that looks surface-specific but may not be intentional |
| `tourDoneButtonBorder` (`#4ADE80 alpha 0.34`) | — | Tour done screen | Uses a *third* green hex (`#4ADE80` — Tailwind green-400) distinct from both `#22C55E` (green-500) and `#16a34a` (green-600). Three greens in the system. Is this intentional or drift? |
| `roleObservedBg`, `roleExpectedBg`, `roleReferenceBg` (all at alpha 0.85) | — | Role chip backgrounds | Alpha 0.85 with non-trivial RGB (blended down for opacity). Are these the *only* "high-alpha role bg" tokens needed, or would the app benefit from the full 8-preset bg set to match `rolePresetColors`? Currently asymmetric: 3 bgs for 8 borders. |

---

## 5. Consolidation groups proposed (this audit)

Groups **A10 through A14**, numbered to extend VIB-498's Groups 1–9 without collision. Each group is sub-ticket-sized.

### Group A10 — Delete system-color alias tokens
- **Tokens (7):** `setupWindowBg`, `setupBorder`, `setupFieldBorder`, `setupTextPrimary`, `setupTextSecondary`, `setupTextDim`, `setupGrayText`
- **Target:** Delete tokens; replace ~34 call sites with the direct `NSColor.*` system constant
- **Visual impact:** None — runtime behavior identical
- **Risk:** Low (mechanical rename); verify tests still pass
- **Size:** M (many call sites, low cognitive load per edit)
- **Overlap:** Supersedes VIB-498 Group 5's aliasing of `setupFieldBorder` → `settingsFieldBorder` for those two tokens. `setupFieldBg` is still a legitimate dynamic overlay and stays in VIB-498 Group 5.

### Group A11 — Collapse `setupGrayBg` into `setupFieldBg`
- **Tokens (1):** delete `setupGrayBg`; repoint 2 consumers to `setupFieldBg`
- **Target:** single "inset field surface" dynamic color
- **Visual impact:** Locked-badge surface shifts from 0.03 alpha → 0.05 alpha in dark mode (imperceptible at the 22×22pt badge size)
- **Risk:** Low. **Size:** XS
- **Overlap:** Folds naturally into VIB-498 Group 5 (field surface unification); could ship as part of that ticket.

### Group A12 — Resolve third green hex (`tourDoneButtonBorder`)
- **Tokens (1):** `tourDoneButtonBorder` (`#4ADE80`)
- **Target:** Decision (Judgment Call 3) — fold into unified green palette from VIB-498 Group 4, or keep as "tour celebration green" because it's the one place a lighter mint green is intentional
- **Visual impact:** If folded: tour "Done" button border loses its lighter-mint cue. If kept: the system has three greens permanently.
- **Risk:** Low (1 call site). **Size:** XS + decision
- **Overlap:** Should be resolved alongside VIB-498 Group 4 (green palette harmonization).

### Group A13 — Amber family decision
- **Tokens (1):** `setupAmberText` plus potential new `warningAmber*` family
- **Target:** Either (a) inline the hex at the one call site and delete the token, OR (b) promote to a `warningAmber*` primitive family (text/bg/border) as a sibling to `copiedGreen*` for future status states
- **Visual impact:** None for option (a); none now for option (b)
- **Risk:** Low. **Size:** XS
- **Overlap:** Independent of VIB-498.

### Group A14 — Role preset bg symmetry (documentation + potential tokens)
- **Tokens (0-5):** potentially add `roleOrangeBg`, `rolePinkBg`, `roleTealBg`, `roleYellowBg`, `roleGrayBg` to match the 8 borders — OR delete the 5 unused borders per VIB-498 Group 1 and shrink to 3 presets (Purple/Green/Blue)
- **Target:** Resolve the border/bg asymmetry — either complete the set or trim it
- **Visual impact:** Depends on decision. VIB-498 Group 1 already proposes the trim direction; this audit just flags that the asymmetry exists either way.
- **Risk:** Low. **Size:** XS
- **Overlap:** Sibling to VIB-498 Group 1; ship together or be explicit about deferring.

---

## 6. Judgment calls for Jonathan

**1. System-color aliases — delete entirely, or alias to a settings-equivalent?**
- *Recommendation:* delete (Group A10). Force consumers to reference `NSColor.*` directly; removes the illusion of a setup-specific knob.
- *Alternative:* keep the tokens as named indirection "for future reskinning."
- *Tradeoff:* a reskin requiring setup-specific text colors is very unlikely, and if it happens, re-adding the token takes five minutes. Principle 6 ("when in doubt, don't add the token") says the burden is on keeping them. Note this supersedes VIB-498 Group 5's narrower proposal for `setupFieldBorder`.

**2. Tour chrome quarantine — resolve NOW so Groups A11, VIB-498 Group 6, and tour-chrome doc placement can all ship.**
- *Recommendation:* un-quarantine tour chrome (`tour*` prefix in `+SetupTour.swift`). Keep only `+TourIllustrations.swift` quarantined.
- *Alternative:* keep tour chrome quarantined.
- *Tradeoff:* un-quarantining unlocks ~6 alias collapses and Category C cluster-thinning. This is the same question as VIB-498 Judgment Call 2 — flagging again because it blocks two audits worth of groups. **Ship a decision before any consolidation work starts.**

**3. Three greens — are `#22C55E`, `#16a34a`, and `#4ADE80` all intentional?**
- *Recommendation:* pick one (recommend `#22C55E` as brand), derive the 0.5/0.34/0.14/0.10 alpha steps from it, alias `tourDoneButtonBorder` into the family.
- *Alternative:* canonicalize two greens (strong #22C55E, rich #16a34a) and keep `#4ADE80` as a fourth tour-only lighter variant.
- *Tradeoff:* mild visible shift on the tour "Done" button border (loses mint-green lift). Folds into VIB-498 Group 4 as an extension, not a separate concern.

**4. Amber — is this a warning state, or a one-off?**
- *Recommendation:* inline the hex, delete the token. No other amber usage in the app; the "warning" pattern doesn't exist as a family yet.
- *Alternative:* promote to `warningAmber*` family now to codify the pattern.
- *Tradeoff:* extending the family adds 3-4 tokens with zero current consumers — violates Principle 4. Inline is consistent with principles.

**5. Role preset bgs — complete the 8-color set or trim to 3?**
- *Recommendation:* trim to Purple/Green/Blue (matches VIB-498 Group 1) — the 5 extra borders have never had consumers; adding 5 more bgs would double the dead weight.
- *Alternative:* keep the 8-preset ambition, add the 5 missing bgs.
- *Tradeoff:* the settings role picker has shipped with only 3 choices per user testing; more presets are not currently a product need.

---

## 7. Projected token reduction

Combining VIB-498 and VIB-499 consolidation groups:

| Source | Hard delete | Aliased (count stays) | Rename |
|---|---|---|---|
| VIB-498 Groups 1-9 | 6 tokens | ~9 tokens | 1 |
| VIB-499 Group A10 | 7 tokens | — | — |
| VIB-499 Group A11 | 1 token | — | — |
| VIB-499 Group A12 | 0-1 (pending JC3) | up to 1 | — |
| VIB-499 Group A13 | 0-1 (pending JC4) | — | — |
| VIB-499 Group A14 | 0-5 (matches VIB-498 Group 1) | — | — |
| **Total** | **~14-20 tokens** | **~10** | **1** |

**Projected final count:** 364 → ~346 (conservative) to ~344 (if Judgment Calls 3, 4 and Group A14 resolve toward deletion).

**Principle violations after full execution:** 0.
**Tour quarantine:** enforced in runtime, YAML, and docs (assuming Judgment Call 2 resolves).

---

## 8. Maintenance note

This file is the canonical token audit. Regenerate it (not via codegen — hand-rewrite) after any major consolidation ships. Historical audits live in `archive/` with a date suffix so the current state is always at `TOKEN_AUDIT.md` without a version number in the path.
