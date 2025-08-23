#!/usr/bin/env bash
set -euo pipefail

# Build Flutter Linux release
flutter build linux --release

# Staging directories
ROOT_DIR="$(pwd)"
DIST_DIR="$ROOT_DIR/dist"
PKG_DIR="$DIST_DIR/mxclone_1.0.0_amd64"
BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"

# Clean previous staging
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN" \
         "$PKG_DIR/usr/bin" \
         "$PKG_DIR/usr/share/applications" \
         "$PKG_DIR/usr/share/icons/hicolor/48x48/apps" \
         "$PKG_DIR/usr/share/icons/hicolor/64x64/apps" \
         "$PKG_DIR/usr/share/icons/hicolor/128x128/apps" \
         "$PKG_DIR/usr/share/icons/hicolor/256x256/apps" \
         "$PKG_DIR/usr/share/icons/hicolor/512x512/apps" \
         "$PKG_DIR/opt/mxclone/lib" \
         "$PKG_DIR/opt/mxclone/data"

# Control files
cat > "$PKG_DIR/DEBIAN/control" << 'EOF'
Package: mxclone
Version: 1.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: MXClone Maintainers <maintainers@example.com>
Depends: libgtk-3-0, libglib2.0-0, libstdc++6, libasound2, liblzma5, desktop-file-utils
Description: MX Player Clone - A comprehensive media player for Linux
 MXClone is a Flutter-based media player supporting video & audio playback.
EOF

cat > "$PKG_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/sh
set -e
update-desktop-database -q || true
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 0755 "$PKG_DIR/DEBIAN/postinst"

cat > "$PKG_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor || true
fi
exit 0
EOF
chmod 0755 "$PKG_DIR/DEBIAN/postrm"

# Binary wrapper
cat > "$PKG_DIR/usr/bin/mxclone" << 'EOF'
#!/usr/bin/env bash
exec /opt/mxclone/mxclone "$@"
EOF
chmod 0755 "$PKG_DIR/usr/bin/mxclone"

# Desktop file (use application ID name). Try from bundle; fallback to rendering template.
DESKTOP_SRC1="$ROOT_DIR/build/linux/x64/release/bundle/share/applications/com.example.mxclone.desktop"
DESKTOP_SRC2="$ROOT_DIR/build/linux/x64/release/bundle/com.example.mxclone.desktop"
DESKTOP_TEMPLATE="$ROOT_DIR/linux/mxclone.desktop.in"
DESKTOP_DEST="$PKG_DIR/usr/share/applications/com.example.mxclone.desktop"
if [ -f "$DESKTOP_SRC1" ]; then
  install -Dm0644 "$DESKTOP_SRC1" "$DESKTOP_DEST"
elif [ -f "$DESKTOP_SRC2" ]; then
  install -Dm0644 "$DESKTOP_SRC2" "$DESKTOP_DEST"
elif [ -f "$DESKTOP_TEMPLATE" ]; then
  sed -e "s|@EXEC_PATH@|mxclone|g" -e "s|@APPLICATION_ID@|com.example.mxclone|g" "$DESKTOP_TEMPLATE" > "$DESKTOP_DEST"
  chmod 0644 "$DESKTOP_DEST"
else
  echo "Error: Could not find or generate desktop file" >&2
  exit 1
fi

# Icons (copy same 512 PNG into all sizes; can replace with real sized assets later)
for s in 48 64 128 256 512; do
  install -Dm0644 "$ROOT_DIR/web/icons/Icon-512.png" \
                       "$PKG_DIR/usr/share/icons/hicolor/${s}x${s}/apps/com.example.mxclone.png"
  # Also provide legacy name for compatibility
  install -Dm0644 "$ROOT_DIR/web/icons/Icon-512.png" \
                       "$PKG_DIR/usr/share/icons/hicolor/${s}x${s}/apps/mxclone.png"
done

# App payload
install -Dm0755 "$BUNDLE_DIR/mxclone" "$PKG_DIR/opt/mxclone/mxclone"
cp -a "$BUNDLE_DIR/lib"/* "$PKG_DIR/opt/mxclone/lib/"
cp -a "$BUNDLE_DIR/data"/* "$PKG_DIR/opt/mxclone/data/"

# Build the .deb
( cd "$DIST_DIR" && dpkg-deb --build mxclone_1.0.0_amd64 )

echo "Built: $DIST_DIR/mxclone_1.0.0_amd64.deb"