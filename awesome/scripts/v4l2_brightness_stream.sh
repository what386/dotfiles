#!/usr/bin/env bash

set -u

RUNTIME_DIR="/tmp/awesomewm-${USER:-user}"
BRIGHTNESS_FILE="${RUNTIME_DIR}/current_brightness"
STREAM_PID_FILE="${RUNTIME_DIR}/brightness_stream.pid"
DEVICE="${AUTO_BACKLIGHT_DEVICE:-/dev/video0}"
POLL_SECONDS="${AUTO_BACKLIGHT_POLL_SECONDS:-3}"

mkdir -p "$RUNTIME_DIR"

is_running() {
    [ -f "$STREAM_PID_FILE" ] || return 1
    local pid
    pid="$(cat "$STREAM_PID_FILE" 2>/dev/null || true)"
    [ -n "$pid" ] || return 1
    kill -0 "$pid" 2>/dev/null
}

normalize_brightness() {
    local raw="$1"
    awk -v value="$raw" 'BEGIN {
        if (value < 0) value = 0;
        if (value > 255) value = 255;
        printf "%.4f\n", value / 255.0;
    }'
}

stream_loop() {
    while true; do
        local raw normalized
        raw="$(v4l2-ctl -d "$DEVICE" --get-ctrl=brightness 2>/dev/null | awk -F': ' '/brightness/ {print $2}' | tr -d '[:space:]')"
        if [[ "$raw" =~ ^[0-9]+$ ]]; then
            normalized="$(normalize_brightness "$raw")"
            printf "%s\n" "$normalized" > "${BRIGHTNESS_FILE}.tmp"
            mv "${BRIGHTNESS_FILE}.tmp" "$BRIGHTNESS_FILE"
        fi
        sleep "$POLL_SECONDS"
    done
}

start_stream() {
    if is_running; then
        echo "Running"
        return 0
    fi

    if ! command -v v4l2-ctl >/dev/null 2>&1; then
        echo "v4l2-ctl not found" >&2
        return 1
    fi

    if [ ! -e "$DEVICE" ]; then
        echo "Device not found: $DEVICE" >&2
        return 1
    fi

    stream_loop >/dev/null 2>&1 &
    echo "$!" > "$STREAM_PID_FILE"
    echo "Started"
}

read_brightness() {
    cat "$BRIGHTNESS_FILE" 2>/dev/null || echo "0.5"
}

stop_stream() {
    if is_running; then
        kill "$(cat "$STREAM_PID_FILE")" 2>/dev/null || true
    fi
    rm -f "$STREAM_PID_FILE" "${BRIGHTNESS_FILE}.tmp" "$BRIGHTNESS_FILE"
    echo "Stopped"
}

status_stream() {
    if is_running; then
        echo "Running"
    else
        echo "Stopped"
    fi
}

case "${1:-}" in
    start)   start_stream ;;
    stop)    stop_stream ;;
    read)    read_brightness ;;
    status)  status_stream ;;
    *)       echo "Usage: $0 {start|stop|read|status}" ;;
esac
