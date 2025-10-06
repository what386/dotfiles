#!/bin/env bash

status_ping=0
local_ping=0

packets="$(ping -q -w2 -c2 24.147.8.143 | grep -o "100% packet loss")"
if [ ! -z "${packets}" ];
then
    status_ping=0
else
    status_ping=1
fi

packets="$(ping -q -w2 -c2 10.0.0.2 | grep -o "100% packet loss")"
if [ ! -z "${packets}" ];
then
    local_ping=0
else
    local_ping=1
fi

echo "$status_ping,$local_ping"
