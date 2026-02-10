#!/usr/bin/env bash

# Manage xss-lock daemon and lock/suspend flow for AwesomeWM lockscreen.

set -u

LOCK_TIMEOUT="${LOCK_TIMEOUT:-300}"          # idle seconds before lock
SUSPEND_TIMEOUT="${SUSPEND_TIMEOUT:-120}"    # seconds after lock before suspend
PID_FILE="/tmp/xss-lock-awesome-${USER}.pid"

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")"
AWESOME_LOCK_CMD='awesome.emit_signal("screen::lockscreen:show")'
AWESOME_QUERY_CMD='if awesome and awesome._lockscreen_is_locked then return 1 else return 0 end'

log() {
    printf '[screenlock] %s\n' "$*" >&2
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1
}

is_pid_ours() {
    local pid="$1"
    [ -n "$pid" ] || return 1
    [ -d "/proc/$pid" ] || return 1
    tr '\0' ' ' </proc/"$pid"/cmdline 2>/dev/null | grep -q "xss-lock"
}

query_locked() {
    local output

    if ! require_cmd awesome-client; then
        return 1
    fi

    output="$(awesome-client "$AWESOME_QUERY_CMD" 2>/dev/null | tr -d '[:space:]')"
    [ "$output" = "1" ]
}

lock_screen() {
    if ! require_cmd awesome-client; then
        log "awesome-client not found"
        return 1
    fi

    if ! awesome-client "$AWESOME_LOCK_CMD" >/dev/null 2>&1; then
        log "failed to emit lockscreen signal"
        return 1
    fi

    # Wait briefly for Awesome to report lock state.
    local i=0
    while [ "$i" -lt 30 ]; do
        if query_locked; then
            return 0
        fi
        sleep 0.1
        i=$((i + 1))
    done

    log "lockscreen signal sent, but lock state was not confirmed"
    return 1
}

suspend_system() {
    if ! require_cmd systemctl; then
        log "systemctl not found"
        return 1
    fi

    systemctl suspend
}

handle_lock() {
    if ! lock_screen; then
        return 1
    fi

    if [ "${1:-}" = "suspend" ]; then
        local elapsed=0
        local check_interval=5

        while [ "$elapsed" -lt "$SUSPEND_TIMEOUT" ]; do
            sleep "$check_interval"
            elapsed=$((elapsed + check_interval))

            # User unlocked before timeout, so skip suspend.
            if ! query_locked; then
                return 0
            fi
        done

        if query_locked; then
            suspend_system
        fi
    fi
}

start_daemon() {
    if ! require_cmd xss-lock; then
        log "xss-lock not found"
        return 1
    fi

    if ! require_cmd xset; then
        log "xset not found"
        return 1
    fi

    if [ -f "$PID_FILE" ]; then
        local old_pid
        old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if is_pid_ours "$old_pid"; then
            log "daemon already running (PID: $old_pid)"
            return 0
        fi
        rm -f "$PID_FILE"
    fi

    xset s "$LOCK_TIMEOUT" "$SUSPEND_TIMEOUT"

    # -l locks before suspend, command after -- is invoked by xss-lock.
    xss-lock -l -- "$SCRIPT_PATH" lock suspend &
    local xss_pid=$!
    echo "$xss_pid" >"$PID_FILE"

    sleep 0.5
    if ! is_pid_ours "$xss_pid"; then
        rm -f "$PID_FILE"
        log "failed to start xss-lock daemon"
        return 1
    fi

    log "daemon started (PID: $xss_pid)"
    return 0
}

stop_daemon() {
    local pid=""
    if [ -f "$PID_FILE" ]; then
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if is_pid_ours "$pid"; then
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi

    # Cleanup any stale instances for this user/script.
    pkill -u "$USER" -f "xss-lock.*$SCRIPT_PATH" 2>/dev/null || true

    log "daemon stopped"
}

status_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid="$(cat "$PID_FILE" 2>/dev/null || true)"
        if is_pid_ours "$pid"; then
            echo "xss-lock daemon is running (PID: $pid)"
            return 0
        fi
        rm -f "$PID_FILE"
    fi

    echo "xss-lock daemon is not running"
    return 1
}

restart_daemon() {
    stop_daemon
    start_daemon
}

show_usage() {
    cat <<USAGE
USAGE:
  $0 <command>

COMMANDS:
  start            Start xss-lock daemon
  stop             Stop xss-lock daemon
  restart          Restart xss-lock daemon
  status           Show daemon status
  lock             Lock immediately
  lock suspend     Lock and suspend after timeout if still locked
USAGE
}

case "${1:-}" in
start)
    start_daemon
    ;;
stop)
    stop_daemon
    ;;
restart)
    restart_daemon
    ;;
status)
    status_daemon
    ;;
lock)
    if [ "${2:-}" = "suspend" ]; then
        handle_lock suspend
    else
        handle_lock
    fi
    ;;
help|--help|-h)
    show_usage
    ;;
*)
    show_usage
    exit 1
    ;;
esac
