#!/usr/bin/env bash
# Regenerates screenshots/ from the demo dataset by running the ScreenshotTests UI test
# and filing its attachments. Run from the repository root:
#
#   ./Tools/screenshots.sh
#
set -euo pipefail

DEVICE="${1:-iPhone 17 Pro}"
BUNDLE="$(mktemp -d)/shots.xcresult"
EXPORT="$(mktemp -d)/shots"

echo "==> Running ScreenshotTests on '$DEVICE'"
xcodebuild test \
  -project HabitForge.xcodeproj \
  -scheme HabitForge \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -only-testing:HabitForgeUITests/ScreenshotTests \
  -resultBundlePath "$BUNDLE" \
  >/dev/null

echo "==> Exporting attachments"
mkdir -p "$EXPORT"
xcrun xcresulttool export attachments --path "$BUNDLE" --output-path "$EXPORT" >/dev/null

echo "==> Filing into screenshots/"
mkdir -p screenshots
python3 - "$EXPORT" << 'PY'
import json, os, re, shutil, sys

export = sys.argv[1]
manifest = json.load(open(os.path.join(export, "manifest.json")))
for entry in manifest:
    for attachment in entry.get("attachments", []):
        human = attachment["suggestedHumanReadableName"]
        name = re.sub(r"_\d+_[0-9A-F-]{36}\.png$", ".png", human)
        name = re.sub(r"^\d+-", "", name)
        shutil.copyfile(
            os.path.join(export, attachment["exportedFileName"]),
            os.path.join("screenshots", name),
        )
        print("  screenshots/" + name)
PY

echo "==> Done"
