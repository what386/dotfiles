#!/bin/bash

# Handles both xss-lock daemon setup and lockscreen/suspend execution

# Configuration
LOCK_TIMEOUT=120                                                                       # Time before locking (seconds)
SUSPEND_TIMEOUT=120                                                                    # Additional time before suspend after lock (seconds)
LOCK_SCRIPT='echo "awesome.emit_signal(\"screen::lockscreen:show\")" | awesome-client' # Command to execute for locking
DAEMON_SCRIPT="$0"                                                                     # This script handles daemon and lock execution
PID_FILE="/tmp/xss-lock-awesome-$USER.pid"

# Lock the screen using configurable command
lock_screen() {
    if ! eval "$LOCK_SCRIPT"; then
        return 1
    fi
}

# Suspend the system
suspend_system() {
    if ! systemctl suspend; then
        return 1
    fi
}

# Check if screen is still locked by checking if awesome lockscreen is active
is_screen_locked() {
    # Query awesome to see if lockscreen is still active
    local result
    result=$(echo "return awesome.emit_signal and awesome.emit_signal('screen::lockscreen:query') or 'unlocked'" | awesome-client 2>/dev/null)

    # If awesome-client fails or returns unlocked, screen is not locked
    if [[ $? -ne 0 ]] || [[ "$result" == *"unlocked"* ]]; then
        return 1
    fi

    # Additional check: if awesome process is gone, screen is not locked
    if ! pgrep -f "awesome" >/dev/null; then
        return 1
    fi

    return 0
}

# Handle screen lock with optional suspend
handle_lock() {
    if ! lock_screen; then
        exit 1
    fi

    if [ "$1" = "suspend" ]; then
        # Instead of sleeping unconditionally, check periodically if screen is still locked
        local elapsed=0
        local check_interval=10 # Check every 5 seconds

        while [ $elapsed -lt $SUSPEND_TIMEOUT ]; do
            sleep $check_interval
            elapsed=$((elapsed + check_interval))

            # If screen is no longer locked, user became active - exit without suspending
            if ! is_screen_locked; then
                exit 0
            fi
        done

        # Only suspend if screen is still locked after timeout
        if is_screen_locked && pgrep -f "awesome" >/dev/null; then
            suspend_system
        fi
    fi
}

# Start the xss-lock daemon
start_daemon() {
    # Kill any existing xss-lock processes for this user
    if [ -f "$PID_FILE" ]; then
        local old_pid
        old_pid=$(cat "$PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid"
            sleep 1
        fi
        rm -f "$PID_FILE"
    fi

    # Configure X11 screensaver settings
    xset s "$LOCK_TIMEOUT" "$SUSPEND_TIMEOUT"

    # Start xss-lock daemon
    xss-lock -l -- "$DAEMON_SCRIPT" lock suspend &
    local xss_pid=$!

    # Save PID for cleanup
    echo "$xss_pid" >"$PID_FILE"

    # Verify xss-lock started successfully
    sleep 1
    if ! kill -0 "$xss_pid" 2>/dev/null; then
        rm -f "$PID_FILE"
        return 1
    fi
}

# Stop the xss-lock daemon
stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
        fi
        rm -f "$PID_FILE"
    fi

    # Also kill any xss-lock processes that might be running
    if pgrep -f "xss-lock.*$DAEMON_SCRIPT" >/dev/null; then
        pkill -f "xss-lock.*$DAEMON_SCRIPT"
    fi
}

# Check daemon status
status_daemon() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "xss-lock daemon is running (PID: $pid)"
            return 0
        else
            rm -f "$PID_FILE"
            return 1
        fi
    else
        echo "xss-lock daemon is not running"
        return 1
    fi
}

# Restart the daemon
restart_daemon() {
    stop_daemon
    sleep 1
    start_daemon
}

# Show usage information
show_usage() {
    cat <<EOF

USAGE:
    $0 <command> [options]

COMMANDS:
    start           Start the lockscreen daemon with xss-lock
    stop            Stop the lockscreen daemon
    restart         Restart the lockscreen daemon  
    status          Show daemon status
    lock            Lock the screen immediately
    lock suspend    Lock the screen and suspend after timeout
    
CONFIGURATION:
    Edit the variables at the top of this script to customize:
    - LOCK_TIMEOUT: Time before auto-lock (currently ${LOCK_TIMEOUT}s)
    - SUSPEND_TIMEOUT: Time from lock to suspend (currently ${SUSPEND_TIMEOUT}s)
    - LOCK_SCRIPT: Command to execute for locking

EXAMPLES:
    $0 start                    # Start auto-lock daemon
    $0 lock                     # Lock screen now
    $0 status                   # Check if daemon is running

EOF
}

# Main command handling
case "${1:-}" in
"start")
    start_daemon
    ;;
"stop")
    stop_daemon
    ;;
"restart")
    restart_daemon
    ;;
"status")
    status_daemon
    ;;
"lock")
    if [ "$2" = "suspend" ]; then
        handle_lock suspend
    else
        handle_lock
    fi
    ;;
"help" | "--help" | "-h")
    show_usage
    ;;
"")
    exit 1
    ;;
*)
    exit 1
    ;;
esac
