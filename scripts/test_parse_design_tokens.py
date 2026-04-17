"""Unit tests for scripts.parse_design_tokens.

Uses small inline Swift fixtures via a tempdir. Does NOT depend on real
Vibeliner/Design/*.swift files.

Run: python3 -m unittest scripts.test_parse_design_tokens
"""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from scripts.parse_design_tokens import parse_directory, parse_file


def _write(dir_path: Path, name: str, body: str) -> Path:
    p = dir_path / name
    p.write_text(body, encoding="utf-8")
    return p


_FIXTURE_HEADER = "import AppKit\n\nenum DesignTokens {\n"
_FIXTURE_FOOTER = "\n}\n"


def _fixture(body: str) -> str:
    """Wrap a body snippet so it's a valid-ish DesignTokens enum file."""
    return _FIXTURE_HEADER + body + _FIXTURE_FOOTER


class ParseFileTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _parse(self, body: str, name: str = "DesignTokens.swift") -> dict:
        path = _write(self.dir, name, _fixture(body))
        return parse_file(path)

    def test_static_color_rgb_emits_hex_and_rgba(self) -> None:
        tokens = self._parse(
            "    /// #EF4444 — all annotation marks\n"
            "    static let red = NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)\n"
        )
        self.assertIn("red", tokens)
        t = tokens["red"]
        self.assertEqual(t["type"], "color")
        self.assertEqual(t["kind"], "static")
        self.assertEqual(t["hex"], "#EF4444")
        self.assertEqual(t["rgba"], "rgba(239,68,68,1)")
        self.assertEqual(t["doc_comment"], "#EF4444 — all annotation marks")
        self.assertEqual(t["source_file"], "DesignTokens.swift")
        self.assertIsInstance(t["line_number"], int)

    def test_static_color_white_form(self) -> None:
        tokens = self._parse(
            "    static let gray = NSColor(white: 0.5, alpha: 1.0)\n"
        )
        t = tokens["gray"]
        self.assertEqual(t["hex"], "#808080")
        self.assertEqual(t["rgba"], "rgba(128,128,128,1)")

    def test_computed_color_black_with_alpha(self) -> None:
        tokens = self._parse(
            "    static let dimOverlay = NSColor.black.withAlphaComponent(0.5)\n"
        )
        t = tokens["dimOverlay"]
        self.assertEqual(t["kind"], "static")
        self.assertEqual(t["rgba"], "rgba(0,0,0,0.5)")
        self.assertEqual(t["hex"], "#000000")

    def test_dynamic_color_inline_ternary(self) -> None:
        tokens = self._parse(
            "    /// Toolbar bg\n"
            "    static let toolbarBg = NSColor(name: nil) { appearance in\n"
            "        isDarkAppearance(appearance)\n"
            "            ? NSColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 0.92)\n"
            "            : NSColor(white: 1.0, alpha: 0.88)\n"
            "    }\n"
        )
        t = tokens["toolbarBg"]
        self.assertEqual(t["kind"], "dynamic")
        self.assertEqual(t["dark"]["rgba"], "rgba(30,30,30,0.92)")
        self.assertEqual(t["light"]["rgba"], "rgba(255,255,255,0.88)")

    def test_dynamic_color_if_return_form_with_intermediate_comment(self) -> None:
        tokens = self._parse(
            "    static let settingsFieldSurface = NSColor(name: nil) { appearance in\n"
            "        if isDarkAppearance(appearance) {\n"
            "            return NSColor(white: 1.0, alpha: 0.06)\n"
            "        }\n"
            "        // #eef0f6\n"
            "        return NSColor(red: 238/255, green: 240/255, blue: 246/255, alpha: 1.0)\n"
            "    }\n"
        )
        t = tokens["settingsFieldSurface"]
        self.assertEqual(t["kind"], "dynamic")
        self.assertEqual(t["dark"]["rgba"], "rgba(255,255,255,0.06)")
        self.assertEqual(t["light"]["hex"], "#EEF0F6")

    def test_dynamic_color_helper_form(self) -> None:
        tokens = self._parse(
            "    /// Divider\n"
            "    static let dividerColor = dynamicColor(\n"
            "        dark: NSColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.08),\n"
            "        light: NSColor(red: 0, green: 0, blue: 0, alpha: 0.08)\n"
            "    )\n"
        )
        t = tokens["dividerColor"]
        self.assertEqual(t["kind"], "dynamic")
        self.assertEqual(t["dark"]["rgba"], "rgba(255,255,255,0.08)")
        self.assertEqual(t["light"]["rgba"], "rgba(0,0,0,0.08)")

    def test_alias_form(self) -> None:
        tokens = self._parse(
            "    static let pillButtonText = NSColor(red: 83/255, green: 74/255, blue: 183/255, alpha: 1.0)\n"
            "    /// Segmented active text\n"
            "    static let segmentedActiveText = pillButtonText\n"
        )
        t = tokens["segmentedActiveText"]
        self.assertEqual(t["kind"], "alias")
        self.assertEqual(t["target"], "pillButtonText")

    def test_dimension_cgfloat_integer(self) -> None:
        tokens = self._parse(
            "    /// 18px badge diameter (radius 9)\n"
            "    static let badgeDiameter: CGFloat = 18\n"
        )
        t = tokens["badgeDiameter"]
        self.assertEqual(t["type"], "dimension")
        self.assertEqual(t["value"], 18)
        self.assertEqual(t["unit"], "pt")

    def test_dimension_cgfloat_decimal(self) -> None:
        tokens = self._parse(
            "    static let strokeWidth: CGFloat = 2.5\n"
        )
        t = tokens["strokeWidth"]
        self.assertEqual(t["type"], "dimension")
        self.assertEqual(t["value"], 2.5)

    def test_dimension_int(self) -> None:
        tokens = self._parse("    static let freehandMinPoints: Int = 3\n")
        t = tokens["freehandMinPoints"]
        self.assertEqual(t["type"], "dimension")
        self.assertEqual(t["value"], 3)
        self.assertEqual(t["unit"], "int")

    def test_font_system(self) -> None:
        tokens = self._parse(
            "    /// Badge number: system 9px weight 600\n"
            "    static let badgeFont = NSFont.systemFont(ofSize: 9, weight: .semibold)\n"
        )
        t = tokens["badgeFont"]
        self.assertEqual(t["type"], "font")
        self.assertEqual(t["family"], "system")
        self.assertEqual(t["size"], 9.0)
        self.assertEqual(t["weight"], "semibold")

    def test_font_monospaced(self) -> None:
        tokens = self._parse(
            "    static let statusPillFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)\n"
        )
        t = tokens["statusPillFont"]
        self.assertEqual(t["family"], "monospace")
        self.assertEqual(t["weight"], "medium")
        self.assertEqual(t["size"], 10.0)

    def test_multi_line_doc_comment_is_concatenated(self) -> None:
        tokens = self._parse(
            "    /// First line\n"
            "    /// Second line\n"
            "    static let red = NSColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)\n"
        )
        self.assertEqual(tokens["red"]["doc_comment"], "First line Second line")

    def test_skips_static_func(self) -> None:
        tokens = self._parse(
            "    static func helper() -> NSColor {\n"
            "        return NSColor.black\n"
            "    }\n"
            "    static let red = NSColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)\n"
        )
        self.assertNotIn("helper", tokens)
        self.assertIn("red", tokens)

    def test_skips_array_constant(self) -> None:
        tokens = self._parse(
            "    static let dashPattern: [CGFloat] = [3, 2]\n"
            "    static let ok: CGFloat = 4\n"
        )
        self.assertNotIn("dashPattern", tokens)
        self.assertIn("ok", tokens)

    def test_skips_shadow_closure(self) -> None:
        tokens = self._parse(
            "    static let titlePillExportShadow: NSShadow = {\n"
            "        let shadow = NSShadow()\n"
            "        shadow.shadowBlurRadius = 8\n"
            "        return shadow\n"
            "    }()\n"
            "    static let after: CGFloat = 4\n"
        )
        self.assertNotIn("titlePillExportShadow", tokens)
        self.assertIn("after", tokens)

    def test_clear_color_resolves(self) -> None:
        tokens = self._parse("    static let nothing = NSColor.clear\n")
        t = tokens["nothing"]
        self.assertEqual(t["rgba"], "rgba(0,0,0,0.0)")

    def test_system_color_alias_captured_as_system(self) -> None:
        tokens = self._parse(
            "    static let border = NSColor.separatorColor\n"
        )
        t = tokens["border"]
        self.assertEqual(t["type"], "color")
        self.assertEqual(t["system_color"], "separatorColor")


class ParseDirectoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_merges_multiple_files(self) -> None:
        _write(self.dir, "DesignTokens.swift", _fixture(
            "    static let red = NSColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)\n"
        ))
        _write(self.dir, "DesignTokens+Layout.swift", _fixture(
            "    static let badgeDiameter: CGFloat = 18\n"
        ))
        merged = parse_directory(self.dir)
        self.assertIn("red", merged)
        self.assertIn("badgeDiameter", merged)
        self.assertEqual(merged["red"]["source_file"], "DesignTokens.swift")
        self.assertEqual(merged["badgeDiameter"]["source_file"], "DesignTokens+Layout.swift")

    def test_duplicate_token_raises_with_both_file_names(self) -> None:
        _write(self.dir, "DesignTokens.swift", _fixture(
            "    static let red = NSColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)\n"
        ))
        _write(self.dir, "DesignTokens+Dup.swift", _fixture(
            "    static let red = NSColor(red: 0, green: 1.0, blue: 0, alpha: 1.0)\n"
        ))
        with self.assertRaises(ValueError) as ctx:
            parse_directory(self.dir)
        msg = str(ctx.exception)
        self.assertIn("red", msg)
        self.assertIn("DesignTokens.swift", msg)
        self.assertIn("DesignTokens+Dup.swift", msg)

    def test_missing_files_raises(self) -> None:
        with self.assertRaises(FileNotFoundError):
            parse_directory(self.dir)

    def test_parse_is_deterministic(self) -> None:
        _write(self.dir, "DesignTokens.swift", _fixture(
            "    static let red = NSColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)\n"
            "    static let badgeDiameter: CGFloat = 18\n"
            "    static let badgeFont = NSFont.systemFont(ofSize: 9, weight: .semibold)\n"
        ))
        first = parse_directory(self.dir)
        second = parse_directory(self.dir)
        self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()
