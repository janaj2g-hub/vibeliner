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
| `scripts/parse_design_tokens.py` | Swift → dict parser | yes |
| `scripts/design_system_codegen.py` | Codegen driver | yes |

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
