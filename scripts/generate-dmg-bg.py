#!/usr/bin/env python3
"""Generate the branded DMG background image for Vibeliner.

Uses only CoreGraphics via Python ctypes — no third-party deps needed.
Falls back to a simpler approach if CG isn't available.

Output: scripts/dmg-background.png (600x400px)
"""

import subprocess
import struct
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(SCRIPT_DIR, "dmg-background.png")

WIDTH, HEIGHT = 600, 400
BG_COLOR = (14, 14, 16)       # #0e0e10
RED = (239, 68, 68)           # #EF4444 — DesignTokens.red
GRAY = (255, 255, 255, 58)    # rgba(255,255,255,0.22)


def generate_with_sips():
    """Generate background using macOS sips + Core Image / AppKit via osascript."""
    # Create a solid dark background, then overlay text via a temporary HTML + screencapture
    # Simplest reliable approach: use Python to draw raw pixels into a BMP, convert with sips

    # Create raw BGRA pixel data
    pixels = bytearray(WIDTH * HEIGHT * 4)
    r, g, b = BG_COLOR
    for i in range(WIDTH * HEIGHT):
        offset = i * 4
        pixels[offset] = b      # Blue
        pixels[offset + 1] = g  # Green
        pixels[offset + 2] = r  # Red
        pixels[offset + 3] = 255  # Alpha

    # Draw "vibeliner" text centered (approximate with pixel rectangles)
    # Since we can't use fonts in raw pixel mode, we'll create the image
    # using a Swift helper via osascript

    # Use NSImage + NSGraphicsContext via Swift snippet
    swift_code = r'''
import AppKit
import CoreText

let width = 600
let height = 400
let size = NSSize(width: width, height: height)

let image = NSImage(size: size)
image.lockFocus()

// Background
NSColor(red: 14/255, green: 14/255, blue: 16/255, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()

// "vibeliner" wordmark — try Jersey 25, fall back to monospace bold
let fontURL = URL(fileURLWithPath: "Vibeliner/Resources/Jersey25-Regular.ttf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
let logoFont = NSFont(name: "Jersey25-Regular", size: 52)
    ?? NSFont.monospacedSystemFont(ofSize: 52, weight: .bold)

let logoAttrs: [NSAttributedString.Key: Any] = [
    .font: logoFont,
    .foregroundColor: NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1),
]
let logoStr = NSAttributedString(string: "vibeliner", attributes: logoAttrs)
let logoSize = logoStr.size()
let logoX = (CGFloat(width) - logoSize.width) / 2
let logoY = (CGFloat(height) - logoSize.height) / 2 + 20
logoStr.draw(at: NSPoint(x: logoX, y: logoY))

// Subtitle
let subFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: subFont,
    .foregroundColor: NSColor(white: 1, alpha: 0.22),
    .kern: 0.5 as NSNumber,
]
let subStr = NSAttributedString(string: "SCREENSHOT \u{00B7} ANNOTATE \u{00B7} PROMPT", attributes: subAttrs)
let subSize = subStr.size()
let subX = (CGFloat(width) - subSize.width) / 2
let subY = logoY - 24
subStr.draw(at: NSPoint(x: subX, y: subY))

image.unlockFocus()

// Save as PNG
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    exit(1)
}
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "scripts/dmg-background.png"
try! png.write(to: URL(fileURLWithPath: outputPath))
'''

    # Write Swift to temp file and compile+run
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.swift', delete=False) as f:
        f.write(swift_code)
        swift_path = f.name

    try:
        result = subprocess.run(
            ['swift', swift_path, OUTPUT],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0 and os.path.exists(OUTPUT):
            print(f"  ✔ DMG background generated: {OUTPUT}")
            return True
        else:
            print(f"  ⚠ Swift generation failed: {result.stderr[:200]}")
            return False
    except Exception as e:
        print(f"  ⚠ Swift generation error: {e}")
        return False
    finally:
        os.unlink(swift_path)


if __name__ == "__main__":
    if not generate_with_sips():
        print("  ⚠ Background generation failed — DMG will use plain layout")
        sys.exit(1)
