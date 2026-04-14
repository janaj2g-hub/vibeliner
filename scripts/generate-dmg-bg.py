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

// VIB-347 attempt 8: Image dimensions EXACTLY match Finder content area.
// Finder bounds {200,200,700,550} = 500x350 window. Title bar ~22px.
// Content area = 500x328. Image at this logical size → @2x = 1000x656px.
let width = 500
let height = 328
let size = NSSize(width: width, height: height)
let w = CGFloat(width)
let h = CGFloat(height)

let image = NSImage(size: size)
image.lockFocus()

// Background — light gray #F0F0F0
NSColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()

// ── Coordinate system (verified with debug grid) ──
// NSImage origin = bottom-left (flipped=false)
// Finder icon at {250, 200} → NSImage {250, h-200} = {250, 128}
// Icon is 80px, so icon top edge in Finder = y=160, NSImage = h-160 = 168
// Text should center between Finder y=0 (top) and y=160 (icon top)
// Midpoint = Finder y=80 → NSImage y = h - 80 = 248

let fontURL = URL(fileURLWithPath: "Vibeliner/Resources/Jersey25-Regular.ttf")
CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
let logoFont = NSFont(name: "Jersey25-Regular", size: 48)
    ?? NSFont.monospacedSystemFont(ofSize: 48, weight: .bold)

let logoAttrs: [NSAttributedString.Key: Any] = [
    .font: logoFont,
    .foregroundColor: NSColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1),
]
let logoStr = NSAttributedString(string: "vibeliner", attributes: logoAttrs)
let logoSize = logoStr.size()

// Place wordmark so its vertical center is at the midpoint (NSImage y=248)
let logoY = 248 - logoSize.height / 2
logoStr.draw(at: NSPoint(x: (w - logoSize.width) / 2, y: logoY))

let subFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .medium)
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: subFont,
    .foregroundColor: NSColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1),
    .kern: 0.5 as NSNumber,
]
let subStr = NSAttributedString(string: "SCREENSHOT \u{00B7} ANNOTATE \u{00B7} PROMPT", attributes: subAttrs)
let subSize = subStr.size()
subStr.draw(at: NSPoint(x: (w - subSize.width) / 2, y: logoY - 20))

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
