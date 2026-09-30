#!/usr/bin/env bash
# Снимает экран в каждом состоянии и видео анимаций, чтобы сверить с макетами.
# Работает и там, где выреза нет (внешний монитор, CI): вырез рисуется
# заглушкой, под окнами — фон «стола» с листов дизайна.
#   scripts/build-app.sh && scripts/screenshots.sh   → build/screenshots/
set -euo pipefail
cd "$(dirname "$0")/.."

bin="build/NotchDashboard.app/Contents/MacOS/NotchDashboard"
out="build/screenshots"
mkdir -p "$out"

run() {
  "$bin" --simulate-notch --backdrop "$@" &
  pid=$!
}

stop() {
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

shoot() {
  local name="$1"
  shift
  run "$@"
  sleep 4
  screencapture -x "$out/$name.png" || echo "Не удалось снять «$name»"
  stop
}

shoot idle
shoot hover --state hover
shoot hover-sample --state hover --sample
shoot dashboard --state dashboard
shoot section --section work

# Видео сценария --demo: панель наведения, ↗, дашборд, раздел, закрытие.
screencapture -x -v -V 10 "$out/demo.mov" &
recorder=$!
sleep 1
run --demo --sample
wait "$recorder" || echo "Не удалось записать видео"
stop

ls -l "$out"
