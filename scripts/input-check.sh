#!/usr/bin/env bash
# Проверка настоящего ввода: курсор на вырезе, ⌥D, Esc, клик по вырезу.
# События синтетические, для них процессу нужно разрешение «Управление
# компьютером». Без него снимки покажут только покой — это видно по ним.
#   scripts/build-app.sh && scripts/input-check.sh   → build/screenshots/input-*.png
set -euo pipefail
cd "$(dirname "$0")/.."

bin="build/NotchDashboard.app/Contents/MacOS/NotchDashboard"
out="build/screenshots"
input="build/input"
mkdir -p "$out"
swiftc -O scripts/input.swift -o "$input"

read -r width _ < <("$input" screen)
x=$((width / 2))

"$bin" --simulate-notch --backdrop &
pid=$!
trap 'kill "$pid" 2>/dev/null || true' EXIT
sleep 3

step() {
  local name="$1"
  shift
  "$input" "$@" || echo "Событие «$*» не отправлено"
  sleep 1.5
  screencapture -x "$out/input-$name.png" || echo "Не удалось снять «$name»"
}

"$input" move "$x" 400
step 1-hover move "$x" 4
step 2-away move "$x" 400
step 3-option-d key 2 option
step 4-esc key 53
step 5-click click "$x" 4
step 6-click-again click "$x" 4

ls -l "$out"
