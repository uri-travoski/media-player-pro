#!/bin/bash
set -e

VERSION="1.7"
ARCH="amd64"
OUTPUT_DIR="${1:-$(pwd)/dist}"
mkdir -p "$OUTPUT_DIR"

STAGING="$(mktemp -d /tmp/deb-pkg-XXXXXX)"
chmod 755 "$STAGING"
trap 'rm -rf "$STAGING"' EXIT

echo "==> Building Debian Package in $STAGING..."

make PREFIX=/usr DESTDIR="$STAGING" install

mkdir -p "$STAGING/DEBIAN"
chmod 755 "$STAGING/DEBIAN"
cat <<EOF > "$STAGING/DEBIAN/control"
Package: media-player-pro
Version: ${VERSION}
Section: video
Priority: optional
Architecture: ${ARCH}
Depends: mpv (>= 0.30.0), fonts-dejavu-core
Maintainer: Uri Travoski <uri-travoski@users.noreply.github.com>
Description: Media Player Pro - Modern Frosted Glass Media Player
 Media Player Pro is a high-performance media player based on mpv with
 a complete transparent/frosted glass skin, 7-second skip buttons,
 speed dropup presets, cursor-targeted zoom and dragging, and genuine
 video enhancements (deband + AMD FidelityFX Contrast Adaptive Sharpening).
EOF

cat <<'EOF' > "$STAGING/DEBIAN/postinst"
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q /usr/share/icons/hicolor || true
fi
EOF
chmod 755 "$STAGING/DEBIAN/postinst"

DEB_OUT="$OUTPUT_DIR/media-player-pro_${VERSION}_${ARCH}.deb"
dpkg-deb --build --root-owner-group "$STAGING" "$DEB_OUT"

echo "==> Debian package created successfully: $DEB_OUT"
