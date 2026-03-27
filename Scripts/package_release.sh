#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Mac Pause"
PLIST_PATH="${ROOT_DIR}/Support/MacPauseApp-Info.plist"
RELEASE_DIR="${ROOT_DIR}/Build/Release"
STAGING_DIR="${RELEASE_DIR}/Package"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${PLIST_PATH}")"
PACKAGE_DIR="${STAGING_DIR}/${APP_NAME} ${VERSION}"
ZIP_PATH="${RELEASE_DIR}/MacPause-${VERSION}.zip"
CHECKSUM_PATH="${ZIP_PATH}.sha256"

"${ROOT_DIR}/Scripts/build_app_bundle.sh" release

rm -rf "${STAGING_DIR}" "${ZIP_PATH}" "${CHECKSUM_PATH}"
mkdir -p "${PACKAGE_DIR}"

cp -R "${RELEASE_DIR}/${APP_NAME}.app" "${PACKAGE_DIR}/${APP_NAME}.app"
cp "${ROOT_DIR}/Support/INSTALL.txt" "${PACKAGE_DIR}/INSTALL.txt"
cp "${ROOT_DIR}/README.md" "${PACKAGE_DIR}/README.md"

ditto -c -k --sequesterRsrc --keepParent "${PACKAGE_DIR}" "${ZIP_PATH}"
shasum -a 256 "${ZIP_PATH}" > "${CHECKSUM_PATH}"

echo "Packaged ${ZIP_PATH}"
echo "Checksum ${CHECKSUM_PATH}"
