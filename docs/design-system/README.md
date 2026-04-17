# Design system — codegen workflow

The canonical `design-system.html` in this directory is **generated**, not hand-authored. The source of truth is `Vibeliner/Design/DesignTokens*.swift`. `tokens-metadata.yaml` supplies presentation-only metadata (which section each token belongs to, descriptions, consumer lists, rendering mode).

## Quickstart

One-time setup (stdlib is not enough — we use Jinja2 + PyYAML):

```
pip3 install jinja2 pyyaml --break-system-packages
```

Regenerate `design-system.html`:

```
python3 scripts/design_system_codegen.py
```

That's it. Output is deterministic — running it twice with the same inputs produces a byte-identical HTML file.

All flags (all optional, sensible defaults):

```
python3 scripts/design_system_codegen.py \
  --tokens-dir Vibeliner/Design \
  --metadata docs/design-system/tokens-metadata.yaml \
  --template docs/design-system/templates/design-system.html.j2 \
  --components-template docs/design-system/templates/_components.html.j2 \
  --output docs/design-system/design-system.html \
  --verbose
```

Use `--verbose` to see `[info]` and `[warn]` output (YAML↔Swift mismatches, etc.).

## When you change tokens

Touching any design token means two files need to stay in sync:

1. Update the Swift declaration in the appropriate `Vibeliner/Design/DesignTokens*.swift` file.
2. Add/edit the matching entry in `docs/design-system/tokens-metadata.yaml` (section, family, description, `consumed_by`, optional `rendering.mode`).
3. Run `python3 scripts/design_system_codegen.py` and commit the regenerated `design-system.html`.

The codegen driver prints a warning (does **not** fail) when a Swift token is missing YAML metadata, or vice versa. A hard validation step will land in VIB-477 and wire into xcodebuild in VIB-484 — until then, the warnings are advisory.

## Files in this workflow

| File | Role | Hand-authored? |
|------|------|----------------|
| `Vibeliner/Design/DesignTokens*.swift` | Runtime source of truth | yes |
| `docs/design-system/tokens-metadata.yaml` | Presentation metadata (section, family, description, consumers, rendering mode) | yes |
| `docs/design-system/templates/design-system.html.j2` | Main Jinja2 template | yes (via VIB-481) |
| `docs/design-system/templates/_components.html.j2` | Component macros | yes (via VIB-482) |
| `docs/design-system/design-system.html` | Generated HTML | **no — do not edit** |
| `docs/design-system/tour-design.html` | Tour-specific reference (quarantined tokens) | **yes — hand-authored** |
| `scripts/parse_design_tokens.py` | Swift → dict parser | yes |
| `scripts/design_system_codegen.py` | Codegen driver | yes |

## `tour-design.html`

Tour illustration tokens (everything in `DesignTokens+TourIllustrations.swift`)
and tour window chrome (the `tour*` prefix in `DesignTokens+SetupTour.swift`) are
**quarantined** per `Design_System_Rules.md` — they exist only for the product
tour and must not be used elsewhere.

`tour-design.html` documents those tokens in a separate, hand-authored file so
the main reference stays focused on tokens available for general use. It reuses
the same CSS chrome / sidebar / mode toggle as `design-system.html` — when the
main file's visual language changes, someone updating `tour-design.html` will
need to re-copy the relevant CSS + JS by hand. The validation script (landing in
VIB-477) does **not** cover this file.

Don't auto-generate it. Don't add tour tokens to `tokens-metadata.yaml`. If the
tour is substantially reworked and the hand-authored reference diverges, a
future ticket can fold it into the codegen.

## Determinism

The driver writes the same bytes every run for the same inputs:

- Tokens within each section sort alphabetically when no explicit `order` entry exists.
- No timestamps in the HTML.
- No commit SHAs; the `{{ generated_from }}` template variable is a stable string.

Verify locally:

```
python3 scripts/design_system_codegen.py && md5sum docs/design-system/design-system.html
python3 scripts/design_system_codegen.py && md5sum docs/design-system/design-system.html
# md5 values must match.
```

## Troubleshooting

**`Missing dependency: pyyaml` / `jinja2`** — run the install command above. If pip refuses with an "externally-managed environment" error on macOS system Python, include `--break-system-packages` as shown.

**`Template not found`** — the Jinja template hasn't been created yet. Templates land in VIB-480 (scaffolding) and get replaced by real designs in VIB-481/482/483.

**`Malformed YAML`** — the driver prints the underlying YAML parse error with a line number. Most often a tab mixed with spaces, or an unquoted string containing `:`.
