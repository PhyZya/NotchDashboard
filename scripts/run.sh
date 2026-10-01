#!/usr/bin/env bash
# Одна команда, чтобы запустить свежую версию: подтягивает с GitHub основную
# ветку (ту, что на GitHub по умолчанию), собирает build/NotchDashboard.app
# и запускает его, остановив старую копию. Аргументы уходят приложению:
#   scripts/run.sh
#   scripts/run.sh --sample            — панель наведения с музыкой и задачами
#   scripts/run.sh --simulate-notch    — экран без выреза
#   OFFLINE=1 scripts/run.sh           — не ходить на GitHub, собрать что есть
#   CONFIG=debug scripts/run.sh        — отладочная сборка
set -euo pipefail
cd "$(dirname "$0")/.."

# Если папка на другой ветке, переключается на основную. Не трогает git,
# когда в папке есть свои незакоммиченные правки.
sync_with_github() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Папка не git-репозиторий, обновиться с GitHub нельзя. Скачайте код так:"
    echo "  git clone https://github.com/PhyZya/NotchDashboard.git"
    return
  fi
  if ! git fetch --prune --quiet origin; then
    echo "GitHub недоступен — собираю то, что есть"
    return
  fi
  git remote set-head origin --auto >/dev/null 2>&1 || true
  local main
  main="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  main="${main#origin/}"
  [ -n "$main" ] || return

  if ! git diff --quiet HEAD 2>/dev/null; then
    echo "В папке есть свои правки — не обновляю, собираю как есть"
    return
  fi
  if [ "$(git rev-parse --abbrev-ref HEAD)" != "$main" ]; then
    echo "Переключаюсь на основную ветку $main"
    git switch --quiet "$main" || { echo "Не получилось переключиться — собираю текущую ветку"; return; }
  fi
  local before
  before="$(git rev-parse --short HEAD)"
  if git merge --ff-only --quiet "origin/$main"; then
    local after
    after="$(git rev-parse --short HEAD)"
    [ "$before" = "$after" ] && echo "Код свежий: $main @ $after" || echo "Обновлено: $before → $after"
  else
    echo "Основная ветка разошлась с GitHub — собираю локальную версию"
  fi

  # Изменения, которые ещё не попали в основную ветку: их не будет в сборке.
  local main_time ref time ahead
  main_time="$(git log -1 --format=%ct "origin/$main")"
  git for-each-ref --format='%(refname:short) %(committerdate:unix)' refs/remotes/origin |
    while read -r ref time; do
      case "$ref" in origin | origin/HEAD | "origin/$main") continue ;; esac
      [ "$time" -gt "$main_time" ] || continue
      ahead="$(git rev-list --count "origin/$main..$ref")"
      [ "$ahead" -gt 0 ] || continue
      echo "Внимание: в ветке ${ref#origin/} есть новые коммиты ($ahead), которых нет в $main — попросите Claude влить их"
    done
}

run() {
  if [ -z "${OFFLINE:-}" ] && [ -z "${NOTCH_SYNCED:-}" ]; then
    sync_with_github
    # После обновления запускаем уже новую версию этого скрипта.
    NOTCH_SYNCED=1 exec scripts/run.sh "$@"
  fi
  scripts/build-app.sh "${CONFIG:-release}"
  open build/NotchDashboard.app --args "$@"
}

run "$@"
