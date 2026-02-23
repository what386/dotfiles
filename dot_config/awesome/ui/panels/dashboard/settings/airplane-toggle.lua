local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local clickable_container = require("ui.clickable-container")
local settings = require("modules.settings-store")
local icons = require("theme.icons")
local ap_state = false

local action_name = wibox.widget({
	text = "Airplane Mode",
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
		image = icons.dashboard.settings.airplane_mode_off,
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
	if ap_state then
		action_status:set_text("On")
		widget_button.bg = beautiful.accent
		button_widget.icon:set_image(icons.dashboard.settings.airplane_mode)
	else
		action_status:set_text("Off")
		widget_button.bg = beautiful.groups_bg
		button_widget.icon:set_image(icons.dashboard.settings.airplane_mode_off)
	end
end

local check_airplane_mode_state = function()
	ap_state = settings.get_bool("airplane_mode", false)
	update_widget()
end

check_airplane_mode_state()

local ap_off_cmd = [[
	
	rfkill unblock wlan

	# Create an AwesomeWM Notification
	awesome-client "
	naughty = require('naughty')
	naughty.notification({
		app_name = 'Network Manager',
		title = '<b>Airplane mode disabled!</b>',
		message = 'Initializing network devices',
		icon = ']] .. icons.dashboard.settings.airplane_mode_off .. [['
	})
	"
]]

local ap_on_cmd = [[

	rfkill block wlan

	# Create an AwesomeWM Notification
	awesome-client "
	naughty = require('naughty')
	naughty.notification({
		app_name = 'Network Manager',
		title = '<b>Airplane mode enabled!</b>',
		message = 'Disabling radio devices',
		icon = ']] .. icons.dashboard.settings.airplane_mode .. [['
	})
	"
]]

local toggle_action = function()
	if ap_state then
		awful.spawn.easy_async_with_shell(ap_off_cmd, function(stdout)
			ap_state = false
			settings.set_bool("airplane_mode", false)
			update_widget()
		end)
	else
		awful.spawn.easy_async_with_shell(ap_on_cmd, function(stdout)
			ap_state = true
			settings.set_bool("airplane_mode", true)
			update_widget()
		end)
	end
end

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_action()
end)))

action_info:buttons(gears.table.join(awful.button({}, 1, nil, function()
	toggle_action()
end)))

awful.spawn.with_line_callback("rfkill event", {
	stdout = function(_)
		check_airplane_mode_state()
	end,
})

gears.timer({
	timeout = 120,
	autostart = true,
	callback = check_airplane_mode_state,
})

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
