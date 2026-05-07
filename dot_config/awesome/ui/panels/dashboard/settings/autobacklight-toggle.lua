local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local brightness = require("services.brightness")

local action_name = wibox.widget({ text = "Auto Backlight", font = "Inter Bold 10", align = "left", widget = wibox.widget.textbox })
local action_status = wibox.widget({ text = "Off", font = "Inter Regular 10", align = "left", widget = wibox.widget.textbox })
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

local function update_widget(enabled)
	if enabled then
		action_status:set_text("On")
		widget_button.bg = beautiful.accent
		button_widget.icon:set_image(icons.dashboard.settings.brightness)
	else
		action_status:set_text("Off")
		widget_button.bg = beautiful.groups_bg
		button_widget.icon:set_image(icons.dashboard.settings.brightness_off)
	end
end

local function toggle_action()
	brightness.toggle_auto_backlight()
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, toggle_action)))
action_info:buttons(gears.table.join(awful.button({}, 1, nil, toggle_action)))

awesome.connect_signal("brightness::auto-backlight", update_widget)
update_widget(brightness.get_state().auto_backlight)

return wibox.widget({
	layout = wibox.layout.fixed.horizontal,
	spacing = dpi(10),
	widget_button,
	{ layout = wibox.layout.align.vertical, expand = "none", nil, action_info, nil },
})
