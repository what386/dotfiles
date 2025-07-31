local awful = require("awful")
local naughty = require("naughty")
local icons = require("theme.icons")

local battery_notify = function(message, title, app_name, icon)
	naughty.notification({
		message = message,
		title = title,
		app_name = app_name,
		icon = icon,
	})
end

local notify_battery_low = function(time)
	local formatted_time
	if time and not time:match("unknown") then
		formatted_time = time
	else
		formatted_time = "unavailable"
	end

	local message = "System will hibernate at 1%" .. "\nTime remaining: <b>" .. formatted_time .. "</b>"
	local title = "Battery is low"
	local app_name = "System Notification"
	local icon = icons.widgets.battery.battery_alert
	battery_notify(message, title, app_name, icon)
end

local notify_system_hibernation = function()
	local message = "System hibernating in 5 seconds!"
	local title = "Battery critically low"
	local app_name = "System Notification"
	local icon = icons.widgets.battery.battery_alert
	battery_notify(message, title, app_name, icon)
end

local message_shown = false
local function check_battery_status(status, charge, time)
	if not charge then
		return
	end

	if charge <= 5 and not message_shown then
		notify_battery_low(time)
		message_shown = true
	end

	if charge > 5 then
		message_shown = false
	end

	-- luas "!=" is "~=" and thats kinda fucked up
	if charge <= 1 and status ~= "Charging" then
		notify_system_hibernation()
		awful.spawn.easy_async_with_shell([[
			sleep 5
			systemctl hibernate
			]])
	end
end

awful.widget.watch("acpi -i", 10, function(_, stdout)
	local status, charge_str, time = string.match(stdout, ".+: (%a+), (%d+)%%, (%d+:%d+:%d+)")
	local charge = tonumber(charge_str)

	check_battery_status(status, charge, time)
end)
