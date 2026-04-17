#!/usr/bin/env python3
"""Design-system codegen driver.

Merges parsed Swift tokens with YAML metadata, renders through a Jinja2
template, writes the generated design-system.html.

Usage (run from repo root with no args uses all defaults):

    python3 scripts/design_system_codegen.py

    python3 scripts/design_system_codegen.py \\
        --tokens-dir Vibeliner/Design \\
        --metadata docs/design-system/tokens-metadata.yaml \\
        --template docs/design-system/templates/design-system.html.j2 \\
        --components-template docs/design-system/templates/_components.html.j2 \\
        --output docs/design-system/design-system.html \\
        --verbose

Dependencies (install once):

    pip3 install jinja2 pyyaml --break-system-packages
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Any

# Let this script be invoked as `python3 scripts/design_system_codegen.py` from repo root.
_REPO_ROOT_FOR_IMPORT = Path(__file__).resolve().parent.parent
if str(_REPO_ROOT_FOR_IMPORT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT_FOR_IMPORT))

_MISSING_DEPS_MSG = (
    "Missing dependency: {pkg}. Install with:\n"
    "    pip3 install jinja2 pyyaml --break-system-packages\n"
)

try:
    import yaml
except ImportError:
    print(_MISSING_DEPS_MSG.format(pkg="pyyaml"), file=sys.stderr)
    sys.exit(2)

try:
    import jinja2
except ImportError:
    print(_MISSING_DEPS_MSG.format(pkg="jinja2"), file=sys.stderr)
    sys.exit(2)

from scripts.parse_design_tokens import parse_directory

# --- Defaults -----------------------------------------------------------------

_REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TOKENS_DIR = _REPO_ROOT / "Vibeliner" / "Design"
DEFAULT_METADATA = _REPO_ROOT / "docs" / "design-system" / "tokens-metadata.yaml"
DEFAULT_TEMPLATE = _REPO_ROOT / "docs" / "design-system" / "templates" / "design-system.html.j2"
DEFAULT_COMPONENTS_TEMPLATE = _REPO_ROOT / "docs" / "design-system" / "templates" / "_components.html.j2"
DEFAULT_OUTPUT = _REPO_ROOT / "docs" / "design-system" / "design-system.html"

# Rendering modes the template knows how to handle. Unknown modes fall back to "dual".
_KNOWN_MODES = {"dual", "triple", "single", "alias"}

# Dimension groups, in display order. Matches `dimension_group` values in the YAML.
_DIMENSION_GROUP_ORDER = (
    "badge",
    "crosshair",
    "arrow",
    "note-pill",
    "dimension-label",
    "freehand",
    "shape-primitives",
    "toolbar",
)


# --- Jinja filters ------------------------------------------------------------


def _filter_truncate_list(items: list[Any], n: int = 3) -> str:
    if not items:
        return ""
    if len(items) <= n:
        return ", ".join(str(x) for x in items)
    head = ", ".join(str(x) for x in items[:n])
    return f"{head} · +{len(items) - n} more"


def _filter_format_value(token: dict[str, Any]) -> str:
    """Canonical short display string for a token's value."""
    t = token.get("type")
    kind = token.get("kind")
    if kind == "alias":
        return f"alias → {token.get('target', '?')}"
    if t == "dimension":
        return f"{token.get('value')}{token.get('unit', '')}"
    if t == "font":
        return f"{token.get('size')}px · {token.get('weight', '')}"
    # Color
    if kind == "dynamic":
        dark = (token.get("dark") or {}).get("rgba") or "?"
        light = (token.get("light") or {}).get("rgba") or "?"
        return f"dark {dark} · light {light}"
    if kind == "static":
        hex_val = token.get("hex")
        rgba = token.get("rgba") or token.get("raw", "")
        return f"{hex_val} · {rgba}" if hex_val else rgba
    return token.get("raw", "")


def _filter_sample_text(token: dict[str, Any]) -> str:
    """Representative sample text for a font token."""
    raw = token.get("raw", "")
    if "monospaced" in raw:
        return "1024 × 768  /Users/jon/captures"
    return "The quick brown fox jumps over the lazy dog"


def _make_resolve_rgba(all_tokens: dict[str, dict[str, Any]]):
    """Factory for a Jinja filter that resolves a color leaf (dict) to an
    rgba string, following identifier-aliases one hop through all_tokens.

    A "leaf" is the dict produced by the parser for a single color side
    (dark or light) — it has either `rgba` directly, or only `alias` (when
    the Swift source was a bare identifier like `dark: purpleLight`).
    """
    def _resolve(leaf: Any) -> str:
        if not isinstance(leaf, dict):
            return ""
        if leaf.get("rgba"):
            return leaf["rgba"]
        alias = leaf.get("alias") or leaf.get("raw")
        if alias and alias in all_tokens:
            target = all_tokens[alias]
            # Follow one more hop: target may itself be static (direct rgba) or dynamic.
            if target.get("rgba"):
                return target["rgba"]
            # Fall back to dark side if target is dynamic.
            if target.get("dark") and target["dark"].get("rgba"):
                return target["dark"]["rgba"]
        return ""
    return _resolve


# --- Loading / merging --------------------------------------------------------


def _load_metadata(path: Path, verbose: bool) -> dict[str, Any]:
    if not path.exists():
        if verbose:
            print(f"[info] Metadata YAML missing; using empty defaults ({path})", file=sys.stderr)
        return {"version": 1, "sections": [], "tokens": {}, "order": {}, "excluded": []}
    try:
        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"[error] Malformed YAML at {path}: {e}", file=sys.stderr)
        sys.exit(1)
    if not isinstance(data, dict):
        print(f"[error] {path} must contain a YAML mapping at the top level", file=sys.stderr)
        sys.exit(1)
    # Fill in optional keys with stable defaults so the template sees a shape.
    data.setdefault("version", 1)
    data.setdefault("sections", [])
    data.setdefault("tokens", {}) or {}
    data.setdefault("order", {})
    data.setdefault("excluded", [])
    if data["tokens"] is None:
        data["tokens"] = {}
    return data


def _merge(
    swift_tokens: dict[str, dict[str, Any]],
    metadata: dict[str, Any],
    verbose: bool,
) -> tuple[dict[str, list[tuple[str, dict[str, Any]]]], list[str]]:
    """Merge Swift tokens with YAML metadata, grouped by section.

    Returns (tokens_by_section, warnings).
    tokens_by_section maps section id -> list of (name, merged_info) in display order.
    """
    yaml_tokens: dict[str, Any] = metadata.get("tokens") or {}
    excluded: set[str] = set(metadata.get("excluded") or [])
    order_map: dict[str, list[str]] = metadata.get("order") or {}
    sections: list[dict[str, Any]] = metadata.get("sections") or []
    known_section_ids = {s["id"] for s in sections if "id" in s}
    warnings: list[str] = []

    # Warn: Swift token missing from YAML/excluded.
    for name in sorted(swift_tokens):
        if name not in yaml_tokens and name not in excluded:
            warnings.append(
                f"Swift token '{name}' is not in tokens-metadata.yaml — it will not appear in the generated HTML"
            )
    # Warn: YAML token with no Swift match.
    for name in sorted(yaml_tokens):
        if name not in swift_tokens:
            warnings.append(f"YAML references '{name}' but no matching token in Swift")

    # Group tokens present in both Swift AND YAML.
    grouped: dict[str, list[tuple[str, dict[str, Any]]]] = {s: [] for s in known_section_ids}
    for name, meta in yaml_tokens.items():
        if name not in swift_tokens:
            continue
        section = (meta or {}).get("section")
        if section not in known_section_ids:
            warnings.append(
                f"Token '{name}' references unknown section '{section}' — skipping"
            )
            continue
        # Validate rendering.mode; fall back to 'dual' if unknown.
        rendering = (meta or {}).get("rendering") or {}
        mode = rendering.get("mode")
        if mode and mode not in _KNOWN_MODES:
            warnings.append(f"Unknown rendering mode '{mode}' for '{name}' — falling back to 'dual'")
            rendering = dict(rendering)
            rendering["mode"] = "dual"
        merged_info: dict[str, Any] = {**swift_tokens[name], **(meta or {})}
        if rendering:
            merged_info["rendering"] = rendering
        grouped[section].append((name, merged_info))

    # Sort: family order (from `order` map) first, then alphabetical by token name.
    for section_id, items in grouped.items():
        family_order = order_map.get(section_id) or []
        family_rank = {fam: idx for idx, fam in enumerate(family_order)}

        def _key(item: tuple[str, dict[str, Any]]) -> tuple[int, str, str]:
            name, info = item
            fam = info.get("family") or ""
            # Families in order map come first (by rank), then unknown families alphabetically.
            rank = family_rank.get(fam, len(family_order))
            return (rank, fam, name)

        items.sort(key=_key)

    if verbose:
        for w in warnings:
            print(f"[warn] {w}", file=sys.stderr)
    return grouped, warnings


# --- Rendering ----------------------------------------------------------------


def _render(
    template_path: Path,
    components_template_path: Path,
    context: dict[str, Any],
) -> str:
    if not template_path.exists():
        print(
            f"[error] Template not found: {template_path}\n"
            f"        Scaffolding is the job of VIB-480 — if you're running this before that lands, run it first.",
            file=sys.stderr,
        )
        sys.exit(1)
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(str(template_path.parent)),
        autoescape=jinja2.select_autoescape(["html"]),
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
    )
    env.filters["items"] = lambda d: list(d)
    env.filters["truncate_list"] = _filter_truncate_list
    env.filters["format_value"] = _filter_format_value
    env.filters["sample_text"] = _filter_sample_text
    env.filters["resolve_rgba"] = _make_resolve_rgba(context.get("all_tokens") or {})
    template = env.get_template(template_path.name)
    return template.render(**context)


# --- Main ---------------------------------------------------------------------


def _parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        prog="design_system_codegen.py",
        description="Generate design-system.html from DesignTokens.swift + tokens-metadata.yaml.",
    )
    p.add_argument("--tokens-dir", type=Path, default=DEFAULT_TOKENS_DIR,
                   help="Directory containing DesignTokens*.swift files")
    p.add_argument("--metadata", type=Path, default=DEFAULT_METADATA,
                   help="Path to tokens-metadata.yaml")
    p.add_argument("--template", type=Path, default=DEFAULT_TEMPLATE,
                   help="Path to main Jinja2 template")
    p.add_argument("--components-template", type=Path, default=DEFAULT_COMPONENTS_TEMPLATE,
                   help="Path to components macros template")
    p.add_argument("--output", type=Path, default=DEFAULT_OUTPUT,
                   help="Path to write the generated HTML")
    p.add_argument("--verbose", action="store_true",
                   help="Print [info] and [warn] messages to stderr")
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(list(sys.argv[1:] if argv is None else argv))

    if not args.tokens_dir.is_dir():
        print(
            f"[error] Tokens directory not found: {args.tokens_dir}\n"
            f"        Run from a checkout that has Vibeliner/Design/.",
            file=sys.stderr,
        )
        return 1

    swift_tokens = parse_directory(args.tokens_dir)
    metadata = _load_metadata(args.metadata, args.verbose)
    tokens_by_section, _warnings = _merge(swift_tokens, metadata, args.verbose)

    # Sorted list of source file names for deterministic template output.
    source_files = sorted({info["source_file"] for info in swift_tokens.values()})

    # Pre-organize dimensions into groups + singletons for the Dimensions section.
    # A dimension token with `dimension_group: <id>` lands in that group; anything
    # without lands in the singleton list. Groups preserve the canonical order
    # defined in _DIMENSION_GROUP_ORDER.
    dim_section = tokens_by_section.get("dimensions") or []
    dim_groups: dict[str, list[tuple[str, dict[str, Any]]]] = {gid: [] for gid in _DIMENSION_GROUP_ORDER}
    dim_singletons: list[tuple[str, dict[str, Any]]] = []
    for name, info in dim_section:
        gid = info.get("dimension_group")
        if gid and gid in dim_groups:
            dim_groups[gid].append((name, info))
        else:
            dim_singletons.append((name, info))

    context: dict[str, Any] = {
        "sections": metadata.get("sections") or [],
        "tokens_by_section": tokens_by_section,
        "all_tokens": swift_tokens,  # for macros needing cross-token lookups (e.g. pill preview)
        "dim_groups": dim_groups,
        "dim_singletons": dim_singletons,
        "token_count": len(swift_tokens),
        "yaml_token_count": len(metadata.get("tokens") or {}),
        "source_files": source_files,
        "generated_from": "Vibeliner/Design/DesignTokens*.swift + docs/design-system/tokens-metadata.yaml",
    }

    html = _render(args.template, args.components_template, context)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(html, encoding="utf-8")
    if args.verbose:
        print(
            f"[info] Wrote {args.output} — {len(swift_tokens)} Swift tokens, "
            f"{len(metadata.get('tokens') or {})} in metadata",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
