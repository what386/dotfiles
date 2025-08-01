local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("widget.clickable-container")

local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/dashboard/end-session/icons/"

local return_button = function()
	local widget = wibox.widget({
		{
			id = "icon",
			image = widget_icon_dir .. "logout.svg",
			resize = true,
			widget = wibox.widget.imagebox,
		},
		layout = wibox.layout.align.horizontal,
	})

	local widget_button = wibox.widget({
		{
			{
				widget,
				margins = dpi(5),
				widget = wibox.container.margin,
			},
			widget = clickable_container,
		},
		bg = beautiful.transparent,
		shape = gears.shape.circle,
		widget = wibox.container.background,
	})

	widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
		awesome.emit_signal("module::exit_screen:show")
		awful.screen.focused().control_center:toggle()
	end)))

	return widget_button
end

return return_button
