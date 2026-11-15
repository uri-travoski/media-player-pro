#!/bin/bash
set -e

VERSION="1.3"
OUTPUT_DIR="${1:-$(pwd)/dist}"
mkdir -p "$OUTPUT_DIR"

echo "==> Building Flatpak bundle..."
if command -v flatpak-builder >/dev/null 2>&1; then
    BUILD_DIR="$(mktemp -d /tmp/flatpak-build-XXXXXX)"
    REPO_DIR="$(mktemp -d /tmp/flatpak-repo-XXXXXX)"
    trap 'rm -rf "$BUILD_DIR" "$REPO_DIR"' EXIT

    flatpak-builder --force-clean --repo="$REPO_DIR" "$BUILD_DIR" packaging/flatpak/org.mediaplayerpro.MediaPlayerPro.yaml
    flatpak build-bundle "$REPO_DIR" "$OUTPUT_DIR/media-player-pro-${VERSION}.flatpak" org.mediaplayerpro.MediaPlayerPro
    echo "==> Flatpak bundle created successfully: $OUTPUT_DIR/media-player-pro-${VERSION}.flatpak"
else
    echo "Notice: flatpak-builder not installed locally. Will build in GitHub Actions."
fi
