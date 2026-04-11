#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Read version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Vibeliner/Info.plist)
echo "Building Vibeliner v${VERSION}..."

# Build in Release configuration
xcodebuild -project Vibeliner.xcodeproj \
    -scheme Vibeliner \
    -configuration Release \
    build \
    CONFIGURATION_BUILD_DIR="$(pwd)/dist"

# Verify build output
if [ ! -d "dist/Vibeliner.app" ]; then
    echo "ERROR: dist/Vibeliner.app not found after build"
    exit 1
fi

# Clean previous DMGs
rm -f dist/Vibeliner-*.dmg

# Create staging directory
STAGING="dist/dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp -R dist/Vibeliner.app "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Create DMG
DMG_PATH="dist/Vibeliner-${VERSION}.dmg"
hdiutil create \
    -volname "Vibeliner" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$STAGING"

echo ""
echo "DMG created: $DMG_PATH"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
