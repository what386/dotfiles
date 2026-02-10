local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local settings = require("modules.settings-store")
local icons = require("theme.icons")

_G.dont_disturb_state = false

local action_name = wibox.widget({
	text = "Don't Disturb",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local action_status = wibox.widget({
	text = "Off",
	font = "Inter Regular 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local action_info = wibox.widget({
	layout = wibox.layout.fixed.vertical,
	action_name,
	action_status,
})

local button_widget = wibox.widget({
	{
		id = "icon",
		image = icons.dashboard.settings.notify,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		{
			button_widget,
			margins = dpi(15),
			forced_height = dpi(48),
			forced_width = dpi(48),
			widget = wibox.container.margin,
		},
		widget = clickable_container,
	},
	bg = beautiful.groups_bg,
	shape = gears.shape.circle,
	widget = wibox.container.background,
})

local update_widget = function()
	if dont_disturb_state then
		action_status:set_text("On")
		widget_button.bg = beautiful.system_cyan_dark
		button_widget.icon:set_image(icons.dashboard.settings.dont_disturb)
	else
		action_status:set_text("Off")
		widget_button.bg = beautiful.groups_bg
		button_widget.icon:set_image(icons.dashboard.settings.notify)
	end
end

local check_disturb_status = function()
	dont_disturb_state = settings.get_bool("disturb_status", false)
	update_widget()
end

check_disturb_status()

local toggle_action = function()
	if dont_disturb_state then
		dont_disturb_state = false
	else
		dont_disturb_state = true
	end
	settings.set_bool("disturb_status", dont_disturb_state)
	update_widget()
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_action()
end)))

action_info:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_action()
end)))

local action_widget = wibox.widget({
	layout = wibox.layout.fixed.horizontal,
	spacing = dpi(10),
	widget_button,
	{
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		action_info,
		nil,
	},
})

-- Create a notification sound
naughty.connect_signal("request::display", function(n)
	if not dont_disturb_state then
		awful.spawn.with_shell("canberra-gtk-play -i message")
	end
end)

return action_widget
