#!/usr/bin/env bash

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}

run /usr/lib/polkit-kde-authentication-agent-1
run blueman-applet
run "${HOME}/.upstream/symlinks/ollama" serve
