#!/bin/bash

BRIGHTNESS_FILE="/tmp/current_brightness"
STREAM_PID_FILE="/tmp/brightness_stream.pid"

start_v4l2_stream() {
    # Use v4l2-ctl to continuously read camera brightness/exposure
    while true; do
        # Get hardware brightness value directly
        brightness=$(v4l2-ctl -d /dev/video0 --get-ctrl=brightness 2>/dev/null | awk -F': ' '{print $2/255}')
        
        # If hardware brightness not available, fall back to frame analysis
        if [ -z "$brightness" ] || [ "$brightness" = "/255" ]; then
            # Quick frame grab and analysis
            brightness=$(timeout 1 ffmpeg -f v4l2 -i /dev/video0 -vframes 1 \
                        -vf scale=40:30 -f image2 pipe:1 2>/dev/null | \
                        convert - -resize 1x1 -format "%[fx:mean]" info: 2>/dev/null)
        fi
        
        if [ -n "$brightness" ]; then
            echo "$brightness" > "$BRIGHTNESS_FILE"
            echo "$(date '+%H:%M:%S') $brightness"
        fi
        
        sleep 2  # Adjust polling rate as needed
    done &
    
    echo $! > "$STREAM_PID_FILE"
}

read_brightness() {
    cat "$BRIGHTNESS_FILE" 2>/dev/null || echo "0.5"
}

stop_stream() {
    if [ -f "$STREAM_PID_FILE" ]; then
        kill $(cat "$STREAM_PID_FILE") 2>/dev/null
        rm -f "$STREAM_PID_FILE" "$BRIGHTNESS_FILE"
    fi
}

case "$1" in
    start)   start_v4l2_stream ;;
    stop)    stop_stream ;;
    read)    read_brightness ;;
    status)  [ -f "$STREAM_PID_FILE" ] && echo "Running" || echo "Stopped" ;;
    *)       echo "Usage: $0 {start|stop|read|status}" ;;
esac
