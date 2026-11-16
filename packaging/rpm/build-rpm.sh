#!/bin/bash
set -e

VERSION="1.7"
OUTPUT_DIR="${1:-$(pwd)/dist}"
mkdir -p "$OUTPUT_DIR"

echo "==> Building RPM package..."

RPM_TOP="$(mktemp -d /tmp/rpmbuild-XXXXXX)"
trap 'rm -rf "$RPM_TOP"' EXIT

mkdir -p "$RPM_TOP"/{BUILD,RPMS,SOURCES,SPECS,SRPMS,BUILDROOT}

# Create source tarball
tar --transform "s,^\.,media-player-pro-${VERSION}," \
    --exclude="./dist" \
    --exclude="./.git" \
    --exclude="./media-player-pro" \
    -czf "$RPM_TOP/SOURCES/media-player-pro-${VERSION}.tar.gz" .

if command -v rpmbuild >/dev/null 2>&1; then
    cp packaging/rpm/media-player-pro.spec "$RPM_TOP/SPECS/"
    rpmbuild --define "_topdir $RPM_TOP" -bb "$RPM_TOP/SPECS/media-player-pro.spec"
    cp "$RPM_TOP"/RPMS/*/*.rpm "$OUTPUT_DIR/"
    echo "==> RPM build succeeded via rpmbuild."
elif command -v fpm >/dev/null 2>&1; then
    STAGING="$(mktemp -d /tmp/fpm-XXXXXX)"
    make PREFIX=/usr DESTDIR="$STAGING" install
    fpm -s dir -t rpm -n media-player-pro -v "$VERSION" \
        --iteration 1 --architecture x86_64 \
        --depends mpv \
        --description "Media Player Pro with frosted glass skin" \
        -C "$STAGING" -p "$OUTPUT_DIR/media-player-pro-${VERSION}-1.x86_64.rpm" .
    rm -rf "$STAGING"
    echo "==> RPM build succeeded via fpm."
elif [ -f "$OUTPUT_DIR/media-player-pro_${VERSION}_amd64.deb" ] && command -v alien >/dev/null 2>&1; then
    cd "$OUTPUT_DIR"
    alien -r -c "media-player-pro_${VERSION}_amd64.deb"
    cd -
    echo "==> RPM build succeeded via alien."
else
    echo "Notice: rpmbuild or fpm required for local RPM builds. Will build in GitHub Actions."
fi
