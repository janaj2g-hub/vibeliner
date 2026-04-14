#!/bin/bash
set -euo pipefail

# ─── Vibeliner DMG Builder ───────────────────────────────────────────
# Builds Vibeliner in Release and packages into a branded DMG.
# Run from the repo root: ./scripts/build-dmg.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Read version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Vibeliner/Info.plist)
echo "▸ Building Vibeliner v${VERSION} (Release)..."

# Build in Release — the Vibeliner scheme's "Copy App to dist" build phase
# handles copying the .app to dist/Vibeliner.app automatically.
# Do NOT override CONFIGURATION_BUILD_DIR — it conflicts with the copy phase.
xcodebuild -project Vibeliner.xcodeproj \
    -scheme Vibeliner \
    -configuration Release \
    build \
    2>&1 | tail -3

# Verify build output
if [ ! -d "dist/Vibeliner.app" ]; then
    echo "✘ ERROR: dist/Vibeliner.app not found after build"
    exit 1
fi
echo "✔ Build succeeded: dist/Vibeliner.app"

# Generate branded DMG background if it doesn't exist
BG_PATH="scripts/dmg-background.png"
if [ ! -f "$BG_PATH" ]; then
    echo "▸ Generating DMG background image..."
    python3 "$SCRIPT_DIR/generate-dmg-bg.py"
fi

# Clean previous DMGs and staging
rm -f dist/Vibeliner-*.dmg
STAGING="dist/dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp -R dist/Vibeliner.app "$STAGING/"
ln -s /Applications "$STAGING/Applications"

DMG_PATH="dist/Vibeliner-${VERSION}.dmg"
DMG_RW="dist/Vibeliner-rw.dmg"

# ─── Try branded DMG with background ─────────────────────────────────
BRANDED=false
if [ -f "$BG_PATH" ]; then
    echo "▸ Creating branded DMG..."

    # Step 1: Create read-write DMG
    hdiutil create \
        -volname "Vibeliner" \
        -srcfolder "$STAGING" \
        -ov \
        -format UDRW \
        "$DMG_RW" \
        2>/dev/null

    # Step 2: Mount and customize
    MOUNT_DIR=$(hdiutil attach "$DMG_RW" -readwrite -noverify -noautoopen 2>/dev/null | grep "Volumes" | awk '{print $3}')
    if [ -n "$MOUNT_DIR" ] && [ -d "$MOUNT_DIR" ]; then
        # Copy background image into hidden .background folder
        mkdir -p "$MOUNT_DIR/.background"
        cp "$BG_PATH" "$MOUNT_DIR/.background/dmg-background.png"

        # Apply Finder customization via AppleScript
        osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "Finder"
    tell disk "Vibeliner"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 700, 500}
        set opts to icon view options of container window
        set icon size of opts to 80
        set arrangement of opts to not arranged
        set background picture of opts to file ".background:dmg-background.png"
        set position of item "Vibeliner.app" of container window to {160, 200}
        set position of item "Applications" of container window to {440, 200}
        close
    end tell
end tell
APPLESCRIPT
        # Give Finder time to write .DS_Store
        sleep 2

        # Unmount
        hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true

        # Convert to compressed read-only
        hdiutil convert "$DMG_RW" -format UDZO -o "$DMG_PATH" -ov 2>/dev/null
        rm -f "$DMG_RW"
        BRANDED=true
    else
        echo "  ⚠ Could not mount DMG for customization — falling back to plain DMG"
        rm -f "$DMG_RW"
    fi
fi

# ─── Fallback: plain DMG ─────────────────────────────────────────────
if [ "$BRANDED" = false ]; then
    echo "▸ Creating plain DMG..."
    hdiutil create \
        -volname "Vibeliner" \
        -srcfolder "$STAGING" \
        -ov \
        -format UDZO \
        "$DMG_PATH"
fi

# Clean up
rm -rf "$STAGING"

# Report
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
echo ""
echo "✔ DMG created: $DMG_PATH ($DMG_SIZE)"
