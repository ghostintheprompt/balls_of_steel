#!/usr/bin/env zsh
#
# Captures App Store screenshots for Steel Trading Desk on an iPhone 17 Pro Max
# simulator (App Store 6.9" device class).
#
# Ported from cloud_break/app_store_assets/capture_app_store_screenshots.sh —
# CloudBreak's version was the only one in the family that consistently shipped
# clean shots without timing glitches. Differences:
#   - Replaces `flutter build` with `xcodebuild` since this is native Swift.
#   - The Steel app doesn't yet read a screenshot-sequence env var, so the
#     long delays between captures are for manual navigation by you on the
#     simulator. If you wire up a STEEL_SCREENSHOT_SEQUENCE responder in
#     MainApp later, you can shorten the delays.
#
# Usage:
#   ./scripts/capture_app_store_screenshots.sh
#   ./scripts/capture_app_store_screenshots.sh <DEVICE_ID> <BUNDLE_ID> <OUT_DIR>
#
# Defaults to the iPhone 17 Pro Max UDID that CloudBreak and Avant Garde
# already use. Run `xcrun simctl list devices available` to see alternates.

set -euo pipefail

# Hop into the repo root regardless of where the script is called from.
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

device_id="${1:-AD634430-4C6A-417F-B66D-004DA65217D6}"
bundle_id="${2:-app.mdrn.steel}"
out_dir="${3:-app_store_assets/screenshots/iphone-6.9}"
derived="${ROOT_DIR}/build/ScreenshotSim"

mkdir -p "$out_dir"

echo "==> Booting simulator $device_id"
xcrun simctl boot "$device_id" 2>/dev/null || true
xcrun simctl bootstatus "$device_id" >/dev/null
open -a Simulator --args -CurrentDeviceUDID "$device_id" 2>/dev/null || true

echo "==> Building Steel Trading Desk for simulator"
xcodebuild -quiet \
  -project Steel_Trading_Desk.xcodeproj \
  -scheme Steel_Trading_Desk \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath "$derived" \
  CODE_SIGNING_ALLOWED=NO \
  build

app_path="$derived/Build/Products/Debug-iphonesimulator/Steel_Trading_Desk.app"
if [[ ! -d "$app_path" ]]; then
  echo "Build artifact missing at $app_path" >&2
  exit 1
fi

echo "==> Installing app"
xcrun simctl install "$device_id" "$app_path"

echo "==> Overriding status bar (9:41, full battery, full wifi)"
xcrun simctl status_bar "$device_id" override \
  --time "9:41" \
  --dataNetwork wifi \
  --wifiBars 3 \
  --cellularBars 4 \
  --batteryState charged \
  --batteryLevel 100

echo "==> Launching app"
# Pass STEEL_SCREENSHOT=1 as a process env var so the app can later opt into a
# deterministic screenshot flow (placeholder — not yet read by MainApp).
SIMCTL_CHILD_STEEL_SCREENSHOT=1 \
  xcrun simctl launch --terminate-running-process "$device_id" "$bundle_id" >/dev/null

capture_after() {
  local wait_seconds="$1"
  local filename="$2"
  local prompt="$3"

  if [[ -n "$prompt" ]]; then
    echo ""
    echo "  Next ($wait_seconds s): $prompt"
  fi
  sleep "$wait_seconds"
  xcrun simctl io "$device_id" screenshot "$out_dir/$filename" >/dev/null
  local dims
  dims=$(sips -g pixelWidth -g pixelHeight "$out_dir/$filename" 2>/dev/null | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {printf "%sx%s", w, h}')
  printf "  saved %s (%s)\n" "$filename" "$dims"
}

echo ""
echo "==> Capturing screens — you have time between each to navigate manually."
echo "    If you wire up auto-sequencing in MainApp later, drop the delays."

capture_after  5 "01-desk-cleared.png"      "Desk home, all four gates visible"
capture_after 15 "02-gate-detail.png"       "Tap a gate to open the drill-in sheet"
capture_after 15 "03-chart-fullscreen.png"  "Tap the chart tile → fullscreen sheet (5M, with overlays)"
capture_after 15 "04-tape-entry.png"        "Open Tape from the desk and enter sample values"
capture_after 15 "05-hard-exit.png"         "Use a simulator clock override to enter 15:55 ET, or capture later"
capture_after 15 "06-settings-audit.png"    "Settings → tap RUN AUDIT, capture the results sheet"

echo ""
echo "==> Done. Files in $out_dir:"
ls -1 "$out_dir"

echo ""
echo "==> Reminder: App Store 6.9\" required dimensions = 1320 x 2868 (portrait)."
echo "    iPhone 17 Pro Max captures at native scale. Verify the dims above match."
