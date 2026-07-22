#!/usr/bin/env bash
# Build a distributable AckBar .plasmoid for upload to the KDE Store.
#
# A .plasmoid MUST be a ZIP archive with metadata.json + contents/ at the root.
# (A tar.gz renamed to .plasmoid is what KPackage rejects with
# "Could not open package file" — see the store install failure this fixes.)
set -euo pipefail
cd "$(dirname "$0")"

command -v zip >/dev/null || { echo "ERROR: 'zip' is required" >&2; exit 1; }

VERSION=$(grep -oP '"Version":\s*"\K[^"]+' metadata.json)
ID=$(grep -oP '"Id":\s*"\K[^"]+' metadata.json)
OUT="releases/${ID}-${VERSION}.plasmoid"

mkdir -p releases
rm -f "$OUT"

# metadata.json + contents/ at the archive root; drop compiled QML and dotfiles.
zip -r "$OUT" metadata.json contents -x '*.qmlc' -x '*/.*' >/dev/null

# Guards: must be a real zip, and metadata.json must sit at the root.
if ! zipinfo -1 "$OUT" | grep -qx 'metadata.json'; then
    echo "ERROR: metadata.json is not at the archive root — bad package" >&2
    exit 1
fi

echo "Built $OUT (zip):"
zipinfo -1 "$OUT"
echo
echo "Smoke-test locally before publishing:"
echo "  kpackagetool6 --type Plasma/Applet --install $OUT"
