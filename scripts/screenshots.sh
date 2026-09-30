#!/usr/bin/env bash
# Снимает экран в каждом состоянии, чтобы сверить с макетами. Работает и там,
# где выреза нет (внешний монитор, CI): вырез рисуется заглушкой.
#   scripts/build-app.sh && scripts/screenshots.sh   → build/screenshots/*.png
set -euo pipefail
cd "$(dirname "$0")/.."

bin="build/NotchDashboard.app/Contents/MacOS/NotchDashboard"
out="build/screenshots"
mkdir -p "$out"

shoot() {
  local name="$1"
  shift
  "$bin" --simulate-notch "$@" &
  local pid=$!
  sleep 4
  screencapture -x "$out/$name.png" || echo "Не удалось снять «$name»"
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

shoot idle
shoot hover --state hover
shoot dashboard --state dashboard
shoot section --section work
ls -l "$out"
