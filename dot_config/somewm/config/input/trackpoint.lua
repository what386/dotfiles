local awful = require("awful")

-- nil  device default (strings)
-- -1:	device default
-- 0:	disable feature
-- 1:	enable feature

awful.input.rules = {
  { rule = { name = "TrackPoint" },
    properties = {
      -- Tap touchpad to click
      tap_to_click = 1,

      -- Invert scrolling direction (macOS-style)
      natural_scrolling = 0,

      -- Pointer acceleration speed
      -- Range: -1.0 to 1.0
      -- Negative = slower pointer movement
      -- Positive = faster pointer movement
      accel_speed = 0.25,

      -- Button used for scroll-on-button-down
      -- 0   = device default
      -- 274 = middle mouse button (common TrackPoint setup)
      -- 8   = back/thumb mouse button
      scroll_button = 274,

      -- Swap left/right mouse buttons
      left_handed = 0,

      -- Press left+right together for middle click
      middle_button_emulation = 1,

      -- Scroll method:
      -- "two_finger" = two-finger scrolling
      -- "edge"       = edge scrolling
      -- "button"     = hold button while moving pointer to scroll
      scroll_method = nil,

      -- Pointer acceleration profile:
      -- "adaptive" = acceleration changes with movement speed
      -- "flat"     = constant pointer speed
      accel_profile = "flat",

      -- Tap then drag without physically clicking
      tap_and_drag = 0,

      -- Keep dragging active briefly after finger release
      drag_lock = 0,

      -- Three-finger drag gesture
      -- Tap with 3 fingers, continue dragging with 1
      tap_3fg_drag = -1,

      -- Disable touchpad while typing
      disable_while_typing = 1,

      -- Disable touchpad while TrackPoint is active (ThinkPads)
      dwtp = 1,

      -- Scroll button behavior:
      -- 1 = press once to toggle scrolling mode
      -- 0 = hold button continuously to scroll
      scroll_button_lock = -1,

      -- Multi-finger click mapping:
      -- "lrm" = 1:left  2:right  3:middle
      -- "lmr" = 1:left  2:middle 3:right
      clickfinger_button_map = nil,

      -- Multi-finger tap mapping:
      -- "lrm" = 1:left  2:right  3:middle
      -- "lmr" = 1:left  2:middle 3:right
      tap_button_map = nil,

      -- Physical click handling:
      -- "none"         = disable software click handling
      -- "button_areas" = use touchpad button regions
      -- "clickfinger"  = use finger count to determine click type
      click_method = nil,

      -- Device event forwarding:
      -- "enabled"                    = always send events
      -- "disabled"                   = never send events
      -- "disabled_on_external_mouse" = disable when external mouse connected
      send_events_mode = nil
    }
  },
}
