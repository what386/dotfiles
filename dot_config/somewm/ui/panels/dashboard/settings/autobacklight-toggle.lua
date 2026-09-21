local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local brightness = require("services.brightness")

local action_name = wibox.widget({ text = "Auto Backlight", font = "Inter Bold 10", align = "left", widget = wibox.widget.textbox })
local action_status = wibox.widget({ text = "Unavailable", font = "Inter Regular 10", align = "left", widget = wibox.widget.textbox })
local action_info = wibox.widget({ layout = wibox.layout.fixed.vertical, action_name, action_status })

local button_widget = wibox.widget({
	{ id = "icon", image = icons.dashboard.settings.brightness_off, widget = wibox.widget.imagebox, resize = true },
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		{ button_widget, margins = dpi(15), forced_height = dpi(48), forced_width = dpi(48), widget = wibox.container.margin },
		widget = clickable_container,
	},
	bg = beautiful.groups_bg,
	shape = gears.shape.circle,
	widget = wibox.container.background,
})

local function toggle_action()
	brightness.toggle_auto_backlight()
end

widget_button:buttons({awful.button({}, 1, nil, toggle_action)})
action_info:buttons({awful.button({}, 1, nil, toggle_action)})

local action_widget = wibox.widget({
	layout = wibox.layout.fixed.horizontal,
	spacing = dpi(10),
	widget_button,
	{ layout = wibox.layout.align.vertical, expand = "none", nil, action_info, nil },
})

action_widget.keyboard_activate = toggle_action
return action_widget
