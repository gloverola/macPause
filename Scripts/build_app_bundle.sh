#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Mac Pause"
EXECUTABLE_NAME="MacPauseApp"
CONFIGURATION="${1:-debug}"
APP_ICON_PATH="${ROOT_DIR}/Support/AppIcon.icns"
SWIFTPM_HOME="${ROOT_DIR}/.swiftpm-home"
MODULE_CACHE_DIR="${ROOT_DIR}/.swift-cache/module-cache"
CLANG_CACHE_DIR="${ROOT_DIR}/.clang-cache"

case "${CONFIGURATION}" in
  debug)
    OUTPUT_DIR="${ROOT_DIR}/Build"
    ;;
  release)
    OUTPUT_DIR="${ROOT_DIR}/Build/Release"
    ;;
  *)
    echo "usage: $0 [debug|release]" >&2
    exit 1
    ;;
esac

APP_DIR="${OUTPUT_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

mkdir -p \
  "${OUTPUT_DIR}" \
  "${SWIFTPM_HOME}/.cache" \
  "${SWIFTPM_HOME}/.config" \
  "${MODULE_CACHE_DIR}" \
  "${CLANG_CACHE_DIR}"

if [[ ! -f "${APP_ICON_PATH}" ]]; then
  swift "${ROOT_DIR}/Scripts/generate_app_icon.swift"
fi

export HOME="${SWIFTPM_HOME}"
export XDG_CACHE_HOME="${SWIFTPM_HOME}/.cache"
export XDG_CONFIG_HOME="${SWIFTPM_HOME}/.config"
export SWIFTPM_MODULECACHE_OVERRIDE="${MODULE_CACHE_DIR}"
export CLANG_MODULE_CACHE_PATH="${CLANG_CACHE_DIR}"

swift build \
  --configuration "${CONFIGURATION}" \
  --disable-sandbox \
  --product "${EXECUTABLE_NAME}"

BIN_DIR="$(swift build \
  --configuration "${CONFIGURATION}" \
  --disable-sandbox \
  --show-bin-path)"

EXECUTABLE_PATH="${BIN_DIR}/${EXECUTABLE_NAME}"

if [[ ! -x "${EXECUTABLE_PATH}" ]]; then
  echo "error: expected executable at ${EXECUTABLE_PATH}" >&2
  exit 1
fi

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${ROOT_DIR}/Support/MacPauseApp-Info.plist" "${CONTENTS_DIR}/Info.plist"
cp "${EXECUTABLE_PATH}" "${MACOS_DIR}/${EXECUTABLE_NAME}"

if [[ -f "${APP_ICON_PATH}" ]]; then
  cp "${APP_ICON_PATH}" "${RESOURCES_DIR}/AppIcon.icns"
fi

chmod +x "${MACOS_DIR}/${EXECUTABLE_NAME}"
printf 'APPL????' > "${CONTENTS_DIR}/PkgInfo"

xattr -cr "${APP_DIR}"
codesign --force --deep --sign - "${APP_DIR}"

echo "Built ${APP_DIR}"
