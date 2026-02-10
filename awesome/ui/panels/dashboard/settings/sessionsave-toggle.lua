local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local icons = require("theme.icons")
local settings = require("modules.settings-store")

local action_name = wibox.widget({
	text = "Session Autosave",
	font = "Inter Bold 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local action_status_text = wibox.widget({
	text = "Off",
	font = "Inter Regular 10",
	align = "left",
	widget = wibox.widget.textbox,
})

local action_info = wibox.widget({
	layout = wibox.layout.fixed.vertical,
	action_name,
	action_status_text,
})

local button_widget = wibox.widget({
	{
		id = "icon",
		image = icons.dashboard.settings.effects,
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

local save_status = true

local update_widget = function()
	if save_status then
		action_status_text:set_text("On")
		widget_button.bg = beautiful.system_magenta_dark
		button_widget.icon:set_image(icons.dashboard.settings.effects)
	else
		action_status_text:set_text("Off")
		widget_button.bg = beautiful.groups_bg
		button_widget.icon:set_image(icons.dashboard.settings.effects_off)
	end
end

local check_save_mode = function()
	save_status = settings.get_bool("autorestore_allowed", true)
	update_widget()
end

check_save_mode()

local enable_save = function()
	awesome.emit_signal("module::session_manager:autosave_enable")
end
local disable_save = function()
	awesome.emit_signal("module::session_manager:autosave_disable")
end

local toggle_session_save = function()
	if save_status then
		save_status = false
		disable_save()
	else
		save_status = true
		enable_save()
	end
	update_widget()
end

local check_autosave_state = function()
	save_status = settings.get_bool("autorestore_allowed", true)
	update_widget()
end

check_autosave_state()

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_session_save()
end)))

action_info:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_session_save()
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

return action_widget
