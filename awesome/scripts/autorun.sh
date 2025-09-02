#!/bin/env bash

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}

run "lxpolkit"             # authenticator
run "mintupdate-launcher"  # update manager
run "kdeconnect-indicator" # kdeconnect

# this breaks the run dialogue for some reason
# picom doesnt duplicate so its probably fine
picom --config /home/bmorin/.config/awesome/dependencies/picom/picom.conf
