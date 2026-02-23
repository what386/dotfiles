#!/bin/env bash

xinput --set-prop "TPPS/2 Elan TrackPoint" "libinput Scrolling Pixel Distance" 50 # slow down trackpoint scrolling
xinput --set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Speed" -0.5            # adjust trackpoint accel

xinput --set-prop "SynPS/2 Synaptics TouchPad" "libinput Scrolling Pixel Distance" 50 # slow down touchpad scrollng
xinput --set-prop "SynPS/2 Synaptics TouchPad" "libinput Accel Profile Enabled" 0 1 0 # disable touchpad accel

xset r rate 200 25 # change [delay] [repeat rate] for keys

#xinput set-prop "Mouse" "Coordinate Transformation Matrix" 0.5 0 0 0 0.5 0 0 0 1
