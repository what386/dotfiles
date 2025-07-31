#!/bin/env bash

# for some reason, a higher number is slower...
xinput --set-prop 10 "libinput Scrolling Pixel Distance" 50 #slow down touchpad scrollng
xinput --set-prop 11 "libinput Scrolling Pixel Distance" 50 # slow down trackpoint scrolling

xinput --set-prop 10 "libinput Accel Profile Enabled" 0 1 0 # disable touchpad accel
#xinput --set-prop 11 "libinput Accel Profile Enabled" 0 1 0 # disable trackpoint accel

# but now, a lower number is slower?
xinput --set-prop 11 "libinput Accel Speed" -0.25 #adjust trackpoint speed
