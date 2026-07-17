#!/usr/bin/env bash
set -uo pipefail

PID_FILE="$HOME/.cache/qs-gsr.pid"
OVERLAY_PID_FILE="$HOME/.cache/qs-gsr-overlay.pid"
OUT_DIR="$HOME/Videos/Recordings"
LOG_FILE="/tmp/gsr-toggle.log"

exec >>"$LOG_FILE" 2>&1
echo "== $(date) gsr-toggle.sh çalıştı =="

mkdir -p "$OUT_DIR"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "kayıt durduruluyor (pid $(cat "$PID_FILE"))"
    kill -INT "$(cat "$PID_FILE")"
    rm -f "$PID_FILE"

    if [ -f "$OVERLAY_PID_FILE" ] && kill -0 "$(cat "$OVERLAY_PID_FILE")" 2>/dev/null; then
        kill "$(cat "$OVERLAY_PID_FILE")"
    fi
    rm -f "$OVERLAY_PID_FILE"

    notify-send "GPU Screen Recorder" "Kayıt durduruldu" 2>/dev/null || true
    exit 0
fi

FILE="$OUT_DIR/$(date +%Y-%m-%d_%H-%M-%S).mp4"
echo "kayıt başlıyor -> $FILE"

quickshell -p "$HOME/.config/quickshell-local/scripts/gsr-overlay" &
echo $! > "$OVERLAY_PID_FILE"

nvidia-offload gpu-screen-recorder -w screen -f 60 -a default_output -o "$FILE" &
GSR_PID=$!
echo "$GSR_PID" > "$PID_FILE"

notify-send "GPU Screen Recorder" "Kayıt başladı" 2>/dev/null || true
wait "$GSR_PID"
rm -f "$PID_FILE"

if [ -f "$OVERLAY_PID_FILE" ] && kill -0 "$(cat "$OVERLAY_PID_FILE")" 2>/dev/null; then
    kill "$(cat "$OVERLAY_PID_FILE")"
fi
rm -f "$OVERLAY_PID_FILE"

echo "kayıt süreci sonlandı"
