#!/usr/bin/env python3
"""Vibeliner design system validation — Level 2.

Four checks against the canonical Swift token source of truth:

  1. Existence (hard error) — every token referenced in
     docs/design-system/tokens-metadata.yaml must exist in
     Vibeliner/Design/DesignTokens*.swift.
  2. Value match (hard error) — YAML entries with an `explicit_value`
     key must match the value the parser extracts from Swift.
  3. Coverage (warning) — every Swift token should be in YAML's
     `tokens` map or `excluded` list. Warnings only; not a build
     blocker.
  4. HTML scan (hard error) — any token-like identifier wrapped in
     `<code>` or a `data-token=` attribute inside
     docs/design-system/design-system.html must resolve to a real
     Swift token.

Exit codes:

  0 — clean (or only warnings, or the .skip-validation sentinel is
      present at repo root)
  1 — at least one hard error; build must fail
  2 — the script itself couldn't run (missing YAML, broken parser,
      missing Swift directory, etc.)

The Vibeliner/Tour/ quarantine is intentional — docs/design-system/
tour-design.html is NEVER validated by this script because it's a
hand-authored reference allowed to drift.

Output is ASCII-only (no Unicode emoji) so it renders cleanly in
xcodebuild log output.

================================================================
Manual test scenarios (for future maintainers)
================================================================

Run each from the repo root, verify the outcome, then revert.

  1. PASS on clean repo:
       python3 scripts/validate_design_system.py
       echo $?                                 # expect 0
       # Prints "OK" and a summary.

  2. EXISTENCE ERROR on bogus YAML token:
       # Temporarily append to tokens-metadata.yaml:
       #   madeUpToken:
       #     section: colors
       python3 scripts/validate_design_system.py
       echo $?                                 # expect 1
       # Prints [ERR] YAML references 'madeUpToken' but it is not
       # defined in any DesignTokens*.swift file
       git checkout docs/design-system/tokens-metadata.yaml

  3. RENAME SUGGESTION for known-historical names:
       # Temporarily append to tokens-metadata.yaml:
       #   noteHoverBg:
       #     section: components
       python3 scripts/validate_design_system.py
       # Prints "Hint: possibly renamed to 'editorNoteSurfaceHover'"
       git checkout docs/design-system/tokens-metadata.yaml

  4. COVERAGE WARNING on Swift-only token:
       # Temporarily append to Vibeliner/Design/DesignTokens.swift,
       # inside the enum body:
       #   static let testWarningToken = NSColor.red
       python3 scripts/validate_design_system.py
       echo $?                                 # expect 0
       # Prints a WARNING for testWarningToken
       git checkout Vibeliner/Design/DesignTokens.swift

  5. VALUE MISMATCH via explicit_value:
       # Temporarily edit tokens-metadata.yaml — pick any token and add:
       #   explicit_value: "rgba(1,2,3,1)"
       python3 scripts/validate_design_system.py
       echo $?                                 # expect 1
       # Prints [ERR] '<name>': YAML expects ..., Swift has ...
       git checkout docs/design-system/tokens-metadata.yaml

  6. SKIP SENTINEL honored:
       touch .skip-validation
       python3 scripts/validate_design_system.py
       echo $?                                 # expect 0
       # Prints skip message only.
       rm .skip-validation

  7. MALFORMED YAML reported with exit 2:
       # Temporarily break the YAML (unclosed quote)
       python3 scripts/validate_design_system.py
       echo $?                                 # expect 2
       git checkout docs/design-system/tokens-metadata.yaml

  8. MISSING SWIFT DIR reported with exit 2:
       mv Vibeliner/Design Vibeliner/Design.bak
       python3 scripts/validate_design_system.py
       echo $?                                 # expect 2
       mv Vibeliner/Design.bak Vibeliner/Design
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any, Optional

# --- Resolve repo root so the script runs from anywhere -------------------

_SCRIPT_DIR = Path(__file__).resolve().parent
_REPO_ROOT = _SCRIPT_DIR.parent
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

_MISSING_DEPS = (
    "[ERR] Missing dependency: {pkg}. Install with:\n"
    "      pip3 install pyyaml --break-system-packages\n"
)

try:
    import yaml  # noqa: E402
except ImportError:
    print(_MISSING_DEPS.format(pkg="pyyaml"), file=sys.stderr)
    sys.exit(2)

from scripts.parse_design_tokens import parse_directory  # noqa: E402

# --- Paths relative to repo root ------------------------------------------

TOKENS_DIR = _REPO_ROOT / "Vibeliner" / "Design"
METADATA_PATH = _REPO_ROOT / "docs" / "design-system" / "tokens-metadata.yaml"
HTML_PATH = _REPO_ROOT / "docs" / "design-system" / "design-system.html"
SKIP_SENTINEL = _REPO_ROOT / ".skip-validation"


# --- Helpers --------------------------------------------------------------


_HTML_TOKEN_PATTERNS = (
    re.compile(r"<code>([a-z][a-zA-Z]{3,})</code>"),
    re.compile(r'data-token="([a-z][a-zA-Z]{3,})"'),
)


def extract_token_references(html_text: str) -> set[str]:
    """Return token-like identifiers embedded in generated HTML."""
    refs: set[str] = set()
    for pattern in _HTML_TOKEN_PATTERNS:
        refs.update(pattern.findall(html_text))
    return refs


def _leaf_value(leaf: Any) -> str:
    if isinstance(leaf, dict):
        return leaf.get("rgba") or leaf.get("raw") or ""
    return str(leaf or "")


def render_token_value(token_info: dict[str, Any]) -> str:
    """Canonical string used for `explicit_value` equality checks."""
    t = token_info.get("type")
    kind = token_info.get("kind")
    if t == "color":
        if kind == "alias":
            return f"alias:{token_info.get('target', '')}"
        if kind == "dynamic":
            return (
                f"dark:{_leaf_value(token_info.get('dark'))}"
                f"/light:{_leaf_value(token_info.get('light'))}"
            )
        # static color
        return token_info.get("rgba") or token_info.get("raw") or ""
    if t == "dimension":
        return str(token_info.get("value"))
    if t == "font":
        return (
            f"{token_info.get('family', '')} "
            f"{token_info.get('size', '')} "
            f"{token_info.get('weight', '')}"
        ).strip()
    return ""


_HISTORICAL_RENAMES: dict[str, Optional[str]] = {
    "noteHoverBg": "editorNoteSurfaceHover",
    "noteHoverBorder": "editorNoteBorderHover",
    "noteSelectedBg": "editorNoteSurfaceSelected",
    "noteSelectedBorder": "editorNoteBorderSelected",
    "noteEditingBg": "editorNoteSurfaceEditing",
    "notePrefixColor": None,
    "filmstripBg": None,
    "darkChromePopover": None,
    "toolbarButtonFont": None,
}
_REMOVED_IN_VIB_437 = {"notePrefixColor", "filmstripBg", "darkChromePopover", "toolbarButtonFont"}


def historical_rename_suggestion(token_name: str) -> tuple[bool, Optional[str]]:
    """(is_known_historical, suggested_new_name)."""
    if token_name in _HISTORICAL_RENAMES:
        return True, _HISTORICAL_RENAMES[token_name]
    return False, None


def format_existence_error(token_name: str) -> str:
    known, suggestion = historical_rename_suggestion(token_name)
    msg = (
        f"[ERR] YAML references '{token_name}' but it is not defined in any "
        f"DesignTokens*.swift file"
    )
    if suggestion:
        msg += f"\n    Hint: possibly renamed to '{suggestion}'"
    elif known and token_name in _REMOVED_IN_VIB_437:
        msg += "\n    Hint: this token was removed in the VIB-437 consolidation"
    return msg


def format_value_mismatch(
    token_name: str, expected: str, actual: str, info: dict[str, Any]
) -> str:
    source = info.get("source_file", "?")
    line = info.get("line_number", "?")
    return (
        f"[ERR] '{token_name}': YAML expects {expected!r}, Swift has {actual!r}\n"
        f"    ({source} line {line})"
    )


def print_report(
    errors: list[str],
    warnings: list[str],
    swift_count: int,
    yaml_count: int,
    html_exists: bool,
) -> None:
    print("Vibeliner Design System Validation")
    print("==================================")
    print()

    if errors:
        print(f"ERRORS ({len(errors)}):")
        for e in errors:
            print(f"  {e}")
        print()

    if warnings:
        print(f"WARNINGS ({len(warnings)}):")
        for w in warnings:
            print(f"  [!] {w}")
        print()

    if not errors:
        print(f"[OK] All {yaml_count} YAML token references resolve to Swift definitions")
        if html_exists:
            print("[OK] Generated HTML uses no undefined tokens")
        print(f"[OK] {swift_count} Swift tokens parsed")
        if warnings:
            print()
            print(f"{len(warnings)} warning(s). Not a build blocker.")
        else:
            print()
            print("OK")
    else:
        print(f"{len(errors)} error(s), {len(warnings)} warning(s).")
        print("Build will fail until errors are resolved.")


# --- Main -----------------------------------------------------------------


def main() -> int:
    if SKIP_SENTINEL.exists():
        print("Design system validation skipped (.skip-validation present)")
        return 0

    try:
        swift_tokens = parse_directory(TOKENS_DIR)
    except FileNotFoundError as e:
        print(f"[ERR] {e}", file=sys.stderr)
        return 2
    except Exception as e:
        print(f"[ERR] Failed to parse Swift tokens: {e}", file=sys.stderr)
        return 2

    try:
        with METADATA_PATH.open("r", encoding="utf-8") as f:
            metadata = yaml.safe_load(f)
    except FileNotFoundError:
        print(f"[ERR] Metadata file not found: {METADATA_PATH}", file=sys.stderr)
        return 2
    except yaml.YAMLError as e:
        print(f"[ERR] Malformed YAML in {METADATA_PATH}: {e}", file=sys.stderr)
        return 2

    if not isinstance(metadata, dict):
        print(f"[ERR] {METADATA_PATH} must be a YAML mapping at the top level", file=sys.stderr)
        return 2

    yaml_tokens: dict[str, Any] = metadata.get("tokens") or {}
    excluded: set[str] = set(metadata.get("excluded") or [])

    errors: list[str] = []
    warnings: list[str] = []

    # Check 1: existence — every YAML token must exist in Swift.
    for name in sorted(yaml_tokens):
        if name not in swift_tokens:
            errors.append(format_existence_error(name))

    # Check 2: value match — YAML entries with explicit_value must agree with Swift.
    for name, meta in yaml_tokens.items():
        if not isinstance(meta, dict):
            continue
        expected = meta.get("explicit_value")
        if expected is None:
            continue
        if name not in swift_tokens:
            continue  # existence already reported
        actual = render_token_value(swift_tokens[name])
        if str(expected) != str(actual):
            errors.append(format_value_mismatch(name, str(expected), actual, swift_tokens[name]))

    # Check 3: coverage (warning only). Tour-prefixed tokens and everything in
    # DesignTokens+TourIllustrations.swift are intentionally out of YAML —
    # documented in docs/design-system/tour-design.html instead.
    yaml_known = set(yaml_tokens.keys()) | excluded
    for name, info in sorted(swift_tokens.items()):
        if name in yaml_known:
            continue
        if name.startswith("tour"):
            continue
        if info.get("source_file") == "DesignTokens+TourIllustrations.swift":
            continue
        warnings.append(
            f"Swift token '{name}' is not in tokens-metadata.yaml "
            f"(consider adding to 'tokens' or 'excluded')"
        )

    # Check 4: HTML scan — any token-like identifier in the generated HTML
    # must resolve to a real Swift token. Hand-authored tour-design.html is
    # intentionally NOT validated.
    html_exists = HTML_PATH.exists()
    if html_exists:
        html_text = HTML_PATH.read_text(encoding="utf-8")
        refs = extract_token_references(html_text)
        for ref in sorted(refs):
            if ref not in swift_tokens:
                errors.append(
                    f"[ERR] Generated HTML references token '{ref}' but no matching "
                    f"Swift definition"
                )

    print_report(errors, warnings, len(swift_tokens), len(yaml_tokens), html_exists)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
