#!/usr/bin/env bash
set -uo pipefail

CMD_FILE="$HOME/.cache/wallpaper/lastwlpp"
LOCK_FILE="$HOME/.cache/qs-restore-wallpaper.lock"
LOG_FILE="/tmp/restore-wallpaper.log"
PID_FILE="$HOME/.cache/qs-mpvpaper.pid"

exec >>"$LOG_FILE" 2>&1
echo "== $(date) restore-wallpaper.sh çalıştı =="

mkdir -p "$(dirname "$LOCK_FILE")"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "başka bir instance zaten çalışıyor, çıkılıyor"
    exit 0
fi

if [ ! -f "$CMD_FILE" ]; then
    echo "komut dosyası ($CMD_FILE) yok, çıkılıyor"
    exit 0
fi

CMD="$(cat "$CMD_FILE")"
echo "çalıştırılacak komut: $CMD"

if [[ "$CMD" == awww\ img* ]]; then
    if ! pgrep -x awww-daemon >/dev/null; then
        echo "awww-daemon çalışmıyor, başlatılıyor..."
        awww-daemon &
        sleep 0.5
    fi
    bash -c "$CMD"
    echo "awww komutu bitti, exit=$?"
    exit 0
fi

if [[ "$CMD" == mpvpaper\ * ]]; then
    echo "mpvpaper komutu tespit edildi, arka planda başlatılıyor..."
    [ -f "$PID_FILE" ] && kill -9 "$(cat "$PID_FILE")" 2>/dev/null
    pkill -x mpvpaper 2>/dev/null
    sleep 0.3
    setsid nohup bash -c "$CMD" >/tmp/mpvpaper.log 2>&1 </dev/null &
    NEW_PID=$!
    echo $NEW_PID > "$PID_FILE"
    echo "mpvpaper başlatıldı, pid=$NEW_PID"
    exit 0
fi

bash -c "$CMD"
echo "komut bitti, exit=$?"
