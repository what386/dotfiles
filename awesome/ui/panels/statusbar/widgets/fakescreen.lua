local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local watch = awful.widget.watch
local dpi = require("beautiful").xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")

-- Track HDMI state
local hdmi_enabled = false

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

local hdmi_tooltip = awful.tooltip({
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
	preferred_positions = { "right", "left", "top", "bottom" },
})

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	if hdmi_enabled then
		-- Toggle OFF
		awful.spawn.with_shell("xrandr --delmode HDMI-1 1920x1080")
		hdmi_enabled = false
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_off)
		hdmi_tooltip.markup = "HDMI-1 is disabled"
		naughty.notify({
			title = "HDMI Display",
			text = "HDMI-1 disabled",
			timeout = 2,
		})
	else
		-- Toggle ON
		awful.spawn.with_shell(
			"xrandr --addmode HDMI-1 1920x1080 && xrandr --output HDMI-1 --mode 1920x1080 --above eDP-1"
		)
		hdmi_enabled = true
		widget.icon:set_image(icons.widgets.bluetooth.bluetooth_on)
		hdmi_tooltip.markup = "HDMI-1 is enabled"
		naughty.notify({
			title = "HDMI Display",
			text = "HDMI-1 enabled at 1920x1080",
			timeout = 2,
		})
	end
end)))

return widget_button
