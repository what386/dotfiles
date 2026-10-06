#!/usr/bin/env bash

# Make the Wayland session available to D-Bus and systemd-activated portals.
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}

run /usr/lib/polkit-kde-authentication-agent-1
run blueman-applet
run "${HOME}/.upstream/state/symlinks/ollama" serve
