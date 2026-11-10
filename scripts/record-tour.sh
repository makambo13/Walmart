#!/usr/bin/env bash
# Uses the app like a person would, entirely from the command line:
#   - simctl boots the simulator, installs and launches the app, switches
#     light/dark mode and text size, and takes screenshots,
#   - xcodebuild runs the paced UI-test tour (GuidedTourUITests) while simctl
#     records the screen.
#
# The raw recording also catches the simulator home screen just before and after
# the app runs; trim those seconds before turning it into a GIF.
#
# The tour runs on the booted simulator itself (parallel testing is off), so the
# recording shows the run.
#
# Usage: scripts/record-tour.sh <simulator-udid> [output-dir]
#   Find a simulator id with: xcrun simctl list devices available
#   DERIVED_DATA=<dir> overrides the build folder (default: ./build)
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:?usage: scripts/record-tour.sh <simulator-udid> [output-dir]}"
OUT="${2:-captures}"
DERIVED="${DERIVED_DATA:-build}"
BUNDLE_ID="com.example.walmart"

mkdir -p "$OUT"

echo "==> Booting simulator"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b >/dev/null
xcrun simctl status_bar "$DEVICE" override --time "9:41" \
  --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3 --operatorName ""

echo "==> Building"
xcodebuild build-for-testing -project walmart.xcodeproj -scheme walmart \
  -destination "platform=iOS Simulator,id=$DEVICE" -derivedDataPath "$DERIVED" -quiet
APP="$DERIVED/Build/Products/Debug-iphonesimulator/walmart.app"

echo "==> Installing"
xcrun simctl uninstall "$DEVICE" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$DEVICE" "$APP"

shot() {  # shot <name> [launch arguments...]
  local name="$1"; shift
  xcrun simctl launch --terminate-running-process "$DEVICE" "$BUNDLE_ID" "$@" >/dev/null
  sleep 2
  xcrun simctl io "$DEVICE" screenshot "$OUT/$name.png" >/dev/null 2>&1
  echo "    $OUT/$name.png"
}

echo "==> Screenshots through simctl"
xcrun simctl ui "$DEVICE" appearance light
shot list-light -UITestStubFeed
xcrun simctl ui "$DEVICE" appearance dark
shot list-dark -UITestStubFeed
xcrun simctl ui "$DEVICE" appearance light
xcrun simctl ui "$DEVICE" content_size accessibility-large
shot list-large-text -UITestStubFeed
xcrun simctl ui "$DEVICE" content_size large
shot error -UITestFailFirstLoad

echo "==> Recording the UI-test tour"
xcrun simctl io "$DEVICE" recordVideo --codec h264 --force "$OUT/tour.mp4" 2>/dev/null &
RECORDER=$!
sleep 1
xcodebuild test-without-building -project walmart.xcodeproj -scheme walmart \
  -destination "platform=iOS Simulator,id=$DEVICE" -derivedDataPath "$DERIVED" \
  -parallel-testing-enabled NO -resultBundlePath "$OUT/tour.xcresult" \
  -only-testing:walmartUITests/GuidedTourUITests/testTourOfTheApp -quiet
kill -INT "$RECORDER"; wait "$RECORDER" 2>/dev/null || true
echo "    $OUT/tour.mp4"

echo "==> Exporting the tour's screenshots"
rm -rf "$OUT/tour-shots"
xcrun xcresulttool export attachments --path "$OUT/tour.xcresult" --output-path "$OUT/tour-shots" >/dev/null
python3 - "$OUT/tour-shots" <<'PY'
import json, os, re, sys
folder = sys.argv[1]
for test in json.load(open(os.path.join(folder, "manifest.json"))):
    for item in test["attachments"]:
        name = item["suggestedHumanReadableName"].split("_0_")[0]
        if re.match(r"\d\d-", name) and item["exportedFileName"].endswith(".png"):
            os.replace(os.path.join(folder, item["exportedFileName"]), os.path.join(folder, name + ".png"))
            print("    " + os.path.join(folder, name + ".png"))
PY

xcrun simctl ui "$DEVICE" appearance light
xcrun simctl status_bar "$DEVICE" clear
echo "Done."
