local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local dpi = require("beautiful").xresources.apply_dpi

local userprefs = require("config.user.preferences")

local clickable_container = require("ui.clickable-container")

local icons = require("theme.icons")

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.bluetooth.bluetooth_off,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		widget,
		margins = dpi(6),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn(userprefs.default.bluetooth_manager, false)
end)))

local bluetooth_tooltip = awful.tooltip({
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "right", "left", "top", "bottom" },
})

local function apply_state(stdout)
	if stdout:match("Soft blocked: yes") then
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_off)
		bluetooth_tooltip.markup = "Bluetooth is off"
	else
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_on)
		bluetooth_tooltip.markup = "Bluetooth is on"
	end
end

local function refresh_state()
	awful.spawn.easy_async_with_shell("rfkill list bluetooth", function(stdout)
		apply_state(stdout)
	end)
end

awful.spawn.with_line_callback("rfkill event", {
	stdout = function(_)
		refresh_state()
	end,
})

gears.timer({
	timeout = 120,
	autostart = true,
	call_now = true,
	callback = refresh_state,
})

return widget_button
