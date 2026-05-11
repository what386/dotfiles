-- Required libraries
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

require("awful.autofocus")

local modkey = "Mod4"

-- Function to create a taglist widget for each screen in AwesomeWM.
-- This function sets up a taglist for each screen connected to the system.
-- The taglist dynamically changes the color of each tag based on whether it contains any windows.
-- @param s The screen for which the taglist is being created.
-- @return A taglist widget configured for the provided screen.
return function(s)
    local tag = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = {
            awful.button({}, 1, function(t) t:view_only() end),
            awful.button({ modkey }, 1, function(t)
                if client.focus then
                    client.focus:move_to_tag(t)
                end
            end),
            awful.button({}, 3, awful.tag.viewtoggle),
            awful.button({ modkey }, 3, function(t)
                if client.focus then
                    client.focus:toggle_tag(t)
                end
            end),
            awful.button({}, 4, function(t) awful.tag.viewprev(t.screen) end),
            awful.button({}, 5, function(t) awful.tag.viewnext(t.screen) end),
        }
    }

    return tag
end
