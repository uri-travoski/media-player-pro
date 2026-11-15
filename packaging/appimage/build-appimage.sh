#!/bin/bash
set -e

VERSION="1.6"
ARCH="x86_64"
OUTPUT_DIR="${1:-$(pwd)/dist}"
mkdir -p "$OUTPUT_DIR"

APP_DIR="$(mktemp -d /tmp/appimage-XXXXXX)"
trap 'rm -rf "$APP_DIR"' EXIT

echo "==> Building Media Player Pro AppImage in $APP_DIR..."

make PREFIX=/usr DESTDIR="$APP_DIR" install

# Copy AppRun and Desktop Integration
cp packaging/appimage/AppRun "$APP_DIR/AppRun"
chmod +x "$APP_DIR/AppRun"
cp data/media-player-pro.desktop "$APP_DIR/"
cp data/icons/512x512.png "$APP_DIR/media-player-pro.png"
cp data/icons/media-player-pro.svg "$APP_DIR/"

# Bundle mpv binary and required core dependencies
mkdir -p "$APP_DIR/usr/bin" "$APP_DIR/usr/lib"
if command -v mpv >/dev/null 2>&1; then
    cp "$(command -v mpv)" "$APP_DIR/usr/bin/mpv"
fi

# Download appimagetool if not present
APPIMAGETOOL="/tmp/appimagetool-${ARCH}.AppImage"
if [ ! -f "$APPIMAGETOOL" ]; then
    echo "==> Downloading appimagetool..."
    curl -sLo "$APPIMAGETOOL" "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage"
    chmod +x "$APPIMAGETOOL"
fi

APPIMAGE_OUT="$OUTPUT_DIR/Media_Player_Pro-${VERSION}-${ARCH}.AppImage"
echo "==> Packaging into $APPIMAGE_OUT..."
ARCH="$ARCH" "$APPIMAGETOOL" --appimage-extract-and-run "$APP_DIR" "$APPIMAGE_OUT"

echo "==> AppImage created successfully: $APPIMAGE_OUT"
