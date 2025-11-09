#!/bin/env bash

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}

run "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"

# this breaks the run dialogue for some reason
# picom doesnt duplicate so its probably fine
picom --config /home/bmorin/.config/awesome/dependencies/picom/picom.conf &
