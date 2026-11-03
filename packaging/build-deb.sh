#!/bin/bash
# Builds the core .deb.
#
# Usage: ./packaging/build-deb.sh <version> [output-dir]
#
# Overlays are data read by the firmware, so the package is Architecture: all
# and can be built on any machine with dpkg-deb.
set -euo pipefail

VERSION="${1:?usage: build-deb.sh <version> [output-dir]}"
OUTDIR="${2:-dist}"
REPO="${GITHUB_REPOSITORY:-techbase-git/core}"

PKG=core
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
# mktemp -d creates 0700; the package root has to be world-readable or every
# path inside it becomes inaccessible once installed.
chmod 755 "$STAGE"

echo "Building $PKG $VERSION"

# --- file tree ----------------------------------------------------------
install -d -m 755 "$STAGE/DEBIAN"
install -d -m 755 "$STAGE/usr/share/$PKG/overlays"
install -d -m 755 "$STAGE/usr/share/doc/$PKG"

# The overlays are staged here rather than straight into /boot/firmware, which
# may not be mounted when dpkg unpacks. postinst copies them across.
install -m 644 "$ROOT"/overlays/*.dtbo "$STAGE/usr/share/$PKG/overlays/"

install -m 644 "$ROOT/README.md" "$STAGE/usr/share/doc/$PKG/README.md"
install -m 644 "$ROOT/LICENSE" "$STAGE/usr/share/doc/$PKG/copyright"

# --- control files ------------------------------------------------------
sed -e "s/@VERSION@/$VERSION/" -e "s#@REPO@#$REPO#" \
    "$ROOT/packaging/control.in" > "$STAGE/DEBIAN/control"
install -m 755 "$ROOT/packaging/postinst" "$STAGE/DEBIAN/postinst"
install -m 644 "$ROOT/packaging/templates" "$STAGE/DEBIAN/templates"

OVERLAYS=""
for dtbo in "$ROOT"/overlays/*.dtbo; do
    OVERLAYS="$OVERLAYS $(basename "$dtbo" .dtbo)"
done
sed -e "s/@OVERLAYS@/${OVERLAYS# }/" \
    "$ROOT/packaging/postrm" > "$STAGE/DEBIAN/postrm"
chmod 755 "$STAGE/DEBIAN/postrm"

# --- build --------------------------------------------------------------
mkdir -p "$ROOT/$OUTDIR"
DEB="$ROOT/$OUTDIR/${PKG}_${VERSION}_all.deb"

# --root-owner-group avoids needing fakeroot just to get root:root ownership.
dpkg-deb --build --root-owner-group "$STAGE" "$DEB"

echo "Built $DEB"
