local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")

local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. "ui/panels/dashboard/settings/icons/"
local data_dir = config_dir .. "persistent/"

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
		image = widget_icon_dir .. "effects.svg",
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
		button_widget.icon:set_image(widget_icon_dir .. "effects.svg")
		awful.spawn("echo false > " .. data_dir .. "autosave")
	else
		action_status_text:set_text("Off")
		widget_button.bg = beautiful.groups_bg
		button_widget.icon:set_image(widget_icon_dir .. "effects-off.svg")
		awful.spawn("echo true > " .. data_dir .. "autosave")
	end
end

local check_save_mode = function()
	local cmd = "cat " .. data_dir .. "airplane_mode"

	awful.spawn.easy_async_with_shell(cmd, function(stdout)
		local status = stdout

		if status:match("true") then
			save_status = true
		elseif status:match("false") then
			save_status = false
		end

		update_widget()
	end)
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
	local cmd = "cat " .. data_dir .. "autosave"

	awful.spawn.easy_async_with_shell(cmd, function(stdout)
		local status = stdout

		if status:match("true") then
			save_status = true
		elseif status:match("false") then
			save_status = false
		else
			save_status = true
			awful.spawn('echo "true" > ' .. data_dir .. "autosave", function(stdout) end)
		end
		update_widget()
	end)
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
