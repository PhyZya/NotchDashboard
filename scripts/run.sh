#!/usr/bin/env bash
# Собирает свежий build/NotchDashboard.app и запускает его, остановив
# старую копию. Аргументы уходят приложению:
#   scripts/run.sh
#   scripts/run.sh --sample            — панель наведения с музыкой и задачами
#   scripts/run.sh --simulate-notch    — экран без выреза
# Отладочная сборка: CONFIG=debug scripts/run.sh
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build-app.sh "${CONFIG:-release}"
open build/NotchDashboard.app --args "$@"
