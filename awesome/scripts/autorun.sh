#!/bin/env bash

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}
run "lxpolkit" # authenticator

run "xss-lock i3lock-fancy" # screen locker

run "mintupdate-launcher" # update manager

run "kdeconnect-indicator" # kdeconnect

# this breaks the run dialogue for some reason
# picom doesnt duplicate so its probably fine
picom --config /home/bmorin/.config/awesome/dependencies/picom/picom.conf


