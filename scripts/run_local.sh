#!/usr/bin/env zsh
#
# Builds Steel Trading Desk (macOS, Debug) and launches it with credentials
# from .env in this repo's root. This is the "local launch wrapper" that
# .env.example refers to — Xcode's own Run button does NOT read .env, and
# `open Steel_Trading_Desk.app` does not forward shell environment variables
# to the launched process (a macOS LaunchServices quirk, not a Steel bug).
# Running the built binary directly from this script is what makes
# EnvSeeder.seedFromDebugEnvironmentIfNeeded() actually see SCHWAB_APP_KEY /
# SCHWAB_APP_SECRET / SCHWAB_CALLBACK_URL.
#
# Usage:
#   cp .env.example .env   # once, then fill in real values
#   ./scripts/run_local.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f .env ]]; then
  set -a
  source .env
  set +a
  echo "Loaded .env"
else
  echo "No .env found (copy .env.example to .env and fill it in first)." >&2
fi

DERIVED_DATA_PATH="/tmp/steel_build"

xcodebuild \
  -project Steel_Trading_Desk.xcodeproj \
  -scheme Steel_Trading_Desk \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  build

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/Steel_Trading_Desk.app"
BINARY_PATH="$APP_PATH/Contents/MacOS/Steel_Trading_Desk"

pkill -f "$BINARY_PATH" 2>/dev/null || true
sleep 1

echo "Launching with SCHWAB_APP_KEY=${SCHWAB_APP_KEY:+set} SCHWAB_APP_SECRET=${SCHWAB_APP_SECRET:+set}"
exec "$BINARY_PATH"
