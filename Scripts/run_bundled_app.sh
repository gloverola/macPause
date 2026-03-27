#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

"${ROOT_DIR}/Scripts/build_app_bundle.sh"

open "${ROOT_DIR}/Build/Mac Pause.app"
