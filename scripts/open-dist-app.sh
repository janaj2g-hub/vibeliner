#!/bin/zsh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${REPO_ROOT}/dist/Vibeliner.app"

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Missing app bundle at ${APP_PATH}" >&2
  echo "Build first with: xcodebuild -project Vibeliner.xcodeproj -scheme Vibeliner build" >&2
  exit 1
fi

open "${APP_PATH}"
