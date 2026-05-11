#!/usr/bin/env bash

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}

# TODO: fix
#run "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
run /usr/lib/polkit-kde-authentication-agent-1
#run "caffeine-indicator"
run "${HOME}/.upstream/archives/ollama-linux-amd64/bin/ollama" serve
