local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local dpi = require("beautiful").xresources.apply_dpi
local icons = require("theme.icons")
local state = false

local clickable_container = require("ui.clickable-container")

local action_name = wibox.widget({
	text = "Automatic Brightness",
	font = "Inter Regular 11",
	align = "left",
	widget = wibox.widget.textbox,
})

local button_widget = wibox.widget({
	{
		id = "icon",
		image = icons.system.toggled_off,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		button_widget,
		top = dpi(7),
		bottom = dpi(7),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

local action_widget = wibox.widget({
	{
		action_name,
		nil,
		{
			widget_button,
			layout = wibox.layout.fixed.horizontal,
		},
		layout = wibox.layout.align.horizontal,
	},
	left = dpi(24),
	right = dpi(24),
	forced_height = dpi(48),
	widget = wibox.container.margin,
})

local update_imagebox = function()
	if state then
		button_widget.icon:set_image(icons.system.toggled_on)
	else
		button_widget.icon:set_image(icons.system.toggled_off)
	end
end

local toggle_action = function()
	if state then
		state = false
		awesome.emit_signal("module::auto_brightness:stop")
		update_imagebox()
	else
		state = true
		awesome.emit_signal("module::auto_brightness:start")
		update_imagebox()
	end
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_action()
end)))

return action_widget
