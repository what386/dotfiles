-- Required libraries
local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local naughty = require("naughty")

local icons = require("theme.icons")
local clickable_container = require("ui.clickable-container")
local userprefs = require("config.user.preferences")

local gfs = require("gears.filesystem")

local icons_battery = {
	icons.widgets.battery.discharging.battery_0,
	icons.widgets.battery.discharging.battery_5,
	icons.widgets.battery.discharging.battery_10,
	icons.widgets.battery.discharging.battery_15,
	icons.widgets.battery.discharging.battery_20,
	icons.widgets.battery.discharging.battery_25,
	icons.widgets.battery.discharging.battery_30,
	icons.widgets.battery.discharging.battery_35,
	icons.widgets.battery.discharging.battery_40,
	icons.widgets.battery.discharging.battery_45,
	icons.widgets.battery.discharging.battery_50,
	icons.widgets.battery.discharging.battery_55,
	icons.widgets.battery.discharging.battery_60,
	icons.widgets.battery.discharging.battery_65,
	icons.widgets.battery.discharging.battery_70,
	icons.widgets.battery.discharging.battery_75,
	icons.widgets.battery.discharging.battery_80,
	icons.widgets.battery.discharging.battery_85,
	icons.widgets.battery.discharging.battery_90,
	icons.widgets.battery.discharging.battery_95,
	icons.widgets.battery.discharging.battery_100,
}

local icons_charging = {
	icons.widgets.battery.charging.battery_charging_0,
	icons.widgets.battery.charging.battery_charging_5,
	icons.widgets.battery.charging.battery_charging_10,
	icons.widgets.battery.charging.battery_charging_15,
	icons.widgets.battery.charging.battery_charging_20,
	icons.widgets.battery.charging.battery_charging_25,
	icons.widgets.battery.charging.battery_charging_30,
	icons.widgets.battery.charging.battery_charging_35,
	icons.widgets.battery.charging.battery_charging_40,
	icons.widgets.battery.charging.battery_charging_45,
	icons.widgets.battery.charging.battery_charging_50,
	icons.widgets.battery.charging.battery_charging_55,
	icons.widgets.battery.charging.battery_charging_60,
	icons.widgets.battery.charging.battery_charging_65,
	icons.widgets.battery.charging.battery_charging_70,
	icons.widgets.battery.charging.battery_charging_75,
	icons.widgets.battery.charging.battery_charging_80,
	icons.widgets.battery.charging.battery_charging_85,
	icons.widgets.battery.charging.battery_charging_90,
	icons.widgets.battery.charging.battery_charging_95,
	icons.widgets.battery.charging.battery_charging_100,
}

local widget = wibox.widget({
	{
		id = "icon",
		image = icons.widgets.battery.battery_alert,
		widget = wibox.widget.imagebox,
		resize = true,
	},
	--{
	--	id = "percentage",
	--	text = "??%",
	--	widget = wibox.widget.textbox,
	--	resize = true,
	--},
	layout = wibox.layout.align.horizontal,
})

local widget_button = wibox.widget({
	{
		widget,
		margins = dpi(5.5),
		widget = wibox.container.margin,
	},
	widget = clickable_container,
})

widget_button:buttons(gears.table.join(awful.button({}, 1, nil, function()
	awful.spawn(userprefs.default.power_manager, false)
end)))

local battery_tooltip = awful.tooltip({
	text = "Loading...",
	objects = { widget_button },
	delay_show = 0.15,
	mode = "outside",
	align = "right",
	preferred_positions = { "left", "right", "top", "bottom" },
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8),
})

local icon_list = icons_battery

local persistent_battery_info = ""

awful.spawn.easy_async_with_shell("acpi -i", function(stdout)
	-- Debug: see what we're trying to parse

	-- Try to extract battery info from the second line
	local design_cap, effective_cap, health =
		string.match(stdout, "design capacity (%d+ mAh), last full capacity (%d+ mAh) = (%d+%%)")

	if design_cap and effective_cap and health then
		persistent_battery_info = "\nDesign capacity: <b>"
			.. design_cap
			.. "</b>\nEffective capacity: <b>"
			.. effective_cap
			.. "</b>\nBattery health: <b>"
			.. health
			.. "</b>"
	else
		persistent_battery_info =
			"\nDesign capacity: <b>unknown</b>\nEffective capacity: <b>unknown</b>\nBattery health: <b>unknown</b>"
	end
end)

local function get_battery_icon(charge)
	-- Clamp charge to 0-100 range
	charge = math.max(0, math.min(100, charge))

	-- Calculate icon index (1-21 for 0%-100%)
	local icon_index = math.floor(charge / 5) + 1
	icon_index = math.max(1, math.min(21, icon_index))

	return icon_list[icon_index]
end

local update_tooltip = function(status, charge, time)
	local formatted_status
	local formatted_charge
	local formatted_time

	if time and not time:match("unknown") then
		formatted_time = time
	else
		formatted_time = "unavailable"
	end

	formatted_charge = "Percentage: <b>" .. charge .. "%</b>"

	if status == "Charging" then
		formatted_status = "Time until fully charged: <b>" .. formatted_time .. "</b>"
	elseif status == "Not charging" then
		formatted_status = "Battery is not charging. "
	elseif status == "discharging at zero rate - will never fully discharge" then
		formatted_status = "Battery discharging at zero rate. "
	else
		formatted_status = "Time until discharged: <b>" .. formatted_time .. "</b>"
	end

	local message = formatted_charge .. "\n" .. formatted_status .. "\n" .. persistent_battery_info

	battery_tooltip:set_markup(message)
end

local function update_widget(status, charge)
	if not charge then
		return
	end

	if status == "Charging" then
		icon_list = icons_charging
	elseif status == "Not charging" then
		icon_list = icons_charging
	elseif status == "discharging at zero rate - will never fully discharge" then
		icon_list = icons_battery
	else
		icon_list = icons_battery
	end

	if charge then
		widget.icon:set_image(get_battery_icon(charge))
	else
		widget.icon:set_image(icons.widgets.battery.battery_alert)
	end
end

awful.widget.watch("acpi -i", 5, function(_, stdout)
	local first_line = stdout:match("^[^\r\n]+")
	local status, charge_str, time

	-- Try to match the standard format with time (HH:MM)
	status, charge_str, time = first_line:match("Battery %d+: ([^,]+), (%d+)%%, (%d+:%d+):")

	if not time then
		-- Try to match format with time remaining text (like "discharging at zero rate...")
		status, charge_str, time = first_line:match("Battery %d+: ([^,]+), (%d+)%%, (.+)$")

		if not time then
			-- Fallback: just status and charge without any time info
			status, charge_str = first_line:match("Battery %d+: ([^,]+), (%d+)%%")
			time = "Unavailable"
		end
	end

	local charge = tonumber(charge_str)
	update_widget(status, charge)
	update_tooltip(status, charge, time)
end)

return widget_button
