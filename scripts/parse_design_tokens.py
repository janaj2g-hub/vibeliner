#!/usr/bin/env python3
"""Regex-based parser that extracts design tokens from DesignTokens*.swift files.

Pure extraction. No rendering, no validation. Returns a dict of token info.
Stdlib only.

Public API:
    parse_file(path: Path) -> dict[str, dict]
    parse_directory(dir_path: Path) -> dict[str, dict]
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import Any, Optional

_RE_DOC = re.compile(r"^\s*///\s?(.*?)\s*$")
_RE_STATIC_LET = re.compile(
    r"^\s*static\s+let\s+(\w+)\s*(?::\s*([^=]+?))?\s*=\s*(.*)$"
)
_RE_STATIC_FUNC = re.compile(r"^\s*static\s+func\s+\w+")
_RE_CLASS = re.compile(
    r"^\s*(?:private\s+|public\s+|internal\s+|fileprivate\s+)?class\s+\w+"
)
_RE_MARK = re.compile(r"^\s*//\s*MARK:")
_RE_NSCOLOR_RGB = re.compile(
    r"NSColor\(\s*red:\s*([^,]+?),\s*green:\s*([^,]+?),\s*blue:\s*([^,]+?),\s*alpha:\s*([^)]+?)\s*\)"
)
_RE_NSCOLOR_WHITE = re.compile(
    r"NSColor\(\s*white:\s*([^,]+?),\s*alpha:\s*([^)]+?)\s*\)"
)
_RE_NSCOLOR_NAMED = re.compile(r"^NSColor\.(\w+)$")
_RE_NSCOLOR_WITH_ALPHA = re.compile(
    r"^NSColor\.(\w+)\s*\.withAlphaComponent\(\s*([^)]+?)\s*\)$"
)
_RE_IDENT_WITH_ALPHA = re.compile(
    r"^(\w+)\s*\.withAlphaComponent\(\s*([^)]+?)\s*\)$"
)
_RE_NSCOLOR_NAME_NIL = re.compile(r"^NSColor\(\s*name:\s*nil\s*\)\s*\{")
_RE_DYNAMIC_HELPER = re.compile(r"^dynamicColor\(\s*dark:\s*(.+?)\s*,\s*light:\s*(.+?)\s*\)$")
_RE_NSFONT_SYSTEM = re.compile(
    r"^NSFont\.systemFont\(\s*ofSize:\s*([0-9.]+)\s*,\s*weight:\s*\.(\w+)\s*\)$"
)
_RE_NSFONT_MONO = re.compile(
    r"^NSFont\.monospacedSystemFont\(\s*ofSize:\s*([0-9.]+)\s*,\s*weight:\s*\.(\w+)\s*\)$"
)
_RE_IDENTIFIER = re.compile(r"^[A-Za-z_]\w*$")
_RE_NUMBER = re.compile(r"^-?\d+(?:\.\d+)?$")

_NAMED_NSCOLOR_RGBA = {
    "black": "rgba(0,0,0,1.0)",
    "white": "rgba(255,255,255,1.0)",
    "clear": "rgba(0,0,0,0.0)",
    "red": "rgba(255,0,0,1.0)",
    "green": "rgba(0,255,0,1.0)",
    "blue": "rgba(0,0,255,1.0)",
}


def _strip_line_comment(line: str) -> str:
    """Remove trailing `// ...` while respecting string literals."""
    out, i, in_str = [], 0, False
    while i < len(line):
        ch = line[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < len(line):
                out.append(line[i + 1]); i += 2; continue
            if ch == '"':
                in_str = False
            i += 1; continue
        if ch == '"':
            in_str = True; out.append(ch); i += 1; continue
        if ch == "/" and i + 1 < len(line) and line[i + 1] == "/":
            break
        out.append(ch); i += 1
    return "".join(out)


def _depth_delta(text: str) -> int:
    """Net bracket-depth change for a line, ignoring strings and line comments."""
    text = _strip_line_comment(text)
    depth, i, in_str = 0, 0, False
    while i < len(text):
        ch = text[i]
        if in_str:
            if ch == "\\" and i + 1 < len(text):
                i += 2; continue
            if ch == '"':
                in_str = False
            i += 1; continue
        if ch == '"':
            in_str = True
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        i += 1
    return depth


def _split_top_level(text: str, seps: str) -> list[str]:
    """Split `text` on any char in `seps` at paren/brace/bracket depth 0."""
    parts, buf, depth, i, in_str = [], [], 0, 0, False
    while i < len(text):
        ch = text[i]
        if in_str:
            buf.append(ch)
            if ch == "\\" and i + 1 < len(text):
                buf.append(text[i + 1]); i += 2; continue
            if ch == '"':
                in_str = False
            i += 1; continue
        if ch == '"':
            in_str = True; buf.append(ch); i += 1; continue
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if depth == 0 and ch in seps:
            parts.append("".join(buf)); buf = []; i += 1; continue
        buf.append(ch); i += 1
    parts.append("".join(buf))
    return parts


def _eval_channel(expr: str) -> float:
    expr = expr.strip()
    if "/" in expr:
        num, _, den = expr.partition("/")
        return float(num.strip()) / float(den.strip())
    return float(expr)


def _rgba(r: float, g: float, b: float, a: float) -> str:
    def ch(v: float) -> str:
        return str(max(0, min(255, int(round(v * 255)))))
    def al(v: float) -> str:
        s = f"{v:.3f}".rstrip("0").rstrip(".")
        return s if s else "0"
    return f"rgba({ch(r)},{ch(g)},{ch(b)},{al(a)})"


def _hex(r: float, g: float, b: float) -> str:
    def ch(v: float) -> int:
        return max(0, min(255, int(round(v * 255))))
    return f"#{ch(r):02X}{ch(g):02X}{ch(b):02X}"


def _resolve_color_expr(expr: str) -> dict[str, Any]:
    """Concrete color if we can compute one; always includes `raw`."""
    expr = expr.strip().rstrip(",").strip()
    m = _RE_NSCOLOR_NAMED.match(expr)
    if m:
        name = m.group(1)
        if name in _NAMED_NSCOLOR_RGBA:
            return {"rgba": _NAMED_NSCOLOR_RGBA[name], "raw": expr}
        return {"raw": expr, "system_color": name}
    m = _RE_NSCOLOR_WITH_ALPHA.match(expr)
    if m:
        base, alpha = m.group(1), _eval_channel(m.group(2))
        if base == "black":
            return {"rgba": _rgba(0, 0, 0, alpha), "hex": "#000000", "raw": expr}
        if base == "white":
            return {"rgba": _rgba(1, 1, 1, alpha), "hex": "#FFFFFF", "raw": expr}
        return {"raw": expr, "system_color": base, "alpha": alpha}
    m = _RE_NSCOLOR_RGB.search(expr)
    if m:
        r, g, b, a = (_eval_channel(x) for x in m.groups())
        return {"hex": _hex(r, g, b), "rgba": _rgba(r, g, b, a), "raw": expr}
    m = _RE_NSCOLOR_WHITE.search(expr)
    if m:
        w, a = _eval_channel(m.group(1)), _eval_channel(m.group(2))
        return {"hex": _hex(w, w, w), "rgba": _rgba(w, w, w, a), "raw": expr}
    # Bare identifier — color alias reference (used inside dynamicColor args).
    if _RE_IDENTIFIER.match(expr):
        return {"raw": expr, "alias": expr}
    return {"raw": expr}


def _extract_branches(inner: str) -> Optional[tuple[str, str]]:
    """Pull dark/light expressions out of a dynamic closure body."""
    # Drop `// ...` comments on every line before flattening.
    lines = [_strip_line_comment(ln) for ln in inner.splitlines()]
    flat = re.sub(r"\s+", " ", " ".join(lines)).strip()
    # Ternary form: `... isDarkAppearance(...) ? DARK : LIGHT`
    idx = flat.find("isDarkAppearance")
    if idx >= 0 and "?" in flat[idx:]:
        tail = flat[idx:]
        # Walk to the top-level `?`.
        parts = _split_top_level(tail, "?")
        if len(parts) >= 2:
            after_q = "?".join(parts[1:])
            branch_parts = _split_top_level(after_q, ":")
            if len(branch_parts) >= 2:
                return branch_parts[0].strip(), ":".join(branch_parts[1:]).strip()
    # If/return form. Capture first `return X`, then trailing `return Y`.
    m = re.search(r"if\s+isDarkAppearance\([^)]*\)\s*\{\s*return\s+(.+?)\s*\}", flat)
    if not m:
        return None
    dark = m.group(1).strip()
    tail = flat[m.end():]
    m2 = re.search(r"return\s+(.+?)\s*(?:\}|$)", tail)
    if not m2:
        return None
    return dark, m2.group(1).strip()


def _looks_like_color_or_font(expr: str) -> bool:
    return (
        expr.startswith("NSColor")
        or expr.startswith("NSFont")
        or expr.startswith("dynamicColor")
    )


def _classify(name: str, type_annot: Optional[str], expr: str) -> Optional[dict[str, Any]]:
    expr = expr.strip().rstrip(";").strip()
    type_annot = (type_annot or "").strip()

    if type_annot in {"CGFloat", "Int", "Double", "Float"}:
        if _RE_NUMBER.match(expr):
            value = float(expr) if "." in expr else int(expr)
            unit = "pt" if type_annot == "CGFloat" else type_annot.lower()
            return {"type": "dimension", "kind": "static", "value": value, "unit": unit, "raw": expr}
        return None
    if type_annot.startswith(("[", "(", "{")):
        return None
    if type_annot and type_annot not in {"NSColor", "NSFont"} and not _looks_like_color_or_font(expr):
        return None

    m = _RE_NSFONT_SYSTEM.match(expr)
    if m:
        return {"type": "font", "kind": "static", "size": float(m.group(1)),
                "weight": m.group(2), "family": "system", "raw": expr}
    m = _RE_NSFONT_MONO.match(expr)
    if m:
        return {"type": "font", "kind": "static", "size": float(m.group(1)),
                "weight": m.group(2), "family": "monospace", "raw": expr}

    if _RE_NSCOLOR_NAME_NIL.match(expr):
        body_start = expr.index("{") + 1
        body_end = expr.rfind("}")
        inner = expr[body_start:body_end] if body_end > body_start else ""
        branches = _extract_branches(inner)
        result: dict[str, Any] = {"type": "color", "kind": "dynamic", "raw": expr}
        if branches:
            result["dark"] = _resolve_color_expr(branches[0])
            result["light"] = _resolve_color_expr(branches[1])
        return result

    m = _RE_DYNAMIC_HELPER.match(expr)
    if m:
        return {
            "type": "color", "kind": "dynamic", "raw": expr,
            "dark": _resolve_color_expr(m.group(1)),
            "light": _resolve_color_expr(m.group(2)),
        }

    if expr.startswith("NSColor(") or expr.startswith("NSColor."):
        return {"type": "color", "kind": "static", **_resolve_color_expr(expr)}

    if _RE_IDENTIFIER.match(expr):
        return {"type": "color", "kind": "alias", "target": expr, "raw": expr}

    m = _RE_IDENT_WITH_ALPHA.match(expr)
    if m and m.group(1) != "NSColor":
        base = m.group(1)
        alpha = _eval_channel(m.group(2))
        return {"type": "color", "kind": "alias", "target": base, "alpha": alpha, "raw": expr}

    if _RE_NUMBER.match(expr):
        value = float(expr) if "." in expr else int(expr)
        return {"type": "dimension", "kind": "static", "value": value, "unit": "pt", "raw": expr}

    return None


def parse_file(path: Path) -> dict[str, dict[str, Any]]:
    """Parse one DesignTokens*.swift file into a dict of token info."""
    lines = path.read_text(encoding="utf-8").splitlines()
    tokens: dict[str, dict[str, Any]] = {}
    doc_buffer: list[str] = []
    i, n = 0, len(lines)
    while i < n:
        raw = lines[i]
        m_doc = _RE_DOC.match(raw)
        if m_doc:
            doc_buffer.append(m_doc.group(1).strip())
            i += 1; continue
        stripped = raw.strip()
        if stripped == "" or _RE_MARK.match(raw) or stripped.startswith("//"):
            doc_buffer = []; i += 1; continue
        if _RE_CLASS.match(raw) or _RE_STATIC_FUNC.match(raw):
            depth = _depth_delta(raw)
            i += 1
            while i < n and depth != 0:
                depth += _depth_delta(lines[i]); i += 1
            doc_buffer = []; continue
        m = _RE_STATIC_LET.match(raw)
        if m:
            name, type_annot, first = m.group(1), m.group(2), m.group(3)
            parts = [first]
            depth = _depth_delta(first)
            start_line = i + 1
            j = i + 1
            while depth > 0 and j < n:
                parts.append(lines[j])
                depth += _depth_delta(lines[j])
                j += 1
            # Strip line comments before joining so `//` can't swallow later lines.
            expr = " ".join(_strip_line_comment(p).strip() for p in parts).strip()
            classified = _classify(name, type_annot, expr)
            if classified is not None:
                doc = " ".join(doc_buffer).strip() if doc_buffer else None
                classified["source_file"] = path.name
                classified["line_number"] = start_line
                if doc:
                    classified["doc_comment"] = doc
                tokens[name] = classified
            doc_buffer = []; i = j; continue
        doc_buffer = []; i += 1
    return tokens


def parse_directory(dir_path: Path) -> dict[str, dict[str, Any]]:
    """Parse every DesignTokens*.swift file and merge. Raises on name collisions."""
    files = sorted(dir_path.glob("DesignTokens*.swift"))
    if not files:
        raise FileNotFoundError(f"No DesignTokens*.swift files under {dir_path}")
    merged: dict[str, dict[str, Any]] = {}
    owners: dict[str, str] = {}
    for f in files:
        for name, info in parse_file(f).items():
            if name in merged:
                raise ValueError(
                    f"Duplicate token '{name}' in {owners[name]} and {f.name}"
                )
            merged[name] = info
            owners[name] = f.name
    return merged


def _main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: parse_design_tokens.py <DesignTokens.swift | Design/>", file=sys.stderr)
        return 2
    target = Path(argv[1])
    tokens = parse_directory(target) if target.is_dir() else parse_file(target)
    print(f"{len(tokens)} tokens parsed")
    by_type: dict[str, int] = {}
    for info in tokens.values():
        by_type[info["type"]] = by_type.get(info["type"], 0) + 1
    for t, count in sorted(by_type.items()):
        print(f"  {t}: {count}")
    return 0


if __name__ == "__main__":
    sys.exit(_main(sys.argv))
