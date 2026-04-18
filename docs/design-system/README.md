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

The codegen driver prints warnings (not errors) when a Swift token is missing from YAML or vice versa. The **validation** step (below) catches the same drift as a build-blocking error.

## Validation

Every `xcodebuild` run invokes `scripts/validate_design_system.py` as the first build phase. The build fails if docs are out of sync with `Vibeliner/Design/DesignTokens*.swift`.

If the build fails with `Design system docs are out of sync`, run:

```
python3 scripts/validate_design_system.py
```

to see the errors, then fix them in either the Swift source or `tokens-metadata.yaml`.

The validator checks:

1. **Existence** (error) — every YAML token must exist in Swift
2. **Value match** (error) — YAML entries with `explicit_value` must match Swift
3. **Coverage** (warning) — every non-tour Swift token should be in YAML
4. **HTML scan** (error) — every token-like identifier in the generated HTML must resolve to a real Swift token

Exit codes: `0` clean · `1` hard error · `2` script-level error (missing YAML, PyYAML, etc.).

### Pre-commit hook (optional)

To catch drift before it even reaches the build:

```
./scripts/install_pre_commit_hook.sh
```

This installs `.git/hooks/pre-commit` to run the validator on every commit. The installer won't overwrite an existing hook without asking. To bypass in an emergency: `git commit --no-verify`.

Uninstall by deleting `.git/hooks/pre-commit`.

### Skipping validation

If you need to build without validation (e.g., fresh clone before the Python deps are installed, or an emergency build):

```
touch .skip-validation
```

The sentinel file is in `.gitignore` and must never be committed. Delete it when you're done.

### Dependency setup

The validator needs PyYAML. First-time setup on a build machine:

```
pip3 install jinja2 pyyaml --break-system-packages
```

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
