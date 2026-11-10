#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
PUBLISH="$ROOT/publish/linux-x64"
APPDIR="$ROOT/publish/Matroska-Batch-Flow.AppDir"
OUTPUT="$ROOT/publish/Matroska-Batch-Flow-x86_64.AppImage"

if [[ ! -x "$PUBLISH/MatroskaBatchFlow" ]]; then
    echo "ERROR: Release executable not found."
    exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"

cp -a "$PUBLISH/." "$APPDIR/usr/bin/"

# Remove Windows-only dependencies.
rm -rf \
    "$APPDIR/usr/bin/libvlc/win-x64" \
    "$APPDIR/usr/bin/libvlc/win-x86"

rm -f \
    "$APPDIR/usr/bin/Binaries/MediaInfo.dll" \
    "$APPDIR/usr/bin/Binaries/mkvpropedit.exe"

# AppImage launcher.
cat > "$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
set -e

HERE="$(dirname "$(readlink -f "$0")")"
cd "$HERE/usr/bin"

exec "$HERE/usr/bin/MatroskaBatchFlow" "$@"
EOF

chmod +x "$APPDIR/AppRun"

# Desktop entry.
cat > "$APPDIR/matroska-batch-flow.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Matroska Batch Flow
Comment=Batch edit Matroska metadata and tracks
Exec=MatroskaBatchFlow
Icon=matroska-batch-flow
Categories=AudioVideo;Video;
Terminal=false
EOF

# App icon.
cp \
    "$ROOT/src/MatroskaBatchFlow.Uno/Resources/Assets/AppIcon.targetsize-256.png" \
    "$APPDIR/matroska-batch-flow.png"

# Verify essential files.
test -f "$APPDIR/usr/bin/appsettings.json"
test -f "$APPDIR/usr/bin/Resources/languages.json"
test -f "$APPDIR/usr/bin/Binaries/libmediainfo.so"

# Build the AppImage.
if ! command -v appimagetool >/dev/null 2>&1; then
    echo "ERROR: appimagetool is not installed."
    echo "Install or download appimagetool before continuing."
    exit 1
fi

ARCH=x86_64 appimagetool \
  --comp lz4 \
  "$APPDIR" "$OUTPUT"

echo
echo "AppImage created:"
ls -lh "$OUTPUT"
