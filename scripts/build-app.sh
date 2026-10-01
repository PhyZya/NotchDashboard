#!/usr/bin/env bash
# Собирает build/NotchDashboard.app из пакета SwiftPM.
#   scripts/build-app.sh          — release, подпись ad-hoc (для себя)
#   scripts/build-app.sh debug    — отладочная сборка
#   CODESIGN_IDENTITY="Developer ID Application: …" scripts/build-app.sh
#                                 — подпись для раздачи (дальше notarytool)
# Собрать и сразу запустить — scripts/run.sh.
#
# Чтобы после сборки всегда запускалась именно она:
# - бинарник проверяется на свежесть, иначе сборка повторяется с нуля;
# - ветка, коммит и время сборки пишутся в Info.plist, приложение
#   показывает их в меню по правому клику на вырезе;
# - запущенная копия останавливается: иначе `open` не запустит новую,
#   а только покажет старую — у приложения нет иконки в Dock.
set -euo pipefail
cd "$(dirname "$0")/.."

config="${1:-release}"
app="build/NotchDashboard.app"

branch="без git"
commit="?"
if git rev-parse --git-dir >/dev/null 2>&1; then
  branch="$(git rev-parse --abbrev-ref HEAD)"
  commit="$(git rev-parse --short HEAD)"
  git diff --quiet HEAD || commit="$commit + правки"
fi
echo "Собираю ветку $branch, коммит $commit"
if behind="$(git rev-list --count 'HEAD..@{u}' 2>/dev/null)" && [ "$behind" -gt 0 ]; then
  echo "Внимание: ветка отстаёт от $(git rev-parse --abbrev-ref '@{u}') на $behind коммит(ов) — сделайте git pull"
fi

# Пакету нужен Swift не старше версии из первой строки Package.swift.
# Частая причина старого Swift в терминале: xcode-select указывает на старые
# Command Line Tools, а Xcode 27 стоит рядом. Тогда берём его сами.
required="$(sed -nE '1s#^// swift-tools-version: *([0-9]+\.[0-9]+).*#\1#p' Package.swift)"

# «6.4» из `… --version` или пусто, если команда не сработала.
swift_version() {
  "$@" --version 2>/dev/null | sed -nE 's/.*Swift version ([0-9]+\.[0-9]+).*/\1/p' | head -n 1
}

# Версия $1 не ниже $2.
at_least() {
  [ -n "$1" ] && [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n 1)" = "$2" ]
}

swift_cmd=(swift)
have="$(swift_version swift)"
if ! at_least "$have" "$required"; then
  xcode=""
  xcode_version=""
  for candidate in /Applications/Xcode*.app "$HOME"/Applications/Xcode*.app; do
    [ -d "$candidate/Contents/Developer" ] || continue
    version="$(swift_version env DEVELOPER_DIR="$candidate/Contents/Developer" xcrun swift)"
    if at_least "$version" "$required" && { [ -z "$xcode" ] || at_least "$version" "$xcode_version"; }; then
      xcode="$candidate"
      xcode_version="$version"
    fi
  done
  if [ -z "$xcode" ]; then
    echo "Нужен Swift $required или новее (Xcode 27), а в терминале — ${have:-не найден}." >&2
    echo "Установите Xcode 27 из App Store, откройте его один раз и выполните:" >&2
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
  fi
  export DEVELOPER_DIR="$xcode/Contents/Developer"
  swift_cmd=(xcrun swift)
  echo "В терминале Swift ${have:-не найден}, беру ${xcode##*/} (Swift $xcode_version)."
  echo "Чтобы терминал сразу брал его: sudo xcode-select -s $DEVELOPER_DIR"
fi

build() {
  "${swift_cmd[@]}" build -c "$config" --product NotchDashboard
  bin="$("${swift_cmd[@]}" build -c "$config" --show-bin-path)/NotchDashboard"
}

# Бинарник старше какого-то исходника — значит, сборка его не обновила.
stale_source() {
  [ -f "$bin" ] || { echo "$bin"; return; }
  find Sources Package.swift -type f -newer "$bin" | head -n 1
}

build
if [ -n "$(stale_source)" ]; then
  echo "Бинарник старше исходников ($(stale_source)) — собираю с нуля"
  rm -rf .build
  build
  if [ -n "$(stale_source)" ]; then
    echo "Сборка не обновила $bin" >&2
    exit 1
  fi
fi

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin" "$app/Contents/MacOS/NotchDashboard"
cp Support/Info.plist "$app/Contents/Info.plist"
build_info="$branch · $commit · $(date '+%d.%m %H:%M')"
plutil -insert NotchDashboardBuild -string "$build_info" "$app/Contents/Info.plist"

identity="${CODESIGN_IDENTITY:--}"
if [ "$identity" = "-" ]; then
  codesign --force --sign - "$app"
else
  codesign --force --options runtime --timestamp --sign "$identity" "$app"
fi

if pgrep -x NotchDashboard >/dev/null; then
  pkill -x NotchDashboard || true
  for _ in $(seq 50); do
    pgrep -x NotchDashboard >/dev/null || break
    sleep 0.1
  done
  pkill -9 -x NotchDashboard 2>/dev/null || true
  echo "Старая копия NotchDashboard остановлена"
fi

echo "Готово: $app ($build_info)"
echo "Запуск: open $app"
