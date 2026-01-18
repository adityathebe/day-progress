#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="DayProgressMenubar"
VERSION="${1:-${VERSION:-0.1.0}}"
BUNDLE_ID="${BUNDLE_ID:-com.adityathebe.dayprogressmenubar}"
BUILD_DIR="${ROOT_DIR}/build"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
ZIP_PATH="${BUILD_DIR}/${APP_NAME}.zip"

export VERSION
export BUNDLE_ID

"${ROOT_DIR}/scripts/build_app.sh"

rm -f "${ZIP_PATH}"
/usr/bin/ditto -c -k --keepParent "${APP_DIR}" "${ZIP_PATH}"

SHA=$(/usr/bin/shasum -a 256 "${ZIP_PATH}" | awk '{print $1}')

echo "Release zip: ${ZIP_PATH}"
echo "SHA256: ${SHA}"
