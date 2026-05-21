#!/usr/bin/env bash
# Freeze the mobile build baseline so the Windows-parity work cannot
# silently drift the mobile build.
#
# Refresh by running this script. Then commit the updated artefacts
# under docs/ as a separate commit (NOT mixed with feature work).

set -euo pipefail

cd "$(dirname "$0")/.."

echo "→ flutter analyze"
flutter analyze | tee /tmp/parity_analyze.txt

echo "→ flutter test (full suite)"
flutter test --reporter expanded | tee /tmp/parity_test.txt

echo "→ flutter build apk --release (Android baseline)"
flutter build apk --release \
  --dart-define=API_BASE_URL=https://baseline.example | tee /tmp/parity_build.txt

apk=build/app/outputs/flutter-apk/app-release.apk
if [[ -f "$apk" ]]; then
  size=$(stat -c %s "$apk" 2>/dev/null || stat -f %z "$apk")
  sha=$(sha256sum "$apk" | awk '{print $1}')
  echo "→ APK: size=$size bytes sha256=$sha"

  echo "→ asset manifest"
  unzip -l "$apk" \
    | awk '$4 ~ /^assets\// { print $4 }' \
    | sort > docs/mobile_assets.txt
  echo "  wrote docs/mobile_assets.txt ($(wc -l < docs/mobile_assets.txt) entries)"
else
  echo "WARN: APK missing — flutter build apk did not produce output"
fi

echo
echo "Now manually update docs/MOBILE_BASELINE.md with the size + sha + test count above."
