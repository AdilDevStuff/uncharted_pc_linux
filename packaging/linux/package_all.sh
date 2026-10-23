#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    VERSION=$(git describe --tags --always 2>/dev/null || echo "0.3.6")
fi
# Strip leading 'v'
VERSION="${VERSION#v}"

echo "=================================================="
echo " Packaging Uncharted Linux Release v${VERSION}"
echo "=================================================="

DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"

# 1. Ensure native binaries are built
if [[ ! -f out/bb-probe || ! -f out/gpu/libbbgpu.so ]]; then
    echo "Compiling native binaries..."
    bash build.sh
fi

BUILD_DIR=$(mktemp -d /tmp/uncharted-pkg-XXXXXX)
trap 'rm -rf "$BUILD_DIR"' EXIT

STAGE_DIR="$BUILD_DIR/stage"
mkdir -p "$STAGE_DIR"

# 2. Populate staging payload
echo "Collecting staging payload..."
mkdir -p "$STAGE_DIR/out/gpu" "$STAGE_DIR/bin" "$STAGE_DIR/lib"

cp -a out/bb-probe "$STAGE_DIR/bin/"
cp -a out/bb-gpu-capabilities "$STAGE_DIR/bin/" 2>/dev/null || true
cp -a out/gpu/libbbgpu.so "$STAGE_DIR/out/gpu/"

# Symlinks for out/
ln -sf ../bin/bb-probe "$STAGE_DIR/out/bb-probe"
ln -sf ../bin/bb-gpu-capabilities "$STAGE_DIR/out/bb-gpu-capabilities" 2>/dev/null || true

# Assets, scripts, launchers
cp -a launcher scripts run.py run.sh "$STAGE_DIR/"
cp -a LICENSE "$STAGE_DIR/" 2>/dev/null || true
cp -a README.md "$STAGE_DIR/" 2>/dev/null || true

# Copy bundled non-standard shared libraries if found (for portable distribution)
for lib_pattern in "libSDL3.so*" "libZydis.so*" "libfmt.so*" "libminiupnpc.so*"; do
    for search_dir in /usr/local/lib /usr/lib /usr/lib/x86_64-linux-gnu /usr/lib64; do
        if compgen -G "${search_dir}/${lib_pattern}" > /dev/null; then
            cp -aL ${search_dir}/${lib_pattern} "$STAGE_DIR/lib/" 2>/dev/null || true
            break
        fi
    done
done

# 3. Build AppImage
APPDIR="$BUILD_DIR/AppDir"
mkdir -p "$APPDIR"
cp -a "$STAGE_DIR"/* "$APPDIR/"
cp packaging/linux/AppRun "$APPDIR/AppRun"
chmod +x "$APPDIR/AppRun"
cp packaging/linux/uncharted.desktop "$APPDIR/uncharted.desktop"
cp launcher/uncharted.png "$APPDIR/uncharted.png"

APPIMAGE_NAME="Uncharted-The-Nathan-Drake-Collection-${VERSION}-x86_64.AppImage"
echo "Creating AppImage: $APPIMAGE_NAME..."
if command -v appimagetool >/dev/null; then
    ARCH=x86_64 appimagetool --no-appstream "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME"
elif [[ -x "$ROOT_DIR/appimagetool" ]]; then
    ARCH=x86_64 "$ROOT_DIR/appimagetool" --no-appstream "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME"
elif [[ -x "/tmp/appimagetool" ]]; then
    ARCH=x86_64 /tmp/appimagetool --no-appstream "$APPDIR" "$DIST_DIR/$APPIMAGE_NAME"
else
    echo "Notice: appimagetool not found; skipping AppImage."
fi

# 4. Prepare system package root (/opt/uncharted + /usr/bin + /usr/share)
PKG_ROOT="$BUILD_DIR/pkg_root"
mkdir -p "$PKG_ROOT/opt/uncharted" \
         "$PKG_ROOT/usr/bin" \
         "$PKG_ROOT/usr/share/applications" \
         "$PKG_ROOT/usr/share/icons/hicolor/128x128/apps"

cp -a "$STAGE_DIR"/* "$PKG_ROOT/opt/uncharted/"
cp packaging/linux/uncharted-wrapper.sh "$PKG_ROOT/usr/bin/uncharted"
chmod 755 "$PKG_ROOT/usr/bin/uncharted"
cp packaging/linux/uncharted.desktop "$PKG_ROOT/usr/share/applications/uncharted.desktop"
cp launcher/uncharted.png "$PKG_ROOT/usr/share/icons/hicolor/128x128/apps/uncharted.png"

# 5. Build .deb and .rpm with FPM
if command -v fpm >/dev/null; then
    DEB_NAME="uncharted-pc_${VERSION}_amd64.deb"
    echo "Creating Debian package: $DEB_NAME..."
    fpm -s dir -t deb \
        -n uncharted-pc \
        -v "$VERSION" \
        -a amd64 \
        -p "$DIST_DIR/$DEB_NAME" \
        --description "Uncharted: The Nathan Drake Collection for Linux" \
        --url "https://github.com/AdilDevStuff/uncharted_pc_linux" \
        --maintainer "Adil" \
        --license "GPL-2.0" \
        --category "games" \
        -d "python3" \
        -d "python3-tk" \
        -C "$PKG_ROOT" .

    RPM_NAME="uncharted-pc-${VERSION}-1.x86_64.rpm"
    echo "Creating RPM package: $RPM_NAME..."
    fpm -s dir -t rpm \
        -n uncharted-pc \
        -v "$VERSION" \
        -a x86_64 \
        -p "$DIST_DIR/$RPM_NAME" \
        --description "Uncharted: The Nathan Drake Collection for Linux" \
        --url "https://github.com/AdilDevStuff/uncharted_pc_linux" \
        --maintainer "Adil" \
        --license "GPL-2.0" \
        --category "Amusements/Games" \
        -d "python3" \
        -d "python3-tkinter" \
        -C "$PKG_ROOT" .
else
    echo "Notice: fpm not found; skipping .deb and .rpm."
fi

# 6. Generate Checksums
cd "$DIST_DIR"
if ls *.AppImage *.deb *.rpm 1> /dev/null 2>&1; then
    sha256sum *.AppImage *.deb *.rpm > SHA256SUMS.txt
    echo "Generated SHA256SUMS.txt"
fi

echo "=================================================="
echo " Packaging completed successfully!"
echo " Artifacts in: $DIST_DIR"
echo "=================================================="
ls -lh "$DIST_DIR"
