#!/usr/bin/env bash
# Собирает build/NotchDashboard.app из пакета SwiftPM.
#   scripts/build-app.sh          — release, подпись ad-hoc (для себя)
#   scripts/build-app.sh debug    — отладочная сборка
#   CODESIGN_IDENTITY="Developer ID Application: …" scripts/build-app.sh
#                                 — подпись для раздачи (дальше notarytool)
set -euo pipefail
cd "$(dirname "$0")/.."

config="${1:-release}"
swift build -c "$config" --product NotchDashboard
bin="$(swift build -c "$config" --show-bin-path)"

app="build/NotchDashboard.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/NotchDashboard" "$app/Contents/MacOS/NotchDashboard"
cp Support/Info.plist "$app/Contents/Info.plist"

identity="${CODESIGN_IDENTITY:--}"
if [ "$identity" = "-" ]; then
  codesign --force --sign - "$app"
else
  codesign --force --options runtime --timestamp --sign "$identity" "$app"
fi
echo "Готово: $app"
